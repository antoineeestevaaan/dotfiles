#!/usr/bin/env -S nu --no-config-file --no-std-lib

use sessionizer.nu [ logln, alternate-session ]

logln ""
logln "ALTERNATE"
alternate-session
