local record ConfigModule
  record Config
    ignore_messages: {string:boolean}
    status_width: integer
    order: {string}
    notify_clear_time: integer
    component_name_recall: boolean
  end

  update: function(Config)
  config: Config

  NS_NAME: string
  NS_ID: integer

  -- Highlight groups
  HL_CONTENT_DIM: string
  HL_CONTENT: string
  HL_TITLE: string
end

ConfigModule.NS_NAME = "Notifier"
ConfigModule.NS_ID = vim.api.nvim_create_namespace "notifier"

ConfigModule.config = {
  ignore_messages = {},
  status_width = (function(): integer
    if vim.o.textwidth ~= 0 then
      return math.floor((vim.o.columns - vim.o.textwidth) * 0.7)
    else
      return math.floor(vim.o.columns / 3)
    end
  end)(),
  order = { "nvim", "lsp" },
  notify_clear_time = 1000,
  component_name_recall = false,
}

function ConfigModule.update(other: ConfigModule.Config)
  ConfigModule.config = vim.tbl_deep_extend("force", ConfigModule.config as {string:any}, other as {string:any} or {}) as ConfigModule.Config
end

local function hl_group(name: string): string
  return ConfigModule.NS_NAME .. name
end

ConfigModule.HL_CONTENT_DIM = hl_group "ContentDim"
ConfigModule.HL_CONTENT = hl_group "Content"
ConfigModule.HL_TITLE = hl_group "Title"

vim.api.nvim_set_hl(0, ConfigModule.HL_CONTENT_DIM, { link = "Comment", default = true })
vim.api.nvim_set_hl(0, ConfigModule.HL_CONTENT, { link = "Normal", default = true })
vim.api.nvim_set_hl(0, ConfigModule.HL_TITLE, { link = "Title", default = true })

return ConfigModule
