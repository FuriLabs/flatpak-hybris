all: build

build:
	make -C src/ all

install:
	make -C src/ install

.PHONY: build install
