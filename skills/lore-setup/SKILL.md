---
name: lore-setup
description: Set up lore (the user's private per-scope knowledge repos under ~/lore) on a machine, by interview, gather the machine's existing agent notes and plans into it, and migrate scope repos after a schema change. Use when the user says "set up lore", "install lore", "add lore to this machine", "upgrade lore" or "migrate lore", or asks to create a new lore scope repo.
---

# lore-setup

An interview that sets up `~/lore` on this machine and moves the machine's
existing agent notes and plans into it. Ask one question at a time, and change
nothing until each answer is in. Before you start, ask the user to pause other
agent sessions on this machine, and to leave the notes alone, until setup is
done: it moves those notes. The conventions are in lore's
[schema](../lore/schema.md); this skill needs nothing from any earlier setup
guide.

## 1. See what's already here

The machine may be half set up already: by hand, by a dotfiles manager, or by an
older version of this setup. Before asking anything, look, and report what you
found:

- Does `~/lore/` exist? Which scope repos are in it, and does each pass the
  `lore` skill's `scripts/check.sh`? Which schema version does each follow (the
  `schema` field in its readme)?
- Who writes `~/lore/readme.md`? Look for a dotfiles template that produces it
  (for chezmoi: `chezmoi source-path ~/lore/readme.md`).
- Which harnesses are installed, and does each one's global instructions already
  point at `~/lore/readme.md`?
- Does a dotfiles manager own those instruction files? With chezmoi,
  `chezmoi managed` lists them.

Then do only the steps that are missing, and fold anything that doesn't match
the schema into it (a scope repo with extra top-level folders, a routing file
that names files deeper inside).

**Migrate first.** If `check.sh` says a scope repo is behind these skills, or
its readme has no `schema` field, apply the steps in
[migrations.md](migrations.md) in order, starting after the repo's version. Show
each change and wait for the user's OK. If a scope repo is ahead of these
skills, stop and ask the user to update the skills (lore's README,
[Update](https://github.com/merrywhether/lore#update)) before going on.

## 2. Where the scope repos live

- Which git host and which org or account hold the scope repos? Recommend an org
  used only for lore, where every repo is private and no third-party apps are
  installed, so "nothing is public" is easy to check.
- Which scopes belong on this machine? A work laptop gets work scopes; a
  personal machine never does. If a scope repo's readme says which machines it
  belongs on (`machines:`), follow it.
- Should any scope be created now? If yes, create it private, write its readme
  per the contract (`check.sh --schema` prints the current `schema` version),
  add `projects/` and `skills/`, then commit and push. Check that the org has no
  public repos.

## 3. Clone

- **chezmoi:** if it manages this machine's dotfiles, follow
  [chezmoi.md](chezmoi.md). It keeps the scope list as machine-local data.
- **Otherwise:** clone each scope with `git` into `~/lore/<scope>/`.
- Check each repo with the `lore` skill's `scripts/check.sh`.

## 4. Build the routing file

Run the `lore` skill's `scripts/routing.sh --write`. If a dotfiles template
writes `~/lore/readme.md` today, offer to retire it, so the routing file has one
writer.

## 5. Point each harness at lore

Ask which harnesses to wire, then for each one:

- **Claude Code:** add `~/lore` to `permissions.additionalDirectories` in
  `~/.claude/settings.json`, and point `~/.claude/CLAUDE.md` at
  `~/lore/readme.md`.
- **Codex:** point `~/.codex/AGENTS.md` at `~/lore/readme.md`.
- **opencode:** point `~/.config/opencode/AGENTS.md` at `~/lore/readme.md`.

Point them at the routing file only, never deeper, so it can change hands later
without touching harness config again. If a dotfiles manager owns a file, change
its source (for chezmoi, `chezmoi edit <file>`), not the file itself, or the
next apply undoes the change.

## 6. Gather existing notes and plans

### Find them

List everything before copying anything. Agent notes and plans often sit in
places git ignores, so search for files that aren't checked in, not only for
known folder names:

- **In each checkout** (for example every git repo under `~/Developer/`): files
  git doesn't track, ignored ones included, that look like notes or plans:

  ```bash
  git -C <checkout> ls-files --others --ignored --exclude-standard \
    | grep -Ei '\.(md|mdx|txt)$' \
    | grep -Ev '(^|/)(node_modules|\.venv|vendor|dist|build|\.cache)/'
  ```

  Typical finds: a `notes/` or `.notes/` folder, an ignored `docs/` folder
  (often in a public repo, where plans can't be checked in), a loose `PLAN.md`.
  Checked-in docs belong to the code repo; leave them there.

  Don't stop at known folder names: a search for `notes/` alone misses an
  ignored `docs/`. And report every checkout you searched, including the ones
  with nothing, so the user can spot a repo that should have had notes. Group
  checkouts by the fetch URLs of all their remotes (the `(fetch)` lines of
  `git remote -v`, never push URLs): two folders sharing a fetch URL are two
  checkouts of one code repo, even when one's `origin` is a fork. Show the user
  any folder that matches more than one group, and let them decide.
- **Global instruction files:** `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
  `~/.config/opencode/AGENTS.md`.
- **Harness memory:** keep it out of the copy below. One memory can mix a fact
  for lore with one that must stay, so once the rest is in place, run the
  `lore-sweep` skill in each harness that keeps memory; each one sorts and moves
  its own memory fact by fact. If it isn't installed, install it first with
  [the README's commands](https://github.com/merrywhether/lore#install).
- **Chat histories**, for each harness installed: Claude Code's
  `~/.claude/projects/*/`, Codex's `~/.codex/sessions/`, and VS Code Copilot's
  `chatSessions/` under
  `~/Library/Application Support/Code/User/workspaceStorage/*/` (on macOS; each
  folder's `workspace.json` names its checkout). They are transcripts, not
  notes: list how many sessions each checkout has and their titles, and ask
  whether a plan lives only there. Copy nothing from them.
- **Never read credentials.** In the harness folders, look only at the notes,
  memory and chat-history paths above: never at sign-in or key files (such as
  `auth.json` or `.credentials.json`) or settings that hold tokens.
- **Anywhere else:** ask the user whether notes live outside these places.

### Place them

For each checkout that has notes or plans, ask:

- **Which scope?** Propose one; unsure means the narrower.
- **Which project?** Plans, research and decisions go under
  `projects/<project>/`. Offer the code repo's name as the project name, or an
  existing or new broader project that covers several repos. List the projects
  the scope already has.
- **What stays per repo?** Steering for contributing to the code repo that can't
  be checked in goes to `repos/<code-repo>/`.
- **Several checkouts of one code repo?** Ask which is the main one (the
  upstream page's `local`) and why each other one exists. The project readme
  lists the others, each with its path and that reason.

Every code repo that gets notes also gets its upstream page,
`repos/<code-repo>.md`, and the project's readme lists the code repo with a link
to that page.

Facts true in every context (preferences, conventions) go to the scope cloned on
every machine, if the user keeps one, often in its `agents.md`.

### Copy them

Only after the user OKs the whole list:

- Copy with `rsync -aL`, so a symlinked source lands as its content rather than
  a link, then prove the copy with `diff -r <source> <copy>`, which must print
  nothing.
- If the destination already exists, stop and ask: another machine copied it,
  and the two need merging by judgement, not by overwrite.
- Scan each scope repo with `gitleaks dir <repo> --redact` before committing.
  Treat every hit as real until shown otherwise.
- Run `scripts/check.sh` on each scope repo, then commit the paths you copied
  (explicit paths, per the `lore` skill's "Writing beside other agents") and
  push.
- **Then ask about each source.** Once its copy is proven, committed and pushed,
  ask the user whether to remove the original, keep it, or replace it with a
  generated copy for tools that can't read `~/lore` (the schema's "Generated
  copies"). Recommend removing it: two copies of a note drift apart. Remove only
  on a yes, moving it to the Trash where the system has one rather than deleting
  it outright. A harness's global instruction file stays, since it holds step
  5's pointer to the routing file: remove from it only what you copied.

Never read or copy another machine's notes, and never move content into a
broader scope without the user's review.

## 7. Check that each harness finds lore

Don't trust the install paths; check them. For each harness wired in step 5:

Run both cold reads from a code repo's checkout, where real sessions start.
Never run them from a clone of this repo or from `~/lore`: there an agent could
answer by reading the files in the current folder, and a broken install would
pass. For the same reason, pick a checkout with no project-local copy of these
skills (in its `.claude/skills/`, `.agents/skills/` or `.opencode/skills/`).

1. **The skill folders** `lore`, `lore-setup`, `lore-sweep` and `lore-collab`
   exist in that harness's global skills folder
   ([the README's Install table](https://github.com/merrywhether/lore#install)).
   If any is missing, install it with the README's commands, then check again.
2. **A cold read of the skills,** in a fresh non-interactive run:
   - Claude Code:
     `claude -p "Which skills do you have whose name starts with lore? Name them."`
   - Codex: `codex exec "<the same question>"`
   - opencode: `opencode run "<the same question>"`

   Add "and the folder each one is in" to the question. It passes if the answer
   names all four skills, each in that harness's global skills folder.
3. **A cold read of the routing,** the same way: "Where would you write a note
   about <one of the user's projects>? Name the file, and the files that led you
   there." It passes if the path is that project's own folder, in the right
   scope (not just any path in the scope), and the files it lists start with the
   routing file, `~/lore/readme.md`. The harness's own global instructions may
   come before it, since step 5 points them at the routing file. Citing the
   scope's or the project's readme for the exact path is fine, as long as the
   routing file came before them.

If the CLI can't run (it isn't signed in, or it won't start inside this
session), but you can start a fresh session of that harness yourself, such as a
new session in its desktop app, do that instead: start it in the same code
checkout, with only the question as its first message. Never use a fork of this
session or a subagent you brief: both carry this setup's context, so they could
answer from it and pass a broken install.

A run that can't start at all is not a failed install: report it as "not run",
with the error, and ask the user to run that command in a terminal of their own.
Running one harness's CLI inside another's session, such as `claude -p` from
inside Claude Code, can fail for reasons that have nothing to do with lore.

Report pass or fail per harness and per check, not just "done". Say whether each
check ran in the CLI or in a fresh session, and the version of what ran it. For
a failure, say what the harness answered and where it looked.
