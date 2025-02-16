#!/bin/bash

BWRAP="/usr/bin/bwrap.real"

# Detect if script is called by completion function
if [[ "$COMP_LINE" != "" || "$1" == "complete" ]]; then
        exec "$BWRAP" "$@"
fi

# Handle --args case
if [[ "$1" == "--args" ]]; then
    shift 1
    fd=$1
    shift 1
    readarray -d '' args < /dev/fd/$fd
else
    args=("$@")
fi

# this seems to be a common issue on arm64. when unsharing pid and user in conjunction it throws an error message.
# preferrably we should figure out exactly why this happens in the first place but this will do for now as a temporary solution
# asahi has a similar approach to bwrap: https://pagure.io/fedora-asahi/mesa-asahi-flatpak/blob/24.08/f/bwrapwrapper
for i in "${!args[@]}"; do
    case "${args[i]}" in
        --unshare-net|--unshare-user|--disable-userns|--unshare-pid|--unshare-all)
            unset 'args[i]'
            ;;
    esac
done

args=("${args[@]}")
exec "$BWRAP" "${args[@]}" "$@"
