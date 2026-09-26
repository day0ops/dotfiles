{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../../shared/home/darwin.nix
  ];

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    unstable.openfga-cli
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix://$HOME/.local/share/containers/podman/machine/podman.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/run/user/$UID/podman/podman.sock";
  };

  llmAgents = [
    "antigravity-cli"
  ];

  home.file = {
  };

  programs = {
  };

  # Disable Spotlight keyboard shortcut (Cmd+Space) to allow Raycast usage
  home.activation.disableSpotlightShortcut = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Disabling Spotlight shortcut (Cmd+Space) for kasunt user on work machine..."

    # Disable Spotlight keyboard shortcut (Cmd+Space) to allow Raycast usage
    $DRY_RUN_CMD /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "
      <dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
          <key>type</key><string>standard</string>
          <key>parameters</key>
          <array>
            <integer>32</integer>
            <integer>49</integer>
            <integer>1048576</integer>
          </array>
        </dict>
      </dict>
    "
  '';

  # Solo.io-specific Claude Code skills live in the private
  # day0ops/solo-claude-skills repo, not this public dotfiles repo. Clone it
  # to $HOME/.solo-claude-skills once by hand; every skill directory it
  # contains then gets linked into ~/.claude-work/skills on each rebuild,
  # matching the CLAUDE_CONFIG_DIR=~/.claude-work convention for work-context
  # Claude Code sessions (see docs/PROJECT.md). No-ops if the clone is absent,
  # so machines without access to the private repo aren't broken.
  home.activation.handleSoloClaudeSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SOLO_SKILLS_PATH="$HOME/.solo-claude-skills"

    if [ -d "$SOLO_SKILLS_PATH/.git" ]; then
      echo "Linking Solo-specific Claude skills from $SOLO_SKILLS_PATH..."
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.claude-work/skills"
      SOLO_SKILL_DIRS=$(cd "$SOLO_SKILLS_PATH" && ${pkgs.findutils}/bin/find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
      if ! $DRY_RUN_CMD ${pkgs.stow}/bin/stow \
        --dir="$SOLO_SKILLS_PATH" --target="$HOME/.claude-work/skills" \
        --restow --no-folding --adopt \
        $SOLO_SKILL_DIRS; then
        echo "Warning: Failed to link solo-claude-skills"
        exit 1
      fi
    else
      echo "solo-claude-skills not cloned at $SOLO_SKILLS_PATH, skipping"
    fi
  '';
}
