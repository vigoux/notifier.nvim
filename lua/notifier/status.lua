local api = vim.api
local cfg = require"notifier.config"
local ns = api.nvim_create_namespace "notifier"

local status = {
  buf_nr = nil,
  win_nr = nil,
  active = {}
}

function status.create_win()
  if not status.win_nr then
    status.buf_nr = api.nvim_create_buf(false, true);
    status.win_nr = api.nvim_open_win(status.buf_nr, false, {
      focusable = false,
      style = "minimal",
      border = "none",
      noautocmd = true,
      relative = "editor",
      anchor = "SE",
      width = cfg.get().status_width,
      height = 3,
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = vim.o.columns,
      zindex = 10,
    })
  end
end

function status.maybe_delete_win(force)
  if force or vim.tbl_isempty(status.active) then
    api.nvim_win_close(status.win_nr, true)
    status.win_nr = nil
  end
end

local function adjust_width(src, width)
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

local function format(name, msg, width)
  local inner_width = width - #name - 1
  local fmt_msg
  if msg.opt then
    local tmp = string.format("%s (%s)", msg.mandat, msg.opt)
    if #tmp > width then
      fmt_msg = adjust_width(msg.mandat, inner_width)
    else
      fmt_msg = adjust_width(tmp, inner_width)
    end
  else
    fmt_msg = adjust_width(msg.mandat, inner_width)
  end

  return fmt_msg .. " " .. name
end

function status.redraw()
  status.create_win()

  local config = cfg.get()

  if not vim.tbl_isempty(status.active) then
    local lines = {}
    local title_lines = {}

    -- For each lsp, print the message
    for _, nsname in ipairs(config.order) do
      for name, msg in pairs(status.active[nsname] or {}) do
        table.insert(lines, format(name, msg.content, config.status_width))
        table.insert(title_lines, { name = name, dim = msg.dim })
      end
    end

    api.nvim_buf_set_lines(status.buf_nr, 0, -1, false, lines)

    -- Then highlight the lines
    for i = 1, api.nvim_buf_line_count(status.buf_nr) do
      local hl_group

      -- Prevents a strange error
      if not title_lines[i] then break end

      if title_lines[i].dim then
        hl_group = cfg.HL_CONTENT_DIM
      else
        hl_group = cfg.HL_CONTENT
      end
      api.nvim_buf_add_highlight(status.buf_nr, ns, hl_group, i - 1, 0, config.status_width - #title_lines[i].name - 1)
      api.nvim_buf_add_highlight(status.buf_nr, ns, cfg.HL_TITLE, i - 1, config.status_width - #title_lines[i].name, -1)
    end

    api.nvim_win_set_height(status.win_nr, #lines)
  else
    status.maybe_delete_win()
  end
end

function status.push(namespace, title, content, dim)
  if not status.active[namespace] then
    status.active[namespace] = {}
  end

  status.active[namespace][title] = { content = content, dim = dim }
end

function status.clear(namespace, title)
  if status.active[namespace] then
    status.active[namespace][title] = nil
  end
end

function status.handle(msg)
  if msg.done then
    status.clear("lsp", msg.name)
  else
    status.push("lsp", msg.name, { mandat = msg.title, opt = msg.message }, true)
  end
  vim.schedule(status.redraw)
end

return status
