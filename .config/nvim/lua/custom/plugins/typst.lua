return {
  {
    'kaarmu/typst.vim',
    enabled = false,
    ft = 'typst',
    lazy = false,
  },

  {
    'chomosuke/typst-preview.nvim',
    enabled = false,
    ft = 'typst',
    lazy = false,
    version = '0.1.*',
    build = function() require 'typst-preview'.update() end,
  }
}
