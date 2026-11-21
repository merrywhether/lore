# The lore schema

The conventions every lore setup follows. The skills in this repo rely on them.

## The folder

- `~/lore/` is a plain folder, not a git repo.
- It holds the **routing file**, `~/lore/readme.md`, and one private git repo
  per **scope**: `~/lore/<scope>/`.
- Agents read the routing file first, then the readme of the scope repo they
  work in.

## Scopes

A scope is a boundary of who may see something: everything you do for one
employer, your own projects, facts true everywhere. Each scope is its own
private repo, so a machine clones only the scopes it should have (a work laptop
gets `work`, never `home`).

- **No scope is special.** Many people keep a scope cloned on every machine,
  often called `global`, for who they are and how they work. That is a
  convention: lore treats every scope the same, and a single-scope setup is
  fine.
- **Unsure where something goes? Pick the narrower scope.** Moving content
  toward a broader scope can leak for good; moving it narrower later is safe.
- Content moves toward a broader scope only after a pass that removes what the
  broader scope mustn't see.

## A scope repo

Every scope repo has the same top level, and nothing else:

| Path                   | Holds                                                                                                                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `readme.md`            | The repo's contract (below).                                                                                                                                                                                                                           |
| `agents.md`            | Optional. How the user works with agents across this scope's projects: preferences, conventions, what they expect of code and writing. Typically only the scope cloned on every machine has one.                                                       |
| `projects/<project>/`  | Plans, research, decisions and working notes, organized however the project needs. A project can cover one code repo, several or none. Its readme lists the code repos it covers, each linked to its upstream page, and their extra checkouts (below). |
| `skills/<skill>/`      | Skills that need this scope's private content. Generic skills belong in a public repo like this one.                                                                                                                                                   |
| `repos/<code-repo>/`   | Optional. Steering and context for contributing to a code repo that can't be checked into it, because it holds private context or opinions, or the repo isn't yours to change. Plans go in a project, not here.                                        |
| `repos/<code-repo>.md` | Optional. The code repo's upstream page (below).                                                                                                                                                                                                       |

Git's own files (`.gitignore`, a `.gitleaks.toml` allowlist) may sit beside
these. A strict top level means an agent always knows where to look, and a stray
file is easy to spot: `skills/lore/scripts/check.sh` reports one.

A scope's private tooling (scripts, sync jobs, git hooks, the files they read)
goes in `skills/<name>/`, with a `SKILL.md` saying when to run it. Never a
top-level `bin/`, `hooks/` or loose file.

### The readme contract

`readme.md` starts with this frontmatter. The routing file is built from it.
Every field is required and needs a value, and each is one plain `key: value`
line: no quotes, no block scalars (`>` or `|`) and no indented continuation
lines, because the scripts read values as plain text. A `#` after a space starts
a comment.

```yaml
---
scope: Everything for the widget-app employer.
machines: work machines only
writes: Work for the employer, its repos and its colleagues' public work.
---
```

Then a `# Lore: <scope>` title, a short paragraph on the scope, and these
sections:

- `## Never put here`: what belongs in another scope, or nowhere.
- `## Layout`: the folders above, and anything specific to this repo.
- `## Status`: what's in it so far.

Other sections may follow, such as the answers a new machine's setup needs
(which org holds the scope repos, which scopes go on which machines).

### Upstream pages

Every code repo with notes gets `repos/<code-repo>.md`, which starts with this
frontmatter (`branch` is optional; the same plain-line rule applies):

```yaml
---
repo: example-lore/widget-app # owner/name
upstream: git@github.com:example-lore/widget-app.git # fetch URL
local: ~/Developer/widget-app
branch: main # only for clones kept on a branch
---
```

After the frontmatter: a line linking the notes folder, then the clone command.
Take `upstream` from the checkout's fetch remote, never a remote name. If the
`local` path is missing on this machine, offer to clone from `upstream`; don't
guess the URL.

### Checkouts

A code repo can have several local checkouts: a preview build, a long-running
branch, a second clone for an experiment. The upstream page's `local` is the
main checkout. A project's readme lists every other checkout of its code repos,
each with its path and one line on why it exists, for example
"`~/Developer/widget-app-preview`: preview build of the next release". A
checkout kept on only some machines says which.

To find which code repo a checkout belongs to, don't go by its folder name,
which may differ. Match its path against the upstream pages' `local` and the
checkouts the project readmes list. Failing that, match the fetch URL of each of
its remotes, not only `origin`, against an upstream page's `upstream`: in a
fork, `origin` is often the fork and the repo you contribute to is another
remote. Use fetch URLs only (the `(fetch)` lines of `git remote -v`): unrelated
repos can share a push URL. Treat the SSH and HTTPS URLs of one repo as the
same. If a checkout matches more than one upstream page, or its path and remotes
disagree, ask the user. A checkout with only the fork's remote is found by its
path, so list it.

Clones a tool makes for its own runs, such as a worktree per agent session, are
that tool's business. Lore doesn't list them; they can still get a generated
copy (see Privacy).

## Plain markdown

- Links are relative markdown links (`[setup](setup.md)`), never
  `[[wikilinks]]`.
- Metadata goes in YAML frontmatter.
- No file depends on a particular editor or plugin to make sense.

## Privacy

- Scope repos are always private. Recommended: keep them in an org of their own,
  used only for lore, where "every repo is private" is one check, and install no
  third-party apps there.
- A repo like this one, holding only the convention and skills, can be public.
- Some tools can read only inside a checkout, such as an editor assistant
  limited to the open workspace, or an agent in a sandbox or the cloud. For
  them, a checkout may hold a generated copy of lore (below).

## Generated copies

A copy of lore inside a checkout is written by a script in a scope repo's
`skills/`, which holds the exact commands and their tests. Whatever the script,
these rules hold:

- **Never checked in.** Ignore the copy in the checkout's local exclude file
  (`git rev-parse --git-path info/exclude`; in a worktree `.git` is a file),
  never in `.gitignore`, so the repo itself never changes.
- **Every file it writes is ignored and untracked,** checked before copying and
  again after. If a check fails, stop and tell the user.
- **It reads only its `sources` and writes only inside its own folder,** the one
  holding its marker.
- **It deletes nothing it didn't create.** A file that was there before the
  copy, even one it overwrote, is the user's to deal with.
- **It's marked** with a `GENERATED.md` at the copy's top that starts with this
  frontmatter (the plain-line rule applies; separate several sources with
  commas):

```yaml
---
generated: lore
sources: ~/lore/work/repos/widget-app, ~/lore/work/projects/widget-app
rebuild: ~/lore/work/skills/copies/sync.sh widget-app
---
```

Other tools write files named `GENERATED.md` too. A folder is a copy of lore
only if its marker says `generated: lore`. Edit its sources, never the copy.
