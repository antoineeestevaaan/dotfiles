use log.nu *
use std repeat

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
    applications.nuon,
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

    let download_dir = $asset.local | path dirname
    if not ($download_dir | path exists) {
	log info $"creating ($download_dir)..."
        mkdir ($download_dir)
    }

    log info $"downloading ($asset.url)..."
    curl -fLo $asset.local $asset.url

    log info $"extracting ($asset.local)..."
    mkdir $extract
    tar xvf $asset.local --directory $extract
}

def "todo"        [msg: string] { print $"("TODO" | str color red): ($msg)"        }
def "unreachable" [msg: string] { print $"("UNREACHABLE" | str color red): ($msg)" }

const OPT_DIR = "~/opt" | path expand
const MAN1_DIR = "~/.local/share/man/man1" | path expand

def check-field [field: string, --types: list<string>, --cp: cell-path]: [ record -> bool ] {
    if ($in | get -i $field) == null {
        if $cp != null {
            log fatal $"missing field ($field) at ($cp)"
        } else {
            log fatal $"missing field ($field)"
        }
        return false
    }

    $in | if $types != null {
        $in | get $field | describe --detailed | get type | if $in not-in $types {
            if $cp != null {
                log fatal $"expected field ($field) to be one of ($types), found ($in), at ($cp)"
            } else {
                log fatal $"expected field ($field) to be one of ($types), found ($in)"
            }
            return false
        }
    }

    true
}

def check-extra-fields [fields: list<string>, --cp: cell-path]: [ record -> bool ] {
    let extra = $in | columns | where $it not-in $fields
    if not ($extra | is-empty) {
        if $cp != null {
            log warning $"extra fields ($extra | each { $"$.($in)" } | str join "") at ($cp)"
        } else {
            log warning $"extra fields ($extra | each { $"$.($in)" } | str join "")"
        }
        return false
    }

    true
}

def expand-vars [--root: string]: [ string -> string ] {
    $in
        | str replace --all '$var::OPT_DIR' $'"($OPT_DIR)"'
        | str replace --all '$var::ROOT' $root
        | str replace --all '$var::' '$'
}

def "cmd log" [cmd: string, --indent: int = 4, --indent-level: int = 0]: [ nothing -> list<string> ] {
    let indentation = " " | repeat (($indent_level + 1) * $indent) | str join ""
    [
        $"($indentation)log info \"($cmd | str trim | nu-highlight)\""
        $cmd
    ]
}

def __install [root: string, --cp: cell-path]: [ list -> list<string>, table -> list<string> ] {
    if ($in | is-empty) {
        log warning $"nothing to install at ($cp)"
        return
    }

    let cp = $cp | split cell-path | append "install" | into cell-path

    $in | enumerate | each { |i|
        let cp = $cp | split cell-path | append $i.index | into cell-path

        if not ($i.item | check-field kind --types [string] --cp $cp) { return [] }

        match $i.item.kind {
            "bin" => {
                if not ($i.item | check-field path --types [string] --cp $cp) { return [] }
                $i.item | check-extra-fields [ kind, path ] --cp $cp

                let raw_src = $i.item.path | expand-vars --root $root
                let src = if ($raw_src | str contains '|') {
                    $"\(($raw_src)\)"
                } else {
                    $"\"($raw_src)\""
                }

                let dest = if ($raw_src | str contains '|') {
                    $"\(\"($OPT_DIR)\" | path join bin \(($raw_src) | path basename\)\)"
                } else {
                    $"\"($OPT_DIR | path join bin ($raw_src | path basename))\""
                }
                [
                    ...(cmd log $"mkdir ($OPT_DIR)"),
                    ...(cmd log $"cp --verbose ($src) ($dest)"),
                ]
            },
            "man" => {
                if not ($i.item | check-field pages --types [list] --cp $cp) { return [] }
                $i.item | check-extra-fields [ kind, pages ] --cp $cp

                [
                    ...(cmd log $"mkdir ($MAN1_DIR)")
                    ...($i.item.pages | each { |it|
                        let src_glob = $it | expand-vars --root $root
                        let dest = $MAN1_DIR
                        cmd log $"cp --verbose \(\"($src_glob)\" | into glob\) \"($dest)\""
                    } | flatten)
                ]
            },
            "link" => {
                if not ($i.item | check-field path --types [string] --cp $cp) { return [] }
                $i.item | check-extra-fields [ kind, path ] --cp $cp

                let raw_src = $i.item.path | expand-vars --root $root
                let src = if ($raw_src | str contains '|') {
                    $"\(($raw_src)\)"
                } else {
                    $"\"($raw_src)\""
                }

                let dest = if ($raw_src | str contains '|') {
                    $"\(\"($OPT_DIR)\" | path join \(($raw_src) | path basename\)\)"
                } else {
                    $"\"($OPT_DIR | path join ($raw_src | path basename))\""
                }
                [
                    ...(cmd log $"mkdir ($OPT_DIR)"),
                    ...(cmd log $"ln --force --symbolic ($src) ($dest)"),
                ]
            }
            _ => { log warning $"unknown kind ($i.item.kind) at ($cp)"; return [] },
        }
    } | flatten
}

export def "install" [
    file?: path,
    --from-stdin,
    --no-confirm (-y),
]: [ any -> nothing ] {
    let install_scripts = if $from_stdin {
        $in
    } else {
        if $file == null {
            log fatal $"missing file argument"
            return
        }
        if not ($file | path exists) {
            log fatal $"($file): no such file or directory"
            return
        }
        open $file
    } | enumerate | each { |entry|
        let cp = [$entry.index] | into cell-path

        if not ($entry.item | check-field kind --types [string] --cp $cp) { return }

        let lines = match $entry.item.kind {
            "apt" => {
                if not ($entry.item | check-field package --types [string] --cp $cp) { return }
                $entry.item | check-extra-fields [ kind, package ] --cp $cp

                [
                    $"use (pwd | path join log.nu) *"
                    ...(cmd log $"yes | sudo apt install ($entry.item.package)")
                ]
            },
            "release" => {
                if not ($entry.item | check-field host    --types [string]      --cp $cp) { return }
                if not ($entry.item | check-field name    --types [string]      --cp $cp) { return }
                if not ($entry.item | check-field tag     --types [string]      --cp $cp) { return }
                if not ($entry.item | check-field asset   --types [string]      --cp $cp) { return }
                if not ($entry.item | check-field install --types [list, table] --cp $cp) { return }
                $entry.item | check-extra-fields [ kind, host, name, tag, asset, install, inner ] --cp $cp

                let entry = $entry | update item { default true inner }

                let pull = match $entry.item.host {
                    "github.com" => {
                        let extract = if $entry.item.inner {
                            "$nu.temp-path"
                        } else {
                            $"$nu.temp-path | path join ($entry.item.asset)"
                        }
                        cmd log $"make gh download-asset-from-release ($entry.item.name) ($entry.item.tag) --no-gh --asset ($entry.item.asset) --extract \(($extract)\)"
                    },
                    _ => { log error $"unknown host ($entry.item.host) at ($cp)"; return },
                }

                [
                    $"use (pwd | path join make.nu)"
                    $"use (pwd | path join log.nu) *"
                    ...$pull,
                    ...($entry.item.install | __install ($nu.temp-path | path join $entry.item.asset) --cp $cp)
                ]
            },
            "build" => {
                if not ($entry.item | check-field git     --types [string]      --cp $cp) { return }
                if not ($entry.item | check-field build   --types [list]        --cp $cp) { return }
                if not ($entry.item | check-field install --types [list, table] --cp $cp) { return }
                $entry.item | check-extra-fields [ kind, git, build, install, variables, deps, checkout ] --cp $cp

                let entry = $entry | update item { default {} variables | default [] deps }

                let cache = [
                    $nu.home-path
                    .cache
                    antoineeestevaaan
                    doffiles
                    ($entry.item.git | url parse | $in.host + $in.path)
                ] | path join

                [
                    $"use (pwd | path join .config nushell modules misc) \"make\""
                    $"use (pwd | path join make.nu)"
                    $"use (pwd | path join log.nu) *"
                    $"if not \(\"($cache)\" | path exists\) {"
                    ...(cmd log $"    git clone ($entry.item.git) ($cache)")
                    "}"
                    ...(cmd log $"cd ($cache)")
                    ...($entry.item.deps | enumerate | each { |dep|
                        let cp = $cp | split cell-path | append [ "deps" $dep.index ] | into cell-path

                        if not ($dep.item | check-field kind --types [string] --cp $cp) { return }

                        match $dep.item.kind {
                            "apt" => {
                                if not ($dep.item | check-field package --types [string] --cp $cp) { return }
                                $dep.item | check-extra-fields [ kind, package ] --cp $cp

                                cmd log $"yes | sudo apt install ($dep.item.package)"
                            },
                            "release" | "build" => { log warning $"unsupported kind ($dep.item.kind) for dependencies at ($cp)"; return },
                            _ => { log warning $"unknown kind ($dep.item.kind) at ($cp)"; return },
                        }
                    } | flatten)
                    ...($entry.item.variables | items { |k, v|
                        $"let ($k) = ($v | expand-vars --root '.')"
                    })
                    ...(if $entry.item.checkout? != null {
                        cmd log $"git checkout ($entry.item.checkout)"
                    } else {
                        []
                    })
                    ...($entry.item.build | each {
                        cmd log $"($in | expand-vars --root '.')"
                    } | flatten )
                    ...($entry.item.install | __install "." --cp $cp)
                ]
            },
            _ => { log warning $"unknown kind ($entry.item.kind) at ($cp)"; return },
        }

        $lines | str join "\n"
    }

    for is in $install_scripts {
        print ("=" | repeat (term size).columns | str join "")
        print ($is | lines | where $it !~ '^\s*log info' | str join "\n" | nu-highlight)
        print ("=" | repeat (term size).columns | str join "")

        if not $no_confirm {
            if ([ no, yes ] | input list "Install ?") != "yes" { continue }
        }

        let file = mktemp --tmpdir dotfiles.XXXXXXX
        $is | save --force $file

        ^$nu.current-exe -I (pwd | path join .config nushell modules) $file
    }
}
