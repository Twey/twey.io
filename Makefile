HERE = $(shell pwd)

build: assets
	cabal run . -- build

rebuild: assets
	cabal run . -- rebuild

watch: assets
	cabal run . -- watch

push: build
	scp -r _site/* twey.co.uk:www.io/

fonts:
	make -C fonts/EB-Garamond-Initials WEB=../../assets/fonts/eb-garamond webfonts
	make -C fonts/EB-Garamond WEB=../../assets/fonts/eb-garamond webfonts

logo:
	convert \
	  -pointsize 144 \
	  -font fonts/EuphoriaScript/EuphoriaScript-Regular.otf \
	  -rotate 180 \
	  -trim \
	  label:'&' \
	  assets/logo.svg

assets: logo fonts

.PHONY: build rebuild watch push fonts logo assets
