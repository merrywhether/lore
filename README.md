# lore

Lore is a convention for keeping your private knowledge where every coding agent
can find it: who you are, how you work, and what you know about each project.
This repo holds the convention and the skills that use it. It holds no knowledge
itself; yours lives in your own private repos.

- **`~/lore/`** is a plain folder holding a routing file, `readme.md`, and one
  private git repo per scope (`~/lore/global/`, `~/lore/work/`, …).
- **Agents read `~/lore/readme.md` first.** It says which scope repos this
  machine has and where writes go.
- **The rules** are in [skills/lore/schema.md](skills/lore/schema.md), which
  installs with the skills.
- **Keep the scope repos in an org of their own**, used only for lore: every
  repo private, no GitHub apps or other third-party integrations installed. Then
  "nothing here is public, and no service reads it" is one check, and a mistake
  elsewhere on your account can't reach it.

## Skills

| Skill                                      | Use it to                                                                        |
| ------------------------------------------ | -------------------------------------------------------------------------------- |
| [lore](skills/lore/SKILL.md)               | Read and write lore day to day, rebuild the routing file, check a scope repo.    |
| [lore-setup](skills/lore-setup/SKILL.md)   | Set up lore on a machine, by interview.                                          |
| [lore-sweep](skills/lore-sweep/SKILL.md)   | Move facts from harness memory into lore, after you approve a sorted list.       |
| [lore-collab](skills/lore-collab/SKILL.md) | Coordinate several interactive agent sessions through a shared log kept in lore. |

`lore-collab` is experimental: it leans on harness-specific features (Claude
Code's background commands, `codex queue`) and has had the least testing.

Each skill is a folder in the portable Agent Skills format: a `SKILL.md` with
`name` and `description`, plus bash scripts.

## Install

All harnesses at once, with the `skills` CLI:

```bash
npx skills add merrywhether/lore -g -a claude-code -a codex -a opencode
```

`-g` installs them for every project, in each harness's global skills folder. To
pin a release, name its tag: `merrywhether/lore@v0.1.0`
([CHANGELOG.md](CHANGELOG.md) lists them).

If you edit the skills yourself, clone this repo instead and link each folder
under `skills/` into the harness's skills folder, so your changes are live:

| Harness     | Global skills folder                                              |
| ----------- | ----------------------------------------------------------------- |
| Claude Code | `~/.claude/skills/<name>/`                                        |
| Codex       | `~/.agents/skills/<name>/`                                        |
| opencode    | `~/.config/opencode/skills/<name>/` (it also reads the two above) |

These paths come from each harness's docs and haven't been checked on a real
machine yet. `lore-setup` ends by checking that each harness finds the skills.
Verified so far: none.

Then ask your agent to "set up lore" and the `lore-setup` skill takes it from
there: it creates or clones the scope repos, builds the routing file, points
each harness at it, and gathers the notes and plans already on the machine into
lore.

If chezmoi manages your dotfiles, `lore-setup` follows
[its chezmoi notes](skills/lore-setup/chezmoi.md) to clone the scope repos
without putting their names in your dotfiles repo.

## Update

```bash
npx skills check
npx skills update -g
```

`update` keeps a pinned install on its tag. To move to a newer release, run
`npx skills add` again with the new tag. With a clone, `git pull` instead. Then
read [CHANGELOG.md](CHANGELOG.md). If a release raised the schema version, your
scope repos need migrating: ask your agent to "set up lore" again, and
`lore-setup` finds each scope repo that's behind and walks you through its
migration. The `lore` skill's `check.sh` also reports a scope repo that's
behind.

## License

MIT; see [LICENSE](LICENSE).
