loop {
    let ret = vcgencmd pmic_read_adc
        | lines
        | parse --regex '\s*(?<name>.*)_[V|A] (?<type>.*)\((?<id>\d+)\)=(?<value>.*).'
        | group-by name --to-table
        | update items { select type value | transpose --header-row | into record }
        | flatten
        | upsert current { if $in != null { into float } }
        | upsert volt { if $in != null { into float } }
        | insert power {
            $in | if $in.current? != null and $in.volt? != null { $in.current * $in.volt }
        }

    let v = $ret | where name == EXT5V | into record | get volt
    let p = $ret | default 0.0 power | get power | math sum

    print $"($v) ($p)"
    sleep 500ms
}
