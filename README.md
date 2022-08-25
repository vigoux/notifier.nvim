# `notifier.nvim` non-intrusive notification system for neovim

_This is still very WIP_

TODO:
- [x] Handle LSP progress
- [x] Hook into `vim.notify` and friends
  - [ ] Allow to customize log levels

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
  order = { "nvim", "lsp" }, -- Order of the components to draw (first nvim notifications, then lsp
  notify_clear_time = 1000, -- Time in milisecond before removing a vim.notifiy notification, 0 to make them sticky
}
```

You can clear the notifications provided through `vim.notify` by
doing:
```vim
:NotifierClear
```

## Acknoledgement

Heavily inspired by [fidget.nvim]

[fidget.nvim]: https://github.com/j-hui/fidget.nvim
