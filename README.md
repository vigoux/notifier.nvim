# `notifier.nvim` non-intrusive notification system for neovim

_This is still very WIP_

TODO:
- [x] Handle LSP progress
- [ ] Hook into `vim.notify` and friends

## Setup

Using `packer.nvim`:
```lua
use {
  "vigoux/notifier.nvim",
  config = function()
    require'notifier'.setup {
    -- You configuration here
    }
  end
}
```

The default configuration is:
```lua
{
  ignore_messages = {}, -- Ignore message from LSP servers with this name
  status_width = something, -- COmputed using 'columns' and 'textwidth'
}
```
