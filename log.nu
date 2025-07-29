export def "str color" [color: string]: [ string -> string ] {
    $"(ansi $color)($in)(ansi reset)"
}

def level-to-int []: [ string -> int ] {
    match ($in | str trim) {
        "FATAL"                =>  0,
        "ERROR"                => 10,
        "WARNING"              => 20,
        "INFO" | "OK" | "HINT" => 30,
        "HINT" | "DEBUG"       => 40,
        "TRACE"                => 50,
        _                      => 30,
    }
}

def log [level: string, color: string, msg: string] {
    let min_level = $env.LOG_LEVEL? | default "INFO"
    if ($level | level-to-int) <= ($min_level | level-to-int) {
        print $"[($level | str color $color)] ($msg)"
    }
}

export def "log fatal"   [msg: string] { log "FATAL"   "red_bold"       $msg }
export def "log error"   [msg: string] { log "ERROR"   "red"            $msg }
export def "log warning" [msg: string] { log "WARNING" "yellow"         $msg }
export def "log info"    [msg: string] { log "INFO"    "cyan"           $msg }
export def "log debug"   [msg: string] { log "DEBUG"   "default_dimmed" $msg }
export def "log ok"      [msg: string] { log "OK"      "green"          $msg }
export def "log hint"    [msg: string] { log "HINT"    "purple"         $msg }
export def "log trace"   [msg: string] { log "TRACE"   "black_dimmed"   $msg }
