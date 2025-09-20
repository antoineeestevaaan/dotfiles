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

const PASSHOME = $nu.home-path | path join ".local/share/pass-store"
const PASS_WITNESS_FILE = $PASSHOME | path join ".witness"
const PASS_WITNESS = "ok"

export def "encrypt" [passphrase?: string, --armor]: [
    string -> nothing,
    string -> string,
    string -> binary,
] {
    let passphrase = if $passphrase == null {
        get-pin --prompt "enter PIN"
    } else {
        $passphrase
    }

    let res = $in | try {
        gpg ...[
            --passphrase $passphrase
            --pinentry-mode loopback
            ...(if $armor {[ --armor ]} else {[]})
            --symmetric
        ] err> /dev/null
    }

    if ($res | is-empty) { null } else { $res }
}

export def decrypt [passphrase?: string, --armor]: [
    nothing -> error,
    string -> string,
    binary -> string,
] {
    if $in == null {
        error make --unspanned { msg: "could not decrypt: invalid input (nothing)" }
    }

    let passphrase = if $passphrase == null {
        get-pin --prompt "enter PIN"
    } else {
        $passphrase
    }

    let res = $in | try { gpg ...[
        --passphrase $passphrase
        --pinentry-mode loopback
        ...(if $armor {[ --armor ]} else {[]})
        --decrypt
    ]}

    if ($res | is-empty) { null } else { $res }
}

export def "pass init" [] {
    mkdir ($PASS_WITNESS_FILE | path dirname)
    $PASS_WITNESS | encrypt | save --force $PASS_WITNESS_FILE
}

def check-pass-store-is-init []: [ nothing -> bool ] {
    if not ($PASS_WITNESS_FILE | path exists) {
        print $"[(ansi red_bold)ERROR(ansi reset)]: store does not exist, use `pass init` first"
        false
    } else {
        true
    }
}

def unlock-pass-store [passphrase: string]: [ nothing -> bool ] {
    let witness = open $PASS_WITNESS_FILE | try { decrypt $passphrase }
    if $witness == null {
        print $"[(ansi red_bold)ERROR(ansi reset)]: could not unlock pass store \(bad key\)"
        false
    } else {
        true
    }
}

export def "pass add" [name: string] {
    if not (check-pass-store-is-init) { return }

    let buf = { parent: $PASSHOME, stem: $name, extension: "txt" } | path join
    let out = { parent: $PASSHOME, stem: $name, extension: "gpg" } | path join

    if ($out | path exists) {
        print $"ERROR: ($name) does exist, use `pass edit ($name)` instead"
        return
    }

    let passphrase = get-pin --prompt $"unlock"
    if not (unlock-pass-store $passphrase) { return }

    mkdir $PASSHOME

    rm -rf $buf
    touch $buf
    chmod 600 $buf
    ^$env.EDITOR $buf
    open $buf | encrypt $passphrase | save --force $out
    rm -rf $buf
}

export def "pass edit" [name: string] {
    if not (check-pass-store-is-init) { return }

    let buf = { parent: $PASSHOME, stem: $name, extension: "txt" } | path join
    let out = { parent: $PASSHOME, stem: $name, extension: "gpg" } | path join

    if not ($out | path exists) {
        print $"($name) does not exist, use `pass add ($name)` first"
        return
    }

    let passphrase = get-pin --prompt $"unlock"
    if not (unlock-pass-store $passphrase) { return }

    mkdir $PASSHOME

    rm -rf $buf
    touch $buf
    chmod 600 $buf
    open $out | decrypt $passphrase | save --force $buf
    ^$env.EDITOR $buf
    open $buf | encrypt $passphrase | save --force $out
    rm -rf $buf
}

export def "pass list" []: [ nothing -> list<string> ] {
    if not (check-pass-store-is-init) { return }

    $PASSHOME
        | path join "*.gpg"
        | into glob
        | try { ls $in } catch { [] }
        | get name
        | path parse
        | get stem
}

export def "pass show" [name: string]: [ nothing -> string ] {
    if not (check-pass-store-is-init) { return }

    let passwd_file = {
        parent: $PASSHOME,
        stem: $name,
        extension: "gpg",
    } | path join

    if not ($passwd_file | path exists) {
        print $"($name) not in pass home, use `pass list`"
        return
    }

    let passphrase = get-pin --prompt $"unlock"
    if not (unlock-pass-store $passphrase) { return }

    open $passwd_file | decrypt $passphrase
}
