vim.opt.clipboard = ""

vim.opt.cursorline = true
vim.opt.cursorcolumn = true

vim.opt.colorcolumn = "81,101"

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wrap = false

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.hlsearch = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.smartcase = true
vim.opt.ignorecase = true

vim.opt.formatoptions:remove "o"

vim.opt.signcolumn = "yes"

vim.opt.inccommand = "nosplit"

vim.opt.shell = "/bin/bash"

vim.opt.list = true
vim.opt.listchars = {
    tab = '» ', trail = '·', extends = '>', precedes = '<', nbsp = '␣'
}
