#!/usr/bin/env -S nu --no-config-file --no-std-lib

use sessionizer.nu [
    get-current-session, logln, save-session, switch-to-or-create-session
]

const UCOLON = char -u "2236"
const UDOT   = char -u "2024"

const TARGET = "~/documents" | path expand
const FINDER = "~/opt/bin/find-git-repos-f8a0c5b5e8568c77ab45df8e659fdbaa81e0a32a0f0ad190d1b9832c881ed458"
    | path expand

def lpad [width: int, --character: string = " "]: [ string -> string ] { fill --alignment right --width $width --character $character }
def rpad [width: int, --character: string = " "]: [ string -> string ] { fill --alignment left  --width $width --character $character }
def "str color" [color: string]: [ string -> string ] { $"(ansi $color)($in)(ansi reset)" }

def get [
    root           : path,
    --finder  (-f) : string,
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
    if $finder == null {
        error make --unspanned {
            msg: $"(ansi red_bold)missing_option(ansi reset): --finder is required",
        }
    }
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

logln ""
logln $"[($env.CURRENT_FILE | path basename) | (date now | format date '%FT%T')]"

let res = get -sA $TARGET --finder $FINDER
if $res != null {
    let name = $"($res.host)($UCOLON)($res.group)/($res.project)"
        | str replace --all "." $UDOT
    let current = get-current-session
    if $current != $name {
        save-session $current
    }
    switch-to-or-create-session $name --path $res.path
}
