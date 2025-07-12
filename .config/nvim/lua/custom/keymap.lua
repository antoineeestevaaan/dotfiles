local M = {}

---@param keys string
---@param func string|function
---@param desc string
---@param bufnr integer
function M.nmap(keys, func, desc, bufnr)
  vim.keymap.set('n', keys, func, { buffer = bufnr, silent = true, noremap = true, desc = desc })
end

return M
