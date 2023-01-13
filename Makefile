build: fonts
	cabal run . -- build

rebuild: fonts
	cabal run . -- rebuild

watch: fonts
	cabal run . -- watch

push: build
	rsync -av _site/ twey.co.uk:www.io/

fonts:
	make -C EB-Garamond WEB=../assets/fonts/eb-garamond webfonts

.PHONY: build rebuild watch push fonts
