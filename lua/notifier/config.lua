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

return {
  get = function()
    return config
  end,
  update = function(other)
    config = vim.tbl_deep_extend("force", config, other or {})
  end
}
