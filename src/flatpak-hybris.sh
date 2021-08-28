#!/bin/bash

FLATPAK="/usr/bin/flatpak.real"

# Get triplet
TRIPLET=$(dpkg-architecture -qDEB_HOST_MULTIARCH 2> /dev/null)

# Get libdir
if [ $(getconf LONG_BIT) == 32 ]; then
	LIBDIR="lib"
else
	LIBDIR="lib64"
fi

[ -z "${HYBRIS_LD_LIBRARY_PATH}" ] && \
	HYBRIS_LD_LIBRARY_PATH="/system/${LIBDIR}:/vendor/${LIBDIR}:/odm/${LIBDIR}"

if [[ "$@" =~ 'run ' ]]; then
	# Flatpak should be ran, ensure we attach our own arguments

	# Ensure we use the hybris extension
	export FLATPAK_GL_DRIVERS="hybris"

	exec ${FLATPAK} \
		--filesystem=/system:ro \
		--filesystem=/vendor:ro \
		--filesystem=/odm:ro \
		--filesystem=/apex:ro \
		--filesystem=/android:ro \
		--device=all \
		--env=HYBRIS_EGLPLATFORM_DIR=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris \
		--env=HYBRIS_LINKER_DIR=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris/linker \
		--env=HYBRIS_LD_LIBRARY_PATH=${HYBRIS_LD_LIBRARY_PATH} \
		--env=LD_LIBRARY_PATH=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris-egl:/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR} \
		$@
else
	# Pass-through to the real executable
	exec ${FLATPAK} $@
fi
