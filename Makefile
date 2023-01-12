fonts:
	make -C EB-Garamond WEB=../assets/fonts/eb-garamond webfonts

build: fonts
	cabal run . -- build

rebuild: fonts
	cabal run . -- rebuild

push: build
	rsync -av _site/ twey.co.uk:www.io/

.PHONY: build rebuild push
