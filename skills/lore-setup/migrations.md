# Schema migrations

The steps that bring a scope repo from one schema version to the next. A scope
repo's version is the `schema` field in its readme's frontmatter; a readme
without one predates versioning. The `lore-setup` skill applies these in order,
starting after the repo's version.

For each step, show the user what will change and wait for their OK. Commit each
migration on its own, following the `lore` skill's "Writing beside other
agents", then push.

## Schema 1

For a scope repo set up before versioning (its readme has no `schema` field, or
`schema: 0`):

1. Run the `lore` skill's `scripts/check.sh` on it, and fix everything it
   reports except the `schema`:
   - the strict top level: tooling in `skills/<name>/`, never a top-level
     `bin/`, `hooks/` or loose file; the user's working preferences in
     `agents.md`. When you move a script, update everything that runs it, such
     as a generated copy's `rebuild` command, a git hook or a scheduled job;
   - a lowercase `readme.md` whose `scope`, `machines` and `writes` are each one
     plain line.
2. Check by hand that each code repo with notes, in `repos/` or a project, has
   an upstream page `repos/<code-repo>.md` with `repo`, `upstream` and `local`.
   Also check that each project's readme lists the code repos it covers, linked
   to those pages: the `lore` skill finds a project's notes through that list.
   `check.sh` checks the pages that exist, but reads neither project readmes nor
   which pages are missing.
3. Set `schema: 1` in the readme's frontmatter, replacing any `schema` line
   already there.
4. Run `check.sh` again. It must print `ok`.
