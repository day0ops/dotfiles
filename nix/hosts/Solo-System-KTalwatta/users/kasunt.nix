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

  packageTools.npmPackages = [
    {
      package = "@googleworkspace/cli";
      bin = "gws";
    }
  ];
  packageTools.uvTools = [ ];

  packageTools.llmAgents = [
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
}
