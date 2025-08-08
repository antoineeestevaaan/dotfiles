export const CLIPBOARD = $nu.temp-path | path join "system-cb.txt"

export def clip []: [ any -> nothing ] {
    tee { print } | to nuon | save --force $CLIPBOARD
}

export def paste [--raw (-r)]: [ nothing -> any ] {
    try {
        if $raw {
            open $CLIPBOARD
        } else {
            open $CLIPBOARD | from nuon
        }
    } catch {
        null
    }
}
