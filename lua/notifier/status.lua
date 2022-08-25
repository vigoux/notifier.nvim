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
    if not status.buf_nr then
      status.buf_nr = api.nvim_create_buf(false, true);
    end
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

function status.delete_win()
  api.nvim_win_close(status.win_nr, true)
  status.win_nr = nil
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

  local lines = {}
  local hl_infos = {}

  -- For each namespace, print the messages
  for _, nsname in ipairs(config.order) do
    local msgs = status.active[nsname] or {}
    if vim.tbl_islist(msgs) then
      for _,msg in ipairs(msgs) do
        table.insert(lines, format(nsname, msg.content, config.status_width))
        table.insert(hl_infos, { name = nsname, dim = msg.dim })
      end
    else
      for name, msg in pairs(msgs) do
        local rname = string.format("%s:%s", nsname, name)
        table.insert(lines, format(rname, msg.content, config.status_width))
        table.insert(hl_infos, { name = rname, dim = msg.dim })
      end
    end
  end


  if #lines > 0 then
    api.nvim_buf_set_lines(status.buf_nr, 0, -1, false, lines)
    -- Then highlight the lines
    for i = 1, #hl_infos do
      local hl_group
      if hl_infos[i].dim then
        hl_group = cfg.HL_CONTENT_DIM
      else
        hl_group = cfg.HL_CONTENT
      end
      api.nvim_buf_add_highlight(status.buf_nr, ns, hl_group, i - 1, 0, config.status_width - #hl_infos[i].name - 1)
      api.nvim_buf_add_highlight(status.buf_nr, ns, cfg.HL_TITLE, i - 1, config.status_width - #hl_infos[i].name, -1)
    end

    api.nvim_win_set_height(status.win_nr, #lines)
  else
    status.delete_win()
  end
end

function status.push(namespace, content, dim, title)
  if not status.active[namespace] then
    status.active[namespace] = {}
  end

  if type(content) == "string" then
    content = { mandat = content }
  end

  if title then
    status.active[namespace][title] = { content = content, dim = dim }
  else
    table.insert(status.active[namespace], { content = content, dim = dim })
  end
  status.redraw()
end

function status.pop(namespace, title)
  if not status.active[namespace] then return end

  if title then
    status.active[namespace][title] = nil
  else
    table.remove(status.active[namespace])
  end
  status.redraw()
end

function status.handle(msg)
  if msg.done then
    status.pop("lsp", msg.name)
  else
    status.push("lsp", { mandat = msg.title, opt = msg.message }, true, msg.name)
  end
end

return status
