# Lore with chezmoi

For people whose dotfiles are managed by [chezmoi](https://www.chezmoi.io/). The
`lore-setup` skill follows this when it finds chezmoi on a machine; you can also
follow it by hand. Everything else in a setup (the routing file, pointing each
harness at lore, gathering existing notes) works the same with or without
chezmoi, so it lives in the skill.

Dotfiles repos are often public, so the one rule here is: **the names of your
scope repos never go into the chezmoi source.** They stay machine-local data.

## 1. Ask for the scope list once per machine

In `.chezmoi.toml.tmpl`, store the list as machine-local data:

```text
{{- $loreRepos := promptStringOnce . "loreRepos" "Lore repos to clone into ~/lore (owner/name, comma-separated, blank for none)" -}}
[data]
    loreRepos = {{ $loreRepos | quote }}
```

The answer lands in `~/.config/chezmoi/chezmoi.toml`, never in the source repo.
`promptStringOnce` asks only once, and a blank answer counts. To change the list
later, run `chezmoi init --prompt` to be asked again, or edit `loreRepos` in
that file, then apply as in section 3. A work laptop might answer
`example-lore/global,example-lore/work`.

## 2. Clone each scope as an external

In `.chezmoiexternal.toml.tmpl`:

```text
{{- range (splitList "," (index . "loreRepos" | default "")) }}
{{- $repo := trim . }}
{{- if $repo }}

[{{ printf "lore/%s" ($repo | base) | quote }}]
    type = "git-repo"
    url = {{ printf "git@github.com:%s.git" $repo | quote }}
{{- end }}
{{- end }}
```

`chezmoi apply` clones them on the first run. Later pulls happen in each repo
with `git pull`, or with `chezmoi apply --refresh-externals`.

## 3. Apply without losing this machine's changes

Run `chezmoi diff` before `chezmoi apply`. Apps rewrite some config files on
their own (Claude Code's `~/.claude/settings.json`, for example), and an apply
would overwrite those changes. Fold them into the source templates first, and
ask about anything that isn't obviously app churn.

## 4. Files chezmoi owns

When the setup changes a file chezmoi manages, such as a harness's global
instructions, change its source with `chezmoi edit <file>` and then apply.
Editing the file itself is undone by the next apply. `chezmoi managed` lists the
files it owns.
