const SESSION_FILE = $nu.home-path | path join ".local" "state" "tmux" "last-session"
const     LOG_FILE = $nu.home-path | path join ".local" "state" "tmux" "log.txt"

export def log   [msg: string] { $"($msg)"   out>> $LOG_FILE }
export def logln [msg: string] { $"($msg)\n" out>> $LOG_FILE }

export def get-current-session []: [ nothing -> string ] {
    ^tmux display-message -p '#{session_name}' | str trim
}

export def get-previous-session []: [ nothing -> string ] {
    $SESSION_FILE | if ($in | path exists) { open $in | str trim } else { "" }
}

export def list-sessions []: [ nothing -> list<string> ] {
    ^tmux list-sessions -F "#{session_name}" | lines
}

export def save-session [current: string] {
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

export def switch-to-session [name: string] {
    logln $"switch-to-session `($name)`"
    ^tmux switch-client -t $name
}

export def create-session [name: string, --path: path = $nu.home-path] {
    logln $"create-session `($name)`"
    ^tmux new-session -ds $name -c $path
}

export def switch-to-or-create-session [name: string, --path: path = $nu.home-path] {
    logln $"switch-to-or-create-session `($name)`"
    if $name not-in (list-sessions) {
        create-session $name --path $path
    }
    switch-to-session $name
}

export def alternate-session [] {
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

export def "path shorten" []: [ string -> string ] {
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

export def kill-session [name: string] {
    logln $"kill-session `($name)`"
    ^tmux kill-session -t $name
}
