local M = {}

-- return `true` if the `v` is inside the `values`, `false` otherwise
--
---@generic T: any
---@param v T
---@param values T[]
---@return boolean
function M.is_in(v, values)
  for _, item in ipairs(values) do
    if v == item then
      return true
    end
  end
  return false
end

return M
