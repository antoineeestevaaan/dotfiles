use std assert
use . *

const TEST_CASES = [
    [ h        , t        , s    , e                                  ];
    [ "694c7c2", "bab8e9f", null , [ "694c7c2", "403824d", "6e05409" ] ],
    [ "1ecd1f7", "98affe8", null , [ "1ecd1f7", "af1fcce" ] ],
    [ "9f1ae14", "7275887", null , [ "9f1ae14", "1f1c8af", "019c45a", "b711381" ] ],
    [ "6e05409", "7275887", null , [ "6e05409", "bab8e9f", "409e443", "019c45a", "b711381" ] ],
    [ "4e77d03", "6e05409", null , [ "4e77d03", "9ce4099", "996b944", "694c7c2", "403824d" ] ],
    [ "4e77d03", "8eb3e44", null , [ "4e77d03", "9ce4099", "c27b4aa", "be7dc40", "3378ceb", "2b1b62e" ] ],
    [ "4e77d03", "7275887", false, [ "4e77d03", "9ce4099", "c27b4aa", "be7dc40", "3378ceb", "2b1b62e", "8eb3e44", "2428183", "014e87a", "765cef9", "98eb0bb", "176510c", "1ecd1f7", "af1fcce", "98affe8", "675e161", "afcef68", "61ba51c", "049a3a2", "9f1ae14", "1f1c8af", "019c45a", "b711381" ] ],
    [ "4e77d03", "7275887", true , [ "4e77d03", "9ce4099", "996b944", "694c7c2", "403824d", "6e05409", "bab8e9f", "409e443", "019c45a", "b711381" ] ],
]

def "test ok" []   { print $"(ansi green   )ok(  ansi reset)" }
def "test fail" [] { print $"(ansi red_bold)fail(ansi reset)" }

for it in $TEST_CASES {
    let target = git rev-parse $it.t
    let head = git rev-parse $it.h
    let expected = $it.e | each { git rev-parse $in }

    def test [code: closure] {
        let actual = do $code
        if $expected == $actual { test ok } else {
            test fail
            print $"    expected: ($expected | each { str substring ..7 })"
            print $"    actual  : ($actual | each { str substring ..7 })"
        }
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
