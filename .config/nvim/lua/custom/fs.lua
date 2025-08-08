local M = {}

--@param path string
--@param lines string[]
function M.write(path, lines)
  local file, err = io.open(path, "w")
  if file then
    file:write(table.concat(lines, "\n"))
    file:close()
  else
    vim.cmd([[echohl ErrorMsg | echomsg "Failed to write ]] .. (err or "unknown error") .. [["]].. [[ | echohl None]])
  end
end

--@param path string
--@return string[]
function M.read(path)
  local file, err = io.open(path, "r")
  if file then
    local content = file:read("a") or ""
    file:close()
    return vim.split(content, "\n", { plain = true })
  else
    vim.cmd([[echohl ErrorMsg | echomsg "Failed to read ]] .. (err or "unknown error") .. [["]].. [[ | echohl None]])
    return {}
  end
end

return M
