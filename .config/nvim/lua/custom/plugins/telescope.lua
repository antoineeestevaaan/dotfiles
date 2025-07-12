return { {
  'nvim-telescope/telescope.nvim',
  enabled = false,
  tag = '0.1.8',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  config = function()
    local telescope = require('telescope')
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")
    local ctelescope = require("custom.telescope")

    telescope.setup {
      defaults = {
        mappings = {
          n = {
            ['L'] = actions.select_vertical,
            ['H'] = actions.select_vertical,
            ['J'] = actions.select_horizontal,
            ['K'] = actions.select_horizontal,
          },
        },
      },
      pickers = {
        find_files = {
          theme = "ivy"
        },
        git_files = {
          theme = "ivy"
        }
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        }
      }
    }

    telescope.load_extension('fzf')

    vim.keymap.set("n", "<leader>fd", function()
      ctelescope.project_files({
        git = { show_untracked = true },
        nogit = { hidden = true },
      })
    end)
    vim.keymap.set("n", "<leader>fh", builtin.help_tags)
    vim.keymap.set("n", "<leader>fg", ctelescope.multigrep)
    vim.keymap.set("n", "<leader>fp", ctelescope.lazy_plugins)
  end
} }
