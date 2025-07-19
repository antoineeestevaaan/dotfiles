#!/usr/bin/env bash

DOWNLOADS="$HOME/downloads"

VERSION="0.11.2"
ARCH="linux-x86_64"

ARCHIVE_WITHOUT_EXT="nvim-$ARCH"
ARCHIVE="$ARCHIVE_WITHOUT_EXT.tar.gz"

mkdir -p "$DOWNLOADS"

gh -R neovim/neovim release download v0.11.2 --pattern "$ARCHIVE" --skip-existing --dir "$DOWNLOADS"
tar xvf "$DOWNLOADS/$ARCHIVE" --directory "$HOME/opt/"
ln -sf "$HOME/opt/$ARCHIVE_WITHOUT_EXT/bin/nvim" "$HOME/opt/bin/nvim"
