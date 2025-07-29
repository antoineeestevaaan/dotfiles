if [[ $(fgconsole 2> /dev/null) == 1 ]]; then
    exec tmux new-session -A -s "0" -c "~/.cargo/bin/nu --login"
else
    [[ -f ~/.bashrc ]] && . ~/.bashrc
fi
