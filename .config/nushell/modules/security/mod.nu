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

export def "pass add" [name: string] {
    let buf = { parent: $PASSHOME, stem: $name, extension: "txt" } | path join
    let out = { parent: $PASSHOME, stem: $name, extension: "gpg" } | path join

    if ($out | path exists) {
        print $"($name) does exist, use `pass edit ($name)` instead"
        return
    }

    mkdir $PASSHOME

    rm -rf $buf

    touch $buf
    chmod 600 $buf

    ^$env.EDITOR $buf
    gpg ...[
        --yes
        --output $out
        --passphrase (get-pin --prompt $"enter PIN for ($name)")
        --pinentry-mode loopback
        --symmetric
        $buf
    ]

    rm -rf $buf
}

export def "pass edit" [name: string] {
    let buf = { parent: $PASSHOME, stem: $name, extension: "txt" } | path join
    let out = { parent: $PASSHOME, stem: $name, extension: "gpg" } | path join

    if not ($out | path exists) {
        print $"($name) does not exist, use `pass add ($name)` first"
        return
    }

    mkdir $PASSHOME

    rm -rf $buf

    let passphrase = get-pin --prompt $"enter PIN for ($name)"

    touch $buf
    chmod 600 $buf
    gpg ...[
        --yes
        --output $buf
        --passphrase $passphrase
        --pinentry-mode loopback
        --decrypt
        $out
    ]

    ^$env.EDITOR $buf
    gpg ...[
        --yes
        --output $out
        --passphrase $passphrase
        --pinentry-mode loopback
        --symmetric
        $buf
    ]

    rm -rf $buf
}

export def "pass list" []: [ nothing -> list<string> ] {
    $PASSHOME
        | path join "*.gpg"
        | into glob
        | ls $in
        | get name
        | path parse
        | get stem
}

export def "pass show" [name: string]: [ nothing -> string ] {
    let passwd_file = {
        parent: $PASSHOME,
        stem: $name,
        extension: "gpg",
    } | path join

    if not ($passwd_file | path exists) {
        print $"($name) not in pass home, use `pass list`"
        return
    }

    gpg ...[
        --yes
        --passphrase (get-pin --prompt $"enter PIN for ($name)")
        --pinentry-mode loopback
        --decrypt
        $passwd_file
    ]
}
