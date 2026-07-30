---
name: show-codex-reset-expiries
description: Show the exact local and ISO expiry times of available Codex rate-limit reset credits for the currently signed-in ChatGPT account. Use only when the user explicitly asks to inspect their earned reset credits or invokes this skill.
---

# Show Codex Reset Expiries

Run the bundled script and report its result.

## Workflow

1. Resolve `scripts/show-reset-expiries.mjs` relative to this `SKILL.md`.
2. Run it with Node.js:

   ```bash
   node <skill-directory>/scripts/show-reset-expiries.mjs
   ```

3. Return the authoritative available-credit count and every expiry record exactly as the script reports it.
4. If the available count exceeds the returned detail rows, state that the service supplied only partial expiry details.
5. If authentication is missing or uses an API key, explain that this check requires Codex to be signed in with ChatGPT.

## Boundaries

- Treat earned reset-credit expiries separately from rolling usage-window resets. This skill reports `rateLimitResetCredits.credits[].expiresAt`.
- Use the bundled app-server client. Do not read, display, copy, or modify stored authentication tokens.
- Do not request an OpenAI API key. Platform API keys do not expose ChatGPT subscription reset credits.
- Keep all timestamps visible: local date and time, timezone, remaining duration, and ISO timestamp.

Completion criterion: every returned reset credit is accounted for, or the response explicitly says that only the count or a partial detail list was available.
