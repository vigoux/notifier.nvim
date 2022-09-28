local notifier = require 'notifier'
local status = require 'notifier.status'
require 'busted.runner' { output = 'TAP', shuffle = true }

local function assert_no_status()
  assert.Falsy(status._ui_valid())
end

local function get_status_lines()
  assert.Truthy(status._ui_valid())
  return vim.api.nvim_buf_get_lines(status.buf_nr, 0, -1, true)
end

local function assert_status(lines)
  assert.are.Same(get_status_lines(), lines)
end

notifier.setup {
  components = { "nvim" },
  notify = {
    min_level = vim.log.levels.INFO,
  },
  status_width = 40
}

describe('notify', function()

  after_each(function()
    status.clear "nvim"
  end)

  it('works', function()
    vim.notify "test"
    assert_status {
      '                               test nvim'
    }
  end)

  it('min_level is respected (level == min_level)', function()
    vim.notify("test INFO", vim.log.levels.INFO)
    assert_status {
      '                          test INFO nvim'
    }
  end)

  it('min_level is respected (level < min_level)', function()
    vim.notify("test DEBUG", vim.log.levels.DEBUG)
    assert_no_status()
  end)

  it('min_level is respected (level > min_level)', function()
    vim.notify("test WARN", vim.log.levels.WARN)
    assert_status {
      '                          test WARN nvim'
    }
  end)

end)
