#!/usr/bin/env node

import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import readline from "node:readline";

const REQUEST_TIMEOUT_MS = 20_000;
const MACOS_BUNDLED_CODEX = "/Applications/ChatGPT.app/Contents/Resources/codex";

export function formatTimestamp(
  unixSeconds,
  { nowMs = Date.now(), locale, timeZone } = {},
) {
  if (unixSeconds == null) {
    return {
      local: "expiry time not supplied",
      iso: null,
      relative: null,
    };
  }

  const date = new Date(unixSeconds * 1000);
  if (Number.isNaN(date.getTime())) {
    throw new TypeError(`Invalid Unix timestamp: ${unixSeconds}`);
  }

  const deltaMs = date.getTime() - nowMs;
  const absMinutes = Math.max(0, Math.round(Math.abs(deltaMs) / 60_000));
  const days = Math.floor(absMinutes / 1_440);
  const hours = Math.floor((absMinutes % 1_440) / 60);
  const minutes = absMinutes % 60;
  const parts = [];

  if (days) parts.push(`${days}d`);
  if (hours) parts.push(`${hours}h`);
  if (minutes || parts.length === 0) parts.push(`${minutes}m`);

  return {
    local: new Intl.DateTimeFormat(locale, {
      dateStyle: "full",
      timeStyle: "long",
      ...(timeZone ? { timeZone } : {}),
    }).format(date),
    iso: date.toISOString(),
    relative:
      deltaMs >= 0
        ? `in ${parts.join(" ")}`
        : `${parts.join(" ")} ago`,
  };
}

export function buildReport(
  result,
  { nowMs = Date.now(), locale, timeZone } = {},
) {
  const resetCredits = result?.rateLimitResetCredits;
  const availableCount = Number(resetCredits?.availableCount ?? 0);
  const credits = Array.isArray(resetCredits?.credits)
    ? resetCredits.credits
    : [];
  const lines = [`Available usage reset credits: ${availableCount}`];

  if (availableCount === 0) {
    lines.push("No available reset credits were returned for this account.");
    return lines.join("\n");
  }

  if (credits.length === 0) {
    lines.push(
      "The service returned the count, but not the individual expiry details.",
    );
    return lines.join("\n");
  }

  credits.forEach((credit, index) => {
    const expiry = formatTimestamp(credit.expiresAt, {
      nowMs,
      locale,
      timeZone,
    });
    const label = credit.title || `Reset credit ${index + 1}`;

    lines.push("", `${index + 1}. ${label}`);
    lines.push(`   Expires: ${expiry.local}`);
    if (expiry.relative) lines.push(`   Remaining: ${expiry.relative}`);
    if (expiry.iso) lines.push(`   ISO: ${expiry.iso}`);
    lines.push(`   Status: ${credit.status ?? "unknown"}`);
  });

  if (credits.length < availableCount) {
    lines.push(
      "",
      `Note: ${availableCount} credits are available, but the service returned expiry details for only ${credits.length}.`,
    );
  }

  return lines.join("\n");
}

function codexCandidates() {
  if (process.env.CODEX_BIN) return [process.env.CODEX_BIN];

  const candidates = ["codex"];
  if (existsSync(MACOS_BUNDLED_CODEX)) candidates.push(MACOS_BUNDLED_CODEX);
  return [...new Set(candidates)];
}

function requestRateLimits(command) {
  return new Promise((resolveRequest, rejectRequest) => {
    const server = spawn(command, ["app-server", "--listen", "stdio://"], {
      stdio: ["pipe", "pipe", "pipe"],
    });
    const lines = readline.createInterface({ input: server.stdout });
    let stderr = "";
    let settled = false;

    server.stderr.setEncoding("utf8");
    server.stderr.on("data", (chunk) => {
      stderr += chunk;
    });

    const cleanup = () => {
      clearTimeout(timeout);
      lines.close();
      server.stdin.end();
      server.kill();
    };

    const reject = (message) => {
      if (settled) return;
      settled = true;
      cleanup();
      const detail = stderr.trim();
      rejectRequest(new Error(detail ? `${message}\n${detail}` : message));
    };

    const resolveResult = (result) => {
      if (settled) return;
      settled = true;
      cleanup();
      resolveRequest(result);
    };

    const send = (message) => {
      server.stdin.write(`${JSON.stringify(message)}\n`);
    };

    const timeout = setTimeout(() => {
      reject("Timed out while asking Codex for ChatGPT rate-limit reset credits.");
    }, REQUEST_TIMEOUT_MS);

    lines.on("line", (line) => {
      let message;
      try {
        message = JSON.parse(line);
      } catch {
        return;
      }

      if (message.id === 1) {
        if (message.error) {
          reject(`Codex initialization failed: ${message.error.message ?? "unknown error"}`);
          return;
        }

        send({ method: "initialized", params: {} });
        send({
          method: "account/read",
          id: 2,
          params: { refreshToken: false },
        });
        return;
      }

      if (message.id === 2) {
        if (message.error) {
          reject(`Could not inspect Codex authentication: ${message.error.message ?? "unknown error"}`);
          return;
        }

        const accountType = message.result?.account?.type;
        if (accountType !== "chatgpt" && accountType !== "chatgptAuthTokens") {
          reject(
            "Codex must be signed in with ChatGPT to inspect reset credits. Run `codex login`, choose ChatGPT sign-in, then try again.",
          );
          return;
        }

        send({ method: "account/rateLimits/read", id: 3 });
        return;
      }

      if (message.id !== 3) return;

      if (message.error) {
        reject(
          `Could not read ChatGPT rate limits: ${message.error.message ?? "unknown error"}`,
        );
        return;
      }

      resolveResult(message.result);
    });

    server.on("error", (error) => {
      reject(`Could not start ${command}: ${error.message}`);
    });

    server.on("exit", (code) => {
      if (settled) return;
      reject(
        `Codex app-server exited before replying${code == null ? "" : ` (code ${code})`}.`,
      );
    });

    send({
      method: "initialize",
      id: 1,
      params: {
        clientInfo: {
          name: "show_codex_reset_expiries",
          title: "Show Codex Reset Expiries",
          version: "1.0.0",
        },
      },
    });
  });
}

export async function fetchRateLimits() {
  const failures = [];

  for (const command of codexCandidates()) {
    try {
      return await requestRateLimits(command);
    } catch (error) {
      failures.push(`${command}: ${error.message}`);
    }
  }

  throw new Error(
    [
      "Unable to query Codex. Install the Codex CLI and sign in with ChatGPT.",
      "Set CODEX_BIN to a working Codex executable if it is not on PATH.",
      "",
      ...failures,
    ].join("\n"),
  );
}

async function main() {
  try {
    const result = await fetchRateLimits();
    console.log(buildReport(result));
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exitCode = 1;
  }
}

const invokedPath = process.argv[1] ? resolve(process.argv[1]) : null;
if (invokedPath === fileURLToPath(import.meta.url)) {
  await main();
}
