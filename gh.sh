BIN="$HOME/opt/bin"
TMP="/tmp"
MAN="/usr/local/share/man/man1"
DOWNLOADS="$HOME/downloads"

VERSION="2.74.2"
ARCH="linux_armv6"

ARCHIVE_WITHOUT_EXT="gh_${VERSION}_${ARCH}"
ARCHIVE="${ARCHIVE_WITHOUT_EXT}.tar.gz"
URL="https://github.com/cli/cli"

mkdir -p "$BIN"
mkdir -p "$DOWNLOADS"
mkdir -p "$TMP"
sudo mkdir -p "$MAN"

curl -fLo "$DOWNLOADS/$ARCHIVE" "$URL/releases/download/v$VERSION/$ARCHIVE"
tar xvf "$DOWNLOADS/$ARCHIVE" --directory "$TMP"
cp "$TMP/$ARCHIVE_WITHOUT_EXT/bin/gh" "$BIN/gh"
for f in $(find "$TMP/$ARCHIVE_WITHOUT_EXT/share/man/man1" -type f); do
    sudo cp --verbose "$f" "$MAN"
done
