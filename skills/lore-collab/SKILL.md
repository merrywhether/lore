---
name: lore-collab
description: Coordinate several interactive agent sessions (in any harness) through a shared append-only log kept in lore. Use when the user says "lore-collab" (alone or with start, join, auto or manual), pastes a "lore-collab join" block, or asks to start, continue, hand off, close or watch a collaboration between sessions.
---

# lore-collab

A collaboration is a folder of markdown logs that several interactive agent
sessions append to. The sessions may run in different apps (Claude Code, Codex,
opencode) and never talk to each other directly: the log is the only channel,
and the user decides. The script `scripts/collab.sh` (beside this file) does
every write, so ids stay unique and no writer erases another's section.

## Where a collaboration lives

In the lore scope repo of the project it serves, at
`~/lore/<scope>/projects/<project>/collab/<name>/`, with one log per phase:
`01-<topic>.md`, `02-<topic>.md`, and so on. Pick the scope from
`~/lore/readme.md`; when unsure, use the narrower scope. Never put a log in a
code repo's checkout.

## The format

- **Sections:** `## [<id>] <topic> — <date> (<name>)`. The id is four random
  characters from `a-z0-9`, unique in the folder.
- **Acks:** `**Ack (<name>):** a1b2, c3d4`, right under the heading of your next
  section. Ack every section you have read, by id. A correction says "supersedes
  a1b2"; never edit an earlier section, your own included.
- **Every section ends with `Waiting on: <names>`** (comma-separated), or
  `nobody`, as its last line. A section without that footer waits on nobody, and
  so does a footer quoted inside a code fence: fenced text is never read as log
  structure.
- **Unread** means: sections by others whose ids you have not acked. Position in
  the file means nothing, because sessions write at the same time.
  `collab.sh unread` computes it.

## Commands

Run them as `<this skill's folder>/scripts/collab.sh <command> <folder> …`. Pass
section bodies on stdin (a heredoc), or `</dev/null` for none.

| Command                                                                  | What it does                                                                                                                                                                                                           |
| ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `start <folder> <topic>`                                                 | Create the folder and `01-<topic>.md`.                                                                                                                                                                                 |
| `post <folder> <name> <topic> [--ack ids] [--waiting names] [--no-push]` | Append a section, commit, and push the lore repo. Prints the new id.                                                                                                                                                   |
| `unread <folder> <name>`                                                 | List sections `<name>` hasn't acked: `id`, author, waiting on, heading.                                                                                                                                                |
| `waiting <folder> <name>`                                                | The unread sections that wait on `<name>`.                                                                                                                                                                             |
| `wait <folder> <name> [--interval <s>] [--then -- <command> [args]]`     | Block until a section waits on `<name>`, print it, run `<command>`, exit. Checks at once, then every few seconds; spends no tokens while it waits. Refuses to start if a wait for the same folder and name is running. |
| `next <folder> <name> <topic>`                                           | Close this phase and start the next log. Members follow on their own: `unread` reads every phase.                                                                                                                      |
| `close <folder> <name>`                                                  | End the collaboration.                                                                                                                                                                                                 |
| `current <folder>`                                                       | Print the newest log's path.                                                                                                                                                                                           |

## Start a collaboration ("lore-collab start")

1. Choose the folder (see above) and run `start`.
2. **Ask the user for the roles**, once: who takes part, what each does, and who
   decides. Only sessions that read and write the log are members. A member's
   sub-agents are not; their results go in the member's sections, credited by
   name.
3. Post an opening section: purpose, roles (including how each member dispatches
   helpers, for example "builds through two sub-agents at high effort"), where
   things are, and the state at the start. No one should be the only reviewer of
   their own work: if the planner also reviews, name a second reviewer.
4. Give the user one copy-able block per other member, for example:

   ```text
   lore-collab join ~/lore/home/projects/widget-app/collab/m2 as rook
   ```

## Join ("lore-collab join <folder> as <name>")

Read every log in the folder, oldest first. Find your role in the opening
section; if it isn't there, ask the user. Post a `Joined` section that acks what
you read. A name given in the join block wins; without one, pick a short name no
section uses yet and claim it in `Joined`. If you lose track of your name, look
for your `Joined` section or ask the user.

## Check the log ("lore-collab")

Said alone, "lore-collab" means: check the collaboration this session is a
member of. If it isn't a member of one, ask whether to start one or join one.

1. Run `unread` for your name.
2. Read those sections, act on what waits on you, and post one section that acks
   every id you read and says what you did. End it with who acts next.
3. If nothing is unread, say so and stop. Don't invent work.

## When something waits on the user

The user doesn't read the log. When you post `Waiting on: <user>`, or find such
a section still unanswered, also ask in your own chat: a plain title, a few
sentences of background, the question, your recommendation and what it blocks,
so it stands alone. When the user answers, post the answer to the log with their
words quoted.

## Rules

- Anything outward-facing (a push outside lore, a pull request, an issue, a
  message to anyone) needs the user's go-ahead each time, given in chat. Quote
  it when relaying it.
- Decisions also go into the project's plan or brief the same day; the log isn't
  the record of what was decided.
- **Write the log only through `collab.sh`.** It appends, then stages and
  commits that one log file, so it never sweeps up other changes in the repo,
  and it retries a rejected push by rebasing, never by force. For any other file
  in the repo, follow the `lore` skill's "Writing beside other agents":
  `git status` first, explicit paths only, never `commit -a` or `add -A`.
- **Members may share one checkout** (several sessions on one machine) or use
  their own clones (several machines). Posting works either way. `wait` reads
  only the local checkout, so it doesn't yet notice sections pushed from another
  machine; there, say "lore-collab" by hand.
- Commit messages carry no AI attribution lines.

## auto ("lore-collab auto")

Opts this session into waking when a section waits on it, so the user doesn't
have to say "lore-collab". Turn it off with "lore-collab manual".

Each member wakes itself: a waiter watches the log for sections addressed to it,
then prompts its own session. Members never reach into each other's apps, so it
works the same whichever harnesses take part. The waiter only delivers a
wake-up; it never acks. The woken turn reads the log, acks what it read and
posts, as for "lore-collab".

- **Claude Code:** run `collab.sh wait <folder> <name>` as a background command.
  The session is re-invoked when the command exits; arm it again at the end of
  each woken turn.
- **Codex:** a Codex session isn't woken by its own background commands, and its
  sandbox can't run `codex queue`, so the waiter runs on the host and queues a
  prompt into the chat:

  ```bash
  collab.sh wait <folder> <name> --repeat --then -- codex queue --thread <thread id> --message 'lore-collab'
  ```

  The thread id is `$CODEX_THREAD_ID` in the session's own shell; if it's empty,
  say so and stay manual. Print the full command with the id filled in, and ask
  the user to run it once in a terminal on this machine, or run it through a
  host launcher the user has approved. With `--repeat` it keeps watching and
  sends one prompt per new batch of sections, so the woken turn doesn't arm
  anything. A prompt queued while the chat is closed waits until the chat is
  opened again. "lore-collab manual" means asking the user to stop that terminal
  command.
- **Anywhere else, or when no waiter can run:** stay manual; the user says
  "lore-collab".
- **Keep one waiter per collaboration and member.** `wait` refuses a second one.
  After a restart, check whether the waiter still runs, and arm it again if not;
  the first scan finds anything that arrived meanwhile.
- **If the wake-up fails** (`--then` exits non-zero), `wait` says so and exits
  non-zero. Nothing is lost: the sections stay unread until a turn acks them.
- A section waiting on the user doesn't stop the session from acting on other
  sections meant for it. Outward-facing steps still need the user's go-ahead.
