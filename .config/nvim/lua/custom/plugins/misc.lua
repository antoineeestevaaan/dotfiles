return {
  {
    "laytan/cloak.nvim",
    enabled = false,
    config = function()
      require('cloak').setup({
        enabled = true,
        cloak_character = '*',
        highlight_group = 'Comment',
        cloak_length = nil,
        patterns = {
          {
            file_pattern = '.env*',
            cloak_pattern = { '=.+', ':.+', '-.+' }
          },
        },
      })
    end
  },

  {
    "folke/todo-comments.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    config = function()
      require("todo-comments").setup {}

      vim.keymap.set("n", "<leader>tc", ":TodoTelescope<CR>")
    end
  },

  {
    "folke/twilight.nvim",
    enabled = false,
  },

  {
    "christoomey/vim-tmux-navigator",
    enabled = true,
  },

  {
    "KilianVounckx/nvim-tetris",
    commit = "3a791b74bbee29e2e4452d2776415de4f3f3e08b",
    enabled = false,
  },
}
