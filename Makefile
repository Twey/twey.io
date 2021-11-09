build:
	cabal run . -- build

rebuild:
	cabal run . -- rebuild

push: build
	rsync -v _site/* twey.co.uk:www.io/

.PHONY: build rebuild push
