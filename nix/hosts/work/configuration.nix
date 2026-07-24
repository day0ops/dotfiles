{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  stateVersions = {
    darwin = 6;
  };
in {
  # Darwin state version 6 - defines system configuration schema/compatibility
  # See flake.nix for actual package channel selection (stable vs unstable)
  # Reference: https://github.com/LnL7/nix-darwin/blob/master/modules/system/default.nix
  system.stateVersion = stateVersions.darwin;

  networking.hostName = "Solo-System-KTalwatta";

  nixpkgs.hostPlatform = "aarch64-darwin";

  time.timeZone = "Pacific/Auckland";

  host.users = {
    kasunt = {
      isAdmin = true;
      isPrimary = true;
      shell = "zsh";
      homeConfig = ./users/kasunt.nix;
    };
  };

  host.extraPackages = with pkgs; [
  ];

  host.extraBrews = [
  ];

  host.extraCasks = [
    "google-chrome"
    "raycast"
  ];

  host.extraMasApps = {
  };
}
