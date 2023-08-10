HERE = $(shell pwd)

build: assets
	cabal run . -- build

rebuild: assets
	cabal run . -- rebuild

watch: assets
	cabal run . -- watch

clean-site:
	cabal run . -- clean

clean-fonts:
	make -C fonts/EB-Garamond clean
	make -C fonts/EB-Garamond-Initials clean

clean-logo:
	rm assets/logo.svg

clean-assets: clean-fonts clean-logo

clean: clean-site clean-assets

push: build
	scp -r _site/* twey.co.uk:www.io/

fonts:
	make -C fonts/EB-Garamond WEB=../../assets/fonts/eb-garamond webfonts
	make -C fonts/EB-Garamond-Initials WEB=../../assets/fonts/eb-garamond webfonts

logo:
	convert \
	  -pointsize 144 \
	  -font fonts/EuphoriaScript/EuphoriaScript-Regular.otf \
	  -rotate 180 \
	  -trim \
	  label:'&' \
	  assets/logo.svg

assets: logo fonts

.PHONY: build rebuild watch clean-site clean-fonts clean-logo clean-assets clean push fonts logo assets
