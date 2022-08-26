local ConfigModule = {Config = {Notify = {}, }, }
























ConfigModule.NS_NAME = "Notifier"
ConfigModule.NS_ID = vim.api.nvim_create_namespace("notifier")

ConfigModule.config = {
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
   order = { "nvim", "lsp" },
   notify = {
      clear_time = 1000,
      min_level = vim.log.levels.INFO,
   },
   component_name_recall = false,
}

function ConfigModule.update(other)
   ConfigModule.config = vim.tbl_deep_extend("force", ConfigModule.config, other or {})
end

local function hl_group(name)
   return ConfigModule.NS_NAME .. name
end

ConfigModule.HL_CONTENT_DIM = hl_group("ContentDim")
ConfigModule.HL_CONTENT = hl_group("Content")
ConfigModule.HL_TITLE = hl_group("Title")

vim.api.nvim_set_hl(0, ConfigModule.HL_CONTENT_DIM, { link = "Comment", default = true })
vim.api.nvim_set_hl(0, ConfigModule.HL_CONTENT, { link = "Normal", default = true })
vim.api.nvim_set_hl(0, ConfigModule.HL_TITLE, { link = "Title", default = true })

return ConfigModule
