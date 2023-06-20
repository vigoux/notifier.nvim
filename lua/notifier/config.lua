---@class Notifier.NotifyCfg
---@field clear_time integer Time to wait before poping the notification
---@field min_level vim.log.Level Minimum log level to consider

---@class Notifier.Config
---@field ignore_messages {string: boolean} TODO
---@field status_width (integer|function(): integer) Width or function to compute width
---@field components string[] Components to activate
---@field notify Notifier.NotifyCfg Configuration for the notify component
---@field component_name_recall boolean Whether to recall the component name in the notifier UI
---@field debug boolean
---@field zindex integer zindex of the UI floating window

---@type Notifier.Config
local config = {
  ignore_messages = {},
  status_width = function()
    local tw = vim.o.textwidth
    local cols = vim.o.columns
    if tw > 0 and tw < cols then
      return math.floor((cols - tw) * 0.7)
    else
      return math.floor(cols / 3)
    end
  end,
  components = { 'nvim', 'lsp' },
  notify = {
    clear_time = 5000,
    min_level = vim.log.levels.INFO,
  },
  component_name_recall = false,
  debug = false,
  zindex = 50,
}

local M = {}

M.NS_NAME = 'Notifier'
M.NS_ID = vim.api.nvim_create_namespace('notifier')


---Updates the configuration to match @p other
---@param other Notifier.Config The new configuration
function M.update(other)
  config = vim.tbl_deep_extend('force', config, other or {})
end

--- Checks whether a component is enabled
---@param compname string The component name to check
---@return boolean enabled Whether the componenent is enabled
function M.has_component(compname)
  return vim.tbl_contains(config.components, compname)
end

--- Creates and sets a highlight group.
---@param name string Short name of the highlight group
---@param options any Options to nvim_set_hl
---@return string hlgroup Name of the created highlight group
---@private
local function hl_group(name, options)
  local hl_name = M.NS_NAME .. name
  vim.api.nvim_set_hl(0, hl_name, options)
  return hl_name
end

M.HL_CONTENT_DIM = hl_group('ContentDim', { link = 'Comment', default = true })
M.HL_CONTENT = hl_group('Content', { link = 'Normal', default = true })
M.HL_TITLE = hl_group('Title', { link = 'Title', default = true })
M.HL_ICON = hl_group('Icon', { link = 'Title', default = true })

if vim.api.nvim_win_set_hl_ns then
  vim.api.nvim_set_hl(M.NS_ID, 'NormalFloat', { bg = 'NONE' })
end

return M
