$env.config = {
    show_banner: false,
    edit_mode  : vi,
    cursor_shape: {
        vi_insert: line,
        vi_normal: block,
    },
    table: {
        mode                : compact,
        index_mode          : always,
        show_empty          : true,
        padding             : { left: 0, right: 0 },
        header_on_separator : true,
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

$env.PATH = $env.PATH | prepend ("~/opt/bin" | path expand) | uniq

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
