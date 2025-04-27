-- lua/smartfolds/init.lua

local M = {}

function M.setup()
  vim.opt.foldtext = "v:lua.require'smartfolds'.foldtext()"
end

--- Generate a custom fold text using Tree-sitter.
---
--- This function parses the current buffer using Tree-sitter,
--- and tries to find a function declaration within the folded region.
--- If a function is found, it extracts and returns its signature as the fold text.
--- Otherwise, it falls back to using the first line of the folded region.
---
--- @param foldstart integer: The starting line number (1-indexed) of the folded region.
--- @param foldend integer: The ending line number (1-indexed) of the folded region.
--- @return string: The custom fold text to be displayed.
local function get_fold_text(foldstart, foldend)
  local ts = vim.treesitter
  local parser = ts.get_parser()

  if parser == nil then
    error("Couldn't find a parser attached to the current buffer")
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local function_signature = nil

  for node in root:iter_children() do
    local start_row, _, end_row, _ = node:range()
    if start_row + 1 >= foldstart and end_row <= foldend then
      local node_type = node:type()
      if node_type == "function_declaration" then
        function_signature = vim.treesitter.get_node_text(node, 0)
      end
    end
  end

  -- If found a function, return it
  if function_signature then
    local first_line = vim.split(function_signature, "\n")[1]
    return "> ƒ " .. first_line
  end

  -- Fallback: get first line of fold
  local first_line = vim.api.nvim_buf_get_lines(0, vim.v.foldstart - 1, vim.v.foldstart, false)[1] or "Folded Code"
  first_line = first_line:gsub("^%s+", "") -- trim leading spaces

  return "> " .. first_line
end

M.foldtext = function()
  return get_fold_text(vim.v.foldstart, vim.v.foldend)
end

return M
