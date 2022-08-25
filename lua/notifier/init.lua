local api = vim.api
local status = require "notifier.status"
local config = require "notifier.config"
local GROUPNAME = "Notifier"

api.nvim_create_augroup(GROUPNAME, {
  clear = true
})

return {
  setup = function(user_config)
    config.update(user_config)

    api.nvim_create_autocmd({ "User" }, {
      group = GROUPNAME,
      pattern = "LspProgressUpdate",
      callback = function()
        local new_messages = vim.lsp.util.get_progress_messages()
        for _, msg in ipairs(new_messages) do
          if not config.get().ignore_messages[msg.name] and msg.progress then
            status.handle(msg)
          end
        end
        return false
      end
    })
  end
}
