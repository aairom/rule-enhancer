#!/usr/bin/env node
/**
 * Bob PermissionRequest policy hook (Insiders 2.3+).
 *
 * Answers the approval prompt for routine, workspace-local work and prints
 * nothing for everything else, so Bob keeps asking about the important calls.
 *
 * Contract: stdin JSON -> stdout JSON or empty output. Always exits 0.
 *   allow: {"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}
 *   defer: print nothing
 */
import { realpathSync } from "node:fs";

const MAX_TIMEOUT_MS = 8000;

const read = () =>
  new Promise(r => {
    let b = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", c => (b += c));
    process.stdin.on("end", () => r(b));
  });

/** Split a command the way Bob does for approval: every segment must be judged. */
const segments = cmd => cmd.split(/\|\||&&|[|;&\n]/).map(s => s.trim()).filter(Boolean);

/** Tokenise, keeping simple quotes so `git commit -m "a; b"` stays one segment. */
const tokens = seg =>
  (seg.match(/"[^"]*"|'[^']*'|\S+/g) ?? []).map(t => t.replace(/^["']|["']$/g, ""));

// Commands this policy may answer. Add your test runner here first.
// Left out on purpose because they can execute or write: awk, jq ($ENV), bare `make`,
// bare `git branch` (creates/deletes). `sed -n` and `uniq` are handled by SPECIAL below.
const ALLOW_PREFIXES = [
  "git status", "git diff", "git log", "git show", "git rev-parse", "git remote -v",
  "git branch --show-current", "git branch --list", "git branch -a", "git branch -r",
  "git branch -v", "git branch -vv",
  "git add -A", "git add .", "git add -p",
  "ls", "cat", "head", "tail", "grep", "rg", "wc", "sort", "which", "du", "df", "pwd",
  "tree", "find", "cut", "nl", "diff", "stat", "file",
  "npm test", "npm run test", "npm run lint", "npm run build", "npm ci", "npm install",
  "pnpm test", "pnpm lint", "pnpm build", "yarn test", "yarn lint", "yarn build",
  "mvn test", "mvn -q test", "mvn verify", "gradle test", "gradle build",
  "./gradlew test", "./gradlew build", "pytest", "python -m pytest",
  "go test", "go build", "go vet", "cargo test", "cargo build", "cargo check",
  "make test", "make build", "docker ps", "docker images",
  "oc get", "oc describe", "kubectl get", "kubectl describe",
  "node --version", "npm --version", "python --version", "java -version", "git --version"
];

// Reads that stay with the human: credentials, env files, Bob's own config.
const SENSITIVE =
  /(^|[\s"'\/])(\.env(?!\.example|\.sample|\.template)(\.[^\s"']*)?|\.ssh|\.aws|\.config\/gh|\.netrc|\.git-credentials|\.npmrc|\.pypirc|id_rsa|id_ed25519|credentials|secrets?|passwords?|tokens?)([\s"'\/.]|$)/i;
const SYSTEM_PATHS = /(^|[\s"'=])\/(etc|usr|bin|sbin|var|private|opt|Library|System)(\/|\s|$)/;
const BOB_HOME = /(\.bob\/|(^|[\s"'=])~\/\.bob)/;

// Never answer these, even when a prefix above would match.
const MUTATING =
  /(^|\s)(rm|rmdir|mv|cp|chmod|chown|sudo|su|kill|pkill|dd|mkfs|shutdown|reboot|systemctl|curl|wget|nc|scp|ssh|rsync|tee|xargs|eval|env|touch|mkdir|ln|truncate|git push|git reset|git clean|npm publish|docker run|docker rm|kubectl apply|kubectl delete|oc apply|oc delete)(\s|$)/;
// Options that make otherwise read-only tools write, delete, or execute.
const WRITE_OPTIONS =
  /(^|\s)(--output|--out|-o|--delete|--exec|--exec-batch|-delete|-exec|-execdir|-fprint|-fprint0|-fprintf|-fls|-ok|--ext-diff|--textconv|--pre|--hostname-bin)(=|\s|$)/;

const isMutating = seg =>
  seg.includes(">") || seg.includes("<(") || seg.includes("`") || seg.includes("$(") ||
  MUTATING.test(seg) || WRITE_OPTIONS.test(seg);

const SECRET_IN_GIT = /git\s+(show|cat-file|diff)\b[^|;&]*[:\s]\.?env(\.|\s|$)/i;

// Dotfile globs (`.e*`, `.*`) and brace lists (`{.env,x}`) expand to files the text never names.
const EXPANDS_HIDDEN = t => /(^|\/)\.[^./\s]*[*?[]/.test(t) || /\{[^}]*,[^}]*\}/.test(t);
// Recursive grep and `rg --hidden/--no-ignore/-u` read dotfiles such as .env.
const READS_HIDDEN = seg => {
  const t = tokens(seg);
  if (["grep", "egrep", "fgrep"].includes(t[0]))
    return t.slice(1).some((x, i, a) =>
      /^-[a-zA-Z]*[rR]/.test(x) || /^--(dereference-)?recursive$/.test(x) ||
      x === "--directories=recurse" || (x === "-d" && a[i + 1] === "recurse"));
  if (t[0] === "rg") return t.slice(1).some(x => /^(--hidden|--no-ignore.*|-u+)$/.test(x));
  return false;
};

const isSensitive = seg => {
  // Judge the text with quotes/backslashes removed too, so `.e''nv` is seen as `.env`.
  const plain = seg.replace(/["'\\]/g, "");
  return (
    SENSITIVE.test(seg) || SENSITIVE.test(plain) || BOB_HOME.test(plain) ||
    SYSTEM_PATHS.test(seg) || SECRET_IN_GIT.test(plain) ||
    tokens(seg).some(EXPANDS_HIDDEN) || READS_HIDDEN(seg)
  );
};

// Tools that are safe only in a narrow form: sed as a pure line printer, uniq with at most
// one file (its second positional argument is an OUTPUT file).
const SPECIAL = {
  sed: t => t[1] === "-n" && /^\d+(,\d+)?p$/.test(t[2] ?? "") && t.slice(3).every(x => !x.startsWith("-")),
  uniq: t => t.slice(1).filter(x => !x.startsWith("-")).length <= 1
};
const specialOk = seg => {
  const t = tokens(seg);
  return Object.hasOwn(SPECIAL, t[0]) && SPECIAL[t[0]](t);
};

const matchesPrefix = (seg, prefix) => {
  const a = tokens(seg);
  const b = tokens(prefix);
  return b.length <= a.length && b.every((t, i) => t === a[i]);
};

/** Only answer for a directory that resolves on disk. */
const isRealDirectory = p => {
  try {
    realpathSync(p);
    return true;
  } catch {
    return false;
  }
};

const main = async () => {
  const timer = setTimeout(() => process.exit(0), MAX_TIMEOUT_MS);
  timer.unref();

  let ev;
  try {
    ev = JSON.parse(await read());
  } catch {
    process.exit(0);
  }

  if (ev?.hook_event_name !== "PermissionRequest") process.exit(0);
  if (ev.tool_name !== "execute_command") process.exit(0);

  const cwd = typeof ev.cwd === "string" ? ev.cwd : "";
  const cmd = typeof ev.tool_input?.command === "string" ? ev.tool_input.command : "";
  if (!cwd || !cmd) process.exit(0);
  if (!isRealDirectory(cwd)) process.exit(0);
  if (cmd.length > 400) process.exit(0);

  const segs = segments(cmd);
  if (segs.length === 0 || segs.length > 6) process.exit(0);

  for (const s of segs) {
    if (isMutating(s)) process.exit(0);
    if (isSensitive(s)) process.exit(0);
    if (!ALLOW_PREFIXES.some(p => matchesPrefix(s, p)) && !specialOk(s)) process.exit(0);
  }

  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: { hookEventName: "PermissionRequest", decision: { behavior: "allow" } }
    })
  );
  process.exit(0);
};

main();
