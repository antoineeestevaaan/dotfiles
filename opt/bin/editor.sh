#!/bin/bash

if command -v nvim &> /dev/null; then
    exec nvim "$@"
else
    exec vim "$@"
fi
