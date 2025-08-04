vim.g.mapleader = " "

vim.o.clipboard      = ""
vim.o.cursorline     = true
vim.o.cursorcolumn   = true
vim.o.colorcolumn    = "81,101"
vim.o.number         = true
vim.o.relativenumber = true
vim.o.wrap           = false
vim.o.expandtab      = true
vim.o.shiftwidth     = 4
vim.o.tabstop        = 4
vim.o.scrolloff      = 8
vim.o.sidescrolloff  = 8
vim.o.hlsearch       = true
vim.o.splitbelow     = true
vim.o.splitright     = true
vim.o.smartcase      = true
vim.o.ignorecase     = true
vim.o.signcolumn     = "yes"
vim.o.inccommand     = "nosplit"
vim.o.shell          = "/bin/bash"
vim.o.list           = true
vim.o.listchars      = "tab:» ,trail:·,extends:>,precedes:<,nbsp:␣"
vim.o.swapfile       = false

vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/tpope/vim-sleuth" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/tpope/vim-rhubarb" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/theprimeagen/harpoon" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
  { src = "https://github.com/ggandor/leap.nvim" },
  { src = "https://github.com/christoomey/vim-tmux-navigator" },
  { src = "https://github.com/mbbill/undotree" },
  { src = "https://github.com/echasnovski/mini.pick" },
})

local oil = require("oil")
local gs = require("gitsigns")
local harpoon_mark = require("harpoon.mark")
local harpoon_ui = require("harpoon.ui")
local ibl = require("ibl")
local leap = require("leap")
local mini_pick = require("mini.pick")

vim.lsp.enable({ "lua_ls" })

oil.setup {
  default_file_explorer = true,
  watch_for_changes = false,
  columns = {
    "icon",
    { "permissions", highlight = "Floatborder" },
    { "size",        highlight = "MatchParen" },
    { "mtime",       highlight = "Whitespace", format = "%Y-%m-%d %T" },
  },
  skip_confirm_for_simple_edits = true,
  prompt_save_on_select_new_entry = true,
  keymaps = {
    ["<C-h>"] = false,
    ["<M-h>"] = "actions.select_split",
  },
  view_options = {
    show_hidden = true,
  },
}
ibl.setup()
leap.add_default_mappings()
mini_pick.setup()

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.buffer = bufnr
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- oil
vim.keymap.set("n", "-", oil.open)
-- LSP
vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format)
-- gitsigns
map('n', '<leader>gp', function() gs.nav_hunk("prev") end)
map('n', '<leader>gn', function() gs.nav_hunk("next") end)
map('n', '<leader>gs', gs.stage_hunk)
map('v', '<leader>gs', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end)
map('n', '<leader>gr', gs.reset_hunk)
map('n', '<leader>gu', gs.undo_stage_hunk)
map('n', '<leader>gS', gs.stage_buffer)
map('v', '<leader>gr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end)
map('n', '<leader>gR', gs.reset_buffer)
map('n', '<leader>gP', gs.preview_hunk)
map('n', '<leader>gb', function() gs.blame_line { full = false } end)
map('n', '<leader>gd', gs.diffthis)
map('n', '<leader>gD', function() gs.diffthis '~' end)
map('n', '<leader>gtb', gs.toggle_current_line_blame)
map('n', '<leader>gtd', gs.toggle_deleted)
-- harpoon
vim.keymap.set("n", "<leader>ha", harpoon_mark.add_file)
vim.keymap.set("n", "<leader>he", harpoon_ui.toggle_quick_menu)
vim.keymap.set("n", "<leader>hh", function() harpoon_ui.nav_file(1) end)
vim.keymap.set("n", "<leader>hj", function() harpoon_ui.nav_file(2) end)
vim.keymap.set("n", "<leader>hk", function() harpoon_ui.nav_file(3) end)
vim.keymap.set("n", "<leader>hl", function() harpoon_ui.nav_file(4) end)
-- undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
-- mini.pick
vim.keymap.set("n", "<leader>ff", function() mini_pick.builtin.files({ tool = "git" }) end)
vim.keymap.set("n", "<leader>fh", ":Pick help<CR>")

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
