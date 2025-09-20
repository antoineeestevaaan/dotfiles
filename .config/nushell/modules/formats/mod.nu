export def "into qr" [--square-font]: [ string -> string ] {
    let code = qrencode --type ASCII --margin 0
        | lines
        | str replace --all '##' '#'
        | str replace --all '  ' ' '

    let color = if ($code | length) > (term size).rows {
        "yellow"
    } else {
        "default"
    } | $"($in)_reverse"

    let expansion = if $square_font { " " } else { "  " }

    $code
        | each {
            str replace --all " " $expansion
            | str replace --all "#" $"(ansi $color)($expansion)(ansi reset)"
        }
        | str join "\n"
}

