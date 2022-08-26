local api = vim.api
local status = require "notifier.status"
local config = require "notifier.config"

local record NotifyOptions
  title: string|nil
end

api.nvim_create_augroup(config.NS_NAME, {
  clear = true
})

local notify_msg_cache = {}

local function notify(msg: string, level: integer, opts: NotifyOptions, no_cache: boolean)
  if level >= config.config.notify.min_level then
    opts = opts or {}
    status.push("nvim", { mandat = msg, title = opts.title })
    if not no_cache then
      table.insert(notify_msg_cache,  { msg = msg, level = level, opts = opts })
    end
    local lifetime = config.config.notify.clear_time
    if lifetime > 0 then
      vim.defer_fn(function() status.pop "nvim" end, lifetime)
    end
  end
end

local commands: {string:function()} = {
  Clear = function()
    status.clear "nvim"
  end,
  Replay = function()
    for _, msg in ipairs(notify_msg_cache) do
      notify(msg.msg, msg.level, msg.opts, true)
    end
  end
}

return {
  setup = function(user_config: config.Config)
    config.update(user_config)

    vim.notify = function(msg:string, level:integer, opts: {any:any})
      notify(msg, level, opts as NotifyOptions)
    end

    for cname, func in pairs(commands) do
      api.nvim_create_user_command(config.NS_NAME .. cname, func, {})
    end

    api.nvim_create_autocmd({ "User" }, {
      group = config.NS_NAME,
      pattern = "LspProgressUpdate",
      callback = function()
        local new_messages = vim.lsp.util.get_progress_messages()
        for _, msg in ipairs(new_messages) do
          if not config.config.ignore_messages[msg.name] and msg.progress then
            status.handle(msg)
          end
        end
      end
    })

    api.nvim_create_autocmd("VimResized", {
      group = config.NS_NAME,
      callback = function()
        status._delete_win()
      end
    })
  end
}
