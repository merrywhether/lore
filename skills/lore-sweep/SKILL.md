---
name: lore-sweep
description: Sweep a harness's memory files (such as Claude Code's ~/.claude/projects/*/memory/) into the user's lore (~/lore), moving nothing until the user approves a sorted list. Use when the user says "sweep memory", "sweep lore", "move memory into lore", or when a scheduled sweep comes due.
---

# lore-sweep

Harness memory keeps filling with facts that belong in lore, even when the
steering points at lore. Pointing a memory folder into a scope repo doesn't
work, because one memory folder mixes scopes. So treat memory as a short-lived
inbox, and sweep it on a regular cadence. The rules are in this repo's
`docs/schema.md`; every write follows the `lore` skill.

## 1. List the memory

- Read `~/lore/readme.md` and the readme of each scope repo on this machine, so
  you know which scopes and projects exist.
- List each memory file:
  - **Claude Code:** `~/.claude/projects/*/memory/`, one folder per working
    directory, each with an index, `MEMORY.md`.
  - **Other harnesses:** ask the user whether theirs keeps memory files, and
    where.
- Read only memory files, never sign-in or key files or settings that hold
  tokens.

## 2. Sort each memory

Put each one in exactly one of these:

- **A correction:** a rule the agent needed because it kept getting something
  wrong (Claude Code marks most of these `type: feedback`). These matter most,
  so don't bury them in a project's notes: put each where agents read at the
  start of every session. That's the every-machine scope's `agents.md` when it
  holds everywhere; otherwise the steering in `repos/<code-repo>/`, or the
  project's readme. Write it as the rule plus a line on why, so the next agent
  can judge the edge cases.
- **A scope's project or repo notes:** a fact about one project or code repo.
  Name the scope and the file, under `projects/<project>/` or
  `repos/<code-repo>/`.
- **`agents.md` in the scope cloned on every machine:** a preference or
  convention true in every context. Without such a scope, the narrowest scope it
  fits.
- **Stays in memory:** facts about this machine (which tool or connector works
  here, local quirks), and memories that only point at lore paths.
- **Delete:** stale, superseded, or already said in lore.

While sorting:

- **Unsure of the scope? Pick the narrower one.** Moving a fact toward a broader
  scope (a work project's convention into the every-machine `agents.md`) needs
  the removal pass the schema requires: strip what that scope mustn't see, and
  show the user the stripped text.
- **A fact for a scope this machine doesn't have stays in memory.** Don't put it
  in another scope; say which scope it belongs to. Run the sweep on the machine
  that holds the narrow scope, so its content never leaves that machine.
- **Check that it still holds.** A memory that names a file, a flag or a path
  may be out of date: check it against the current state before moving it.
- **If lore already says something different,** don't overwrite either side:
  list both, and ask which wins.

## 3. Show the list, then wait

Show one row per memory: the file, a one-line summary, and where it goes (scope
and path, "stays" or "delete"). For each move, show the text that will land.
Move nothing until the user approves the list; they may change any row.

## 4. Move

1. Write each approved fact to its destination, following the `lore` skill's
   "Writing" and "Writing beside other agents": pull first, stage and commit
   explicit paths, push right after. One commit per scope repo for the sweep is
   fine.
2. Then, in memory, delete each moved file, or cut it to a one-line pointer to
   its lore path when the harness needs the cue. Delete the files marked
   "delete".
3. Keep the harness's index in step: remove or update the line for each file you
   deleted or cut (for Claude Code, in that folder's `MEMORY.md`).
4. Report what moved where, the commits, and what stayed.

## Cadence

The user picks it: weekly, say, or as part of a regular review. Step 3 needs the
user, so run the sweep where they can answer:

- **By hand:** ask the agent to "sweep memory".
- **On a schedule:** a recurring task in a harness that runs on this machine and
  lets the user answer, such as a scheduled task in the Claude desktop app's
  Code tab. A cloud agent can't see this machine's memory. A headless run (cron
  with `claude -p` or `codex exec`) can't wait for approval, so it may only
  print the list, and must move nothing.
- **Or a reminder** in the user's calendar, then run it by hand.
