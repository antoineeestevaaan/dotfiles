def foo [items: list<string>]: [ nothing -> list<string> ] {
    def aux [items: list<string>, prefix: int = 0]: [ nothing -> list<string> ] {
        $items
            | group-by --to-table { str substring ..0 }
            | update items { str substring 1.. }
            | each { |it|
                let new_prefix = $prefix + 1
                if ($it.items | length) == 1 {
                    [ $new_prefix ]
                } else {
                    aux $it.items $new_prefix
                }
            }
            | flatten
    }

    aux ($items | sort) 0
}

let items = git rev-list --all | lines
$items | zip (foo $items) | each { |it|
    $"(ansi default)($it.0 | str substring ..<$it.1)(ansi default_dimmed)($it.0 | str substring $it.1..)(ansi reset)"
}
