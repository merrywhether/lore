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

| Path                   | Holds                                                                                                                                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `readme.md`            | The repo's contract (below).                                                                                                                                                                                        |
| `agents.md`            | Optional. How the user works with agents across this scope's projects: preferences, conventions, what they expect of code and writing. Typically only the scope cloned on every machine has one.                    |
| `projects/<project>/`  | Plans, research, decisions and working notes, organized however the project needs. A project can cover one code repo, several or none. Its readme lists the code repos it covers, each linked to its upstream page. |
| `skills/<skill>/`      | Skills that need this scope's private content. Generic skills belong in a public repo like this one.                                                                                                                |
| `repos/<code-repo>/`   | Optional. Steering and context for contributing to a code repo that can't be checked into it, because it's private or the repo isn't yours to change. Plans go in a project, not here.                              |
| `repos/<code-repo>.md` | Optional. The code repo's upstream page (below).                                                                                                                                                                    |

Git's own files (`.gitignore`, a `.gitleaks.toml` allowlist) may sit beside
these. A strict top level means an agent always knows where to look, and a stray
file is easy to spot: `skills/lore/scripts/check.sh` reports one.

A scope's private tooling (scripts, sync jobs, git hooks, the files they read)
goes in `skills/<name>/`, with a `SKILL.md` saying when to run it. Never a
top-level `bin/`, `hooks/` or loose file.

### The readme contract

`readme.md` starts with YAML frontmatter between two `---` lines. The routing
file is built from it, and every field is required:

```yaml
scope: Everything for the widget-app employer.
machines: work machines only
writes: Work for the employer, its repos and its colleagues' public work.
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
frontmatter between `---` lines (`branch` is optional):

```yaml
repo: example-lore/widget-app # owner/name
upstream: git@github.com:example-lore/widget-app.git # fetch URL
local: ~/Developer/widget-app
branch: main # only for clones kept on a branch
```

After the frontmatter: a line linking the notes folder, then the clone command.
Take `upstream` from the checkout's fetch remote, never a remote name. If the
`local` path is missing on this machine, offer to clone from `upstream`; don't
guess the URL.

## Plain markdown

- Links are relative markdown links (`[setup](setup.md)`), never
  `[[wikilinks]]`.
- Metadata goes in YAML frontmatter.
- No file depends on a particular editor or plugin to make sense.

## Privacy

- Scope repos are always private. Keep them in an org of their own, used only
  for lore, where "every repo is private" is one check, and install no
  third-party apps there.
- A repo like this one, holding only the convention and skills, can be public.
- A code repo's checkout may hold a generated copy of its lore notes for tools
  that can't read `~/lore`. Mark it generated, name the sync that writes it, and
  edit lore, never the copy.
