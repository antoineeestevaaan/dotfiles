export PATH="$HOME/.cargo/bin:$PATH"

if [[ $(fgconsole 2> /dev/null) == 1 ]]; then
    exec tmux new-session -A -s "0" -c "nu --login"
else
    [[ -f ~/.bashrc ]] && . ~/.bashrc
fi
