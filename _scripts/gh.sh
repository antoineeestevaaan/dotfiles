#!/usr/bin/env bash

BIN="$HOME/opt/bin"
TMP="/tmp"
MAN="$HOME/.local/share/man/man1"
DOWNLOADS="$HOME/downloads"

VERSION="2.74.2"
ARCH="linux_$1"

ARCHIVE_WITHOUT_EXT="gh_${VERSION}_${ARCH}"
ARCHIVE="${ARCHIVE_WITHOUT_EXT}.tar.gz"
URL="https://github.com/cli/cli"

zipped="$DOWNLOADS/$ARCHIVE"
remote="$URL/releases/download/v$VERSION/$ARCHIVE"

mkdir -p "$BIN"
mkdir -p "$DOWNLOADS"
mkdir -p "$TMP"
mkdir -p "$MAN"

echo "fetching $remote"
curl -#fLo "$zipped" "$remote" || exit 1

tar xvf "$zipped" --directory "$TMP"
cp "$TMP/$ARCHIVE_WITHOUT_EXT/bin/gh" "$BIN/gh"
for f in $(find "$TMP/$ARCHIVE_WITHOUT_EXT/share/man/man1" -type f); do
    cp --verbose "$f" "$MAN"
done
