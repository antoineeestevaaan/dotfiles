#!/usr/bin/env bash

DEFAULT_BIN_DIR="$HOME/opt/bin"

usage() {
    echo "Usage: $0 <Nushell version> [--bin <path> = $DEFAULT_BIN_DIR]"
    exit 1
}

# argument parsing: start
if [[ $# -lt 1 ]]; then
    usage
fi

bin_dir="$DEFAULT_BIN_DIR"
version="$1"
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bin)
            shift
            if [[ -z "$1" ]]; then
                echo "Error: --bin requires a path argument"
                usage
            fi
	    bin_dir=$(realpath "$1")
        ;;
        *)
            echo "Error: unknown argument $1"
            usage
        ;;
    esac
    shift
done
# argument parsing: end

arch=$(uname -m)

case "$arch" in
    aarch64) url="https://github.com/nushell/nushell/releases/download/$version/nu-$version-aarch64-unknown-linux-musl.tar.gz"       ;;
    *)       url="https://raw.githubusercontent.com/amtoine/nushell-builds/refs/heads/main/nu-$version-arm-unknown-linux-gnueabihf" ;;
esac

mkdir -p "$bin_dir"

echo "Downloading $url..."
curl -fLo "$bin_dir/nu" "$url" || exit "$?"
chmod +x "$bin_dir/nu"
