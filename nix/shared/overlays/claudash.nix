# Packages claudash (day0ops/claudash, a Claude Code status line) from its
# GitHub source, since it isn't published to nixpkgs or crates.io.
{inputs}: final: prev: let
  cargoToml = builtins.fromTOML (builtins.readFile "${inputs.claudash}/Cargo.toml");
in {
  claudash = final.rustPlatform.buildRustPackage {
    pname = cargoToml.package.name;
    version = cargoToml.package.version;
    src = inputs.claudash;
    cargoLock.lockFile = "${inputs.claudash}/Cargo.lock";

    meta = with final.lib; {
      description = cargoToml.package.description;
      homepage = cargoToml.package.repository;
      license = licenses.mit;
      mainProgram = "claudash";
    };
  };
}
