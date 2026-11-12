#!/usr/bin/env node
// PermissionResolved: append one JSON line per approval outcome. Never decides.
import { appendFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const read = () =>
  new Promise(r => {
    let b = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", c => (b += c));
    process.stdin.on("end", () => r(b));
  });

try {
  const ev = JSON.parse(await read());
  if (ev?.hook_event_name === "PermissionResolved") {
    const dir = join(ev.cwd || ".", ".bob", "audit");
    mkdirSync(dir, { recursive: true });
    appendFileSync(
      join(dir, "approvals.jsonl"),
      JSON.stringify({
        ts: new Date().toISOString(),
        session: ev.session_id,
        tool: ev.tool_name,
        decision: ev.decision,
        input: ev.tool_input ?? null
      }) + "\n"
    );
  }
} catch {
  // Fail open: the audit line is missing, the approval is not blocked.
}
process.exit(0);
