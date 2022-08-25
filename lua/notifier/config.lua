local config = {
  ignore_messages = {},
  status_width = (function()
    if vim.o.textwidth ~= 0 then
      return math.floor((vim.o.columns - vim.o.textwidth) * 0.7)
    else
      return math.floor(vim.o.columns / 3)
    end
  end)()
}

local M = {
  NS_ID = vim.api.nvim_create_namespace "notifier",
  NS_NAME = "Notifier",
}

function M.get()
  return config
end

function M.update(other)
  config = vim.tbl_deep_extend("force", config, other or {})
end

function M.hl_group(name)
  return M.NS_NAME .. name
end

M.HL_CONTENT_DIM = M.hl_group "ContentDim"
M.HL_CONTENT = M.hl_group "Content"
M.HL_TITLE = M.hl_group "Title"

vim.api.nvim_set_hl(0, M.HL_CONTENT_DIM, { link = "Comment", default = true })
vim.api.nvim_set_hl(0, M.HL_CONTENT, { link = "Normal", default = true })
vim.api.nvim_set_hl(0, M.HL_TITLE, { link = "Title", default = true })

return M
