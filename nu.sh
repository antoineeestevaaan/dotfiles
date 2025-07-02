DOWNLOADS="$HOME/downloads"
TMP="/tmp"
VERSION="0.105.1"
ARCH="armv7-unknown-linux-gnueabihf"

mkdir -p "$DOWNLOADS"

NAME="nu-$VERSION-$ARCH"
ARCHIVE="$NAME.tar.gz"
URL="https://github.com/nushell/nushell"

curl -fLo "$DOWNLOADS/$ARCHIVE" "$URL/releases/download/$VERSION/$ARCHIVE"
tar xvf "$DOWNLOADS/$ARCHIVE" --directory "$TMP"
cp "$TMP/$NAME/nu" ~/opt/bin/nu
