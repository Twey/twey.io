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
	# these are just prototypes for now, but I like them better than
	# no initial
	ln -s '../EBGaramond-Lettrines.sfdir/W full.svg' \
	  fonts/EB-Garamond/SFD/EBGaramond-Initials.sfdir/W.svg || :
	ln -s '../EBGaramond-Lettrines.sfdir/W F1.svg' \
	  fonts/EB-Garamond/SFD/EBGaramond-InitialsF1.sfdir/W.svg || :
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
