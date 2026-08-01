---
name: bash-scripting
description: Design, implement, review, test, and debug Bash and POSIX shell scripts with safe quoting, error handling, portability, ShellCheck, shfmt, and predictable command behavior. Use when asked to create or modify .sh files, automate command-line workflows, fix shell bugs, improve script safety, remove bashisms, or validate Linux and CI shell scripts.
---

# bash-scripting

## Scope

Shell work in any repository: a script committed to the tree, a CI step, or a
pipeline written once at the prompt. For the same job on Windows use
`powershell-scripting`. When a script outgrows the shell, particularly when it
starts parsing structured data, move it to `python-scripting` rather than adding
another layer of `sed`.

## Workflow

1. Read the repository's instructions, the declared interpreter, the script's
   callers, and every platform it has to run on.
2. Decide whether the work needs Bash or stays POSIX `sh`, before writing rather
   than after.
3. Name the inputs, side effects, privileges, failure behavior, and cleanup the
   script owes.
4. Make the smallest maintainable change, reusing helpers the project already
   has.
5. Validate syntax, static analysis, formatting, and a representative success and
   failure path.

## Shell selection

- Use `#!/bin/sh` unless a Bash feature buys something concrete.
- Use `#!/usr/bin/env bash`, or whichever Bash shebang the repository already
  uses, when arrays, `[[ ]]`, process substitution, or `mapfile` are required.
- Keep Bash syntax out of a script declaring `sh`. On Debian and Ubuntu `/bin/sh`
  is `dash`, so a `[[` that works in an interactive Bash fails under the real
  `sh` a CI runner uses.
- Keep the interpreter and compatibility target the repository already set,
  unless changing them is the task.
- Assume the oldest Bash any target platform ships. macOS is still on 3.2, which
  has no `mapfile`, no associative arrays, and no `${var,,}`, and where expanding
  an empty array under `set -u` is an unbound-variable error rather than an empty
  list. Bash 5 does not reproduce that last rule even under `BASH_COMPAT`, so
  only a macOS run is evidence.

## Implementation rules

- Quote every expansion: `"$value"`, `"${array[@]}"`. Unquoted, an empty value
  disappears entirely and turns `[ $x = y ]` into a syntax error, and a value
  holding a space or a `*` is split and globbed.
- Use `printf` rather than `echo`. Handling of `-n`, `-e`, and backslashes
  differs between shells and between the builtin and `/bin/echo`.
- Use `case` for multi-branch string matching and `getopts` for portable option
  parsing.
- Write a function when an operation is meaningful and reused, not around every
  individual command.
- Keep normal output on stdout and diagnostics on stderr, so a caller can consume
  one without the other.
- Return nonzero on failure, and preserve an informative exit status rather than
  flattening it to 1.
- Check that an optional external command exists before depending on it.
- Create temporary files with `mktemp` and remove them from a `trap`, not at a
  predictable path a rerun or another user can collide with.
- Keep destructive and privileged operations explicit and narrowly scoped.
- Avoid `eval`, command strings assembled from unquoted variables, and parsing
  `ls`, whose output is ambiguous for a filename containing a space or a newline.
- Do not pipe a remote download straight into a shell unless the user asks for
  it and the trust implication is written down.
- Treat `set -e` as a control-flow choice rather than error handling. It does not
  fire for a command inside `if`, `&&`, `||`, or `!`, nor for a non-final command
  in a pipeline, and `local x="$(false)"` hides the status because `local` itself
  succeeds.
- Add `set -u` and `set -o pipefail` only where the declared interpreter supports
  them. `pipefail` is a Bash feature that `dash` rejects, so it cannot appear in
  a `sh` script.
- Keep installation and configuration scripts idempotent: a second run reports no
  change instead of repeating the first run's writes.

## Diagnostics

```bash
bash -n path/to/script.sh          # syntax only, nothing executes
sh -n path/to/script.sh
shellcheck path/to/script.sh
shfmt -d path/to/script.sh         # the diff, without rewriting the file
checkbashisms path/to/script.sh    # only for a script declaring sh
```

Run only the checks matching the declared shell. `bash -n` says nothing about a
`sh` script's portability, and `checkbashisms` against a Bash script reports
nothing but false positives.

## Validation

- Syntax passes under the declared interpreter.
- ShellCheck is clean, or each surviving finding is disabled by rule with a
  stated reason.
- Formatting matches the repository, or `shfmt` where the repository sets none.
- Arguments containing spaces, empty strings, glob characters, and leading dashes
  are handled; a user-supplied operand that may start with `-` needs a `--`
  terminator.
- Failure paths return a useful status and say on stderr what failed.
- Temporary files and partial state are cleaned up, including on an early exit.
- Privileged, destructive, and network operations are exercised safely or
  reported as untested.
