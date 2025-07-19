#!/usr/bin/env bash

RED="\e[31m"
LIGHTRED="\e[91m"
MAGENTA="\e[35m"
LIGHT_MAGENTA="\e[95m"
RESET="\e[0m"

pattern="${1:-*}"

for f in $(find .                  \
    -type f                        \
    -path "*$pattern*"             \
    -not -path './.git/*'          \
    -not -path './_scripts/*'      \
    -not -path '*.swp'             \
    -not -path './@*'              \
); do
    f="$(echo $f | cut -c 3-)"

    src="$(realpath $f)"
    dest="$HOME/$f"

    echo -e "$MAGENTA$f$RESET -> $LIGHT_MAGENTA~/$f$RESET"
    mkdir -p "$(dirname $dest)"
    ln --symbolic --force $src $dest
done

for f in $(find .     \
    -type f           \
    -path './@*'      \
); do
    f="$(echo $f | cut -c 3-)"

    src="$(realpath $f)"
    dest="$(echo $f | sed 's/@/\//')"

    echo -e "$RED$f$RESET -> $LIGHT_RED$dest$RESET"
    sudo mkdir -p "$(dirname $dest)"
    sudo ln --symbolic --force $src $dest
done
