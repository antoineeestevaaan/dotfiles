use std assert
use git *

# TODO: use commits from a real public repository
const TEST_CASES = [
    [ t     , h     , s    , e                                  ];
    [ "ffe9", "7d28", null , [ "7d28", "e20a"                 ] ],
    [ "13b5", "24a2", null , [ "24a2", "2c52", "0ad9"         ] ],
    [ "13b5", "49e7", null , [ "49e7", "0ad9"                 ] ],
    [ "2c52", "f3aa", null , [ "f3aa", "24a2"                 ] ],
    [ "49e7", "f3aa", null , [ "f3aa"                         ] ],
    [ "13b5", "f3aa", false, [ "f3aa", "49e7", "0ad9"         ] ],
    [ "13b5", "f3aa", true , [ "f3aa", "24a2", "2c52", "0ad9" ] ],
]

def "test ok" []   { print $"(ansi green   )ok(  ansi reset)" }
def "test fail" [] { print $"(ansi red_bold)fail(ansi reset)" }

for it in $TEST_CASES {
    let target = git rev-parse $it.t
    let head = git rev-parse $it.h
    let expected = $it.e | each { git rev-parse $in }

    def test [code: closure] {
        if $expected == (do $code) { test ok } else { test fail }
    }

    match $it.s {
        false => {
            print --no-newline $"($it.t) ($it.h)                 "
            test { git rls $target --head $head }
        },
        true  => {
            print --no-newline $"($it.t) ($it.h) \(follow second\) "
            test { git rls $target --head $head --follow-second }
        },
        null  => {
            print --no-newline $"($it.t) ($it.h)                 "
            test { git rls $target --head $head }

            print --no-newline $"($it.t) ($it.h) \(follow second\) "
            test { git rls $target --head $head --follow-second }
        },
        _  => { error make --unspanned { msg: "UNREACHABLE" } },
    }
}
