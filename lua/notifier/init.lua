local api = vim.api
local ns = api.nvim_create_namespace "notifier"

local GROUPNAME = "Notifier"

api.nvim_create_augroup(GROUPNAME, {
  clear = true
})

local status = {
  buf_nr = nil,
  win_nr = nil,
  active = {}
}

local config = {
  ignore_messages = {},
  status_width = (function()
    if vim.o.textwidth ~= 0 then
      return math.floor((vim.o.columns - vim.o.textwidth) * 0.7)
    else
      return math.floor(vim.o.columns / 3)
    end
  end)()
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
      width = config.status_width,
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

local function format(msg, width)
  local inner_width = width - #msg.name - 1
  local fmt_msg
  if msg.message then
    local tmp = string.format("%s (%s)", msg.title, msg.message)
    if #tmp > width then
      fmt_msg = adjust_width(msg.title, inner_width)
    else
      fmt_msg = adjust_width(tmp, inner_width)
    end
  else
    fmt_msg = adjust_width(msg.title, inner_width)
  end

  return fmt_msg .. " " .. msg.name
end

function status.redraw()
  status.create_win()

  if not vim.tbl_isempty(status.active) then
    local lines = {}
    local title_lines = {}

    -- For each lsp, print the message
    for _, msg in pairs(status.active) do
      table.insert(lines, format(msg, config.status_width))
      title_lines[#lines] = #msg.name
    end

    api.nvim_buf_set_lines(status.buf_nr, 0, -1, false, lines)

    -- Then highlight the lines
    for i = 1, api.nvim_buf_line_count(status.buf_nr) do
      api.nvim_buf_add_highlight(status.buf_nr, ns, "Comment", i - 1, 0, config.status_width - title_lines[i] - 1)
      api.nvim_buf_add_highlight(status.buf_nr, ns, "Title", i - 1, config.status_width - title_lines[i], -1)
    end

    api.nvim_win_set_height(status.win_nr, #lines)
  else
    status.maybe_delete_win()
  end
end

function status.handle(msg)
  if msg.done then
    status.active[msg.name] = nil
  else
    status.active[msg.name] = msg
  end
  vim.schedule(status.redraw)
end

local function progress_handle()
  local new_messages = vim.lsp.util.get_progress_messages()
  for _, msg in ipairs(new_messages) do
    if not config.ignore_messages[msg.name] and msg.progress then
      status.handle(msg)
    end
  end
  return false
end

return {
  setup = function(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})

    api.nvim_create_autocmd({ "User" }, {
      group = GROUPNAME,
      pattern = "LspProgressUpdate",
      callback = progress_handle
    })
  end
}
