# Schema migrations

The steps that bring a scope repo from one schema version to the next. A scope
repo's version is the `schema` field in its readme's frontmatter; a readme
without one predates versioning. The `lore-setup` skill applies these in order,
starting after the repo's version.

For each step, show the user what will change and wait for their OK. Commit each
migration on its own, following the `lore` skill's "Writing beside other
agents", then push.

## Schema 1

For a scope repo set up before versioning (its readme has no `schema` field):

1. Run the `lore` skill's `scripts/check.sh` on it, and fix everything it
   reports except the missing `schema`:
   - the strict top level: tooling in `skills/<name>/`, never a top-level
     `bin/`, `hooks/` or loose file; the user's working preferences in
     `agents.md`;
   - a lowercase `readme.md` whose `scope`, `machines` and `writes` are each one
     plain line;
   - an upstream page `repos/<code-repo>.md` with `repo`, `upstream` and `local`
     for each code repo that has notes.
2. Add `schema: 1` to the readme's frontmatter.
3. Run `check.sh` again. It must print `ok`.
