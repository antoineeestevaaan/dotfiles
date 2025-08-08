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

const CONSOLE_FONTS_DIR = "/usr/share/consolefonts/"
const CONSOLE_FONT_FILE_FORMAT = "psf.gz"

const BASE_FONT = {
    ACTIVE_CONSOLES : "/dev/tty[1-6]",
    CHARMAP         : "UTF-8",
    CODESET         : "guess",
    FONTFACE        : null,
    FONTSIZE        : null,
    VIDEOMODE       : "",
}

const TMP_CONSOLE_SETUP_FILE = "/tmp/.console-setup"

const CONSOLE_FONT_VARIANT = "custom"
const TARGET_ROOT_CONSOLE_SETUP_FILE = $"/root/.console-setup.($CONSOLE_FONT_VARIANT)"

# update the font of TTYs using `setupcon` and `console-setup`
#
# > [!note] this script uses `sudo` to run `setupcon` from files in `/root/`
export def update-tty-font [--all-ttys (-a)] {
    let cache_font_file = $nu.temp-path | path join (whoami) font current

    let current_font = try { open $cache_font_file | parse "{face}:{a}x{b}" | into record }
    let console_fonts = ls $CONSOLE_FONTS_DIR
        | get name
        | path parse --extension $CONSOLE_FONT_FILE_FORMAT
        | get stem
        | parse "{codeset}-{font}"
        | update font { parse --regex '(?<face>[a-zA-Z]*)(?<size>\d.*)' }
        | flatten font --all
        | reject codeset
        | uniq
        | update size {
            let parsed = $in | parse --regex '(?<a>\d+)x(?<b>\d+)|(?<c>\d+)' | into record
            if $parsed.c? != "" {
                {
                    a: $parsed.c,
                    b: 8,
                }
            } else {
                {
                    a: $parsed.a,
                    b: $parsed.b,
                }
            }
        }
        | insert current {
            if $current_font == null {
                return false
            }

            $in.face == $current_font.face and $in.size.a == $current_font.a and $in.size.b == $current_font.b
        }

    let choice = $console_fonts
        | insert display { $" (if $in.current { '*' } else { ' ' }) ($in.face) ($in.size.a) ($in.size.b)" }
        | try { input list --fuzzy --display display "Choose a font" }
    if $choice == null {
        return
    }

    $BASE_FONT
        | update FONTFACE $choice.face
        | update FONTSIZE $"($choice.size.a)x($choice.size.b)"
        | items { |k, v| $"($k)=\"($v)\""}
        | str join "\n"
        | save --force $TMP_CONSOLE_SETUP_FILE

    sudo cp $TMP_CONSOLE_SETUP_FILE $TARGET_ROOT_CONSOLE_SETUP_FILE
    sudo setupcon ...[
        --force
        ...(if not $all_ttys { [ --current-tty ] } else { [] })
        --font-only
        $CONSOLE_FONT_VARIANT
    ]

    sudo rm $TARGET_ROOT_CONSOLE_SETUP_FILE

    mkdir ($cache_font_file | path dirname)
    $"($choice.face):($choice.size.a)x($choice.size.b)" | save --force $cache_font_file
}

export alias utf = update-tty-font

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
