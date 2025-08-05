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
    log.nu
    bootstrap.sh,
    applications.nuon,
    lock.json,
    TODO.txt,
]

const LINK_STATUS = {
    ok           : 0
    skipped_file : 1
    forced_file  : 2
    skipped_link : 3
    forced_link  : 4
}

def link-file [
    file: record<src: string, dest: string>,
    --git-files: list<string>,
    --force,
    --dry-run,
    --sudo,
] {
    let res = if $sudo {
        sudo $nu.current-exe -c $"try { ls ($file.dest) } catch { [] } | length" | into int
    } else {
        try { ls $file.dest } catch { [] } | length
    }
    let status = if $res != 0 {
        let target = if $sudo {
            sudo $nu.current-exe -c $"try { ls -l ($file.dest) | to nuon }" | from nuon | get 0.target
        } else {
            try { ls -l $file.dest | get 0.target }
        }

        log trace $"($file.dest) -> ($target)"
        if $target == null {
            if not $force { $LINK_STATUS.skipped_file } else { $LINK_STATUS.forced_file }
        } else if $target not-in ($git_files) {
            if not $force { $LINK_STATUS.skipped_link } else { $LINK_STATUS.forced_link }
        } else {
            $LINK_STATUS.ok
        }
    } else {
        $LINK_STATUS.ok
    }

    if $status in [ $LINK_STATUS.ok, $LINK_STATUS.forced_file, $LINK_STATUS.forced_link ] {
        if        $status == $LINK_STATUS.ok          { log debug   $"     ($file.src)"
        } else if $status == $LINK_STATUS.forced_file { log warning $"    (ansi yellow)#(ansi reset)($file.src)"
        } else if $status == $LINK_STATUS.forced_link { log warning $"    (ansi yellow)*(ansi reset)($file.src)"
        } else { log fatal "UNREACHABLE" }

        let src = $file.src | path expand

        if not $dry_run {
            if $sudo {
                sudo mkdir ($file.dest | path dirname)
                sudo ln --symbolic --force $src $file.dest
            } else {
                mkdir ($file.dest | path dirname)
                ln --symbolic --force $src $file.dest
            }
        }
    } else if $status == $LINK_STATUS.skipped_file { log error $"    (ansi red   )#(ansi reset)($file.src)"
    } else if $status == $LINK_STATUS.skipped_link { log error $"    (ansi red   )*(ansi reset)($file.src)"
    } else { log fatal "UNREACHABLE" }
}

export def link [--config, --system, --dry-run, --force] {
    let git_files = git ls-files --full-name | lines | each { |it| pwd | path join $it }

    if $config or not $system {
        log info $"gathering config files..."
        let config_files = find-files --strip-prefix --exclude $NOT_CONFIG_FILE_PATTERN

        log info $"linking config files to (ansi magenta)~(ansi reset)"
        $config_files | each { |it|
            link-file --git-files $git_files --force=$force --dry-run=$dry_run {
                src: $it,
                dest: ($nu.home-path | path join $it),
            }
        }
    }

    if $system or not $config {
        log info $"gathering system files..."
        let system_files = find-files --strip-prefix (pwd) --pattern $SYSTEM_FILE_PATTERN

        log warning $"linking system files to (ansi magenta)/(ansi reset)"
        $system_files | each { |it|
            link-file --git-files $git_files --force=$force --dry-run=$dry_run --sudo {
                src: $it,
                dest: ($it | str replace --regex '^@' '/'),
            }
        }
    }
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

def expand-const-vars [--root: string]: [ string -> string ] {
    $in
        | str replace --all '{{$OPT_DIR}}' $'"($OPT_DIR)"'
        | str replace --all '{{$ROOT}}' $root
}

def expand-vars [vars: record, --root: string, --wrap]: [ string -> string ] {
    let input = $in
    $vars | transpose k v | reduce --fold ($input | expand-const-vars --root $root) { |it, acc|
        $acc | str replace --all $"{{$($it.k)}}" (if $wrap { $"\(($it.v)\)" } else { $it.v })
    }
    | expand-const-vars --root $root
}

def "cmd log" [cmd: string, --indent: int = 4, --indent-level: int = 0]: [ nothing -> list<string> ] {
    let indentation = " " | repeat ($indent_level * $indent) | str join ""
    [
        $"($indentation)log info \"($cmd | str trim | nu-highlight)\""
        $cmd
    ]
}

def lock-app [
    name: string,
    value_block_lines: list<string>,
]: [ nothing -> list<string> ] {
    [
       $"try { open (pwd)/lock.json }"
        "    | default {}"
       $"    | upsert ($name) {"
        ...($value_block_lines | each { $"        ($in)" })
        "    }"
        "    | transpose k v"
        "    | sort-by k"
        "    | transpose --header-row"
        "    | into record"
       $"    | collect { save --force (pwd)/lock.json }"
    ]
    | each { $"($in) #" }
}

def __system [--cp: cell-path]: [ record -> list<string> ] {
    if not ($in | check-field package --types [record] --cp $cp) { return }
    $in | check-extra-fields [ name, kind, package ] --cp $cp

    let cp = $cp | split cell-path | append "package" | into cell-path
    if not ($in.package | check-field apt --types [string] --cp $cp) { return }
    $in.package | check-extra-fields [ name, kind, apt ] --cp $cp

    [
        ...(cmd log $"yes | sudo apt install ($in.package.apt)")
        ...(lock-app $in.name [
            "apt list --installed"
            "    | lines"
            "    | parse \"{name}/{tags} {version} {arch} [{status}]\""
            "    | update tags { split row ',' }"
            "    | update status { split row ',' }"
           $"    | where name == ($in.package.apt)"
            "    | into record"
            "    | get version"
           $"    | $\"apt.($in.package.apt)@\($in\)\""
        ])
    ]
}

def __curl [--cp: cell-path]: [ record -> list<string> ] {
    if not ($in | check-field url --types [string] --cp $cp) { return }
    $in | check-extra-fields [ name, kind, url, args, run, variables, install ] --cp $cp

    let entry = $in | default [] args | default {} variables | default [] install
    let url = $in.url | expand-vars $entry.variables --root $nu.temp-path
    let archive_path = $url | url parse | get path | path parse | update parent $nu.temp-path | path join
    let vars = {
        ...$entry.variables,
        ARCHIVE: ($archive_path | path parse --extension "tar.gz" | get stem),
    }
    let root = $nu.temp-path | path join $vars.ARCHIVE

    [
        ...(if not ($entry.run? | is-empty) {[
            ...(cmd log $"curl ($entry.args | str join ' ') ($url) | ($entry.run)")
        ]} else {[
            ...(cmd log $"curl -fLo ($archive_path) ($entry.args | str join ' ') ($url)")
            ...(cmd log $"mkdir ($nu.temp-path | path join $vars.ARCHIVE)")
            ...(cmd log $"tar xvf ($archive_path) --directory ($nu.temp-path | path join $vars.ARCHIVE)")
        ]}),
        ...($entry.install | __install $vars $root --cp $cp)
    ]
}

def __git [--cp: cell-path]: [ record -> list<string> ] {
    if not ($in | check-field git     --types [string]      --cp $cp) { return }
    if not ($in | check-field build   --types [list]        --cp $cp) { return }
    if not ($in | check-field install --types [list, table] --cp $cp) { return }
    $in | check-extra-fields [ name, kind, git, build, install, variables, deps, checkout ] --cp $cp

    let entry = $in | default {} variables | default [] deps
    let vars = $entry.variables? | default {}
    let git_repo_root = '.'

    let cache = [
        $nu.home-path
        .cache
        antoineeestevaaan
        doffiles
        ($entry.git | url parse | $in.host + $in.path)
    ] | path join

    [
        $"if not \(\"($cache)\" | path exists\) {"
        ...(cmd log $"    git clone ($entry.git) ($cache)" --indent-level 1)
        "}"
        ...(cmd log $"cd ($cache)")
        ...(cmd log $"git fetch")
        ...($entry.deps | enumerate | each { |dep|
            let cp = $cp | split cell-path | append [ "deps" $dep.index ] | into cell-path

            if not ($dep.item | check-field kind --types [string] --cp $cp) { return }

            match $dep.item.kind {
                "system" => { $dep.item | __system --cp $cp },
                "curl" => { $dep.item | __curl --cp $cp },
                "git" => { $dep.item | __git --cp $cp },
                _ => { log warning $"unknown kind ($dep.item.kind) at ($cp)"; return },
            }
        } | flatten)
        ...(if $entry.checkout? != null { cmd log $"git checkout ($entry.checkout)" } else { [] })
        ...($entry.build | each { cmd log $"($in | expand-vars $vars --root $git_repo_root --wrap)" } | flatten )
        ...($entry.install | __install $vars $git_repo_root --cp $cp)
        ...(lock-app $entry.name [ $"$\"($entry.git)@\(git rev-parse HEAD\)\"" ])
    ]
}

def __install [vars: record, root: string, --cp: cell-path]: [ list -> list<string>, table -> list<string> ] {
    if ($in | is-empty) {
        log warning $"nothing to install at ($cp)"
        return []
    }

    let cp = $cp | split cell-path | append "install" | into cell-path

    $in | enumerate | each { |i|
        let cp = $cp | split cell-path | append $i.index | into cell-path

        if not ($i.item | check-field kind --types [string] --cp $cp) { return [] }

        match $i.item.kind {
            "bin" => {
                if not ($i.item | check-field path --types [string] --cp $cp) { return [] }
                $i.item | check-extra-fields [ name, kind, path ] --cp $cp

                let raw_src = $i.item.path | expand-vars $vars --root $root
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
                $i.item | check-extra-fields [ name, kind, pages ] --cp $cp

                [
                    ...(cmd log $"mkdir ($MAN1_DIR)")
                    ...($i.item.pages | each { |it|
                        let src_glob = $it | expand-vars $vars --root $root
                        let dest = $MAN1_DIR
                        cmd log $"cp --verbose \(\"($src_glob)\" | into glob\) \"($dest)\""
                    } | flatten)
                ]
            },
            "link" => {
                if not ($i.item | check-field path --types [string] --cp $cp) { return [] }
                $i.item | check-extra-fields [ name, kind, path ] --cp $cp

                let raw_src = $i.item.path | expand-vars $vars --root $root
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
                    ...(cmd log $"ln --verbose --force --symbolic ($src) ($dest)"),
                ]
            }
            _ => { log warning $"unknown kind ($i.item.kind) at ($cp)"; return [] },
        }
    } | flatten
}

@example "install everything"                       { make install applications.nuon }
@example "install without interactive confirmation" { make install --no-confirm applications.nuon }
@example "select what to install, e.g. Neovim"      { open applications.nuon | where name == neovim | make install --from-stdin }
export def "install" [
    file?: path,
    --from-stdin,
    --no-confirm (-y),
    --dry-run,
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
            "system" => { $entry.item | __system --cp $cp },
            "curl" => { $entry.item | __curl --cp $cp },
            "git" => { $entry.item | __git --cp $cp },
            _ => { log warning $"unknown kind ($entry.item.kind) at ($cp)"; return },
        }

        [
            $"use (pwd | path join .config nushell modules misc) \"make\""
            $"use (pwd | path join make.nu)"
            $"use (pwd | path join log.nu) *"
            ...$lines
        ] | str join "\n"
    }

    for is in $install_scripts {
        let file = mktemp --tmpdir dotfiles.XXXXXXX
        $is | save --force $file

        print ("=" | repeat (term size).columns | str join "")
        print $"(ansi default_dimmed)# complete script: ($file)(ansi reset)"
        print ($is | lines | where $it !~ '^\s*log info |^\s*use | #$' | str join "\n" | nu-highlight)
        print ("=" | repeat (term size).columns | str join "")

        if not $no_confirm {
            if ([ no, yes ] | input list "Install ?") != "yes" { continue }
        }

        if not $dry_run {
            ^$nu.current-exe -I (pwd | path join .config nushell modules) $file
        }
    }
}
