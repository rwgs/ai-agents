---
name: web-verification
description: Serve and verify a web application in a real browser, covering local static and development servers, port and process hygiene, cache and service-worker staleness, console and network errors, and screenshot evidence for user-visible changes. Use when a change affects what a page renders or does, when confirming a UI fix, or when a page behaves differently in the browser than the tests suggest.
---

# web-verification

## Scope

Serving a site or application locally and confirming its behavior in a browser.
Stack-agnostic: it applies whether the backend is JavaScript, Python, Rust, Go, or
a static generator. JavaScript and TypeScript project tooling, meaning package
managers, type checking, linting, and test runner configuration, is covered by
`web-development`. Scripting the commands around a server belongs to
`bash-scripting` or `powershell-scripting`. Administering the host or container
the site runs on is out of scope.

## Workflow

1. Identify how the project is meant to be served and use that, rather than
   inventing a second server.
2. Start it, confirm the port is actually listening, and note the process so it
   can be stopped.
3. Load the page, then read the console and network panel before judging the
   rendered result.
4. Capture evidence for anything user-visible, and stop the server.

## Serving locally

- Serve over HTTP rather than opening `file://`. Module imports, `fetch`,
  cookies, and service workers all behave differently on `file://`, so a failure
  there is often an artifact of the protocol rather than a real bug.
- Use the project's own command when one exists. A generic static server bypasses
  the rewrites, proxying, and headers a dev server provides, and it will
  disagree with production for exactly the routes that matter.
- Bind explicitly when the result must be reachable from another machine or a
  container. A server on `127.0.0.1` is unreachable from outside its host, which
  looks like a firewall problem.

```bash
python3 -m http.server 8000        # static files, no rewrites
npx serve -l 8000                  # static files with SPA fallback
```

## Port and process hygiene

An orphaned server holding the port makes the next run fail confusingly, often
with a message about the port rather than about the stale process:

```bash
ss -ltnp | grep :8000              # Linux: what is listening
lsof -i :8000                      # macOS
```

```powershell
Get-NetTCPConnection -LocalPort 8000 | Select-Object OwningProcess
Get-Process -Id <pid>
```

Stop the server when finished. If a dev server was started in the background,
stop it in the same session rather than leaving it for the next one.

## Stale output

A page that does not reflect a change is usually serving something old, not
failing to apply it. Rule these out before concluding the fix did not work:

- A service worker serving cached assets. Reload bypassing the cache, or
  unregister the worker; a normal reload will keep returning the old asset.
- A build artifact that was not rebuilt, so the served bundle predates the edit.
- A CDN or proxy cache in front of the server.
- The browser holding a cached redirect, which survives a normal reload.

## Reading the browser, not just the page

- Check the console for errors and warnings. A page can render completely while a
  failed request leaves it non-functional.
- Check the network panel for non-200 responses, especially 404s on assets and
  failed preflight requests, which do not always surface visually.
- Prefer the automation tool's own waiting over fixed sleeps. A timeout that
  passes locally and fails in CI is usually a race, not a slow machine.

## Validation

- The page was loaded over HTTP from the project's intended server.
- The console shows no new errors, and the network panel no new failed requests.
- Anything user-visible was verified in a browser and captured as a screenshot or
  equivalent rendered output, not inferred from passing tests.
- The change was confirmed against fresh output rather than a cached asset.
- No server was left running on a port after the check finished.
