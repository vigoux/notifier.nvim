local api = vim.api
local status = require('notifier.status')
local config = require('notifier.config')

local M = {}

---@class Notifier.NotifyMsg
---@field msg string The message
---@field level integer Message level
---@field opts {[string]: any} Options for the notification

---@type Notifier.NotifyMsg[]
local notify_msg_cache = {}

--- Reimplementation of vim.notify
---@param msg string Message
---@param level integer Level (see vim.log.Level)
---@param opts {[string]:any}? Options
---@param no_cache boolean? Whether to add the current notification in the cache
local function notify(msg, level, opts, no_cache)
  level = level or vim.log.levels.INFO
  opts = opts or {}
  if level >= config.config.notify.min_level then
    status.push('nvim', { mandat = msg, title = opts.title, icon = opts.icon })
    if not no_cache then
      table.insert(notify_msg_cache, { msg = msg, level = level, opts = opts })
    end
    local lifetime = config.config.notify.clear_time
    if lifetime > 0 then
      vim.defer_fn(function()
        status.pop('nvim')
      end, lifetime)
    end
  end
end

local commands = {
  Clear = {
    opts = {},
    func = function()
      status.clear('nvim')
    end,
  },
  Replay = {
    opts = {
      bang = true,
    },
    func = function(args)
      if args.bang then
        ---@type any[]
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

M.notify = notify

--- Sets up notifier
---@param user_config Notifier.Config User configuration
function M.setup(user_config)
  api.nvim_create_augroup(config.NS_NAME, {
    clear = true,
  })

  config.update(user_config)

  if config.has_component('nvim') then
    ---@diagnostic disable-next-line:duplicate-set-field
    vim.notify = function(msg, level, opts)
      notify(msg, level, opts)
    end
  end

  for cname, def in pairs(commands) do
    api.nvim_create_user_command(config.NS_NAME .. cname, def.func, def.opts)
  end

  if config.has_component('lsp') then
    ---@type {[string]: Notifier.Message}
    local lsp_storage = {}

    --- Progress handler for LSP
    ---@param _ any
    ---@param params any?
    ---@param ctx any
    ---@diagnostic disable-next-line:duplicate-set-field
    vim.lsp.handlers['$/progress'] = function(_, params, ctx)
      if not params then
        return
      end

      ---@type {kind: string, message: string, title: string}
      local value = params.value

      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if value.kind == 'end' then
        status.pop('lsp', client.name)
        lsp_storage[params.token] = nil
      elseif value.kind == 'report' then
        local msg = lsp_storage[params.token]
        if not msg then
          error('Report without begin ?')
        end

        msg.opt = value.message or msg.opt

        status.push('lsp', msg, client.name)
      else
        lsp_storage[params.token] = { mandat = value.title, opt = value.message, dim = true }
        status.push('lsp', lsp_storage[params.token], client.name)
      end
    end
  end

  api.nvim_create_autocmd('VimResized', {
    group = config.NS_NAME,
    callback = function()
      status._delete_win()
    end,
  })
end

return M
--   notify = function(msg, level, opts)
--     notify(msg, level, opts)
--   end,
--   ---@type function(Notifier.Config)
-- }
