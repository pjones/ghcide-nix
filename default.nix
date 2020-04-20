{ # Pinned nixpkgs commit:
  commit ? "516e3c1440e61abf38e5af2f60271ef385189578"
}:

let
  url = "https://github.com/nixos/nixpkgs/archive/${commit}.tar.gz";
  name = "nixpkgs-${commit}";

  pkgs = import (fetchTarball {inherit url name;}) {
    config = { allowBroken = true; };
  };

  ghcideAttrs = pkgs.lib.importJSON ./ghcide.json;
  lsptestAttrs = pkgs.lib.importJSON ./lsp-test.json;

  # Haskell overrides to build latest ghcide:
  overrides = self: super: with pkgs.haskell.lib; {
    hie-bios = dontCheck super.hie-bios;
    haskell-lsp = super.haskell-lsp_0_21_0_0;
    haskell-lsp-types = super.haskell-lsp-types_0_21_0_0;

    lsp-test = dontCheck (super.callCabal2nix "lsp-test"
      (fetchGit { inherit (lsptestAttrs) url rev;}) {});

    ghcide = justStaticExecutables (
      dontCheck (super.callCabal2nix "ghcide"
        (fetchGit {inherit (ghcideAttrs) url rev;}) {}));
  };

  # Perform the overrides:
  haskell = pkgs.haskellPackages.override (orig: {
    overrides = pkgs.lib.composeExtensions
                 (orig.overrides or (_: _: {}))
                 overrides;
  });

# The package!
in haskell.ghcide
