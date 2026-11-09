# Claude Code skills sourced from external git repos, cloned/updated fresh on
# each rebuild instead of pinned via git submodule. Each repo's skill
# directories are symlinked (via Stow, so they merge cleanly with whatever
# else is already stowed into the same target) into both ~/.claude/skills
# and ~/.claude-work/skills.
#
# Usage:
#   externalSkills = {
#     claude-skills.url = "https://github.com/day0ops/claude-skills.git";
#     emilkowalski-skills = {
#       url = "https://github.com/emilkowalski/skills.git";
#       subdir = "skills";
#     };
#     private-skills = {
#       url = "https://github.com/your-org/private-skills.git";
#       autoClone = false;
#     };
#   };
#
# Keyed by name so a host-specific config can override just one field
# (e.g. `externalSkills.claude-skills.localPath = ...;`) while inheriting
# the rest from a shared entry defined elsewhere.
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
      skillsRoot = if entry.localPath != null then entry.localPath else cacheDir;
      skillsDir = if entry.subdir == "." then skillsRoot else "${skillsRoot}/${entry.subdir}";
      targets = map (t: targetDirs.${t}) entry.targets;

      linkSkills = ''
        SKILL_DIRS=$(cd "${skillsDir}" && ${pkgs.findutils}/bin/find . -mindepth 1 -maxdepth 1 -type d -exec ${pkgs.coreutils}/bin/test -f "{}/SKILL.md" \; -printf '%f\n')
        ${lib.concatMapStringsSep "\n" (target: ''
          for skill in $SKILL_DIRS; do
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${target}/$skill"
            if ! $DRY_RUN_CMD ${pkgs.stow}/bin/stow \
              --dir="${skillsDir}" --target="${target}/$skill" \
              --restow --no-folding --adopt \
              "$skill"; then
              echo "Warning: failed to link ${name}/$skill into ${target}"
            fi
          done
        '') targets}
      '';
    in
    if entry.localPath != null then
      ''
        echo "${name}: using local checkout at ${entry.localPath}, skipping clone/pull"
        if [ -d "${skillsDir}" ]; then
          ${linkSkills}
        else
          echo "Warning: ${name} local path ${skillsDir} not found, skipping"
        fi
      ''
    else
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
          ${linkSkills}
        fi
      '';
in
{
  options.externalSkills = lib.mkOption {
    type = lib.types.attrsOf (
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
          localPath = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Use an existing local checkout instead of a managed clone
              under ~/.cache/claude-external-skills. Skips the clone/pull
              step entirely and links skills straight from this path, so
              edits in the checkout show up without a push/pull
              round-trip. Typically set by a host-specific config to
              override just this field on an entry whose `url` etc. is
              defined elsewhere.
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
    default = { };
  };

  config.home.activation.handleExternalSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStringsSep "\n" mkEntryScript (lib.attrValues config.externalSkills)
  );
}
