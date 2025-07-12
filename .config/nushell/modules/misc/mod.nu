# wrapper around system's `make` command
#
#     use `help make` to show this help
#     use `make --help` to get the help of the wrapped `make`
@example "simple usage"         { make }
@example "call  rule"           { make foo_rule bar_rule }
@example "regular variables"    { make FOO=my_foo foo_rule }
@example "structured variables" { make -V { FOO: my_foo } foo_rule }
export def --wrapped make [
    --make-variables (-V): record,
    ...args: string,
] {
    let make_variables = $make_variables | default {} | items { |k, v|
        $"($k)=($v)"
    }

    ^make ...$make_variables ...$args
}

def "ls-console-variants" []: [
    nothing -> table<value: string, description: string>
] {
    print --no-newline $"(ansi default_dimmed)getting `.console-setup` variants from `/root/`...(ansi reset)"
    sudo find /root -maxdepth 1 -name '*.console-setup*'
        | lines
        | wrap filename
        | insert name { $in.filename | path parse | get extension }
        | insert content {
            sudo cat $in.filename
                | lines
                | parse "{k}={v}"
                | update v { str trim --left --right --char '"' }
                | transpose --header-row
                | into record
        }
        | insert description {
            $in.content | select CHARMAP FONTFACE FONTSIZE | to nuon
        }
        | rename --column { name: value }
        | select value description
}

# update the font of TTYs using `setupcon` and `console-setup`
#
# > [!note] this uses `.console*` files stored in `/root/` so that
# > running the script with `sudo` uses the proper files.
export def "update-tty-font" [
    variant: string@ls-console-variants = "",
    --all-ttys (-a),
] {
    sudo setupcon ...[
        --force
        ...(if not $all_ttys { [ --current-tty ] } else { [] })
        --font-only
        $variant
    ]
}
