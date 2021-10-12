with import <nixpkgs> { };
let
  ghc = haskellPackages.ghc.withPackages (p: [p.cabal-install p.hakyll]);
  asciidoctor = callPackage nix/asciidoctor { };
in
mkShell {
  buildInputs = [ ghc haskellPackages.hakyll asciidoctor bashInteractive ];
}
