local api = vim.api
local status = require "notifier.status"
local config = require "notifier.config"

api.nvim_create_augroup(config.NS_NAME, {
  clear = true
})

local function notify(msg, level, opts)
  status.push("nvim", msg)
  vim.defer_fn(function() status.pop "nvim" end, config.get().notify_clear_time)
end


return {
  setup = function(user_config)
    config.update(user_config)

    vim.notify = notify

    api.nvim_create_autocmd({ "User" }, {
      group = config.NS_NAME,
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
