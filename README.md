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
  components = {  -- Order of the components to draw from top to bottom (first nvim notifications, then lsp)
    "nvim",  -- Nvim notifications (vim.notify and such)
    "lsp"  -- LSP status updates
  },
  notify = {
    clear_time = 5000, -- Time in milliseconds before removing a vim.notify notification, 0 to make them sticky
    min_level = vim.log.levels.INFO, -- Minimum log level to print the notification
  },
  component_name_recall = false -- Whether to prefix the title of the notification by the component name
}
```

This plugin provides some commands:
```vim
:NotifierClear   " Clear the vim.notify items
:NotifierReplay  " Replay all vim.notify items
```

This plugin defines multiple highlight groups that you can configure:
- `NotifierTitle`: the title of the notification (`lsp:..` and `nvim`)
- `NotifierIcon`: Icon of the notification (if any)
- `NotifierContent`: the content of the notification
- `NotifierContentDim`: dimmed content of the notification

## `vim.notify` options

This plugin supports two options for `vim.notify`:
```lua
title: string -- The title for this notification
icon: string -- The icon for this notification, must be of display width 1 (see strdisplaywidth())
```

## Acknowledgement

Heavily inspired by [fidget.nvim]

[fidget.nvim]: https://github.com/j-hui/fidget.nvim

## TODO

- [x] Handle LSP progress
- [x] Hook into `vim.notify` and friends
  - [x] Allow to customize log levels
- [ ] When out, hook into `ui_attach` to route more messages from nvim
- [ ] Add docs for `status.push` and `status.pop`
