#!/usr/bin/env -S nu --no-config-file --no-std-lib

use sessionizer.nu [
    list-sessions, get-current-session, switch-to-session
]

let current = get-current-session

let res = try {
    list-sessions
        | wrap name 
        | insert attached { $in.name == $current } 
        | insert display { $"(if $in.attached { "*" } else { ' ' }) ($in.name)" } 
        | input list --fuzzy --display display
} catch {
    null
}
if $res != null and $res.name != current {
    switch-to-session $res.name
}
