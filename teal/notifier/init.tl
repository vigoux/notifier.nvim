local api = vim.api
local status = require "notifier.status"
local config = require "notifier.config"

local record NotifyOptions
  title: string|nil
  icon: string|nil
end

local notify_msg_cache = {}

local function notify(msg: string, level: integer, opts: NotifyOptions, no_cache: boolean)
  level = level or vim.log.levels.INFO
  opts = opts or {}
  if level >= config.config.notify.min_level then
    status.push("nvim", { mandat = msg, title = opts.title, icon = opts.icon })
    if not no_cache then
      table.insert(notify_msg_cache,  { msg = msg, level = level, opts = opts })
    end
    local lifetime = config.config.notify.clear_time
    if lifetime > 0 then
      vim.defer_fn(function() status.pop "nvim" end, lifetime)
    end
  end
end

local record CommandDef
  func: function(vim.api.UserCommandArgs)
  opts: vim.api.CreateUserCommandOptions
end

local commands: {string:CommandDef} = {
  Clear = {
    opts = {},
    func = function()
      status.clear "nvim"
    end
  },
  Replay = {
    opts = {
      bang = true
    },
    func = function(args: vim.api.UserCommandArgs)
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
    end
  }
}

return {
  notify = function(msg: string, level: integer, opts: NotifyOptions)
      notify(msg, level, opts)
  end,
  setup = function(user_config: config.Config)
    api.nvim_create_augroup(config.NS_NAME, {
      clear = true
    })

    config.update(user_config)

    if config.has_component "nvim" then
      vim.notify = function(msg:string, level:integer, opts: {any:any})
        notify(msg, level, opts as NotifyOptions)
      end
    end

    for cname, def in pairs(commands) do
      api.nvim_create_user_command(config.NS_NAME .. cname, def.func, def.opts)
    end

    if config.has_component "lsp" then
      local lsp_storage: {string|integer: Message} = {}

      -- We'll plug into the lsp handler
      vim.lsp.handlers["$/progress"] = function(_: any, params: vim.lsp.ProgressParams, ctx: vim.lsp.HandlerCtx)
        if not params then return end

        local value = params.value

        local client: vim.lsp.Client = vim.lsp.get_client_by_id(ctx.client_id)
        if value.kind == "end" then
          status.pop("lsp", client.name, tostring(params.token))
          lsp_storage[params.token] = nil
        elseif value.kind == "report" then
          local msg = lsp_storage[params.token]
          if not msg then error "Report without begin ?" end

          msg.opt = value.message or msg.opt

          status.push("lsp", msg, client.name, tostring(params.token))
        else -- begin
          lsp_storage[params.token] = { mandat = value.title, opt = value.message, dim=true }
          status.push("lsp", lsp_storage[params.token], client.name, tostring(params.token))
        end
      end
    end

    api.nvim_create_autocmd("VimResized", {
      group = config.NS_NAME,
      callback = function()
        status._delete_win()
      end
    })
  end
}
