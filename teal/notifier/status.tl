local api = vim.api
local cfg = require"notifier.config"

local record Message
  mandat: string
  dim: boolean
  title: string|nil
  opt: string|nil
end

local type Component = {string|integer:Message}

local record StatusModule
  active: {string:Component}
  buf_nr: vim.api.BufNr|nil
  win_nr: vim.api.WinNr|nil

  -- API functions
  redraw: function()

  -- Private functions
  _create_win: function()
  _delete_win: function()
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
  if not StatusModule.win_nr then
    if not StatusModule.buf_nr then
      StatusModule.buf_nr = api.nvim_create_buf(false, true);
    end
    StatusModule.win_nr = api.nvim_open_win(StatusModule.buf_nr, false, {
      focusable = false,
      style = "minimal",
      border = "none",
      noautocmd = true,
      relative = "editor",
      anchor = "SE",
      width = get_status_width(),
      height = 3,
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = vim.o.columns,
      zindex = 10,
    })
  end
end

function StatusModule._delete_win()
  api.nvim_win_close(StatusModule.win_nr, true)
  StatusModule.win_nr = nil
end

local function adjust_width(src: string, width: integer): string
  if #src > width then
    return string.sub(src, 1, width - 3) .. "..."
  else
    local acc = src
    while #acc < width do
      acc = " " .. acc
    end

    return acc
  end
end

local function format(name: string, msg: Message, width: integer): string
  local inner_width = width - #name - 1
  local fmt_msg: string
  if msg.opt then
    local tmp = string.format("%s (%s)", msg.mandat, msg.opt)
    if #tmp > inner_width then
      fmt_msg = adjust_width(msg.mandat, inner_width)
    else
      fmt_msg = adjust_width(tmp, inner_width)
    end
  else
    fmt_msg = adjust_width(msg.mandat, inner_width)
  end

  return fmt_msg .. " " .. name
end

function StatusModule.redraw()
  StatusModule._create_win()

  local lines = {}
  local hl_infos = {}
  local width = get_status_width()
  local function push_line(title: string, content: Message)
    table.insert(lines, format(title, content, width))
    table.insert(hl_infos, { name = title, dim = content.dim })
  end

  -- For each component, print the messages
  for _, compname in ipairs(cfg.config.order) do
    local msgs = StatusModule.active[compname] or {}
    local is_tbl = vim.tbl_islist(msgs)

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
      api.nvim_buf_add_highlight(StatusModule.buf_nr, cfg.NS_ID, hl_group, i - 1, 0, #lines[i] - #hl_infos[i].name - 1)
      api.nvim_buf_add_highlight(StatusModule.buf_nr, cfg.NS_ID, cfg.HL_TITLE, i - 1, #lines[i] - #hl_infos[i].name, -1)
    end

    api.nvim_win_set_height(StatusModule.win_nr, #lines)
  else
    StatusModule._delete_win()
  end
end

function StatusModule.push(component: string, content: Message|string, title: string|nil)
  if not StatusModule.active[component] then
    StatusModule.active[component] = {}
  end

  if content is string then
    content = { mandat = content }
  end

  content = content as Message

  if title then
    StatusModule.active[component][title] = content
  else
    table.insert(StatusModule.active[component] as {integer:Message}, content)
  end
  StatusModule.redraw()
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

function StatusModule.handle(msg: vim.lsp.ProgressMessage)
  if msg.done then
    StatusModule.pop("lsp", msg.name)
  else
    StatusModule.push("lsp", { mandat = msg.title, opt = msg.message, dim = true }, msg.name)
  end
end

return StatusModule
