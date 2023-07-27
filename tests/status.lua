local notifier = require('notifier')
local status = require('notifier.status')
require('busted.runner')({ output = 'TAP', shuffle = true })

local function get_status_lines()
  assert.Truthy(status._ui_valid())
  return vim.api.nvim_buf_get_lines(status.buf_nr, 0, -1, true)
end

local function assert_status(lines)
  assert.are.Same(get_status_lines(), lines)
end

notifier.setup {
  components = { 'test' },
  status_width = 40,
}

describe('status window', function()
  after_each(function()
    status.clear('test')
  end)

  it('works', function()
    status.push('test', 'test')
    assert_status({
      '                               test test',
    })
  end)

  it('handles multiline notifications #8', function()
    status.push('test', 'test\ntest')
    assert_status({
      '                               test test',
      '                               test',
    })
  end)

  it('right alligns notifications', function()
    status.push('test', 'test with more text\ntest')
    assert_status({
      '                test with more text test',
      '                test',
    })

    status.push('test', 'test\ntest')
    assert_status({
      '                test with more text test',
      '                test',
      '                               test test',
      '                               test',
    })
  end)

  it('handles very long notifications #11', function()
    status.push('test', 'very long notification that should wrap correctly otherwise that is a bug')
    assert_status({
      ' very long notification that should test',
      ' wrap correctly otherwise that is a',
      ' bug',
    })
  end)
end)
