{
  inputs = {
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskell-nix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, haskell-nix, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux"] (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ haskell-nix.overlay ];
        inherit (haskell-nix) config;
      };
      flake = (pkgs.haskell-nix.hix.project { src = ./.; }).flake {};
    in {
      legacyPackages = pkgs;
      packages.default = flake.packages."site2021:exe:site";
      devShells.default = flake.devShells.default.overrideAttrs {
        buildInputs = with pkgs; [
          asciidoctor-with-extensions
          rubyPackages.tilt
          (python3.withPackages (ps: [ps.fontforge]))
          ttfautohint-nox
          imagemagick
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
