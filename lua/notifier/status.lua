local api = vim.api
local cfg = require('notifier.config')
local displayw = vim.fn.strdisplaywidth

---@class Notifier.Message
---@field mandat string Mandatory part of the message
---@field opt string? Optional part of the message
---@field dim boolean Whether to dim the message
---@field title string? Optional title for the message
---@field icon string? Optional icon of the message

local M = {
  win_nr = nil,
  buf_nr = nil,
  active = {}
}

local function get_status_width()
  local w = cfg.config.status_width
  if type(w) == 'function' then
    return w()
  else
    return w
  end
end

--- Creates the status window if not already created
---@private
local function create_win()
  if not M.win_nr or not api.nvim_win_is_valid(M.win_nr) then
    if not M.buf_nr or not api.nvim_buf_is_valid(M.buf_nr) then
      M.buf_nr = api.nvim_create_buf(false, true)
    end

    ---@type string
    local border
    if cfg.config.debug then
      border = 'single'
    else
      border = 'none'
    end

    local success
    success, M.win_nr = pcall(api.nvim_open_win, M.buf_nr, false, {
      focusable = false,
      style = 'minimal',
      border = border,
      noautocmd = true,
      relative = 'editor',
      anchor = 'SE',
      width = get_status_width(),
      height = 3,
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = vim.o.columns,
      zindex = cfg.config.zindex,
    })

    if success then
      if api.nvim_win_set_hl_ns then
        api.nvim_win_set_hl_ns(M.win_nr, cfg.NS_ID)
      end
    end
  end
end

--- Checks if the UI is valid, including the UI buffer
---@return boolean valid Whether the UI is valid
---@private
function M._ui_valid()
  return M.win_nr ~= nil and api.nvim_win_is_valid(M.win_nr) and M.buf_nr ~= nil and api.nvim_buf_is_valid(M.buf_nr)
end

--- Closes the status window
local function delete_win()
  if M.win_nr and api.nvim_win_is_valid(M.win_nr) then
    api.nvim_win_close(M.win_nr, true)
  end
  M.win_nr = nil
end

--- Pads @p src to fit in @p width
---@param src string The string to pad
---@param width integer Width to fit
---@return string padded The argument padded with spaces to fit in width
local function adjust_width(src, width)
  return vim.fn['repeat'](' ', width - displayw(src)) .. src
end

--- Redraws the notifier UI
local function redraw()
  create_win()

  if not M._ui_valid() then
    return
  end

  local lines = {}
  local hl_infos = {}
  local width = get_status_width()

  local function push_line(title, content)
    local message_lines = vim.split(content.mandat, '\n', { plain = true, trimempty = true })

    local inner_width = width - (displayw(title) + 1)
    if content.icon then
      inner_width = inner_width - (displayw(content.icon) + 1)
    end

    if cfg.config.debug then
      vim.pretty_print(message_lines)
    end

    ---@type string[]
    local tmp_lines = {}

    local maxlen = 0

    for _, line in ipairs(message_lines) do
      ---@type string
      local tmp_line
      local words = vim.split(line, '%s', { trimempty = true })

      for _, w in ipairs(words) do
        ---@type string
        local tmp
        if not tmp_line then
          tmp = w
        else
          tmp = tmp_line .. ' ' .. w
        end

        if displayw(tmp) > inner_width then
          tmp_lines[#tmp_lines + 1] = tmp_line
          maxlen = math.max(maxlen, displayw(tmp_line))
          tmp_line = w
        else
          tmp_line = tmp
        end
      end

      tmp_lines[#tmp_lines + 1] = tmp_line
      maxlen = math.max(maxlen, displayw(tmp_line))
    end

    message_lines = tmp_lines

    if cfg.config.debug then
      vim.pretty_print(message_lines)
    end

    for i, line in ipairs(message_lines) do
      ---@type integer
      local right_pad_len = maxlen - displayw(line)

      ---@type string
      local fmt_msg
      if content.opt and i == #message_lines then
        local tmp = string.format('%s (%s)', line, content.opt)
        if displayw(tmp) > inner_width - right_pad_len then
          fmt_msg = adjust_width(line, inner_width - right_pad_len)
        else
          fmt_msg = adjust_width(tmp, inner_width - right_pad_len)
        end
      else
        fmt_msg = adjust_width(line, inner_width - right_pad_len)
      end

      ---@type string
      local formatted
      if i == 1 then
        local right_pad = vim.fn['repeat'](' ', right_pad_len)
        if content.icon then
          formatted = string.format('%s%s %s %s', fmt_msg, right_pad, title, content.icon)
        else
          formatted = string.format('%s%s %s', fmt_msg, right_pad, title)
        end
      else
        formatted = fmt_msg
      end

      if cfg.config.debug then
        vim.pretty_print(formatted)
      end

      table.insert(lines, formatted)
      if i == 1 then
        table.insert(hl_infos, { name = title, dim = content.dim, icon = content.icon })
      else
        table.insert(hl_infos, { name = '', icon = '', dim = content.dim })
      end
    end
  end

  for _, compname in ipairs(cfg.config.components) do
    local msgs = M.active[compname] or {}
    local is_tbl = vim.tbl_islist(msgs)

    for name, msg in pairs(msgs) do
      local rname = msg.title
      if not rname and is_tbl then
        rname = compname
      elseif not is_tbl then
        rname = name
      end

      if cfg.config.component_name_recall and not is_tbl then
        rname = string.format('%s:%s', compname, rname)
      end

      push_line(rname, msg)
    end
  end

  if #lines > 0 then
    api.nvim_buf_clear_namespace(M.buf_nr, cfg.NS_ID, 0, -1)
    api.nvim_buf_set_lines(M.buf_nr, 0, -1, false, lines)

    for i = 1, #hl_infos do
      local hl_group
      if hl_infos[i].dim then
        hl_group = cfg.HL_CONTENT_DIM
      else
        hl_group = cfg.HL_CONTENT
      end

      local title_start_offset = #lines[i] - #hl_infos[i].name
      if hl_infos[i].icon then
        title_start_offset = title_start_offset - (#hl_infos[i].icon + 1)
      end

      local title_stop_offset
      if hl_infos[i].icon then
        title_stop_offset = #lines[i] - #hl_infos[i].icon - 1
      else
        title_stop_offset = -1
      end
      api.nvim_buf_add_highlight(
        M.buf_nr,
        cfg.NS_ID,
        hl_group,
        i - 1,
        0,
        title_start_offset - 1
      )
      api.nvim_buf_add_highlight(
        M.buf_nr,
        cfg.NS_ID,
        cfg.HL_TITLE,
        i - 1,
        title_start_offset,
        title_stop_offset
      )

      if hl_infos[i].icon then
        api.nvim_buf_add_highlight(
          M.buf_nr,
          cfg.NS_ID,
          cfg.HL_ICON,
          i - 1,
          title_stop_offset + 1,
          -1
        )
      end
    end

    api.nvim_win_set_height(M.win_nr, #lines)
  else
    delete_win()
  end
end

function M._ensure_valid(msg)
  if msg.icon and displayw(msg.icon) == 0 then
    msg.icon = nil
  end

  if msg.title and displayw(msg.title) == 0 then
    msg.title = nil
  end

  if msg.title and string.find(msg.title, '\n') then
    error('Message title cannot contain newlines')
  end

  if msg.icon and string.find(msg.icon, '\n') then
    error('Message icon cannot contain newlines')
  end

  if msg.opt and string.find(msg.opt, '\n') then
    error('Message optional part cannot contain newlines')
  end

  return true
end

--- Push a new content into a given component
---@param component string Component to put the message int
---@param content string|Notifier.Message Message to display
---@param title string? Subcomponent title
function M.push(component, content, title)
  if not M.active[component] then
    M.active[component] = {}
  end

  if type(content) == 'string' then
    content = { mandat = content }
  end

  content = content
  if M._ensure_valid(content) then
    if title then
      M.active[component][title] = content
    else
      table.insert(M.active[component], content)
    end
    redraw()
  end
end

function M.pop(component, title)
  if not M.active[component] then
    return
  end

  if title then
    M.active[component][title] = nil
  else
    table.remove(M.active[component])
  end
  redraw()
end

function M.clear(component)
  M.active[component] = nil
  redraw()
end

return M
