local builtin = require("telescope.builtin")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values
local sorters = require("telescope.sorters")

local M = {}

---@class GitFilesOptions
---@field prompt_title string?
---@field show_untracked boolean?

---@class NoGitFilesOptions
---@field prompt_title string?
---@field hidden boolean?

---@class ProjectFilesOptions
---@field git GitFilesOptions
---@field nogit NoGitFilesOptions

---@param opts ProjectFilesOptions
M.project_files = function(opts)
  opts = opts or {}
  opts.git = opts.git or {}
  opts.nogit = opts.nogit or {}

  vim.fn.system("git rev-parse --is-inside-work-tree")

  if vim.v.shell_error == 0 then
    opts.prompt_title = opts.git.prompt_title or "Find Git files..."
    opts.show_untracked = opts.git.show_untracked or false
    builtin.git_files(opts)
  else
    opts.prompt_title = opts.nogit.prompt_title or "Find files..."
    opts.hidden = opts.nogit.hidden or false
    builtin.find_files(opts)
  end
end

---@class MultiGrepOptions
---@field cwd string?

---@param opts MultiGrepOptions
M.multigrep = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt --[[@param prompt string]])
      if not prompt or prompt == "" then
        return nil
      end

      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }
      if pieces[1] then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end
      if pieces[2] then
        table.insert(args, "-g")
        table.insert(args, pieces[2])
      end

      ---@diagnostic disable-next-line: deprecated
      return vim.tbl_flatten {
        args,
        { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case" }
      }
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers.new(opts, {
    debounce = 100,
    prompt_title = "Multi Grep",
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorters = sorters.empty(),
  }):find()
end

M.lazy_plugins = function()
  local lazypath = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
  builtin.find_files {
    prompt_title = "Explore LazyVim plugin files from " .. lazypath .. "...",
    results_title = false,
    preview_title = false,
    cwd = lazypath,
  }
end

return M
