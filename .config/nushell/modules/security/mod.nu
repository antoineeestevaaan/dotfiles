@example "entering 'my password' as PIN" { get-pin }                             --result "my password"
@example "entering '' as PIN"            { (get-pin) == "" }                     --result true
@example "canceling the PIN with C-C"    { (get-pin) == null }                   --result true
@example "canceling the PIN with button" { (get-pin --pinentry curses) == null } --result true
export def get-pin [--pinentry: string = "tty", --prompt: string, --title: string]: [
    nothing -> string,
    nothing -> nothing,
] {
    let pinentry_bin = $"pinentry-($pinentry)"
    if (which $pinentry_bin | is-empty) {
        let pinentries = $env.PATH
            | each { ls $in }
            | get name
            | flatten
            | path parse
            | reject parent
            | path join
            | uniq
            | where $it =~ "^pinentry-"

        error make {
            msg: $"(ansi red_bold)invalid_pinentry(ansi reset)",
            label: {
                text: $"'($pinentry)' is not a valid pinentry",
                span: (metadata $pinentry).span,
            },
            help: $"choose among: ($pinentries)",
        }

    }

    let script = [
        ...(if $title != null {[ $"SETTITLE ($title)" ]} else {[]})
        ...(if $prompt != null {[ $"SETPROMPT ($prompt)" ]} else {[]})
        "GETPIN"
        "BYE"
    ]

    let res = $script
        | str join "\n"
        | ^$pinentry_bin --lc-ctype "UTF-8" -T (tty)
        | lines

    if ($res | last) != "OK" {
        return
    }

    $res
        | parse "D {res}"
        | into record
        | get -i res
        | default ""
}

const PASSHOME = "/tmp/pass"

export def "pass add" [passwd: string, --force] {
    let buf = { parent: $PASSHOME, stem: $passwd, extension: "txt" } | path join
    let out = { parent: $PASSHOME, stem: $passwd, extension: "gpg" } | path join

    mkdir $PASSHOME

    rm -rf $buf

    touch $buf
    chmod 600 $buf

    ^$env.EDITOR $buf
    gpg ...[
        ...(if $force {[ --yes ]} else {[]})
        --output $out
        --passphrase (get-pin --prompt "my prompt")
        --pinentry-mode loopback
        --symmetric
        $buf
    ]

    rm -rf $buf
}
