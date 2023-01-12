with import <nixpkgs> { };
let
  ghc = haskellPackages.ghc.withPackages (p: [p.cabal-install p.hakyll]);
  asciidoctor = callPackage nix/asciidoctor { };
in
mkShell {
  buildInputs = [
    gnumake ghc haskellPackages.hakyll asciidoctor
    (python3.withPackages (ps: [ps.fontforge])) ttfautohint-nox
    bashInteractive
  ];
}
