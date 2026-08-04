# Combines all overlays into a single overlay function
{inputs}: final: prev: { }
// (import ./claudash.nix {inherit inputs;} final prev)
# Add other overlays here as needed by merging their results
# // (import ./other-overlay.nix {inherit inputs;} final prev)
