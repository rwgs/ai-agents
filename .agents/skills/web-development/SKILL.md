---
name: web-development
description: Build, test, and debug JavaScript and TypeScript projects, including package managers, TypeScript compilation, ESLint, Prettier and Biome, bundlers, test runners such as Vitest, Jest, and Playwright, local static servers, and browser debugging. Use when working on .js, .ts, .jsx, .tsx, or web assets, fixing type or lint errors, configuring formatting, or debugging behavior in a browser.
---

# web-development

## Scope

JavaScript and TypeScript project work, from type errors to browser behavior.
For shell automation around a project use `bash-scripting` or
`powershell-scripting`. Administering the host or container a site runs on is
out of scope for this skill.

## Workflow

1. Identify the package manager, TypeScript configuration, and test runner
   already in use. Do not introduce a second one.
2. Reproduce the failure with the narrowest command that shows it.
3. Implement the smallest change consistent with the project's existing
   patterns.
4. Validate types, lint, formatting, and the affected tests.

## Package manager selection

Detect rather than assume, because using the wrong one rewrites the lockfile:

```bash
ls package-lock.json pnpm-lock.yaml yarn.lock bun.lockb 2>/dev/null
```

`package-lock.json` means npm, `pnpm-lock.yaml` means pnpm, `yarn.lock` means
Yarn, `bun.lockb` means Bun. Use `npm ci`, `pnpm install --frozen-lockfile`, or
the equivalent in CI so the lockfile is respected rather than updated.

## Implementation rules

- Read `tsconfig.json` before fixing a type error. `strict`, `moduleResolution`,
  and `paths` change what a correct fix looks like.
- Fix the type rather than reaching for `any` or `@ts-ignore`. When a suppression
  is genuinely required, use `@ts-expect-error` with a reason so it fails once
  the underlying issue is fixed.
- Keep formatting decisions in the formatter's config, not in review. Prettier
  and Biome own formatting; ESLint owns correctness. Do not hand-format code a
  formatter will rewrite.
- Do not add Prettier to a project already using Biome, or a second ESLint
  config, without removing the one it replaces.
- Respect the module system in use. Mixing `require` into an ESM package, or
  omitting file extensions in ESM imports, fails only at runtime.
- Prefer the project's existing test runner. Vitest and Jest have compatible
  surfaces but incompatible configs.
- Check whether a dependency is already present before adding one.

## Diagnostics

```bash
node --check path/to/file.js        # syntax only, no execution
npx tsc --noEmit                    # type check without building
npx eslint .                        # correctness
npx prettier --check .              # formatting, without rewriting
npx vitest run                      # or: npx jest, npx playwright test
npm ls <package>                    # resolve a version conflict
```

RTK wrappers reduce the noisiest of these:

```bash
rtk tsc | rtk lint | rtk prettier --check
rtk vitest | rtk jest | rtk playwright test
rtk pnpm install | rtk pnpm outdated
```

## Browser and local server debugging

- Serve a static site over HTTP rather than opening `file://`, because module
  imports, fetch, and service workers behave differently on `file://`.
- Stop a background server when finished; an orphaned process holding the port
  makes the next run fail confusingly.
- A service worker serves stale assets after a change. Reload bypassing the
  cache, or unregister it, before concluding a fix did not work.
- Prefer Playwright's own waiting over fixed sleeps; a timeout that passes
  locally and fails in CI is usually a race, not a slow machine.

## Validation

- `tsc --noEmit` reports no new errors.
- Lint passes, and formatting is checked rather than assumed.
- Affected tests pass, and a test that should fail without the change does.
- The lockfile changed only if a dependency intentionally changed.
- Behavior verified in a browser for anything user-visible, not only in tests.
