#!/usr/bin/env python3
"""Merge repository-owned entries into files the agents also write.

`~/.codex/config.toml`, `~/.codex/rules/default.rules`, and
`~/.claude/settings.json` are shared: this repository owns some of their entries
and the agent owns the rest. None of them is ever replaced. Every entry this
program writes is recorded in a state file, and the record is what decides
whether a later run may change or withdraw it:

- write an entry only when it is absent, or when its current value is
  byte-identical to the value the state file says was written;
- withdraw an entry only when the state file records that this program
  introduced it and the entry is still byte-identical to what was written;
- otherwise preserve the entry and report it.

A missing state file therefore means nothing is managed: the run adds what is
absent, changes nothing that exists, and removes nothing. `DECISIONS.md` records
why provenance lives outside the files rather than in them.
"""

import argparse
import json
import os
import pathlib
import re
import shutil
import sys

STATE_VERSION = 1

# Table headers and key lines as this program writes and recognises them. A
# quoted key can hold anything, so both string forms are matched; Codex writes
# literal strings for project paths and this program writes basic strings.
TABLE_PATTERN = re.compile(r"^\s*\[([^\[\]]*)\]\s*$")
KEY_PATTERN = re.compile(
    r"""^\s*(?P<key>[A-Za-z0-9_-]+|"(?:[^"\\]|\\.)*"|'[^']*')\s*="""
)
PRUNED_DIRECTORIES = {
    ".git",
    "node_modules",
    ".venv",
    "venv",
    "target",
    "build",
    "dist",
}


class Report:
    """Collects the lines the installer prints for this run."""

    def __init__(self):
        self.lines = []

    def add(self, message):
        self.lines.append(message)

    def emit(self):
        for line in self.lines:
            print(line)


def decode_toml_key(token):
    """Return the value of a bare, basic, or literal TOML key."""

    if token.startswith("'"):
        return token[1:-1]

    if not token.startswith('"'):
        return token

    def replace(match):
        escape = match.group(1)
        if escape.startswith("u"):
            return chr(int(escape[1:], 16))
        return {"n": "\n", "t": "\t", "r": "\r"}.get(escape, escape)

    return re.sub(r"\\(u[0-9a-fA-F]{4}|.)", replace, token[1:-1])


def encode_toml_basic_string(value):
    if any(ord(character) < 0x20 or ord(character) == 0x7F for character in value):
        raise SystemExit(
            "error: project path contains unsupported control characters: %r" % value
        )
    return '"%s"' % value.replace("\\", "\\\\").replace('"', '\\"')


def read_text(path):
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def split_lines(text):
    return text.split("\n")[:-1] if text.endswith("\n") else text.split("\n")


def join_lines(lines):
    return "".join(line + "\n" for line in lines)


def index_config(lines):
    """Map the target file's tables and keys to line numbers.

    Returns the last content line of each table, so a new key lands with the
    table it belongs to, the line of each key, and the keys a file defines more
    than once. An ambiguous key is never written, because there is no way to
    tell which occurrence the agent reads.
    """

    table_end = {"": -1}
    keys = {}
    ambiguous = set()
    current = ""

    for number, line in enumerate(lines):
        header = TABLE_PATTERN.match(line)
        if header:
            current = header.group(1).strip()
            table_end[current] = number
            continue

        if line.strip():
            table_end[current] = number

        key = KEY_PATTERN.match(line)
        if key:
            identity = (current, decode_toml_key(key.group("key")))
            if identity in keys:
                ambiguous.add(identity)
            else:
                keys[identity] = number

    return table_end, keys, ambiguous


def parse_source_entries(text):
    """Return the (table, key, line) entries this repository owns."""

    entries = []
    current = ""

    for line in split_lines(text):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        header = TABLE_PATTERN.match(line)
        if header:
            current = header.group(1).strip()
            continue

        key = KEY_PATTERN.match(line)
        if key:
            entries.append((current, decode_toml_key(key.group("key")), line.rstrip()))

    return entries


def insert_config_key(lines, table, new_line):
    table_end, _, _ = index_config(lines)

    if table not in table_end:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append("[%s]" % table)
        lines.append(new_line)
        return

    lines.insert(table_end[table] + 1, new_line)


def describe(table, key):
    return key if not table else "%s.%s" % (table, key)


def discover_trusted_projects(roots):
    """Return each root and every Git worktree beneath it."""

    projects = []
    seen = set()

    for root in roots:
        root_path = pathlib.Path(root)
        candidates = [str(root_path)]

        if root_path.is_dir():
            for current, directories, _ in os.walk(str(root_path)):
                if pathlib.Path(current, ".git").exists():
                    candidates.append(current)
                directories[:] = [
                    directory
                    for directory in directories
                    if directory not in PRUNED_DIRECTORIES
                    and not pathlib.Path(current, directory).is_symlink()
                ]

        for candidate in candidates:
            key = os.path.normcase(os.path.normpath(candidate))
            if key not in seen:
                seen.add(key)
                projects.append(candidate)

    return projects


def project_tables(lines):
    """Map each trusted project path in the file to its table header line."""

    found = {}

    for number, line in enumerate(lines):
        header = TABLE_PATTERN.match(line)
        if not header:
            continue

        name = header.group(1).strip()
        if not name.startswith("projects."):
            continue

        path = decode_toml_key(name[len("projects.") :])
        found[os.path.normcase(os.path.normpath(path))] = number

    return found


def merge_config(source, target, state, trust_roots, report):
    """Merge the repository's Codex defaults and trust entries into the target."""

    entries = parse_source_entries(read_text(source))
    if not entries:
        raise SystemExit("error: no managed entries in %s" % source)

    lines = split_lines(read_text(target))
    recorded_keys = {
        (record["table"], record["key"]): record["line"]
        for record in state.get("keys", [])
    }
    recorded_preexisting = {
        (record["table"], record["key"]) for record in state.get("preexisting", [])
    }
    recorded_trust = {
        os.path.normcase(os.path.normpath(record["path"])): record
        for record in state.get("trust", [])
    }

    managed = []
    preexisting = []
    changed = False

    for table, key, new_line in entries:
        identity = (table, key)
        _, keys, ambiguous = index_config(lines)
        label = describe(table, key)

        if identity in ambiguous:
            report.add("preserved: %s defines %s more than once" % (target, label))
            continue

        if identity not in keys:
            insert_config_key(lines, table, new_line)
            managed.append({"table": table, "key": key, "line": new_line})
            report.add("set: %s %s" % (target, label))
            changed = True
            continue

        current = lines[keys[identity]].rstrip()

        if identity in recorded_preexisting or identity not in recorded_keys:
            preexisting.append({"table": table, "key": key})
            if current != new_line:
                report.add(
                    "preserved: %s has %s; the baseline sets %s"
                    % (target, current.strip(), new_line)
                )
            continue

        if current != recorded_keys[identity]:
            managed.append(
                {"table": table, "key": key, "line": recorded_keys[identity]}
            )
            report.add("preserved: %s %s changed since installation" % (target, label))
            continue

        if current != new_line:
            lines[keys[identity]] = new_line
            report.add("updated: %s %s" % (target, label))
            changed = True

        managed.append({"table": table, "key": key, "line": new_line})

    source_identities = {(table, key) for table, key, _ in entries}
    for identity, recorded_line in recorded_keys.items():
        if identity in source_identities:
            continue

        _, keys, _ = index_config(lines)
        if identity not in keys:
            continue

        label = describe(*identity)
        if lines[keys[identity]].rstrip() == recorded_line:
            del lines[keys[identity]]
            report.add("withdrew: %s %s" % (target, label))
            changed = True
        else:
            report.add(
                "preserved: %s %s is no longer managed and has changed" % (target, label)
            )

    trust = []
    wanted = discover_trusted_projects(trust_roots)
    wanted_keys = set()

    for path in wanted:
        key = os.path.normcase(os.path.normpath(path))
        wanted_keys.add(key)
        existing = project_tables(lines)

        if key in existing:
            if key in recorded_trust:
                trust.append(recorded_trust[key])
            continue

        block = [
            "[projects.%s]" % encode_toml_basic_string(path),
            'trust_level = "trusted"',
        ]
        if lines and lines[-1].strip():
            lines.append("")
        lines.extend(block)
        trust.append({"path": path, "lines": block})
        report.add("trusted: %s" % path)
        changed = True

    for key, record in recorded_trust.items():
        if key in wanted_keys:
            continue

        existing = project_tables(lines)
        if key not in existing:
            continue

        start = existing[key]
        end = start + len(record["lines"])
        if [line.rstrip() for line in lines[start:end]] == record["lines"]:
            del lines[start:end]
            report.add("withdrew trust: %s" % record["path"])
            changed = True
        else:
            report.add("preserved: changed trust entry for %s" % record["path"])
            trust.append(record)

    return (
        join_lines(lines) if changed else None,
        {"keys": managed, "preexisting": preexisting, "trust": trust},
    )


def curated_rules(source):
    return [
        line.rstrip()
        for line in split_lines(read_text(source))
        if line.strip() and not line.lstrip().startswith("#")
    ]


def merge_rules(source, target, state, report, fresh=False):
    """Merge the curated command rules into the machine's own rule file."""

    curated = curated_rules(source)
    if not curated:
        raise SystemExit("error: no rules in %s" % source)

    lines = [] if fresh else split_lines(read_text(target))
    present = {line.rstrip() for line in lines}
    recorded = set(state.get("rules", []))
    recorded_preexisting = set(state.get("preexisting", []))

    managed = []
    preexisting = []
    added = 0
    changed = False

    for rule in curated:
        if rule in present:
            if rule in recorded and rule not in recorded_preexisting:
                managed.append(rule)
            else:
                preexisting.append(rule)
            continue

        lines.append(rule)
        present.add(rule)
        managed.append(rule)
        added += 1
        changed = True

    if added:
        report.add("added %d curated rule(s): %s" % (added, target))

    curated_set = set(curated)
    for rule in sorted(recorded - curated_set - recorded_preexisting):
        if rule not in present:
            continue

        lines = [line for line in lines if line.rstrip() != rule]
        present.discard(rule)
        report.add("withdrew rule: %s" % rule)
        changed = True

    # A rule that was already in the machine's file when this program first ran
    # is the machine's, so dropping it from the curated set withdraws nothing.
    # Reporting it once is the only honest outcome: the two are identical text.
    for rule in sorted(recorded_preexisting - curated_set):
        if rule in present:
            report.add("preserved: %s is no longer curated but predates this install" % rule)

    return (
        join_lines(lines) if changed else None,
        {"rules": managed, "preexisting": preexisting},
    )


def derived_permissions(rules_source):
    """Return the Claude Code allow entries the curated rules imply."""

    pattern = re.compile(r'^prefix_rule\(pattern=\["([^"]*)"\], decision="allow"\)$')
    commands = []

    for line in split_lines(read_text(rules_source)):
        match = pattern.match(line.strip())
        if match and match.group(1) not in commands:
            commands.append(match.group(1))

    entries = []
    for command in commands:
        entries.append("Bash(%s *)" % command)
        entries.append("PowerShell(%s *)" % command)

    return entries


def merge_claude_settings(rules_source, target, state, report):
    """Merge the derived permissions into Claude Code's own settings file."""

    entries = derived_permissions(rules_source)
    if not entries:
        raise SystemExit("error: no allow rules derived from %s" % rules_source)

    text = read_text(target)
    if text.strip():
        try:
            settings = json.loads(text)
        except ValueError as error:
            report.add("preserved: %s is not valid JSON (%s)" % (target, error))
            return None, dict(state)
    else:
        settings = {}

    if not isinstance(settings, dict):
        report.add("preserved: %s does not hold a JSON object" % target)
        return None, dict(state)

    permissions = settings.setdefault("permissions", {})
    if not isinstance(permissions, dict):
        report.add("preserved: %s has a non-object permissions value" % target)
        return None, dict(state)

    allow = permissions.setdefault("allow", [])
    if not isinstance(allow, list):
        report.add("preserved: %s has a non-list permissions.allow value" % target)
        return None, dict(state)

    recorded = set(state.get("allow", []))
    recorded_preexisting = set(state.get("preexisting", []))
    present = {entry for entry in allow if isinstance(entry, str)}

    managed = []
    preexisting = []
    added = 0
    changed = False

    for entry in entries:
        if entry in present:
            if entry in recorded and entry not in recorded_preexisting:
                managed.append(entry)
            else:
                preexisting.append(entry)
            continue

        allow.append(entry)
        present.add(entry)
        managed.append(entry)
        added += 1
        changed = True

    if added:
        report.add("added %d derived permission(s): %s" % (added, target))

    wanted = set(entries)
    for entry in sorted(recorded - wanted - recorded_preexisting):
        if entry not in present:
            continue

        allow[:] = [existing for existing in allow if existing != entry]
        present.discard(entry)
        report.add("withdrew permission: %s" % entry)
        changed = True

    # An entry that was already approved when this program first ran belongs to
    # the user, and nothing in the file distinguishes it from a managed one, so
    # it survives with a report rather than being withdrawn.
    for entry in sorted(recorded_preexisting - wanted):
        if entry in present:
            report.add(
                "preserved: %s is no longer curated but was approved before this install"
                % entry
            )

    rendered = json.dumps(settings, indent=2, ensure_ascii=False) + "\n"
    return (
        rendered if changed or rendered != text else None,
        {"allow": managed, "preexisting": preexisting},
    )


def load_state(path):
    if not path.exists():
        return {}

    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except ValueError:
        return {}

    if not isinstance(state, dict) or state.get("version") != STATE_VERSION:
        return {}

    return state


def artifact_state(state, name, target):
    """Return the record for one artifact, or nothing when it does not apply.

    A record written for a different target path says nothing about this one, so
    it is treated as absent and the run manages nothing in the new file.
    """

    record = state.get(name)
    if not isinstance(record, dict) or record.get("path") != str(target):
        return {}

    return record


def write_text(path, content):
    # newline is set explicitly because pathlib.Path.write_text only accepts it
    # from Python 3.10, and these files use LF on every platform.
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(str(path), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def write_file(path, content, backup_dir, backup_name, dry_run, report):
    if content is None:
        report.add("already current: %s" % path)
        return

    if dry_run:
        report.add("would write: %s" % path)
        return

    if path.exists() and backup_dir:
        backup = pathlib.Path(backup_dir, backup_name)
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(str(path), str(backup))
        report.add("backed up: %s -> %s" % (path, backup))

    write_text(path, content)
    report.add("merged: %s" % path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", required=True)
    parser.add_argument("--backup-dir")
    parser.add_argument("--config-source", required=True)
    parser.add_argument("--config-target", required=True)
    parser.add_argument("--rules-source", required=True)
    parser.add_argument("--rules-target", required=True)
    parser.add_argument("--claude-target", required=True)
    parser.add_argument("--trust-root", action="append", default=[])
    # Set when the caller is about to replace a linked rules directory, so a dry
    # run reports the rules it would write rather than reading them back through
    # the link it has not moved yet.
    parser.add_argument("--rules-fresh", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    arguments = parser.parse_args(argv)

    state_path = pathlib.Path(arguments.state)
    config_target = pathlib.Path(arguments.config_target)
    rules_target = pathlib.Path(arguments.rules_target)
    claude_target = pathlib.Path(arguments.claude_target)
    state = load_state(state_path)
    report = Report()

    config_content, config_state = merge_config(
        pathlib.Path(arguments.config_source),
        config_target,
        artifact_state(state, "codexConfig", config_target),
        arguments.trust_root,
        report,
    )
    rules_content, rules_state = merge_rules(
        pathlib.Path(arguments.rules_source),
        rules_target,
        {} if arguments.rules_fresh else artifact_state(state, "codexRules", rules_target),
        report,
        fresh=arguments.rules_fresh,
    )
    claude_content, claude_state = merge_claude_settings(
        pathlib.Path(arguments.rules_source),
        claude_target,
        artifact_state(state, "claudeSettings", claude_target),
        report,
    )

    # Backups keep the layout the installer's other backups use, so a restore is
    # a copy back to the matching home.
    write_file(
        config_target,
        config_content,
        arguments.backup_dir,
        "config.toml",
        arguments.dry_run,
        report,
    )
    write_file(
        rules_target,
        rules_content,
        arguments.backup_dir,
        os.path.join("rules", "default.rules"),
        arguments.dry_run,
        report,
    )
    write_file(
        claude_target,
        claude_content,
        arguments.backup_dir,
        os.path.join("claude", "settings.json"),
        arguments.dry_run,
        report,
    )

    if not arguments.dry_run:
        config_state["path"] = str(config_target)
        rules_state["path"] = str(rules_target)
        claude_state["path"] = str(claude_target)
        state_path.parent.mkdir(parents=True, exist_ok=True)
        state_path.write_text(
            json.dumps(
                {
                    "version": STATE_VERSION,
                    "codexConfig": config_state,
                    "codexRules": rules_state,
                    "claudeSettings": claude_state,
                },
                indent=2,
                ensure_ascii=False,
            )
            + "\n",
            encoding="utf-8",
            newline="\n",
        )

    report.emit()
    return 0


if __name__ == "__main__":
    sys.exit(main())
