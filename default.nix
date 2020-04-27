{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { config = { allowBroken = true; }; }
, lsp-test ? sources.lsp-test
, ghcide ? sources.ghcide
, ghc ? "ghc883"
}:

let
  # Haskell overrides to build latest ghcide:
  overrides = self: super: with pkgs.haskell.lib; {
    hie-bios = dontCheck super.hie-bios;
    haskell-lsp = super.haskell-lsp_0_21_0_0;
    haskell-lsp-types = super.haskell-lsp-types_0_21_0_0;
    lsp-test = dontCheck (super.callCabal2nix "lsp-test" lsp-test {});

    ghcide = justStaticExecutables (
      dontCheck (super.callCabal2nix "ghcide" ghcide {}));
  };

  # Perform the overrides:
  haskell = pkgs.haskell.packages."${ghc}".override (orig: {
    overrides = pkgs.lib.composeExtensions
                 (orig.overrides or (_: _: {}))
                 overrides;
  });

# The package!
in haskell.ghcide
