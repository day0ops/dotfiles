{inputs, ...}: {
  mkDarwin = {configPath, ...}:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules =
        [
          {nixpkgs.overlays = [(import ../shared/overlays {inherit inputs;})];}
          inputs.home-manager-unstable.darwinModules.home-manager # unstable pkgs
          # Bootstrap and manage Homebrew itself
          inputs.nix-homebrew.darwinModules.nix-homebrew
          ./users.nix
          ../shared/system/darwin.nix
          ../shared/system/common.nix
          configPath
        ]
        ++ (
          if builtins.pathExists (builtins.dirOf configPath + "/home.nix")
          then [(builtins.dirOf configPath + "/home.nix")]
          else []
        );
    };
}
