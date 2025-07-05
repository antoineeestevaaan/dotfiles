#!/usr/bin/env -S nu --no-config-file --no-std-lib

use sessionizer.nu [
    list-sessions, get-current-session, create-session, switch-to-session, kill-session, logln, save-session
]

logln ""
logln $"[($env.CURRENT_FILE | path basename) | (date now | format date '%FT%T')]"

let current = get-current-session

let res = try {
    list-sessions
        | wrap name 
        | insert attached { $in.name == $current } 
        | insert display { $"(if $in.attached { "*" } else { ' ' }) ($in.name)" } 
        | input list --fuzzy --display display "Select a session to kill:"
} catch {
    null
}
if $res != null {
    if $res.name == $current {
        let name = random uuid | hash sha256
        create-session $name
        save-session "__NOT_A_SESSION__"
        switch-to-session $name
    }
    kill-session $res.name
}
