---
name: lore
description: Read and write the user's private lore (~/lore), the per-scope git repos holding who they are, how they work and what they know about each project. Use at the start of work in any repo, when the user says "update lore", "put this in lore", "check lore", or asks where notes, plans or decisions should be kept.
---

# lore

Lore is the user's private knowledge in `~/lore/`: a routing file,
`~/lore/readme.md`, and one private git repo per scope. The rules are in this
repo's `docs/schema.md`; this skill is how to use them day to day.

## At the start of work

1. Read `~/lore/readme.md`. It lists the scope repos on this machine and where
   writes go.
2. Read the readme of the scope repo for the code repo you're in, and its
   `agents.md` if it has one. Then read what that scope keeps for this code
   repo: `repos/<code-repo>/` (steering for contributing to it), plus any
   project under `projects/` whose readme lists this code repo.
3. If a checkout has a folder marked as a generated copy of its lore notes,
   never edit it: edit lore, then run the sync its marker names.

## Writing ("update lore")

1. **Pick the scope** from the routing file. Unsure: the narrower one. Never
   move content toward a broader scope without removing what that scope mustn't
   see.
2. **Pick the place** in that repo:
   - a project's plans, research, decisions and logs: `projects/<project>/`;
   - steering and context for contributing to one code repo that can't be
     checked into it (it's private, or the repo isn't yours to change):
     `repos/<code-repo>/`, with its upstream page `repos/<code-repo>.md`;
   - how the user works with agents, across this scope's projects: `agents.md`;
   - a skill that needs this scope's private content: `skills/<skill>/`.

   Nothing else goes at a scope repo's top level. If something fits none of
   these, ask.
3. **Write plain markdown:** relative links, YAML frontmatter for metadata.
4. **When a decision changes, fix every record of it** (plans, notes, comments)
   the same day, so no agent reads the losing option and brings it back.
5. **Commit and push** (below), touching only your own changes.

## Writing beside other agents

Other agent sessions may be writing to the same scope repo: in the same checkout
on this machine, or in their own clones on other machines. Assume they are.

- **Before writing, run `git status` and `git pull --rebase --autostash`.**
  Changes you didn't make belong to someone else, even when they look
  unfinished. Leave them alone: don't commit, stash, discard, reformat or "tidy"
  them.
- **Stage and commit explicit paths only:** `git add -- <path>…` and
  `git commit -- <path>…`. Never `git add -A`, `git add .`, `git commit -a` or a
  formatter run at the repo root: each one sweeps another session's work into
  your commit.
- **Append to shared files rather than rewriting them.** For a log, use a shell
  append (`>>`) or the `lore-collab` script, never a read-modify-write of the
  whole file, which drops whatever landed between your read and your write.
- **Commit each change when it's complete:** one concern per commit, with a
  Conventional Commits message (`docs(widget-app): record the cache decision`)
  and no AI attribution lines.
- **Push right after committing.** A scope repo is private, so pushing it isn't
  outward-facing and needs no go-ahead. Anything that leaves lore (a public
  repo, a pull request, an issue) does.
- **If the push is rejected,** another writer got there first:
  `git pull --rebase --autostash`, then push again. Retry a few times.
- **If the rebase conflicts:**
  - In an append-only log, keep both sides in full. Order doesn't matter,
    because sections are read by id.
  - Elsewhere, if both sides changed different things, keep both. If they
    disagree, stop the rebase (`git rebase --abort`), tell the user what each
    side says, and ask which wins.
- **Never force-push a scope repo, and never rewrite pushed history.** If you
  committed someone else's changes by mistake, leave the commit, tell them which
  commit holds their work, and ask the user whether anything needs fixing.

Lore is private. Never copy its content anywhere public (a checked-in file, a
pull request, an issue, a public repo) unless the user asks.

## Scripts

- `scripts/routing.sh [--root <dir>] [--write]` builds the routing file from
  each scope repo's readme frontmatter (`scope`, `machines`, `writes`). It
  prints the result; `--write` replaces `~/lore/readme.md`. Don't use `--write`
  where something else (a dotfiles template) owns that file.
- `scripts/check.sh <scope repo>` checks a scope repo against the readme
  contract and the layout.
