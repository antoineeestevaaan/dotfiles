local M = {}


--@param path string
--@return bool
function M.is_git_repo(path)
  local cmd = string.format('git -C "%s" rev-parse --is-inside-work-tree 2> /dev/null', path)

  local f = io.popen(cmd)
  local result = f:read("*a")
  f.close()

  return result:match("true") ~= nil
end

return M
