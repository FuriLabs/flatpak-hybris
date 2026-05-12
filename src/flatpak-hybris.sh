#!/bin/bash

FLATPAK="/usr/bin/flatpak.real"

error() {
	echo "E: $*" >&2
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

EXTRA_FLAGS=()
[ -e /run/user/${UID}/wayland-0 ] && \
	EXTRA_FLAGS+=("--filesystem=/run/user/${UID}/wayland-0:ro")
[ -e /run/dbus/system_bus_socket ] && \
	EXTRA_FLAGS+=("--filesystem=/run/dbus/system_bus_socket:ro")

# Get libdir
if [ "$(getconf LONG_BIT)" == 32 ]; then
	LIBDIR="lib"
else
	LIBDIR="lib64"
fi

[ -z "${HYBRIS_LD_LIBRARY_PATH}" ] && \
	HYBRIS_LD_LIBRARY_PATH="/system/${LIBDIR}:/vendor/${LIBDIR}:/odm/${LIBDIR}"

subcommand=""
app_id=""
seen_subcommand=0

for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
        continue
    fi
    if [[ $seen_subcommand -eq 0 ]]; then
        subcommand="$arg"
        seen_subcommand=1
        continue
    fi
    app_id="$arg"
    break
done

if [[ "$subcommand" != "run" ]]; then
    exec "$FLATPAK" "$@"
fi

if [[ -n "$app_id" ]]; then
	sdk=$("$FLATPAK" info "$app_id" 2>/dev/null | awk -F': *' '/^[[:space:]]*Sdk:/ {print $2}')
	SDK_SKIP_PATTERNS=(
		"org.kde.Sdk/*/6.*"
	)

	override_gl_driver=1
	for pattern in "${SDK_SKIP_PATTERNS[@]}"; do
		# Glob matching for SDK
		# shellcheck disable=SC2053
		if [[ "$sdk" == $pattern ]]; then
			override_gl_driver=0
			break
		fi
	done

	if [[ $override_gl_driver -eq 1 ]]; then
		export FLATPAK_GL_DRIVERS="hybris"
	fi
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
	--env=LD_PRELOAD=libtls-padding.so:libglesshadercache.so \
	--env=HYBRIS_EGLPLATFORM_DIR=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris \
	--env=HYBRIS_VULKANPLATFORM_DIR=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris \
	--env=HYBRIS_LINKER_DIR=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris/linker \
	--env=HYBRIS_LD_LIBRARY_PATH=${HYBRIS_LD_LIBRARY_PATH} \
	--env=LD_LIBRARY_PATH=/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR}/libhybris-egl:/usr/lib/${TRIPLET}/GL/hybris/${LIBDIR} \
	"${EXTRA_FLAGS[@]}" \
	"$@"
