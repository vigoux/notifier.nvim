global record vim
  record o
    textwidth: integer
    lines: integer
    columns: integer
    cmdheight: integer
  end

  record api
    type BufNr = integer
    type WinNr = integer

    record SetHlOptions
      link: string
      default: boolean
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

    nvim_create_augroup: function(string, CreateAugroupOptions)
    nvim_create_autocmd: function(string|{string}, CreateAutocmdOptions)
    nvim_create_user_command: function(string, function(), CreateUserCommandOptions)
    nvim_buf_set_lines: function(BufNr, integer, integer, boolean, {string})
    nvim_buf_add_highlight: function(BufNr, integer, string, integer, integer, integer)
    nvim_buf_clear_namespace: function(BufNr, integer, integer, integer)
    nvim_open_win: function(BufNr, boolean, OpenWinOptions): WinNr
    nvim_win_close: function(WinNr, boolean)
    nvim_win_set_height: function(WinNr, integer)
    nvim_create_buf: function(boolean, boolean): BufNr
    nvim_create_namespace: function(string): integer
    nvim_set_hl: function(integer, string, SetHlOptions)
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

  notify: function(string, integer, {any:any})
  defer_fn: function(function(), integer)

  tbl_deep_extend: function(string, ...: table): table
  tbl_islist: function({any:any}): boolean
  tbl_contains: function<T>({T}, T): boolean

  pretty_print: function(any)
end
