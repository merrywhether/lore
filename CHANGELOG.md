# Changelog

Each release is a git tag, `vX.Y.Z`, that the `skills` CLI can pin. A release
that raises the schema version changes what scope repos must hold. Its entry
says so, and the steps are in
[the `lore-setup` skill's migrations](skills/lore-setup/migrations.md), which
`lore-setup` applies when you run it again.

## Unreleased

- `lore-setup` step 6 asks, for each source it copied, whether to remove the
  original, keep it or replace it with a generated copy, and recommends removing
  it.
- `lore-setup` step 7: when a harness's CLI can't run, a fresh session of that
  harness started in the code checkout does the cold read; never a fork or a
  briefed subagent.
- `chezmoi.md`: how to change a `loreRepos` answer, blank included.
- README: the three questions the `skills` CLI asks without `-y`.

## 0.1.2 (schema 1)

- `lore-setup` step 7: the routing check also passes when the harness's own
  global instructions, which step 5 points at the routing file, come first.
- README: Claude Code and Codex are verified with 0.1.1, and the install command
  drops `-a opencode`, which `-a codex` already covers.

## 0.1.1 (schema 1)

- `lore-sweep` sweeps only the memory of the harness it runs in, which knows
  where that memory lives and how to change it; run it in each harness. A
  correction or convention that holds across one scope's projects goes to that
  scope's `agents.md`; links between memories become relative links or plain
  words; a large first sweep runs in rounds.
- `check.sh`: a readme with no `schema` says to migrate it with `lore-setup`.
- No migration.

## 0.1.0 (schema 1)

The first tagged release.

- The lore schema, with a `schema` field in each scope readme's frontmatter.
  `check.sh` reports a scope repo that's behind or ahead of the skills.
- The `lore`, `lore-setup`, `lore-sweep` and `lore-collab` skills.
- **Migration:** a scope repo set up before versioning needs
  [schema 1](skills/lore-setup/migrations.md#schema-1).
