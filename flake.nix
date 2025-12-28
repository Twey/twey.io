{
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, haskellNix, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux"] (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ haskellNix.overlay ];
        inherit (haskellNix) config;
      };
      theFlake = (pkgs.haskell-nix.hix.project { src = ./.; }).flake;
      flake = theFlake {};
    in {
      legacyPackages = pkgs;
      theFlake = theFlake;
      packages.default = flake.packages."site2021:exe:site";
      devShells.default = flake.devShells.default.overrideAttrs {
        buildInputs = with pkgs; [
          (callPackage nix/asciidoctor {})
          (python3.withPackages (ps: [ps.fontforge]))
          ttfautohint-nox
          imagemagick
          pkgs.haskell-nix.haskellPackages.haskell-language-server
        ];
      };
    });

  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    # This sets the flake to use the IOG nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}
