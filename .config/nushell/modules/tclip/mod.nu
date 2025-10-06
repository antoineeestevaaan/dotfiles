export const CLIPBOARD = $nu.temp-path | path join "system-cb.txt"

export def clip []: [ any -> nothing ] {
    tee { print }
        | match ($in | describe --detailed).type {
            "string" => { $in },
            _        => { to nuon },
        }
        | save --force $CLIPBOARD
}

export def paste [--raw (-r)]: [ nothing -> any ] {
    try {
        open $CLIPBOARD | if $raw { $in } else { from nuon }
    } catch {
        try { open $CLIPBOARD }
    }
}
