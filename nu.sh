BIN="$HOME/opt/bin"
VERSION="0.105.1"
ARCH="arm-unknown-linux-gnueabihf"

mkdir -p "$BIN"

NAME="nu-$VERSION-$ARCH"
URL="https://raw.githubusercontent.com/amtoine/nushell-builds"

curl -fLo "$BIN/nu" "$URL/refs/heads/main/$NAME"
chmod +x "$BIN/nu"
