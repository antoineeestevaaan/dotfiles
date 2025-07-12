# wrapper around system's `make` command
#
#     use `help make` to show this help
#     use `make --help` to get the help of the wrapped `make`
@example "simple usage"         { make }
@example "call  rule"           { make foo_rule bar_rule }
@example "regular variables"    { make FOO=my_foo foo_rule }
@example "structured variables" { make -V { FOO: my_foo } foo_rule }
export def --wrapped make [
    --make-variables (-V): record,
    ...args: string,
] {
    let make_variables = $make_variables | default {} | items { |k, v|
        $"($k)=($v)"
    }

    ^make ...$make_variables ...$args
}
