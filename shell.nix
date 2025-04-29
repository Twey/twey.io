(builtins.getFlake ("git+file://" + toString ./.)).devShells.${builtins.currentSystem}.default
mkShell {
  buildInputs = [
    gnumake ghc haskellPackages.hakyll asciidoctor graphviz-nox
    (python3.withPackages (ps: [ps.fontforge])) ttfautohint-nox imagemagick
    pikchr nodePackages.mermaid-cli
    bashInteractive
  ];
}
