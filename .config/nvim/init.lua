vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

term = os.getenv("TERM")
if     term == "linux"          then theme = "ron"
elseif term == "xterm-256color" then theme = "default"
elseif term == "st-256color"    then theme = "default"
else                                 theme = "default"
end
vim.cmd.colorscheme(theme)

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
  pattern = '*',
})

-- Highlight trailing whitespaces
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  pattern = "*",
  callback = function()
    local extra_whitespaces = ""

    if require("custom.list").is_in(vim.bo.filetype, {
          "", "aerial", "help", "presenting_markdown", "neo-tree", "git"
        }) then
      extra_whitespaces = "//"
    else
      extra_whitespaces = "/\\s\\+$\\|\\t/"
    end

    local color = "darkred"

    vim.cmd {
      cmd = "highlight",
      args = {
        "ExtraWhitespace",
        string.format("ctermbg=%s", color),
        string.format("guibg=%s", color)
      },
      bang = false,
    }

    vim.cmd {
      cmd = "match",
      args = { "ExtraWhitespace", extra_whitespaces },
      bang = false,
    }
  end
})
