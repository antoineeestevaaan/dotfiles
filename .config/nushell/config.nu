$env.SHELL = $nu.current-exe

$env.config = {
    show_banner: false,
    edit_mode  : vi,
    cursor_shape: {       # NOTE: looks like this does not work in a TTY
        vi_insert: line,
        vi_normal: block,
    },
    table: {
        mode                : compact,
        index_mode          : always,
        show_empty          : true,
        padding             : { left: 0, right: 0 },
        header_on_separator : true,
        trim: {
            methodology: "truncating",
            truncating_suffix: "...",
        },
    },
    footer_mode: auto,
    datetime_format: {
        normal : "%F %T",
        table  : "%F %T",
    },
}

$env.PROMPT_COMMAND = {||
    let color = if $env.LAST_EXIT_CODE == 0 { "green" } else { "red" }
    $"(ansi reset)(ansi $color)#(ansi reset)"
}

$env.PROMPT_COMMAND_RIGHT = ""

$env.PROMPT_INDICATOR                      = ""
$env.PROMPT_INDICATOR_VI_INSERT            = " "
$env.PROMPT_INDICATOR_VI_NORMAL            = "."
$env.PROMPT_MULTILINE_INDICATOR            = ":::"
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR  = ""

$env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge {
    "PATH": {
        from_string : { split row (char esep)    | path expand --no-symlink }
        to_string   : { path expand --no-symlink | str join (char esep)     }
    }
    "MANPATH": {
        from_string : { split row (char esep)    | path expand --no-symlink             }
        to_string   : { path expand --no-symlink | str join (char esep)     | $"($in):" }  # NOTE: MANPATH needs a trailing colon to work
    }
}

do --env {
    def prepend-to-paths-and-uniq [paths: list<path>, --env-var: string] {
        $env
            | get --ignore-errors $env_var
            | default []
            | prepend $paths
            | path expand # FIXME: shouldn't be required ??
            | uniq
    }

    $env.PATH    = prepend-to-paths-and-uniq --env-var PATH    [ "~/opt/bin" ]
    $env.MANPATH = prepend-to-paths-and-uniq --env-var MANPATH [ "~/.local/share/man" ]
}

export-env {
    def cmd [cmd: string]: [ nothing -> record<send: string, cmd: string> ] {{
        send: executehostcommand,
        cmd: $cmd,
    }}
    def vi [--insert (-i), --normal (-n)]: [ nothing -> list<string> ] {
        match [$insert, $normal] {
            [ true  , true  ] => [ vi_insert, vi_normal       ],
            [ false , true  ] => [            vi_normal       ],
            [ true  , false ] => [ vi_insert                  ],
            [ false , false ] => [                      emacs ],
        }
    }

    $env.config.keybindings = [
        [ name   , modifier , keycode , mode     , event           ];
        [ reload , alt      , char_r  , (vi -in) , (cmd "exec nu") ],
    ]
}

const NU_LIB_DIRS = [
    ($nu.default-config-dir | path join "modules")
]

alias which = which --all
