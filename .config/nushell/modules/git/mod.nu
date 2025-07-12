const HASH_PATTERN = '[0-9a-fA-F]+'
const GIT_BRANCH_PATTERN = '[\w@\-_/\.]*'

def "regex capture" [pattern: string, --name (-n): string]: [ nothing -> string ] {
    if $name == null {
        $"\(?=($pattern)\)"
    } else {
        $"\(?<($name)>($pattern)\)"
    }
}

def "regex start"       []: [ nothing -> string ] { '^'   }
def "regex end"         []: [ nothing -> string ] { '$'   }
def "regex dot"         []: [ nothing -> string ] { '\.'  }
def "regex whitespaces" []: [ nothing -> string ] { '\s*' }
def "regex any"         []: [ nothing -> string ] { '.*'  }

def "regex join" []: [ string -> string, list<string> -> string ] { str join "" }

# `$cases` is either a list of
#     - string       : fully constructed regex
#     - list<string> : list of regex tokens to be joined
def "regex or" [cases: list]: [ nothing -> string ] { $cases | each { regex join } | str join "|" }

export def --wrapped "git fetch" [...args: string] {
    let pattern = regex or [
        [
            (regex start),
            (regex whitespaces),
            (regex capture $HASH_PATTERN -n "update_base_ref"),
            (regex dot),
            (regex dot),
            (regex capture $HASH_PATTERN -n "update_new_ref"),
            (regex whitespaces),
            (regex capture $GIT_BRANCH_PATTERN -n "update_local_branch"),
            (regex whitespaces),
            '->',
            (regex whitespaces),
            (regex capture $GIT_BRANCH_PATTERN -n "update_remote_branch"),
            (regex whitespaces),
            (regex end),
        ],
        [
            (regex start),
            (regex whitespaces),
            '\* \[new branch\]',
            (regex whitespaces),
            (regex capture $GIT_BRANCH_PATTERN -n "new_local_branch"),
            (regex whitespaces),
            '->',
            (regex whitespaces),
            (regex capture $GIT_BRANCH_PATTERN -n "new_remote_branch"),
            (regex whitespaces),
            (regex end),
        ],
        [
            (regex capture (regex any) -n "sink")
        ],
    ]

    let raw = ^git fetch ...$args | complete
    if $raw.exit_code != 0 {
        print ($raw.stdout + $raw.stderr)
        return
    }

    let output = $raw.stderr | lines
    if ($output | is-empty) {
        return
    }

    {
        url: ($output | parse "From {from}" | into record | get from),
        changes: ($output | parse --regex $pattern | each { |it|
            match ([$it.update_remote_branch, $it.new_remote_branch] | str length) {
                [0, 0] => { kind: "invalid", ...$it },
                [0, _] => {
                    kind          : "new",
                    local_branch  : $it.new_local_branch,
                    remote_branch : $it.new_remote_branch,
                },
                [_, 0] => {
                    kind          : "update",
                    base_ref      : $it.update_base_ref,
                    new_ref       : $it.update_new_ref,
                    local_branch  : $it.update_local_branch,
                    remote_branch : $it.update_remote_branch,
                },
                [_, _] => { kind: "invalid", ...$it },
            }
        }),
    }
}
