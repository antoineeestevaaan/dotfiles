vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({ { import = 'custom.plugins' } }, {})

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
