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

# wrapper around system's `git clone` command
#
#     use `help git clone` to show this help
#     use `git clone --help` to get the help of the wrapped `git clone`
@example "clone to default location" { git clone https://github.com/antoineeestevaaan/dotfiles } --result "# cloned to ~/documents/github.com/antoineeestevaaan/dotfiles"
@example "clone to custom location"  { git clone https://github.com/antoineeestevaaan/dotfiles ~/my_dir/my_repo }
export def --wrapped "git clone" [repo: string, dest?: path, ...args: string]: [ nothing -> path ] {
    let dest = $dest
        | default (
            if ($repo | str starts-with "-") {
                ""
            } else {
                $nu.home-path | path join documents ($repo | url parse | [ $in.host, $in.path] | str join "")
            }
        )
        | path expand
    ^git clone $repo $dest ...$args

    $dest
}

# lists commits from a target to head, but in a smart way
#
# In the example, the following hypothetical Git history is used:
#
#     * K
#     * J
#     * I
#     *   H
#     |\
#     | * G
#     | * F
#     * | E
#     * | D
#     |/
#     * C
#     * B
#     * A
#
@example "list without any merge in the way"         { git rls H --head K                 } --result "[K, J, I]"
@example "same but less trivial"                     { git rls B --head G                 } --result "[G, F, C]"
@example "list in merge (left parent => no choice)"  { git rls D --head H                 } --result "[H, E]"
@example "list in merge (right parent => no choice)" { git rls F --head H                 } --result "[H, G]"
@example "list in merge (traversal)"                 { git rls B --head H                 } --result "[H, E, D, C]"
@example "list in merge (traversal)"                 { git rls B --head H --follow-second } --result "[H, G, F, C]"
export def "git rls" [
    target: string,
    --head: string = "HEAD",
    --follow-second,
]: [ nothing -> list<string> ] {
    let merge = do {
        let commit = try { git rev-list --merges --ancestry-path $head $"^($target)" }

        if $commit == "" {
            {}
        } else {
            let ret = git merge-base --is-ancestor $target $"($commit)^1" | complete
            let first = if $ret.exit_code == 0 { $"($commit)^1" } else { $"($commit)^2" }
            let second = if $ret.exit_code == 0 { $"($commit)^2" } else { $"($commit)^1" }

            {
                commit : (git rev-parse $commit),
                first  : (git rev-parse $first),
                second : (git rev-parse $second),
                base   : (git merge-base $first $second),
            }
        }
    }

    if $merge == {} {
        git rev-list $"($target)..($head)" | lines
    } else {
        let ret = git merge-base --is-ancestor $target $merge.base | complete
        match $ret.exit_code {
            0 => {
                let list_with_merge = if $follow_second {
                    git rev-list $"($target)..($head)" $"^($merge.first)" | lines
                } else {
                    git rev-list $"($target)..($head)" $"^($merge.second)" | lines
                }
                let list_before_merge = git rev-list $"($target)..($merge.base)" | lines
                $list_with_merge ++ $list_before_merge
            },
            1 => {
                let ret = git merge-base --is-ancestor $target $merge.first | complete
                match $ret.exit_code {
                    0 => {
                        git rev-list $"($target)..($head)" $"^($merge.second)" | lines
                    },
                    1 => {
                        git rev-list $"($target)..($head)" $"^($merge.first)" | lines
                    },
                    _ => { error make --unspanned { msg: "UNREACHABLE" } },
                }
            },
            _ => { error make --unspanned { msg: "UNREACHABLE" } },
        }
    }
}
