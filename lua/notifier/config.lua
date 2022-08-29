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
   components = { "nvim", "lsp" },
   notify = {
      clear_time = 1000,
      min_level = vim.log.levels.INFO,
   },
   component_name_recall = false,
}

function ConfigModule.update(other)
   ConfigModule.config = vim.tbl_deep_extend("force", ConfigModule.config, other or {})
end

function ConfigModule.has_component(compname)
   return vim.tbl_contains(ConfigModule.config.components, compname)
end

local function hl_group(name, options)
   local hl_name = ConfigModule.NS_NAME .. name
   vim.api.nvim_set_hl(0, hl_name, options)
   return hl_name
end


ConfigModule.HL_CONTENT_DIM = hl_group("ContentDim", { link = "Comment", default = true })
ConfigModule.HL_CONTENT = hl_group("Content", { link = "Normal", default = true })
ConfigModule.HL_TITLE = hl_group("Title", { link = "Title", default = true })


vim.api.nvim_set_hl(ConfigModule.NS_ID, "NormalFloat", { bg = "bg" })

return ConfigModule
