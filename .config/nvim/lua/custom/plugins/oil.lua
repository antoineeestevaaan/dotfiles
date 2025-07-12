return {
  'stevearc/oil.nvim',
  enabled = true,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local oil = require("oil")

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

    vim.keymap.set("n", "-", oil.open)
    vim.keymap.set("n", "<leader>-", oil.toggle_float)
  end,
}
