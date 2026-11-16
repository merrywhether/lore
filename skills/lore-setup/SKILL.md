---
name: lore-setup
description: Set up lore (the user's private per-scope knowledge repos under ~/lore) on a machine, by interview, and gather the machine's existing agent notes and plans into it. Use when the user says "set up lore", "install lore", "add lore to this machine", or asks to create a new lore scope repo.
---

# lore-setup

An interview that sets up `~/lore` on this machine and moves the machine's
existing agent notes and plans into it. Ask one question at a time, and change
nothing until each answer is in. The conventions are in this repo's
`docs/schema.md`; this skill needs nothing from any earlier setup guide.

## 1. See what's already here

The machine may be half set up already: by hand, by a dotfiles manager, or by an
older version of this setup. Before asking anything, look, and report what you
found:

- Does `~/lore/` exist? Which scope repos are in it, and does each pass the
  `lore` skill's `scripts/check.sh`?
- Who writes `~/lore/readme.md`? Look for a dotfiles template that produces it
  (for chezmoi: `chezmoi source-path ~/lore/readme.md`).
- Which harnesses are installed, and does each one's global instructions already
  point at `~/lore/readme.md`?
- Does a dotfiles manager own those instruction files? With chezmoi,
  `chezmoi managed` lists them.

Then do only the steps that are missing, and fold anything that doesn't match
the schema into it (a scope repo with extra top-level folders, a routing file
that names files deeper inside).

## 2. Where the scope repos live

- Which git host and which org or account hold the scope repos? Recommend an org
  used only for lore, where every repo is private and no third-party apps are
  installed, so "nothing is public" is easy to check.
- Which scopes belong on this machine? A work laptop gets work scopes; a
  personal machine never does. If a scope repo's readme says which machines it
  belongs on (`machines:`), follow it.
- Should any scope be created now? If yes, create it private, write its readme
  per the contract, add `projects/` and `skills/`, then commit and push. Check
  that the org has no public repos.

## 3. Clone

- **chezmoi:** if it manages this machine's dotfiles, follow `docs/chezmoi.md`.
  It keeps the scope list as machine-local data.
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

  Typical finds: a `.llms/` or `.notes/` folder, an ignored `docs/` folder
  (often in a public repo, where plans can't be checked in), a loose `PLAN.md`.
  Checked-in docs belong to the code repo; leave them there.

  Don't stop at known folder names: a search for `.llms/` alone misses an
  ignored `docs/`. And report every checkout you searched, including the ones
  with nothing, so the user can spot a repo that should have had notes.
- **Global instruction files:** `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
  `~/.config/opencode/AGENTS.md`.
- **Agent memory folders**, such as `~/.claude/projects/*/memory/`: list what
  each holds, and propose which facts belong in lore. Leave the folders in
  place.
- **Chat histories**, for each harness installed: Claude Code's
  `~/.claude/projects/*/`, Codex's `~/.codex/sessions/`, and VS Code Copilot's
  `chatSessions/` under
  `~/Library/Application Support/Code/User/workspaceStorage/*/` (on macOS; each
  folder's `workspace.json` names its checkout). They are transcripts, not
  notes: list how many sessions each checkout has and their titles, and ask
  whether a plan lives only there. Copy nothing from them.
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

Every code repo that gets notes also gets its upstream page,
`repos/<code-repo>.md`, and the project's readme lists the code repo with a link
to that page.

Facts true in every context (preferences, conventions) go to the scope cloned on
every machine, if the user keeps one, often in its `agents.md`.

### Copy them

Only after the user OKs the whole list:

- Copy with `rsync -a`, then prove the copy with `rsync -anc --itemize-changes`,
  which must print nothing.
- If the destination already exists, stop and ask: another machine copied it,
  and the two need merging by judgement, not by overwrite.
- Scan each scope repo with `gitleaks dir <repo> --redact` before committing.
  Treat every hit as real until shown otherwise.
- Run `scripts/check.sh` on each scope repo, then commit the paths you copied
  (explicit paths, per the `lore` skill's "Writing beside other agents") and
  push.
- Leave the sources in place until the user switches over. Then offer to delete
  each one, or to replace it with a generated copy for tools that can't read
  `~/lore` (see the schema's Privacy section).

Never read or copy another machine's notes, and never move content into a
broader scope without the user's review.
