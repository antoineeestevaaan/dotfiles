def find-files [
    root: path = ("." | path expand),
    --pattern: string = "**/*",
    --exclude: list<string> = [],
    --strip-prefix,
] {
    glob $"($root)/($pattern)" --no-dir --exclude $exclude
        | if $strip_prefix {
            each { str replace $"($root)/" '' }
        } else {
            $in
        }
}

def __log [
    level: string,
    color: string,
    msg: string,
] {
    print $"[(ansi $color)($level)(ansi reset)] ($msg)"
}
def "log debug"   [msg: string] { __log DBG default_dimmed $msg }
def "log info"    [msg: string] { __log INF cyan           $msg }
def "log warning" [msg: string] { __log WRN yellow         $msg }

const SYSTEM_FILE_PATTERN = "@*/**"
const NOT_CONFIG_FILE_PATTERN = [
    .git/**/*,
    _scripts/**,
    README.md,
    LICENSE,
    .editorconfig,
    $SYSTEM_FILE_PATTERN,
    make.nu,
    bootstrap.sh,
]

export def link [--config, --system, --dry-run] {
    if $config or not $system {
        log info $"gathering config files..."
        let config_files = find-files --strip-prefix --exclude $NOT_CONFIG_FILE_PATTERN

        log info $"linking config files to (ansi magenta)~(ansi reset)"
        for src in $config_files {
            if $dry_run {
                log debug $"    (ansi default_dimmed)($src)(ansi reset)"
            } else {
                log debug $"    (ansi magenta)($src)(ansi reset)"
            }

            let dest = $nu.home-path | path join $src
            let src = $src | path expand

            if not $dry_run {
                mkdir ($dest | path dirname)
                ln --symbolic --force $src $dest
            }
        }
    }

    if $system or not $config {
        log info $"gathering system files..."
        let system_files = find-files --strip-prefix (pwd) --pattern $SYSTEM_FILE_PATTERN

        log warning $"linking system files to (ansi magenta)/(ansi reset)"
        for src in $system_files {
            if $dry_run {
                log debug $"    (ansi default_dimmed)($src)(ansi reset)"
            } else {
                log debug $"    (ansi magenta)($src)(ansi reset)"
            }

            let dest = $src | str replace --regex '^@' '/'
            let src = $src | path expand

            if not $dry_run {
                sudo mkdir --parent ($dest | path dirname)
                sudo ln --symbolic --force $src $dest
            }
        }
    }
}

# > [!important] only supports .tar.gz files for Linux
@example "with GitHub CLI"                 { make gh download-asset-from-release cli/cli v2.74.2 linux_armv6.tar.gz }
@example "without GitHub CLI"              { make gh download-asset-from-release cli/cli v2.74.2 --no-gh --asset gh_2.74.2_linux_armv6 }
@example "archive with no inner directory" { make gh download-asset-from-release jesseduffield/horcrux v0.2 --no-gh --asset horcrux_0.2_Linux_armv6 --extract "/tmp/horcrux-0.2-armv6" }
export def "gh download-asset-from-release" [
    project        : string,
    tag            : string,
    asset_pattern? : string, # (only used without --no-gh)
    --no-gh,
    --asset        : string, # exact, without extension (only used with --no-gh)
    --extract      : path = $nu.temp-path,
] {
    let asset = if $no_gh {
        if $asset == null {
             error make --unspanned {
                msg: $"(ansi red_bold)argument_error(ansi reset): `asset` is required with `--no-gh`",
            }
        }

        let archive = $"($asset).tar.gz"
        {
            url     : $"https://github.com/($project)/releases/download/($tag)/($archive)",
            local   : ($nu.home-path | path join downloads $archive),
        }
    } else {
        if $asset_pattern == null {
             error make --unspanned {
                msg: $"(ansi red_bold)argument_error(ansi reset): `asset_pattern` is required without `--no-gh`",
            }
        }

        log debug "pulling GitHub"
        let res = try { ^gh -R $project release view $tag --json assets } catch { null }
        if $res == null {
             error make {
                msg: $"(ansi red_bold)argument_error(ansi reset)",
                label: {
                    text: $"(ansi default_dimmed)($tag)(ansi reset) is not a valid released tag for (ansi default_dimmed)($project)(ansi reset)",
                    span: (metadata $tag).span,
                },
                help: ([
                    $"see (ansi default_dimmed)https://github.com/($project)/releases(ansi reset) or run (ansi default_dimmed)gh -R ($project) release list --json name,tagName,isLatest(ansi reset) for a list of possible released tags.",
                ] | str join "\n")
            }
        }

        let assets = $res | from json | get assets

        $assets
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
                        $"see (ansi default_dimmed)https://github.com/($project)/releases/tag/($tag)(ansi reset) or run (ansi default_dimmed)gh -R ($project) release view ($tag) --json assets(ansi reset) for a list of possible assets.",
                    ] | str join "\n")
                } },
                1 => {
                    $in
                        | into record
                        | insert archive {      $in.name }
                        | update name    { path parse --extension "tar.gz" | get stem }
                        | insert local   { |it| $nu.home-path | path join downloads $it.archive }
                        | select url local
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
                        $"see (ansi default_dimmed)https://github.com/($project)/releases/tag/($tag)(ansi reset) or run (ansi default_dimmed)gh -R ($project) release view ($tag) --json assets(ansi reset) for a list of possible assets.",
                    ] | str join "\n")
                } },
            }
    }

    log info $"downloading ($asset.url)..."
    curl -fLo $asset.local $asset.url

    log info $"extracting ($asset.local)..."
    mkdir $extract
    tar xvf $asset.local --directory $extract
}
