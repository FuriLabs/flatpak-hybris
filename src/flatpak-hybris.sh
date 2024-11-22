#!/bin/bash

FLATPAK="/usr/bin/flatpak.real"

error() {
	echo "E: $@" >&2
	exit 1
}

# Detect if script is called by completion function
if [[ "$COMP_LINE" != "" || "$1" == "complete" ]]; then
	exec "$FLATPAK" "$@"
fi

# Get triplet
case "$(dpkg --print-architecture)" in
	"amd64")
		TRIPLET="x86_64-linux-gnu"
		;;
	"i386")
		TRIPLET="i386-linux-gnu"
		;;
	"arm64")
		TRIPLET="aarch64-linux-gnu"
		;;
	"armhf")
		TRIPLET="arm-linux-gnueabihf"
		;;
	*)
		error "Unable to obtain triplet"
		;;
esac

[ -e /run/user/${UID}/wayland-0 ] && \
	EXTRA_FLAGS="${EXTRA_FLAGS} --filesystem=/run/user/${UID}/wayland-0:ro"
[ -e /run/dbus/system_bus_socket ] && \
	EXTRA_FLAGS="${EXTRA_FLAGS} --filesystem=/run/dbus/system_bus_socket:ro"

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

	args=("$@")
	# @@u @@ are supposed to represent that everything after these arguments are URIs supposed to be passed in to file forwarding
	# but there are cases that these are specified but the app is not giving any paths. in these cases app will just refuse to start
	# handle the case where these two args are given but app is not requesting anything
	if [ "${args[-2]}" = "@@u" ] && [ "${args[-1]}" = "@@" ]; then
		unset 'args[-1]'
		unset 'args[-1]'
		set -- "${args[@]}"
	fi

	if ! [[ "$(flatpak info $(echo $@ | rev | cut -d ' ' -f 1 | rev) | grep -E 'org.kde.Sdk' | cut -d '/' -f 3)" =~ 6.* ]]; then
		# Ensure we use the hybris extension
		export FLATPAK_GL_DRIVERS="hybris"
	fi

	exec ${FLATPAK} \
		--filesystem=/system:ro \
		--filesystem=/vendor:ro \
		--filesystem=/odm:ro \
		--filesystem=/apex:ro \
		--filesystem=/android:ro \
		--filesystem=/mnt:ro \
		--filesystem=/data:ro \
		--device=all \
		--env=LD_PRELOAD=libtls-padding.so:libgtk6216workaround.so \
		--env=HYBRIS_EGLPLATFORM_DIR=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris \
		--env=HYBRIS_LINKER_DIR=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris/linker \
		--env=HYBRIS_LD_LIBRARY_PATH=${HYBRIS_LD_LIBRARY_PATH} \
		--env=LD_LIBRARY_PATH=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris-egl:/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR} \
		${EXTRA_FLAGS} \
		$@
else
	# Pass-through to the real executable
	exec ${FLATPAK} $@
fi
