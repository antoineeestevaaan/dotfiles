use conversions [ "maybe-into int", "maybe-into filesize" ]

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

export const CONSOLE_SETUP_FILES_DIR = "/root"

def "ls-console-variants" []: [
    nothing -> table<value: string, description: string>
] {
    print --no-newline $"(ansi default_dimmed)getting `.console-setup` variants from `($CONSOLE_SETUP_FILES_DIR)/`...(ansi reset)"
    sudo find $CONSOLE_SETUP_FILES_DIR -maxdepth 1 -name '*.console-setup*'
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
# > [!note] this uses `.console*` files stored in `$CONSOLE_SETUP_FILES_DIR` so that
# > running the script with `sudo` uses the proper files.
export def "update-tty-font" [
    variant: string@ls-console-variants = "",
    --all-ttys (-a),
] {
    let screen = open /sys/class/graphics/fb0/virtual_size
        | parse "{w},{h}"
        | into record
        | into int w h

    let font = sudo cat $"($CONSOLE_SETUP_FILES_DIR)/([".console-setup", $variant] | where $it != "" | str join ".")"
        | lines
        | parse '{k}="{v}"' | where k == "FONTSIZE"
        | into record
        | get v
        | parse "{w}x{h}"
        | into record
        | into int w h

    let unused_w_pixels = $screen.w mod $font.w
    if $unused_w_pixels > 0 {
        if $variant == "" {
            print $"[(ansi yellow)WARNING(ansi reset)] default TTY font variant will leave ($unused_w_pixels) unused pixels horizontally."
        } else {
            print $"[(ansi yellow)WARNING(ansi reset)] TTY font variant '($variant)' will leave ($unused_w_pixels) unused pixels horizontally."
        }
    }
    let unused_h_pixels = $screen.h mod $font.h
    if $unused_h_pixels > 0 {
        if $variant == "" {
            print $"[(ansi yellow)WARNING(ansi reset)] default TTY font variant will leave ($unused_h_pixels) unused pixels vertically."
        } else {
            print $"[(ansi yellow)WARNING(ansi reset)] TTY font variant '($variant)' will leave ($unused_h_pixels) unused pixels vertically."
        }
    }

    sudo setupcon ...[
        --force
        ...(if not $all_ttys { [ --current-tty ] } else { [] })
        --font-only
        $variant
    ]
}

# a "fat" and structured wrapper around `df`
export def df [--all (-a), --summary (-s)]: [ nothing -> table ] {
    let options = [
        ...(if $all and not $summary { [--all] } else { [] }),
        --block-size=KiB
        --output
    ]

    ^df ...$options
        | detect columns --guess
        | each {{
            name: $in.Filesystem,
            type: $in.Type,
            inodes: {
                total : ($in.Inodes | maybe-into int),
                used  : ($in.IUsed  | maybe-into int),
                free  : ($in.IFree  | maybe-into int),
            },
            memory: {
                total : ($in.1KiB-blocks | maybe-into filesize),
                used  : ($in.Used        | maybe-into filesize),
                free  : ($in.Avail       | maybe-into filesize),
            },
            mount: $in."Mounted on",
        }}
        | if $summary {
            sort-by mount | where $it.type != tmpfs and ($it.memory.total | default 0b) > 0b
        } else {
            $in
        }
}
