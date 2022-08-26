# `notifier.nvim` non-intrusive notification system for neovim

![Showcase](https://user-images.githubusercontent.com/39092278/186714682-f51ea665-6fca-4442-bad8-8cc7fda2f138.gif)

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
  notify = {
    clear_time = 1000, -- Time in milisecond before removing a vim.notifiy notification, 0 to make them sticky
    min_level = vim.log.level.INFO, -- Minimum log level to print the notification
  },
  component_name_recall = false -- Whether to prefix the title of the notification by the component name
}
```

This plugin provides some commands:
```vim
:NotifierClear   " Clear the vim.notify items
:NotifierReplay  " Replay all notifications
```

This plugin defines multiple highlight groups that you can configure:
- `NotifierTitle`: the title of the notification (`lsp:..` and `nvim`)
- `NotifierContent`: the content of the notification
- `NotifierContentDim`: dimmed content of the notification

## Acknoledgement

Heavily inspired by [fidget.nvim]

[fidget.nvim]: https://github.com/j-hui/fidget.nvim

## TODO

- [x] Handle LSP progress
- [x] Hook into `vim.notify` and friends
  - [ ] Allow to customize log levels

