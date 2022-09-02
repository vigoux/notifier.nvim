local api = vim.api
local cfg = require("notifier.config")
local displayw = vim.fn.strdisplaywidth

local Message = {}







local Component = {}

local StatusModule = {}














StatusModule.buf_nr = nil
StatusModule.win_nr = nil
StatusModule.active = {}

local function get_status_width()
   local w = cfg.config.status_width
   if type(w) == "function" then
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
      local border
      if cfg.config.debug then
         border = "single"
      else
         border = "none"
      end
      StatusModule.win_nr = api.nvim_open_win(StatusModule.buf_nr, false, {
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
         zindex = 10,
      })
      if api.nvim_win_set_hl_ns then
         api.nvim_win_set_hl_ns(StatusModule.win_nr, cfg.NS_ID)
      end
   end
end

function StatusModule._ui_valid()
   return StatusModule.win_nr and api.nvim_win_is_valid(StatusModule.win_nr) and
   StatusModule.buf_nr and api.nvim_buf_is_valid(StatusModule.buf_nr)
end

function StatusModule._delete_win()
   if StatusModule.win_nr and api.nvim_win_is_valid(StatusModule.win_nr) then
      api.nvim_win_close(StatusModule.win_nr, true)
   end
   StatusModule.win_nr = nil
end

local function padding(length)
   local acc = ""
   while displayw(acc) < length do
      acc = " " .. acc
   end

   return acc
end

local function adjust_width(src, width)
   if displayw(src) > width then
      return string.sub(src, 1, width - 3) .. "..."
   else
      return padding(width - displayw(src)) .. src
   end
end

function StatusModule.redraw()
   StatusModule._create_win()

   if not StatusModule._ui_valid() then return end

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

      for i, line in ipairs(message_lines) do



         local fmt_msg
         if content.opt and i == #message_lines then
            local tmp = string.format("%s (%s)", line, content.opt)
            if displayw(tmp) > inner_width then
               fmt_msg = adjust_width(line, inner_width)
            else
               fmt_msg = adjust_width(tmp, inner_width)
            end
         else
            fmt_msg = adjust_width(line, inner_width)
         end

         local formatted
         if i == 1 then
            if content.icon then
               formatted = string.format("%s %s %s", fmt_msg, title, content.icon)
            else
               formatted = string.format("%s %s", fmt_msg, title)
            end
         else
            formatted = string.format("%s %s", fmt_msg, padding(width - (inner_width + 1)))
         end

         if cfg.config.debug then
            vim.pretty_print(formatted)
         end

         table.insert(lines, formatted)
         table.insert(hl_infos, { name = title, dim = content.dim, icon = content.icon })
      end
   end


   for _, compname in ipairs(cfg.config.components) do
      local msgs = StatusModule.active[compname] or {}
      local is_tbl = vim.tbl_islist(msgs)

      for name, msg in pairs(msgs) do

         local rname = msg.title
         if not rname and is_tbl then
            rname = compname
         elseif not is_tbl then
            rname = name
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

function StatusModule._ensure_valid(msg)
   if msg.icon and displayw(msg.icon) == 0 then
      msg.icon = nil
   end

   if msg.title and displayw(msg.title) == 0 then
      msg.title = nil
   end

   if msg.title and string.find(msg.title, "\n") then
      error("Message title cannot contain newlines")
   end

   if msg.icon and string.find(msg.icon, "\n") then
      error("Message icon cannot contain newlines")
   end

   if msg.opt and string.find(msg.opt, "\n") then
      error("Message optional part cannot contain newlines")
   end

   return true
end

function StatusModule.push(component, content, title)
   if not StatusModule.active[component] then
      StatusModule.active[component] = {}
   end

   if type(content) == "string" then
      content = { mandat = content }
   end

   content = content
   if StatusModule._ensure_valid(content) then
      if title then
         StatusModule.active[component][title] = content
      else
         table.insert(StatusModule.active[component], content)
      end
      StatusModule.redraw()
   end
end

function StatusModule.pop(component, title)
   if not StatusModule.active[component] then return end

   if title then
      StatusModule.active[component][title] = nil
   else
      table.remove(StatusModule.active[component])
   end
   StatusModule.redraw()
end

function StatusModule.clear(component)
   StatusModule.active[component] = nil
   StatusModule.redraw()
end

function StatusModule.handle(msg)
   if msg.done then
      StatusModule.pop("lsp", msg.name)
   else
      StatusModule.push("lsp", { mandat = msg.title, opt = msg.message, dim = true }, msg.name)
   end
end

return StatusModule
