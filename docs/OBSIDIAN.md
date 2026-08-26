# Obsidian

Both vaults (personal and work) live in iCloud Drive at
`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/{personal,work}`,
synced by Obsidian itself. Claude Code already treats them as a wiki via the
`obsidian` skills (`stow/shared/.claude/skills/obsidian`,
`stow/shared/.claude-work/skills/obsidian`), reading and writing plain
markdown files directly on disk. This page covers the parts of that setup
that are manual/one-time and don't belong in Nix or Stow: giving **Claude
Desktop** the same access, and backing up the vaults.

## Claude Desktop integration

Claude Desktop has no shell, so it needs
[`mcp-obsidian`](https://pypi.org/project/mcp-obsidian/) to reach the vaults
at all. None of the setup below can be driven by Nix or Stow: it's either a
GUI-only step or a per-vault secret.

### Why this is manual

- `claude_desktop_config.json` holds a real API key per vault. This repo is
  public and has no secrets-management mechanism wired up (no sops, agenix,
  1Password CLI integration, etc.), so this file must never be committed with
  real values filled in. Treat it the same way [`PROJECT.md`](PROJECT.md)
  treats `~/.claude.json` MCP snippets: a copy-paste template, not a live
  dotfile.
- Desktop Custom Skills are uploaded via Settings > Features > Skills, which
  is GUI-only, per-user, and has no sync from claude.ai or automation path.

### 1. Install the "Local REST API" plugin in both vaults

`mcp-obsidian` is single-vault per server instance (one host/port/key), and it
talks to Obsidian through the
[Local REST API](https://github.com/coddingtonbear/obsidian-local-rest-api)
community plugin, which only answers requests while its vault is open. Giving
Desktop both vaults means running two separate plugin instances at the same
time, so they need distinct ports.

For each vault:

1. Open the vault in Obsidian.
2. Settings > Community plugins > Browse > search "Local REST API" > Install
   > Enable.
3. Open the plugin's settings and note down its **API key** and **port**
   (default `27124` over HTTPS). Leave the personal vault on the default port
   and change the work vault's port to something else (e.g. `27125`) so both
   can run at once without a bind conflict.

### 2. Claude Desktop config: two `mcp-obsidian` entries

`mcp-obsidian` is installed via `packageTools.uvTools` in
`nix/shared/home/darwin.nix` (`uv tool install`, symlinked to
`~/.local/bin`), so `command` below can call it directly rather than the
`uvx mcp-obsidian` form shown in its own README.

macOS config location: `~/Library/Application Support/Claude/claude_desktop_config.json`.

> [!IMPORTANT]
>
> This file is populated by hand on each machine and is never committed. It
> isn't stowed, and it isn't tracked anywhere in this repo, precisely because
> it must hold real API keys and this repo is public.

```json
{
  "mcpServers": {
    "obsidian-personal": {
      "command": "mcp-obsidian",
      "env": {
        "OBSIDIAN_API_KEY": "<personal vault API key>",
        "OBSIDIAN_HOST": "127.0.0.1",
        "OBSIDIAN_PORT": "27124"
      }
    },
    "obsidian-work": {
      "command": "mcp-obsidian",
      "env": {
        "OBSIDIAN_API_KEY": "<work vault API key>",
        "OBSIDIAN_HOST": "127.0.0.1",
        "OBSIDIAN_PORT": "27125"
      }
    }
  }
}
```

Restart Claude Desktop after editing this file for the new servers to load.

### 3. Both vaults must stay open

The Local REST API plugin only serves requests for the vault it's running
in, so both vaults need to be open as separate Obsidian windows (File > Open
another vault..., or launch a second window) at the same time for both MCP
entries to respond. If the personal vault's window is closed,
`obsidian-personal` will fail with no indication in Desktop that the vault
simply isn't open.

### 4. Package and upload the Desktop Custom Skill

Desktop only executes Python/Node inside a skill's `scripts/` folder, and
this skill's `scripts/lint.sh` is bash, so the packaged zip should contain
`SKILL.md` only:

```bash
cd stow/shared/.claude/skills/obsidian && zip obsidian-personal-skill.zip SKILL.md
cd stow/shared/.claude-work/skills/obsidian && zip obsidian-work-skill.zip SKILL.md
```

Upload each zip under Settings > Features > Skills. Re-run and re-upload
whenever `SKILL.md` changes meaningfully; Desktop doesn't read the file live
from disk.

### 5. Verify

Once a rebuild has installed the `claude` cask and `mcp-obsidian`, and steps
1-4 above are done:

1. Open both vaults, each in its own Obsidian window.
2. Restart Claude Desktop.
3. Ask it to list files, search, read a note, append to today's Daily note,
   and create a throwaway test note in each vault, confirming
   `obsidian-personal` and `obsidian-work` both respond independently and
   follow the same folder/frontmatter/autonomy conventions documented in the
   `obsidian` skills.

## Backing up the vaults

iCloud Drive syncs the vaults across devices, but sync isn't backup: a
corrupted or deleted file on one device propagates to every other device
signed into the same iCloud account. This adds an independent copy via
Google Drive for desktop.

Google Drive for desktop is installed via the `google-drive` Homebrew cask
(`nonDevelopmentCasks` in `nix/shared/system/darwin.nix`). Sign-in and folder
selection are GUI-only and can't be scripted safely, so they stay manual:

1. Launch Google Drive and sign in.
2. Open its menu bar icon > Preferences > Settings.
3. Under **My Computer** ("Folders from your computer" in some versions),
   click **Add folder** and add each vault:
   - `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/personal`
   - `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/work`
4. For each, choose **"Sync with Google Drive"** (two-way), not backup-only.
   Obsidian needs to keep writing to the same on-disk files that iCloud also
   syncs.

> [!IMPORTANT]
>
> This stacks two sync engines (iCloud Drive and Google Drive) on the same
> live folder Obsidian is actively writing to. If Google Drive's client
> offers an option to propagate deletions from the cloud side back down to
> disk, leave it off: the goal is protection against an accidental
> cloud-side delete, not two-way deletion mirroring.
