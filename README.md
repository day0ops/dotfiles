# dotfiles 🗃️

Personal dotfiles, managed in three layers:

- **[Nix](https://nixos.org)** (`nix/`) — system configuration and packages, pinned by `flake.lock` and applied with a rebuild. Fully reproducible.
- **Stow** (`stow/`) — dotfiles symlinked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/). Changes take effect immediately, no rebuild needed.
- **Homebrew** (macOS) — GUI apps and Mac App Store apps. Nix declares _which_ packages and a rebuild installs or removes to match, but versions are unpinned and upgraded manually.

## Quickstart

### Nix

> [!NOTE]
>
> - This requires having Nix installed. See [the Nix docs](docs/NIX.md).
> - The `flake.nix` is designed to set up the machine based on its hostname.

```sh
# Rebuild system + packages + dotfiles (reproducible, uses flake.lock)
sudo darwin-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"  # macOS
sudo nixos-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"   # NixOS

# Update ALL flake inputs, then rebuild
nix flake update

# Update only the unstable-pinned inputs, then rebuild
nix flake update nixpkgs-unstable nix-darwin home-manager-unstable llm-agents dotfiles

# Clean up old Nix generations, keeping the last 5 days for rollback safety
sudo nix-collect-garbage --delete-older-than 5d
```

> [!NOTE]
> Language toolchains (go, python3, node, ruby, rustup, ...) aren't on the base PATH outside Neovim. Use the shared dev shell instead: `dev-toolchain` (alias for `nix develop ~/.dotfiles#dev --command zsh`, see `shell/aliases.sh`), or `nix develop ~/.dotfiles#dev -c <cmd>` for a single command. See `CLAUDE.md` for details.

> [!NOTE]
> On macOS, home-manager's per-user activation can silently fail to apply (a known upstream `launchctl asuser` flakiness). The rebuild self-heals this: a guard in `nix/shared/system/darwin.nix` verifies the activation landed and retries it, failing loudly otherwise. See `CLAUDE.md` for manual verification and recovery.

### Stow

Dotfiles are managed with GNU Stow, not Nix.

> [!NOTE]
>
> The `darwin-rebuild` and `nixos-rebuild` commands will run stow as well.

- Edit files in `stow/` directory and run stow
- Changes are immediately active (no rebuild needed)

```bash
# Apply dotfiles (no Nix rebuild needed)
cd ~/.dotfiles/stow
stow --target="$HOME" --restow --no-folding --adopt shared "$(uname -s)"
```

`--adopt` absorbs any real file that has replaced a managed symlink into the repo instead of aborting; review the result with `git diff` before committing.

#### Shell

The shell entrypoint is `stow/shared/.zshrc`, which sources `stow/shared/.zshrc_user`. The user file loads the shell configuration chain:

1. [`shell/exports.sh`](shell/exports.sh) — PATH (including [`shell/bin/`](shell/bin/) utils), globals, env vars
2. [`shell/aliases.sh`](shell/aliases.sh) — shell aliases
3. [`shell/sourcing.sh`](shell/sourcing.sh) — tool initialization, plugins, completions

See [Project config](docs/PROJECT.md) for details on shell initialization, direnv, and per-project tooling.

### Homebrew

`nix/shared/system/darwin.nix` declares Homebrew taps, brews, casks, and Mac App Store apps; a rebuild installs or removes to match. Versions are unpinned — upgrade manually with `brew upgrade`.

LLM agent CLIs (claude-code, opencode,...) are plain Nix packages from the `llm-agents` flake input, upgraded via `nix flake update llm-agents` + rebuild. `mcp-obsidian` (Claude Desktop's Obsidian bridge, Darwin-only) is installed directly via `uv tool install` — see `nix/shared/home/darwin.nix`.

## Other READMEs and references

- Neovim ⌨️
  - [Minimalistic config](nvim-simple/README.md)
  - My full `vim.pack`-based config lives on the `neovim` branch
- Workflows 🌊
  - [Git config](docs/GIT.md)
  - [Project config](docs/PROJECT.md)
  - [Container config](docs/CONTAINER.md)
  - [Obsidian](docs/OBSIDIAN.md)
- Fonts
  - [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono) ❤️
  - [Maple Mono](https://github.com/subframe7536/maple-font)
  - [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)
  - [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)
- Host-specific documentation
  - [rpi5-homelab](nix/hosts/rpi5-homelab/README.md) - requires custom installation procedure
