#!/usr/bin/env -S nu --no-config-file --no-std-lib

use sessionizer.nu [ logln, alternate-session ]

logln ""
logln $"[($env.CURRENT_FILE | path basename) | (date now | format date '%FT%T')]"

alternate-session
