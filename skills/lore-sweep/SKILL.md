---
name: lore-sweep
description: Sweep the memory of the harness you're running in into the user's lore (~/lore), moving nothing until the user approves a sorted list. Use when the user says "sweep memory", "sweep lore", "move memory into lore", or when a scheduled sweep comes due.
---

# lore-sweep

Harness memory keeps filling with facts that belong in lore, even when the
steering points at lore. Pointing memory into a scope repo doesn't work, because
one harness's memory mixes scopes. So treat memory as a short-lived inbox, and
sweep it on a regular cadence. The rules are in lore's
[schema](../lore/schema.md); every write follows the `lore` skill.

**Sweep only the memory of the harness you're running in.** You know where it
lives, what format it's in and how changes to it should be made; another
harness's memory you'd have to guess at. To sweep several harnesses, run the
sweep in each one. A fact the first sweep moved is one the next sweep finds
already in lore.

## 1. List the memory

- Read `~/lore/readme.md` and the readme of each scope repo on this machine, so
  you know which scopes and projects exist.
- If your harness gives you no known way to list its memory, or to change one
  fact in it, say what's missing and leave that memory alone. Never guess at its
  files or database.
- Find all of your memory first. A harness may keep a separate memory for each
  directory a session starts in, and tell you only where the current directory's
  memory lives. That's about where sessions start, not about git checkouts: one
  checkout can have several memories (sessions started in its subfolders), and a
  memory can cover no checkout at all. Find the memory for every other directory
  too, and say which ones you found.
- List what each memory holds. If it's files, note each file's checksum
  (`shasum`) when you read it, and sort from that same read, so the checksum
  matches what you sorted.
- Read only memory, never sign-in or key files or settings that hold tokens.

## 2. Sort each fact

One memory can hold several facts with different homes, such as a preference
beside a detail about this machine. Sort each fact, not each memory. Put each
fact in exactly one of these:

- **A correction:** a rule you needed because you kept getting something wrong.
  These matter most, so don't bury them in a project's notes: put each where
  agents read at the start of every session. That's the every-machine scope's
  `agents.md` when it holds everywhere; that scope's `agents.md` when it holds
  across one scope's projects; otherwise the steering in `repos/<code-repo>/`,
  or the project's readme. Write it as the rule plus a line on why, so the next
  agent can judge the edge cases.
- **A scope's project or repo notes:** a fact about one project or code repo.
  Name the scope and the file, under `projects/<project>/` or
  `repos/<code-repo>/`.
- **A preference or convention:** one true in every context goes to `agents.md`
  in the scope cloned on every machine (without such a scope, the narrowest one
  it fits); one true across one scope's projects goes to that scope's
  `agents.md`.
- **Stays in memory:** facts about this machine (which tool or connector works
  here, local quirks), and memories that only point at lore paths.
- **Delete:** stale, superseded, or already said in lore.

While sorting:

- **A request to forget something stays.** Leave it, so your memory acts on it.
  If lore says the thing to be forgotten, list that lore passage too, and ask
  whether to remove it.
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
- **Rewrite links.** Lore uses relative markdown links only. A memory's link to
  another memory, such as a `[[name]]` wikilink, becomes a relative link only
  where its target is an approved move into the same scope repo, and that move
  lands too (step 4 may skip one whose source changed). Otherwise drop the link
  and keep the words: a link into another scope would show its path, and break
  on machines without that scope.

## 3. Show the list, then wait

Show one row per fact: where it is in memory, a one-line summary, and where it
goes (scope and path, "stays" or "delete"). For each move, show the text that
will land. Move nothing until the user approves the list; they may change any
row.

A first sweep can be large (a hundred memories across a dozen projects). Then
work in rounds: group the rows by destination scope and project, show about 20
rows per round, and move each approved round (step 4) before listing the next.
Moving a round changes the memories it touched, so read those again before the
next round, and list any of their facts whose text changed for approval again.

## 4. Move

1. **Check each source first.** Your memory may have changed while the user read
   the list. If a file's checksum changed since you read it, move none of its
   facts and leave it alone; sort it again in the next sweep.
2. Write each approved fact to its destination, following the `lore` skill's
   "Writing" and "Writing beside other agents": pull first, stage and commit
   explicit paths, push right after. One commit per scope repo for the sweep is
   fine.
3. Then remove from memory each fact that moved or was approved for deletion,
   the way your harness expects memory to change: edit or delete its files and
   keep its index in step, or record a request to forget, whichever your memory
   uses. Recheck a file's checksum right before you change it; if it changed
   while you wrote to lore, leave it and report it.
   - **Remove only the approved facts.** Keep every fact that stays, word for
     word. Where you'd still want the cue, leave a one-line pointer to the lore
     path in place of a moved fact.
4. Report what moved where, the commits, what stayed, and anything skipped
   because it changed.

## Cadence

The user picks it: weekly, say, or as part of a regular review. Step 3 needs the
user, so run the sweep where they can answer:

- **By hand:** ask the agent to "sweep memory", in each harness that keeps
  memory.
- **On a schedule:** a recurring task in a harness that runs on this machine and
  lets the user answer, such as a scheduled task in the Claude desktop app's
  Code tab. A cloud agent can't see this machine's memory. A headless run (cron
  with `claude -p` or `codex exec`) can't wait for approval, so it may only
  print the list, and must move nothing.
- **Or a reminder** in the user's calendar, then run it by hand.
