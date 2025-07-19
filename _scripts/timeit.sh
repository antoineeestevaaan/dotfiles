#!/usr/bin/env bash
ts=$(date +%s%N)
$@
echo $(($(date +%s%N) - $ts))
