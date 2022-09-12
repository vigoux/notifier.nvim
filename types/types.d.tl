global unpack: function<T>({T}, number, number): T...

global record vim
  record o
    textwidth: integer
    lines: integer
    columns: integer
    cmdheight: integer
  end

  record fn
    strdisplaywidth: function(string): integer
  end

  record api
    type BufNr = integer
    type WinNr = integer
    type NSId = integer

    record SetHlOptions
      link: string
      default: boolean
      bg: string
    end

    record OpenWinOptions
      relative: string
      win: WinNr|nil
      anchor: string|nil
      width: integer
      height: integer
      bufpos: {integer,integer}
      row: integer
      col: integer
      focusable: boolean
      external: boolean
      zindex: integer|nil
      style: string|nil
      border: string|nil
      noautocmd: boolean
    end

    record CreateAugroupOptions
      clear: boolean
    end

    record CreateUserCommandOptions
    end

    record CreateAutocmdOptions
      group: string|integer|nil
      pattern: string|{string}|nil
      buffer: BufNr|nil
      desc: string|nil
      callback: function()|string|nil
      command: string|nil
      once: boolean|nil
      nested: boolean|nil
    end

    nvim_buf_add_highlight: function(BufNr, NSId, string, integer, integer, integer)
    nvim_buf_clear_namespace: function(BufNr, NSId, integer, integer)
    nvim_buf_is_valid: function(BufNr): boolean
    nvim_buf_set_lines: function(BufNr, integer, integer, boolean, {string})
    nvim_create_augroup: function(string, CreateAugroupOptions)
    nvim_create_autocmd: function(string|{string}, CreateAutocmdOptions)
    nvim_create_buf: function(boolean, boolean): BufNr
    nvim_create_namespace: function(string): NSId
    nvim_create_user_command: function(string, function(), CreateUserCommandOptions)
    nvim_open_win: function(BufNr, boolean, OpenWinOptions): WinNr
    nvim_set_hl: function(NSId, string, SetHlOptions)
    nvim_win_close: function(WinNr, boolean)
    nvim_win_is_valid: function(WinNr): boolean
    nvim_win_set_height: function(WinNr, integer)
    nvim_win_set_hl_ns: function(WinNr, NSId)
  end

  record log
    record levels
      TRACE: integer
      DEBUG: integer
      INFO: integer
      WARN: integer
      ERROR: integer
      OFF: integer
    end
  end

  record lsp
    record ProgressMessage
      name: string
      title: string
      message: string|nil
      percentage: integer|nil
      done: boolean
      progress: boolean
    end

    record util
      get_progress_messages: function(): {ProgressMessage}
    end
  end

  record SplitOptions
    plain: boolean
    trimempty: boolean
  end

  notify: function(string, integer, {any:any})
  defer_fn: function(function(), integer)

  tbl_contains: function<T>({T}, T): boolean
  tbl_deep_extend: function(string, ...: table): table
  tbl_islist: function({any:any}): boolean

  pretty_print: function(any)

  split: function(string, string, SplitOptions): {string}

  schedule: function(function())
end
