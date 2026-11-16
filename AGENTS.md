# Working on this repo

This repo is public. The lore it describes is private, so nothing from anyone's
real lore comes in here.

- **Invented names only** in every example: scopes `global`, `work` and `home`;
  the org `example-lore`; the code repo `widget-app`; the project `widget-app`;
  agent sessions `kit` and `rook`. Never a real employer, org, project,
  colleague or machine name.
- **Run `gitleaks dir . --redact` before every push** and treat any hit as real
  until shown otherwise.
- **Skills stay portable:** `SKILL.md` frontmatter holds `name` and
  `description` only. Scripts are bash, with no dependencies beyond a POSIX
  system, git and `awk`.
- **Plain markdown:** relative links (`[schema](docs/schema.md)`), YAML
  frontmatter for metadata, nothing that needs a particular editor.
- **Format before committing:** `pnpm install` once, then `pnpm format`.
  `pnpm lint` checks it. Biome formats the Markdown (wrapped at its default 80
  columns, which suits side-by-side review) and JSON; it's a tool for this repo
  only, so the skills still need nothing beyond bash, git and `awk`, and nothing
  formats anyone's scope repos.
- **Fence frontmatter examples as `yaml`, never `markdown`:** Biome formats a
  `markdown` fence's contents as Markdown and joins the fields into one line.
- **Run `pnpm test` after changing a script or the schema.** It builds a scope
  repo from the schema's own examples and runs the scripts on it, so the two
  can't drift apart. CI runs it too.
- Commits use Conventional Commits, `type(scope): description`.
