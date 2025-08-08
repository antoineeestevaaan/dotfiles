local fs = require("custom.fs")

local M = {}

function M.setup(opts)
  file = opts.file or "/tmp/system-clipboard.txt"

  vim.o.clipboard = opts.clipboard or ""
  vim.g.clipboard = {
    name = "custom clipboard",
    copy = {
      ["+"] = function(lines) fs.write(file, lines) end,
      ["*"] = function(lines) fs.write(file, lines) end,
    },
    paste = {
      ["+"] = function() return fs.read(file) end,
      ["*"] = function() return fs.read(file) end,
    },
    cache_enabled = opts.cache or false,
  }
end

return M
