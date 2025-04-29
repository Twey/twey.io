{ lib, bundlerApp, makeWrapper, cmake, pkg-config, bison, flex, glib, cairo, pango, gdk-pixbuf, libxml2,
  # Optional dependencies, can be null
  epubcheck,
  bundlerUpdateScript,
  graphviz-nox,
  pikchr,
  nodePackages,
}:

let
  binPath = lib.makeBinPath [ epubcheck graphviz-nox pikchr nodePackages.mermaid-cli ];
  app = bundlerApp {
    pname = "asciidoctor";
    gemdir = ./.;

    exes = [
      "asciidoctor"
      "asciidoctor-pdf"
      "asciidoctor-epub3"
      "asciidoctor-revealjs"
    ];

    nativeBuildInputs = [ makeWrapper cmake pkg-config ];

    buildInputs = [ bison flex glib cairo pango gdk-pixbuf libxml2 ];

    postBuild = ''
      wrapProgram "$out/bin/asciidoctor-epub3" \
        ${lib.optionalString (epubcheck != null) "--set EPUBCHECK ${epubcheck}/bin/epubcheck"} \
        --set PATH ${binPath}
      wrapProgram "$out/bin/asciidoctor" \
        --set PATH ${binPath}
    '';

    passthru = {
      updateScript = bundlerUpdateScript "asciidoctor";
    };

    meta = with lib; {
      description = "A faster Asciidoc processor written in Ruby";
      homepage = "https://asciidoctor.org/";
      license = licenses.mit;
      maintainers = with maintainers; [ gpyh nicknovitski ];
      platforms = platforms.unix;
    };
  };
in
  app
