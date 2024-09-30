global unpack: function<T>({T}, number, number): T...

global record Message
  mandat: string
  dim: boolean
  title: string|nil
  icon: string|nil
  opt: string|nil
end

global record vim
  record o
    textwidth: integer
    lines: integer
    columns: integer
    cmdheight: integer
  end

  record BufNr
  end

  record QfItem
    bufnr: BufNr
    filename: string

    lnum: integer
    end_lnum: integer
    col: integer
    end_col: integer

    text: string
    type: string
    valid: integer


    -- Not really useful stuff
    nr: integer
    vcol: integer
    module: string
    pattern: string
  end


  record fn
    exists: function(string): integer
    strdisplaywidth: function(string): integer
    setqflist: function({QfItem}, string, {string:boolean})
    ["repeat"]: function<T>(T, integer): T
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

    record UserCommandArgs
      args: {string}
      bang: boolean
    end

    record CreateUserCommandOptions
      bang: boolean
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
    nvim_create_user_command: function(string, function(UserCommandArgs), CreateUserCommandOptions)
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
    record ClientId
    end

    enum WorkDoneProgressKind
      'begin'
      'report'
      'end'
    end

    record WorkDoneProgress
      kind: WorkDoneProgressKind
      message: string
      title: string
      cancellable: boolean
      percentage: integer
    end

    record HandlerCtx
      method: string
      client_id: ClientId
      bufnr: BufNr
      params: any
    end

    record ProgressParams
      token: string|integer
      value: WorkDoneProgress
    end

    record Client
      id: ClientId
      name: string
    end

    handlers: {string: function(any, any, HandlerCtx)}
    get_client_by_id: function(ClientId): Client
  end

  record SplitOptions
    plain: boolean
    trimempty: boolean
  end

  print: function(any)

  notify: function(string, integer, {any:any})
  defer_fn: function(function(), integer)

  tbl_contains: function<T>({T}, T): boolean
  tbl_deep_extend: function(string, ...: table): table
  islist: function({any:any}): boolean

  pretty_print: function(any)

  split: function(string, string, SplitOptions): {string}

  schedule: function(function())
end
