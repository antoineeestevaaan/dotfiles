const HASH_PATTERN = "[0-9a-fA-F]+"
const GIT_BRANCH_PATTERN = "[\\w@\\-_/]*"

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

def "regex join" []: [ list<string> -> string ] { str join "" }

def "regex or" [a: string, b: string]: [ nothing -> string ] { $"($a)|($b)"}

let pattern = [
    [
        (regex start),
        (regex whitespaces),
        (regex capture $HASH_PATTERN -n "a"),
        (regex dot),
        (regex dot),
        (regex capture $HASH_PATTERN -n "b"),
        (regex whitespaces),
        (regex capture $GIT_BRANCH_PATTERN -n "l"),
        (regex whitespaces),
        '->',
        (regex whitespaces),
        (regex capture $GIT_BRANCH_PATTERN -n "r"),
        (regex whitespaces),
        (regex end),
    ],
    [
        (regex capture (regex any) -n "sink")
    ],
] | each { regex join } | regex or $in.0 $in.1


let raw = git fetch --dry-run | complete | get stderr | lines

{
    foo: ($raw.0 | parse "From {from}" | into record | get from),
    bar: ($raw | skip 1 | parse --regex $pattern),
}
