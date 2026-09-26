# Claude Code skills sourced from external git repos, cloned/updated fresh on
# each rebuild instead of pinned via git submodule. Each repo's skill
# directories are symlinked (via Stow, so they merge cleanly with whatever
# else is already stowed into the same target) into both ~/.claude/skills
# and ~/.claude-work/skills.
#
# Usage:
#   externalSkills = [
#     { url = "https://github.com/day0ops/claude-skills.git"; }
#     { url = "https://github.com/emilkowalski/skills.git"; subdir = "skills"; }
#     { url = "https://github.com/your-org/private-skills.git"; autoClone = false; }
#   ];
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cacheRoot = "$HOME/.cache/claude-external-skills";

  targetDirs = {
    personal = "$HOME/.claude/skills";
    work = "$HOME/.claude-work/skills";
  };

  mkEntryScript =
    entry:
    let
      urlParts = lib.reverseList (lib.splitString "/" (lib.removeSuffix ".git" entry.url));
      name = "${lib.elemAt urlParts 1}-${lib.elemAt urlParts 0}";
      cacheDir = "${cacheRoot}/${name}";
      skillsDir = if entry.subdir == "." then cacheDir else "${cacheDir}/${entry.subdir}";
      targets = map (t: targetDirs.${t}) entry.targets;
    in
    ''
      CLONE_OK=1
      if [ -d "${cacheDir}/.git" ]; then
        echo "Updating ${name}..."
        $DRY_RUN_CMD ${pkgs.git}/bin/git -C "${cacheDir}" pull --ff-only \
          || echo "Warning: failed to update ${name}, using cached copy"
      elif [ "${lib.boolToString entry.autoClone}" = "true" ]; then
        echo "Cloning ${name}..."
        if ! $DRY_RUN_CMD ${pkgs.git}/bin/git clone "${entry.url}" "${cacheDir}"; then
          echo "Warning: failed to clone ${name}, skipping"
          CLONE_OK=0
        fi
      else
        echo "${name} not cloned at ${cacheDir}, skipping (clone it manually)"
        CLONE_OK=0
      fi

      if [ "$CLONE_OK" = "1" ] && [ -d "${skillsDir}" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${
          lib.concatStringsSep " " (map (t: "\"${t}\"") targets)
        }
        SKILL_DIRS=$(cd "${skillsDir}" && ${pkgs.findutils}/bin/find . -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
        ${lib.concatMapStringsSep "\n" (target: ''
          if ! $DRY_RUN_CMD ${pkgs.stow}/bin/stow \
            --dir="${skillsDir}" --target="${target}" \
            --restow --no-folding --adopt \
            $SKILL_DIRS; then
            echo "Warning: failed to link ${name} into ${target}"
          fi
        '') targets}
      fi
    '';
in
{
  options.externalSkills = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "Git remote URL to clone.";
          };
          subdir = lib.mkOption {
            type = lib.types.str;
            default = ".";
            description = "Path within the repo containing one directory per skill.";
          };
          autoClone = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Clone automatically if missing. Only safe for public repos
              reachable without interactive auth; private repos should set
              this to false and be cloned by hand once (still auto-updated
              via `git pull` on every rebuild after that).
            '';
          };
          targets = lib.mkOption {
            type = lib.types.listOf (
              lib.types.enum [
                "personal"
                "work"
              ]
            );
            default = [
              "personal"
              "work"
            ];
            description = ''
              Which Claude Code profiles to link into: "personal"
              (~/.claude/skills) and/or "work" (~/.claude-work/skills).
            '';
          };
        };
      }
    );
    default = [ ];
  };

  config.home.activation.handleExternalSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStringsSep "\n" mkEntryScript config.externalSkills
  );
}
