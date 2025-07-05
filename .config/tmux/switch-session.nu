#!/usr/bin/env -S nu --no-config-file --no-std-lib

use sessionizer.nu [
    list-sessions, get-current-session, switch-to-session, logln, save-session
]

logln ""
logln $"[($env.CURRENT_FILE | path basename) | (date now | format date '%FT%T')]"

let current = get-current-session

let res = try {
    list-sessions
        | wrap name 
        | insert attached { $in.name == $current } 
        | insert display { $"(if $in.attached { "*" } else { ' ' }) ($in.name)" } 
        | input list --fuzzy --display display "Select a session to switch to:"
} catch {
    null
}
if $res != null and $res.name != current {
    save-session $current
    switch-to-session $res.name
}
