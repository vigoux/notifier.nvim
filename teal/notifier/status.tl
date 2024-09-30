local api = vim.api
local cfg = require"notifier.config"
local displayw = vim.fn.strdisplaywidth

local type Component = {string|integer:Message}

local record StatusModule
  active: {string:Component}
  buf_nr: vim.api.BufNr|nil
  win_nr: vim.api.WinNr|nil

  -- API functions
  redraw: function()

  -- Private functions
  _ensure_valid: function(Message): boolean
  _create_win: function()
  _delete_win: function()
  _ui_valid: function(): boolean
end

StatusModule.buf_nr = nil
StatusModule.win_nr = nil
StatusModule.active = {}

local function get_status_width(): integer
  local w = cfg.config.status_width
  if w is function(): integer then
    return w()
  else
    return w
  end
end

function StatusModule._create_win()
  if not StatusModule.win_nr or not api.nvim_win_is_valid(StatusModule.win_nr) then
    if not StatusModule.buf_nr or not api.nvim_buf_is_valid(StatusModule.buf_nr) then
      StatusModule.buf_nr = api.nvim_create_buf(false, true);
    end
    local border: string
    if cfg.config.debug then
      border = "single"
    else
      border = "none"
    end
    local success, win_nr = pcall(api.nvim_open_win, StatusModule.buf_nr, false, {
      focusable = false,
      style = "minimal",
      border = border,
      noautocmd = true,
      relative = "editor",
      anchor = "SE",
      width = get_status_width(),
      height = 3,
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = vim.o.columns,
      zindex = cfg.config.zindex,
    })

    if success then
      StatusModule.win_nr = win_nr
      if api.nvim_win_set_hl_ns then
        api.nvim_win_set_hl_ns(StatusModule.win_nr, cfg.NS_ID)
      end
    end
  end
end

function StatusModule._ui_valid(): boolean
  return StatusModule.win_nr and api.nvim_win_is_valid(StatusModule.win_nr)
    and StatusModule.buf_nr and api.nvim_buf_is_valid(StatusModule.buf_nr)
end

function StatusModule._delete_win()
  if StatusModule.win_nr and api.nvim_win_is_valid(StatusModule.win_nr) then
    api.nvim_win_close(StatusModule.win_nr, true)
  end
  StatusModule.win_nr = nil
end

local function adjust_width(src: string, width: integer): string
  return vim.fn["repeat"](" ", width - displayw(src)) .. src
end

local record HlInfo
  name: string
  icon: string
  dim: boolean
end

function StatusModule.redraw()
  StatusModule._create_win()

  if not StatusModule._ui_valid() then return end

  local lines: {string} = {}
  local hl_infos: {integer:HlInfo} = {}
  local width = get_status_width()

  -- This is the main "drawing" function, handling en ensure the correct placement of everything in
  -- the message
  local function push_line(title: string, content: Message)
    local message_lines = vim.split(content.mandat, '\n', { plain = true, trimempty = true })

    -- Compute the available room for messages
    local inner_width: integer = width - (displayw(title) + 1)
    if content.icon then
      inner_width = inner_width - (displayw(content.icon) + 1) -- One space plus the icon which is of size 1 cell
    end

    if cfg.config.debug then
      vim.pretty_print(message_lines)
    end

    -- Now go over each line, and if it does not fit break the line in multiple parts
    local tmp_lines: {string} = {}
    local maxlen: integer = 0

    for _, line in ipairs(message_lines) do
      local tmp_line: string
      local words = vim.split(line, '%s', { trimempty = true })

      for _, w in ipairs(words) do
        local tmp: string
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

    for i,line in ipairs(message_lines) do
      -- This is where we handle multiline notifications

      -- For a given line, the amount of space to be left-alligned in the message
      local right_pad_len = maxlen - displayw(line)

      -- Try to render optional message part and see if it fits
      local fmt_msg: string
      if content.opt and i == #message_lines then
        -- The optional parts of messages is drawn with the last line
        local tmp = string.format("%s (%s)", line, content.opt)
        if displayw(tmp) > inner_width - right_pad_len then
          fmt_msg = adjust_width(line, inner_width - right_pad_len)
        else
          fmt_msg = adjust_width(tmp, inner_width - right_pad_len)
        end
      else
        fmt_msg = adjust_width(line, inner_width - right_pad_len)
      end

      local formatted: string
      if i == 1 then
        local right_pad: string = vim.fn["repeat"](' ', right_pad_len)
        if content.icon then
          formatted = string.format("%s%s %s %s", fmt_msg, right_pad, title, content.icon)
        else
          formatted = string.format("%s%s %s", fmt_msg, right_pad, title)
        end
      else
        formatted = fmt_msg
      end

      if cfg.config.debug then
        vim.pretty_print(formatted)
      end

      -- TODO(vigoux): right allign multiline messages instead of push like this
      table.insert(lines, formatted)
      if i == 1 then
        table.insert(hl_infos, { name = title, dim = content.dim, icon = content.icon })
      else
        table.insert(hl_infos, { name = "", icon = "", dim = content.dim })
      end
    end
  end

  -- For each component, print the messages
  for _, compname in ipairs(cfg.config.components) do
    local msgs = StatusModule.active[compname] or {}
    local is_tbl = vim.islist(msgs)

    for name, msg in pairs(msgs) do
      -- Resolve notification name
      local rname: string = msg.title
      if not rname and is_tbl then
        rname = compname
      elseif not is_tbl then
        rname = name as string -- This is actually a string here, as checks by tbl_islist
      end

      if cfg.config.component_name_recall and not is_tbl then
        rname = string.format("%s:%s", compname, rname)
      end

      push_line(rname, msg)
    end
  end


  if #lines > 0 then
    api.nvim_buf_clear_namespace(StatusModule.buf_nr, cfg.NS_ID, 0, -1)
    api.nvim_buf_set_lines(StatusModule.buf_nr, 0, -1, false, lines)
    -- Then highlight the lines
    for i = 1, #hl_infos do
      local hl_group: string
      if hl_infos[i].dim then
        hl_group = cfg.HL_CONTENT_DIM
      else
        hl_group = cfg.HL_CONTENT
      end

      -- Here the highlighting is done in byte indexes, so we have to correct the byte offset
      -- compared to the cell offsets
      local title_start_offset: integer = #lines[i] - #hl_infos[i].name
      if hl_infos[i].icon then
        title_start_offset = title_start_offset - (#hl_infos[i].icon + 1)
      end

      local title_stop_offset: integer
      if hl_infos[i].icon then
        title_stop_offset = #lines[i] - #hl_infos[i].icon - 1
      else
        title_stop_offset = -1
      end
      api.nvim_buf_add_highlight(StatusModule.buf_nr, cfg.NS_ID, hl_group, i - 1, 0, title_start_offset - 1)
      api.nvim_buf_add_highlight(StatusModule.buf_nr, cfg.NS_ID, cfg.HL_TITLE, i - 1, title_start_offset, title_stop_offset)

      if hl_infos[i].icon then
        api.nvim_buf_add_highlight(StatusModule.buf_nr, cfg.NS_ID, cfg.HL_ICON, i - 1, title_stop_offset + 1, -1)
      end
    end

    api.nvim_win_set_height(StatusModule.win_nr, #lines)
  else
    StatusModule._delete_win()
  end
end

function StatusModule._ensure_valid(msg: Message): boolean
  if msg.icon and displayw(msg.icon) == 0 then
    msg.icon = nil
  end

  if msg.title and displayw(msg.title) == 0 then
    msg.title = nil
  end

  if msg.title and string.find(msg.title, "\n") then
    error "Message title cannot contain newlines"
  end

  if msg.icon and string.find(msg.icon, "\n") then
    error "Message icon cannot contain newlines"
  end

  if msg.opt and string.find(msg.opt, "\n") then
    error "Message optional part cannot contain newlines"
  end

  return true
end

function StatusModule.push(component: string, content: Message|string, title: string|nil)
  if not StatusModule.active[component] then
    StatusModule.active[component] = {}
  end

  if content is string then
    content = { mandat = content }
  end

  content = content as Message
  if StatusModule._ensure_valid(content) then
    if title then
      StatusModule.active[component][title] = content
    else
      table.insert(StatusModule.active[component] as {integer:Message}, content)
    end
    StatusModule.redraw()
  end
end

function StatusModule.pop(component: string, title: string|nil)
  if not StatusModule.active[component] then return end

  if title then
    StatusModule.active[component][title] = nil
  else
    table.remove(StatusModule.active[component] as {integer:Message})
  end
  StatusModule.redraw()
end

function StatusModule.clear(component: string)
  StatusModule.active[component] = nil
  StatusModule.redraw()
end

return StatusModule
