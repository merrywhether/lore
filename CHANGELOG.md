# Changelog

Each release is a git tag, `vX.Y.Z`, that the `skills` CLI can pin. A release
that raises the schema version changes what scope repos must hold. Its entry
says so, and the steps are in
[the `lore-setup` skill's migrations](skills/lore-setup/migrations.md), which
`lore-setup` applies when you run it again.

## 0.1.0 (schema 1)

The first tagged release.

- The lore schema, with a `schema` field in each scope readme's frontmatter.
  `check.sh` reports a scope repo that's behind or ahead of the skills.
- The `lore`, `lore-setup`, `lore-sweep` and `lore-collab` skills.
- **Migration:** a scope repo set up before versioning needs
  [schema 1](skills/lore-setup/migrations.md#schema-1).
