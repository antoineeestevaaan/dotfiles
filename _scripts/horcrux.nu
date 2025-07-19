#!/usr/bin/env -S nu --no-std-lib --no-config-file

const PROJECT = "jesseduffield/horcrux"

def main [tag: string, asset_pattern: string] {
    let res = try { ^gh -R $PROJECT release view $tag --json assets } catch { null }
    if $res == null {
         error make {
            msg: $"(ansi red_bold)argument_error(ansi reset)",
            label: {
                text: $"(ansi default_dimmed)($tag)(ansi reset) is not a valid released tag for (ansi default_dimmed)($PROJECT)(ansi reset)",
                span: (metadata $asset_pattern).span,
            },
            help: ([
                $"> see (ansi default_dimmed)https://github.com/($PROJECT)/releases(ansi reset) or run (ansi default_dimmed)gh -R ($PROJECT) release list --json name,tagName,isLatest(ansi reset) for a list of possible released tags.",
            ] | str join "\n")
        }
    }

    let assets = $res | from json | get assets

    let asset = $assets
        | where $it.name =~ $asset_pattern
        | match ($in | length) {
            0 => { error make {
                msg: $"(ansi red_bold)argument_error(ansi reset)",
                label: {
                    text: $"'($asset_pattern)' is too strict or incorrect and matched no asset",
                    span: (metadata $asset_pattern).span,
                },
                help: ([
                    "available assets:",
                    ...($assets | each { $"    (ansi default_dimmed)($in.name)(ansi reset)" }),
                    $"> see (ansi default_dimmed)https://github.com/($PROJECT)/releases/tag/($tag)(ansi reset) or run (ansi default_dimmed)gh -R ($PROJECT) release view ($tag) --json assets(ansi reset) for a list of possible assets.",
                ] | str join "\n")
            } },
            1 => {
                $in
                    | into record
                    | insert archive {      $in.name }
                    | update name    { path parse --extension "tar.gz" | get stem }
                    | insert local   { |it| $nu.home-path | path join downloads $it.archive }
                    | insert extract { |it| $nu.temp-path | path join $it.name }
            },
            _ => { error make {
                msg: $"(ansi red_bold)argument_error(ansi reset)",
                label: {
                    text: $"'($asset_pattern)' is not strict enough and matched multiple assets",
                    span: (metadata $asset_pattern).span,
                },
                help: ([
                    "matched assets:",
                    ...($in | each { $"    (ansi default_dimmed)($in.name)(ansi reset)" }),
                    "available assets:",
                    ...($assets | each { $"    (ansi default_dimmed)($in.name)(ansi reset)" }),
                    $"> see (ansi default_dimmed)https://github.com/($PROJECT)/releases/tag/($tag)(ansi reset) or run (ansi default_dimmed)gh -R ($PROJECT) release view ($tag) --json assets(ansi reset) for a list of possible assets.",
                ] | str join "\n")
            } },
        }

    curl -fLo $asset.local $asset.url

    mkdir $asset.extract
    tar xvf $asset.local --directory $asset.extract
    cp ($asset.extract | path join "horcrux") ($nu.home-path | path join opt bin horcrux)
}
