-- luacheck: globals unpack vim utf8
local nvim = vim.api
local shared = {}

shared.show = function(obj)
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")
  if obj.buffer == nil then
    local cb
    if vim.api.nvim_open_win ~= nil then
      cb = vim.api.nvim_create_buf(false, true)
      local winid = vim.api.nvim_open_win(cb, true, {
          width = width,
          height = 20,
          relative = "editor",
          row = height - 20,
          col = 0
        })
      vim.api.nvim_win_set_option(winid, "breakindent", true)
      vim.api.nvim_win_set_option(winid, "number", false)
      vim.api.nvim_win_set_option(winid, "relativenumber", false)
      vim.api.nvim_buf_set_option(cb, "bufhidden", "wipe")
      obj:set("winid", winid)
    else
      nvim.nvim_command("botright 15 new")
      cb = nvim.nvim_get_current_buf()
      -- TODO Change to API-based when nvim_win_set_option exists.
      nvim.nvim_command("setl breakindent nonu nornu nobuflisted buftype=nofile bufhidden=wipe nolist wfh wfw nowrap")
    end
    obj:set("buffer", math.ceil(cb))
  end

  return obj
end

shared.window_for_obj = function(obj)
  obj = shared.show(obj)

  local bufnr = nvim.nvim_call_function("bufnr", {obj.buffer})
  local window = obj.winid or nvim.nvim_call_function("win_getid", {
    nvim.nvim_call_function("bufwinnr", {obj.buffer})
  })
  local sz = nvim.nvim_win_get_width(window)
  local h = nvim.nvim_win_get_height(window)
  local top_offset = 0
  if obj.header ~= nil then
    top_offset = top_offset + 2
  end

  return {
    bufnr = bufnr,
    window = window,
    width = sz,
    height = h,
    top_offset = top_offset,
    bottom_offset = 0
  }
end

shared.header = function(obj, window_ops)
  local header = {}

  if obj.header ~= nil then
    table.insert(header, obj.header)
    table.insert(header, shared.div(window_ops.width))
  end

 return header
end

shared.footer = function(content, window_ops)
  local footer = {}

  table.insert(footer, shared.sub_div(window_ops.width))
  table.insert(footer, content)

 return footer
end

shared.draw_area_size = function(window_ops)
  return window_ops.height - window_ops.top_offset - window_ops.bottom_offset
end

shared.spacer = function(content, window_ops)
  local whitespace = {}
  local draw_area_size = shared.draw_area_size(window_ops)

  if #content < draw_area_size then
    local fill = draw_area_size - #content

    for _ = 1, fill do
      table.insert(whitespace, "")
    end
  end

  return whitespace
end

shared.with_bottom_offset = function(window_ops)
  window_ops.bottom_offset = 2

  return window_ops
end

shared.sort = function(a, b)
    return a.description < b.description
  end

shared.div = function(sz)
  return string.rep("─", sz)
end

shared.sub_div = function(sz)
  return string.rep("─", sz)
end

shared.get_footer = function(obj)
  local footer = ""

  if obj.footer ~= nil then
    footer = obj.footer
  end

   return footer
 end


return shared
