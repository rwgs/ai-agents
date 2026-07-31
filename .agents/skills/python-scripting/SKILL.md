---
name: python-scripting
description: Design, implement, test, and debug Python scripts, modules, and projects with uv, virtual environments, ruff, pytest, type checking, packaging, and safe subprocess, path, and encoding handling. Use when asked to create or modify .py files, automate a task in Python, manage Python dependencies, fix an import, type, or lint error, or debug a failing pytest run.
---

# python-scripting

## Scope

General Python work in any repository, including a one-off script in a project
that is not otherwise a Python project. Python AI applications, meaning provider
APIs, prompts, agents, retrieval, and evaluation, are covered by the `python-ai`
skill in the optional pool rather than here. For shell automation around a Python
project use `bash-scripting` or `powershell-scripting`.

## Workflow

1. Identify the interpreter, environment manager, and test runner already in use.
   Do not introduce a second one.
2. Reproduce the failure with the narrowest command that shows it.
3. Implement the smallest change consistent with the project's existing patterns.
4. Validate types, lint, formatting, and the affected tests.

## Environment selection

Detect rather than assume, because the wrong tool writes a second lockfile:

```bash
ls uv.lock poetry.lock pdm.lock Pipfile.lock requirements*.txt pyproject.toml 2>/dev/null
```

`uv.lock` means uv, `poetry.lock` means Poetry, `pdm.lock` means PDM, and a bare
`requirements.txt` means pip into a virtual environment. Run tools through the
project's runner, `uv run` or `poetry run`, so the project interpreter is used
rather than whichever `python` is first on `PATH`.

- Never install into the system interpreter. On Debian and Ubuntu `pip install`
  outside a virtual environment is blocked by `EXTERNALLY-MANAGED`, and working
  around that breaks system packages.
- A virtual environment's executables are in `bin/` on Linux and macOS and
  `Scripts/` on Windows. A path hardcoded to one fails silently on the other by
  falling back to the system interpreter.
- `uv run` creates and syncs the environment itself, so a separate activate step
  is usually unnecessary and often the reason two environments exist.

## Implementation rules

- Pass `encoding="utf-8"` to `open()` and to `subprocess` text mode. The default
  is locale-dependent, so a file that reads correctly on Linux raises
  `UnicodeDecodeError` on a Windows machine using cp1252.
- Use `pathlib.Path` and the `/` operator rather than string concatenation or
  manual separators.
- Call `subprocess.run` with a list and without `shell=True`. Check the result,
  by `check=True` or by reading `returncode`, because a failed command otherwise
  returns quietly.
- Make timezone-aware datetimes explicit: `datetime.now(timezone.utc)`, not
  `utcnow()`, which returns a naive value that compares wrongly against aware
  ones.
- Never use a mutable default argument. `def f(items=[])` shares one list across
  every call.
- Prefer the standard library before adding a dependency, and check whether a
  dependency is already present before adding one.
- Keep formatting decisions in the formatter's config. `ruff format` and Black
  own formatting and `ruff check` owns correctness; do not add Black to a project
  already formatting with ruff.
- Read the type checker's config before fixing a type error. `strict`,
  `disallow_untyped_defs`, and per-module overrides change what a correct fix is.
  Fix the annotation rather than reaching for `Any` or a blanket `# type: ignore`;
  when a suppression is required, narrow it to the rule and give a reason.
- Guard script entry points with `if __name__ == "__main__":`, which is required
  rather than stylistic once `multiprocessing` is involved on Windows or macOS.
- Use logging rather than `print` in anything imported as a module.

## Diagnostics

```bash
python -m py_compile path/to/file.py   # syntax only, no execution
uv run ruff check .                    # correctness
uv run ruff format --check .           # formatting, without rewriting
uv run mypy .                          # or: uv run pyright
uv run pytest -x -q                    # stop at the first failure
uv run pytest path/to/test.py::test_name
uv run python -c 'import mod; print(mod.__file__)'   # which copy is imported
uv pip list                            # resolve a version conflict
```

An import error that contradicts an installed package usually means two
environments or a local file shadowing the module; the `__file__` check above
shows which copy won.

RTK wrappers reduce the noisiest of these:

```bash
rtk pytest | rtk ruff check | rtk mypy
```

## Validation

- The type checker reports no new errors.
- Lint passes, and formatting is checked rather than assumed.
- Affected tests pass, and a test that should fail without the change does.
- The lockfile changed only if a dependency intentionally changed.
- Paths, encodings, and subprocess calls behave on both Windows and POSIX when
  the script is expected to run on both.
