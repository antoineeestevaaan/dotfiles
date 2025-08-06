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
vim.o.winborder      = "rounded"

vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim"                   , version = "bbad9a76b2617ce1221d49619e4e4b659b3c61fc" },
  { src = "https://github.com/neovim/nvim-lspconfig"               , version = "d0dbf489a8810672fa9a61f4a86e5cf89214b772" },
  { src = "https://github.com/tpope/vim-sleuth"                    , version = "be69bff86754b1aa5adcbb527d7fcd1635a84080" },
  { src = "https://github.com/tpope/vim-fugitive"                  , version = "61b51c09b7c9ce04e821f6cf76ea4f6f903e3cf4" },
  { src = "https://github.com/tpope/vim-rhubarb"                   , version = "5496d7c94581c4c9ad7430357449bb57fc59f501" },
  { src = "https://github.com/lewis6991/gitsigns.nvim"             , version = "8270378ab83540b03d09c0194ba3e208f9d0cb72" },
  { src = "https://github.com/theprimeagen/harpoon"                , version = "1bc17e3e42ea3c46b33c0bbad6a880792692a1b3" },
  { src = "https://github.com/nvim-lua/plenary.nvim"               , version = "b9fd5226c2f76c951fc8ed5923d85e4de065e509" },
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim" , version = "005b56001b2cb30bfa61b7986bc50657816ba4ba" },
  { src = "https://github.com/ggandor/leap.nvim"                   , version = "02bf52e49c72cc5dabb53ec9494d10d304f0b2c9" },
  { src = "https://github.com/christoomey/vim-tmux-navigator"      , version = "c45243dc1f32ac6bcf6068e5300f3b2b237e576a" },
  { src = "https://github.com/mbbill/undotree"                     , version = "28f2f54a34baff90ea6f4a735ef1813ad875c743" },
  { src = "https://github.com/echasnovski/mini.pick"               , version = "82ec629ca108c7b96b8b9bb733d235b39e137690" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter"     , version = "42fc28ba918343ebfd5565147a42a26580579482" },
})

local oil = require("oil")
local gs = require("gitsigns")
local harpoon_mark = require("harpoon.mark")
local harpoon_ui = require("harpoon.ui")
local ibl = require("ibl")
local leap = require("leap")
local mini_pick = require("mini.pick")
local nvim_treesitter_configs = require("nvim-treesitter.configs")

vim.lsp.enable({ "lua_ls", "tinymist", "clangd", "nushell" })
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      }
    }
  }
})

nvim_treesitter_configs.setup({
  ensure_installed = { "nu" },
  highlight = { enable = true },
})

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.nu = {
  install_info = {
    url = "https://github.com/nushell/tree-sitter-nu",
    files = { "src/parser.c", "src/scanner.c" },
    rev = "6544c4383643cf8608d50def2247a7af8314e148",
    generate_requires_npm = false,
    requires_generate_from_grammar = false,
  },
  filetype = "nu",
}

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
ibl.setup({
  indent = { char = "." }
})
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
vim.keymap.set("n", '<leader>le', vim.diagnostic.open_float)
vim.keymap.set("n", '<leader>lq', vim.diagnostic.setloclist)
vim.keymap.set('n', '<leader>ln', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>lr', vim.lsp.buf.references)
vim.keymap.set('n', '<leader>ld', vim.lsp.buf.definition)
vim.keymap.set("n", '<leader>li', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end)
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
