# tries to convert to filesize
@example "valid filesize 1" { "1kib" | maybe-into filesize | into int } --result 1024
@example "valid filesize 2" { "2.5mib" | maybe-into filesize | into int } --result 2621440
@example "invalid filesize" { "-" | maybe-into filesize | describe } --result "nothing"
export def "maybe-into filesize" []: [
    string -> filesize,
    string -> nothing,
] {
    match $in {
        "-" => null,
        _ => { $in | into filesize },
    }
}

export def "maybe-into int" []: [
    string -> int,
    string -> nothing,
] {
    match $in {
        "-" => null,
        _ => { $in | into filesize | into int },
    }
}
