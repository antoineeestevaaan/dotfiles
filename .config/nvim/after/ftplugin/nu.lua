local format = function(range)
  if vim.bo.filetype ~= "nu" then
    print "not a Nushell buffer"
  else
    print("formatting " .. range)
    pcall(function() vim.cmd(":" .. range .. [[s/\([a-zA-Z"\])}0-9]\)\s*|\s*/\1\r    | /g]]) end)
    pcall(function() vim.cmd(":" .. range .. [[s/^\s*|/    |/]]) end)
  end
end

vim.keymap.set("n", "<leader>lf", function() format("%") end)
vim.keymap.set("v", "<leader>lf", function() format("'<,'>") end)
