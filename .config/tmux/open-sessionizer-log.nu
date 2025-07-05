#!/usr/bin/env -S nu --no-config-file --no-std-lib

use sessionizer.nu LOG_FILE

^($env.EDITOR? | default vim) $LOG_FILE
