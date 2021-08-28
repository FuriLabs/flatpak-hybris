DESTDIR ?= /

all: flatpak-hybris.sh

install: flatpak-hybris.sh
	install -d $(DESTDIR)/usr/lib/flatpak-hybris/
	install -m 755 flatpak-hybris.sh $(DESTDIR)/usr/lib/flatpak-hybris/

.PHONY: all install
