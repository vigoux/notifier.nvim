local api = vim.api
local status = require("notifier.status")
local config = require("notifier.config")

local NotifyOptions = {}




local notify_msg_cache = {}

local function notify(msg, level, opts, no_cache)
   level = level or vim.log.levels.INFO
   opts = opts or {}
   if level >= config.config.notify.min_level then
      status.push("nvim", { mandat = msg, title = opts.title, icon = opts.icon })
      if not no_cache then
         table.insert(notify_msg_cache, { msg = msg, level = level, opts = opts })
      end
      local lifetime = config.config.notify.clear_time
      if lifetime > 0 then
         vim.defer_fn(function() status.pop("nvim") end, lifetime)
      end
   end
end

local CommandDef = {}




local commands = {
   Clear = {
      opts = {},
      func = function()
         status.clear("nvim")
      end,
   },
   Replay = {
      opts = {
         bang = true,
      },
      func = function(args)
         if args.bang then
            local list = {}
            for _, msg in ipairs(notify_msg_cache) do
               list[#list + 1] = {
                  text = msg.msg,
               }
            end

            vim.fn.setqflist(list, 'r')
         else
            for _, msg in ipairs(notify_msg_cache) do
               notify(msg.msg, msg.level, msg.opts, true)
            end
         end
      end,
   },
}

return {
   notify = function(msg, level, opts)
      notify(msg, level, opts)
   end,
   setup = function(user_config)
      api.nvim_create_augroup(config.NS_NAME, {
         clear = true,
      })

      config.update(user_config)

      if config.has_component("nvim") then
         vim.notify = function(msg, level, opts)
            notify(msg, level, opts)
         end
      end

      for cname, def in pairs(commands) do
         api.nvim_create_user_command(config.NS_NAME .. cname, def.func, def.opts)
      end

      if config.has_component("lsp") then
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
            end,
         })
      end

      api.nvim_create_autocmd("VimResized", {
         group = config.NS_NAME,
         callback = function()
            status._delete_win()
         end,
      })
   end,
}
