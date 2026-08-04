-- Shared parser-install helper for plugin/nvim_treesitter.lua and any
-- plugin/lang/*.lua file whose plugins touch treesitter queries directly
-- (and so need the parser installed before they run, not just on FileType).

local M = {}

--- Sign parser .so on macOS to prevent code-signature crashes.
---@param parser_name string
local function sign_parser_macos(parser_name)
  if vim.fn.has("mac") ~= 1 then
    return
  end
  local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. parser_name .. ".so"
  if vim.fn.filereadable(parser_path) == 1 then
    vim.fn.system({ "codesign", "--force", "--sign", "-", parser_path })
  end
end

--- Install a parser via nvim-treesitter, if not already installed.
---@param lang string parser/language name
---@return boolean success
function M.ensure_installed(lang)
  if not Config.use_nvim_treesitter then
    return false
  end
  local parsers = require("nvim-treesitter.parsers")
  if not parsers[lang] then
    return false
  end
  require("nvim-treesitter").install({ lang }):wait(30000)
  sign_parser_macos(lang)
  return true
end

return M
