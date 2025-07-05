def lpad [width: int, --character: string = " "]: [ string -> string ] { fill --alignment right --width $width --character $character }
def rpad [width: int, --character: string = " "]: [ string -> string ] { fill --alignment left  --width $width --character $character }
def "str color" [color: string]: [ string -> string ] { $"(ansi $color)($in)(ansi reset)" }

const DEFAULT_FINDER = "~/documents/bin/find-git-repos-e96486f52751828ff5f8ebdfadacbd37cdb802afa559d098bbd59cac4df8b46d" | path expand
const SESSION_FILE = $nu.home-path | path join ".local" "state" "tmux" "last-session"
const LOG_FILE = "/tmp/log.txt"

def log   [msg: string] { $"($msg)"   out>> $LOG_FILE }
def logln [msg: string] { $"($msg)\n" out>> $LOG_FILE }

def get [
    root           : path,
    --finder  (-f) : string = $DEFAULT_FINDER,
    --no-ansi (-A),
    --sort    (-s),
]: [
    nothing -> record<
        root    : path,
        host    : string,
        group   : string,
        project : string,
        path    : path,
    >
] {
    if not ($finder | path exists) {
        error make {
            msg: $"(ansi red_bold)unknown_finder(ansi reset)",
            label: {
                text: $"(ansi purple)($finder)(ansi reset): no such file",
                span: (metadata $finder).span,
            },
        }
    }
    let finder = $finder | path expand

    let repos = ^$finder $root | lines | if $sort { sort } else { $in } | each {
        str replace --regex $"^($root)/" ''
            | path split
            | {
                host: $in.0,
                group: ($in | skip 1 | reverse | skip 1 | reverse | str join "/"),
                project: ($in | last),
            }
    }

    let width = {
        host: ($repos.host | str length | math max),
        group: ($repos.group | str length | math max),
        project: ($repos.project | str length | math max),
    }

    try {
        $repos
            | insert display {
                      update host    { rpad $width.host    | if $no_ansi { $in } else { str color "cyan_dimmed"    } }
                    | update group   { rpad $width.group   | if $no_ansi { $in } else { str color "default_dimmed" } }
                    | update project { rpad $width.project | if $no_ansi { $in } else { str color "yellow"         } }
                    | $"($in.host) ($in.group) ($in.project)"
            }
            | input list --fuzzy --display display
            | reject display
            | insert root $root
            | select root host group project
            | insert path { values | path join }
    } catch {
        null
    }
}

def get-current-session []: [ nothing -> string ] {
    ^tmux display-message -p '#{session_name}' | str trim
}

def get-previous-session []: [ nothing -> string ] {
    $SESSION_FILE | if ($in | path exists) { open $in | str trim } else { "" }
}

def list-sessions []: [ nothing -> list<string> ] {
    ^tmux list-sessions -F "#{session_name}" | lines
}

def save-session [current: string] {
    log $"save-session `($current)`"
    mkdir ($SESSION_FILE | path dirname)

    let previous = get-previous-session
    if $previous != $current {
        logln " (saved)"
        $current | save --force $SESSION_FILE
    } else {
        logln ""
    }
}

def switch-to-session [name: string] {
    logln $"switch-to-session `($name)`"
    ^tmux switch-client -t $name
}

def create-session [name: string, --path: path] {
    logln $"create-session `($name)`"
    ^tmux new-session -ds $name -c $path
}

def switch-to-or-create-session [name: string, --path: path = $nu.home-path] {
    logln $"switch-to-or-create-session `($name)`"
    if $name not-in (list-sessions) {
        create-session $name --path $path
    }
    switch-to-session $name
}

def alternate-session [] {
    let current = get-current-session
    let previous = get-previous-session
    logln "alternate-session"
    logln $"    previous : ($previous)"
    logln $"    current  : ($current)"
    if $previous in (list-sessions) {
        save-session $current
        switch-to-session $previous
    }
}

def "path shorten" []: [ string -> string ] {
    path split
        | each {
            if ($in | str starts-with '.') {
                str substring ..1
            } else {
                str substring ..0
            }
        }
        | path join
}
