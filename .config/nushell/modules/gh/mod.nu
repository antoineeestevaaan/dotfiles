export def "gh ls-files" [repo: string, branch: string, --recursive (-r)]: [
    nothing -> table<
        path: string,
        mode: string,
        type: string,
        sha: string,
        url: string,
    >
] {
    let endpoint = if $recursive {
        $"/repos/($repo)/git/trees/($branch)?recursive=true"
    } else {
        $"/repos/($repo)/git/trees/($branch)"
    }

    let res = gh api $endpoint err> /dev/null | from json
    if $res.status? != null {
        error make --unspanned {
            msg: $"(ansi red_bold)invalid_api_endpoint(ansi reset): ($res.message) \(($res.status)\)",
            help: ([
                 "parameters",
                $"    repo        : ($repo)",
                $"    branch      : ($branch)",
                $"    --recursive : ($recursive)",
            ] | str join "\n")
        }
    }

    $res.tree
}

export def "gh contents" [repo: string, file: string]: [
    nothing -> record<
        name         : string,
        path         : string,
        sha          : string,
        size         : int,
        url          : string,
        html_url     : string,
        git_url      : string,
        download_url : string,
        type         : string,
        content      : string,
        encoding     : string,
        _links       : record<self: string, git: string, html: string>,
    >, # success
    nothing -> record<
        message: string,
        documentation_url: string,
        status: string,
    >, # error
] {
    gh api $"repos/($repo)/contents/($file)" err> /dev/null | from json
}

export def "gh download-file" [repo: string, file: string, --output: path] {
    let output = $output | default ($file | path basename)

    let res = gh contents $repo $file
    if $res.status? != null {
        error make --unspanned {
            msg: $"(ansi red_bold)invalid_api_endpoint(ansi reset): ($res.message) \(($res.status)\)",
            help: ([
                 "parameters",
                $"    repo     : ($repo)",
                $"    file     : ($file)",
                $"    --output : ($output)",
            ] | str join "\n")
        }
    }

    http get $res.download_url | save --progress --force $output
}

# available templates:
# - '{{$pr.body}}'  : the body
# - '{{$pr.title}}' : the title
# - '{{$pr.id}}'    : the ID
export def "gh pr merge" [
    id: int,
    --title: string = "{{$pr.title}} (#{{$pr.id}})",
    --body: string = "{{$pr.body}}",
    --method: string = "squash",
] {
    let pr = ^gh pr view $id --json title,body | from json

    let body = $body
        | str replace --all '{{$pr.body}}' $pr.body
        | str replace --all '{{$pr.title}}' $pr.title
        | str replace --all '{{$pr.id}}' $"($id)"
    let title = $title
        | str replace --all '{{$pr.body}}' $pr.body
        | str replace --all '{{$pr.title}}' $pr.title
        | str replace --all '{{$pr.id}}' $"($id)"

    let merge_opt = match $method {
        "merge"  => "--merge",
        "rebase" => "--rebase",
        "squash" => "--squash",
        _        => {
            error make {
                msg: $"(ansi red_bold)invalid_merge_method(ansi reset)",
                label: {
                    text: $"'($method)' is not a valid merge method on GitHub",
                    span: (metadata $method).span,
                },
                help: "valid merge methods: 'merge', 'rebase', 'squash'",
            }
        },
    }

    $body | ^gh pr merge $id -t $title -F - -s
}
