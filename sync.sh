RED="\e[31m"
MAGENTA="\e[35m"
LIGHT_MAGENTA="\e[95m"
RESET="\e[0m"

for f in $(find . -type f -not -path './.git/*' -not -path './sync.sh' -not -path './gh.sh' -not -path './nu.sh' -not -path './scripts/*'); do
    f="$(echo $f | cut -c 3-)"

    src="$(realpath $f)"
    dest="$HOME/$f"

    echo "$MAGENTA$f$RESET -> $LIGHT_MAGENTA~/$f$RESET"
    ln --symbolic --force $src $dest
done
