---
name: obsidian
description:
  Find, navigate, read, and edit notes in the user's personal Obsidian vault (an
  iCloud-synced markdown collection on macOS). Use whenever the user mentions
  "the vault", "my notes", "Obsidian", a daily note, a meeting note, scratchpad,
  or asks to look up/jot down something that sounds personal-knowledge-base-like
  (e.g. "what did I write about X", "add a note about Y", "today's daily note")
  — even if they don't say the word "Obsidian".
---

# Obsidian vault

The user keeps a personal Obsidian vault as plain markdown files synced via
iCloud. The vault is just a directory tree, so all standard Unix tools work — no
Obsidian app required to read or write notes.

## Where it lives

```
/Users/kasunt/Library/Mobile Documents/iCloud~md~obsidian/Documents/work
```

Because the path contains spaces and tildes, **always quote it** in shell
commands. A useful shorthand is to assign it once per session:

```bash
VAULT="/Users/kasunt/Library/Mobile Documents/iCloud~md~obsidian/Documents/work"
```

If `$VAULT` doesn't exist (e.g. on a non-mac host or before iCloud has synced),
stop and tell the user — don't fabricate notes.

## How the user normally interacts with it

The user edits the vault from Neovim via the
[`obsidian.nvim`](https://github.com/obsidian-nvim/obsidian.nvim) plugin.
Configuration (workspace path, daily-notes folder, template settings, keymaps)
lives in `nvim-custom/plugin/obsidian.lua` on the `neovim` branch of this
dotfiles repo — read it when you need the current setup, since it changes
occasionally and this skill should not duplicate it.

When suggesting a workflow, prefer pointing the user at the relevant keymap or
`:Obsidian` command (look them up in that file) over spawning a shell command,
unless they're clearly outside Neovim.

## Folder layout

```
$VAULT/
├── Daily/                  # Daily notes, one file per day: YYYY-MM-DD.md
│                           # (also the vault's append-only log, see Ingest workflow)
├── Meeting notes/          # Meeting notes (template: meeting_notes.md)
├── Resources/              # PARA-style references (Go/, Postgres/, Neovim/, ...)
├── Ideas/                  # Half-baked ideas
├── Archive/                # Things no longer active
├── Clippings/              # Web clippings
├── _templates/             # Frontmatter templates (daily.md, meeting_notes.md)
├── _excalidraw/            # Excalidraw drawings
├── .trash/                 # Obsidian's soft-delete bin (treat as deleted)
├── index.md                # Curated catalog of durable topics (see below)
└── *.md                    # A handful of loose top-level notes
                            # (scratchpad.md, Running.md, LEARNING.md, blog drafts)
```

Underscored folders (`_templates`, `_excalidraw`) sort to the top in the
Obsidian UI — they're conventions, not hidden files. Skip `.trash/` when
searching unless the user explicitly asks about deleted notes.

## Note conventions

### Filenames

- Daily notes: `Daily/YYYY-MM-DD.md` (e.g. `Daily/2026-05-08.md`).
- Other new notes created via the Neovim plugin are prefixed with today's date:
  `YYYY-MM-DD-<title>.md`. Match this pattern when creating notes
  programmatically.
- Filenames may contain spaces (`API design.md`) and emoji (`🧚‍♀️ LEARNING.md`).

### Frontmatter

Every note has YAML frontmatter. Minimum shape:

```yaml
---
id: <usually filename without .md>
aliases: []
tags: []
categories: []
---
```

Daily notes also include `date: YYYY-MM-DD` and `tags: [daily-notes]`. Meeting
notes include `company: "[[Einride]]"` and `date`. When creating a new note,
copy the relevant template from `_templates/` rather than hand-rolling
frontmatter.

### Links

Notes use **Obsidian wikilinks** in _shortest_ form:

- `[[API design]]` — link by note title (no path, no `.md`)
- `[[API design|how we design APIs]]` — with display text
- `[[API design#Choose level of abstraction]]` — link to a heading

Standard markdown links (`[text](path.md)`) are not used — preserve wikilink
style when editing.

## The index note (`index.md`)

`$VAULT/index.md` is a curated catalog of the vault's durable topics: a home
page, not a dump of every note. Each entry is a topic with a wikilink into
`Resources/` (or wherever the durable note lives), plus at most a short clause
of context.

- For broad "what do I know about X" questions, check `index.md` first (see
  [Query workflow](#query-workflow) below) before falling back to search.
- When filing a new durable note (anything landing in `Resources/`, or any
  other note meant to last), add or update its entry in `index.md` so the
  catalog stays current. Don't index Daily notes, meeting notes, or ideas;
  those aren't durable topics.
- If `index.md` doesn't exist yet, create it the first time you file a durable
  note, same as creating any other note.

## Finding things (portable, no Obsidian needed)

Prefer `rg` and `fd`; fall back to `grep`/`find` if those aren't installed.
Always exclude `.obsidian/` and `.trash/` to keep results signal-rich.

```bash
# Find notes by filename (case-insensitive, fuzzy on basename)
fd -tf 'pattern' "$VAULT" -E .obsidian -E .trash

# Full-text search across notes, with filename + line context
rg --type md -n 'search term' "$VAULT" -g '!.obsidian' -g '!.trash'

# Find all notes tagged X (frontmatter or inline #tag)
rg --type md -n '(^|\s)#X\b|tags:.*\bX\b' "$VAULT" -g '!.obsidian' -g '!.trash'

# Find backlinks to a note titled "API design"
rg --type md -n '\[\[API design(\||#|\]\])' "$VAULT" -g '!.obsidian' -g '!.trash'

# Today's daily note (create-if-missing pattern)
TODAY="$VAULT/Daily/$(date +%Y-%m-%d).md"
```

For broader exploration (e.g. "what notes do I have about Postgres?"), look at
both filenames and full-text — the user organizes by both folder and tag.

## Ingest workflow

When the user hands you a source to save (a clipping, a link, a quote, a
paper), work through it in order:

1. **Extract takeaways.** Summarize the key points; don't just paste the raw
   source in full.
2. **File it** in the right folder per [Creating notes](#creating-notes)
   below (e.g. `Clippings/` for a raw web clipping, `Resources/<topic>/` for a
   distilled reference).
3. **Cross-link** the new note to related existing notes via wikilinks.
   Search for related notes using the recipes above.
4. **Update `index.md`** if the note is a durable topic (see
   [The index note](#the-index-note-indexmd) above).
5. **Mention it in today's Daily note**: a one-line pointer with a wikilink.
   `Daily/` is already the vault's append-only log; don't invent a separate
   log file for this.

All five steps are low-risk appends and cross-links, so none of them need
confirmation first (see the autonomy note in [Creating notes](#creating-notes)
below).

## Query workflow

For "what do I know about X"-style questions:

1. Check `index.md` first for a matching curated entry.
2. Fall back to the `rg`/`fd` recipes above for anything the index doesn't
   cover.
3. Synthesize an answer from what you find, citing the source notes (with
   wikilinks) rather than just dumping search results.
4. **Offer, don't auto-create,** to save the synthesis as a new note. Which
   folder it belongs in, and whether it's durable enough to index, are calls
   the user should make.

## Creating notes

When the user asks you to add a note, follow these rules:

1. **Pick the right folder** based on intent: daily entry → `Daily/`, meeting →
   `Meeting notes/`, work topic → `Einride/<area>/`, durable reference →
   `Resources/<topic>/`, half-formed thought → `Ideas/` or append to
   `scratchpad.md`.
2. **Use the matching template** from `_templates/` as the starting point.
   Replace `{{date}}` with `YYYY-MM-DD` and `{{title}}` with the note's title.
3. **Set `id`** to the filename without `.md` (the Neovim plugin uses
   `YYYY-MM-DD-<title>` for non-daily notes — match that for consistency).
4. **Use wikilinks** for any cross-references, not markdown links.

If unsure which folder fits, ask — folder choice is how the user finds things
later.

Creating a new note this way, including Daily/inbox-style appends and adding
cross-links, doesn't need confirmation first. It's a low-risk, additive
change.

## Editing notes

- Preserve existing frontmatter exactly; only add fields that are missing.
- Don't rewrite `id` even if the filename suggests a different one (it may be a
  deliberate alias).
- Keep the wikilink style — if the user wrote `[[Foo]]`, don't "improve" it to
  `[Foo](Foo.md)`.

Confirm with the user before: renaming a note, restructuring folders, deleting
a note, or making an edit that touches multiple files at once. Those are
harder to reverse than an append.

## Vault health check

Run `scripts/lint.sh "$VAULT"` for a quick, read-only pass over the vault. It
flags (without modifying anything):

- **Orphaned notes**: no incoming wikilinks, excluding `Daily/`, `Ideas/`,
  `Archive/`, and `_templates/` (these are expected to be link-sparse).
- **Broken wikilinks**: a `[[Target]]` reference where no note titled
  `Target` exists. This matches on filename only, not on `aliases:` in
  frontmatter, so a note reached only via an alias will show up as a false
  positive; check before treating it as a real break.
- **Notes missing required frontmatter fields** (`id`, `aliases`, `tags`,
  `categories`).

Treat its output as a prompt for cleanup, not something to auto-fix. Fixing
orphans or broken links usually means a rename or a restructuring edit, which
needs the user's confirmation per the rule above.

## Plugins worth knowing about

The vault has two community plugins enabled (see
`.obsidian/community-plugins.json`):

- **frontmatter-generator** — auto-fills frontmatter on note creation in the
  Obsidian app. Notes created from the shell won't go through it, so copy from
  `_templates/` to get equivalent output.
- **obsidian-excalidraw-plugin** — drawings live in `_excalidraw/` as
  `.excalidraw.md` files. Treat them as opaque unless the user asks
  specifically.

## On Claude Desktop

Desktop has no shell, only `mcp-obsidian` tool calls (one MCP server per
vault; see `docs/OBSIDIAN.md` for setup). Everything above still applies:
folder layout, frontmatter, wikilink style, the autonomy rule, the ingest and
query workflows. Just swap the shell recipe for its MCP equivalent:

| Shell recipe (this file)                     | `mcp-obsidian` tool                        |
| --------------------------------------------- | ------------------------------------------- |
| `fd`/`ls` over `$VAULT`                       | `list_files_in_vault`, `list_files_in_dir`  |
| `rg` full-text / tag / backlink search        | `search`                                    |
| Read a note's contents                        | `get_file_contents`                         |
| Append to Daily/inbox note, add a cross-link  | `append_content` / `patch_content`          |
| Create a new note                             | `append_content` (creates the file if missing) |
| Delete a note (moves to `.trash/`)            | `delete_file`                               |

Tool names current as of `mcp-obsidian` 0.2.2; confirm against whatever
version is actually installed if this stops matching (`uv tool list`).

`scripts/lint.sh` is bash, and Desktop only executes Python/Node inside skill
scripts, so the vault health check above is Code-only.
