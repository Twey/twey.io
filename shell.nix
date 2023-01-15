with import <nixpkgs> { };
let
  ghc = haskellPackages.ghc.withPackages (p: [p.cabal-install p.hakyll]);
  asciidoctor = callPackage nix/asciidoctor { };
in
mkShell {
  buildInputs = [
    gnumake ghc haskellPackages.hakyll asciidoctor graphviz-nox
    (python3.withPackages (ps: [ps.fontforge])) ttfautohint-nox imagemagick
    bashInteractive
  ];
}
