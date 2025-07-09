term = os.getenv("TERM")
if     term == "linux"          then theme = "ron"
elseif term == "xterm-256color" then theme = "default"
elseif term == "st-256color"    then theme = "default"
else                                 theme = "default"
end
vim.cmd.colorscheme(theme)
