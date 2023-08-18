
vim.o.runtimepath = '.,' .. vim.fn.expand('$VIMRUNTIME')

-- Now integrate luarocks to get the test dependencies
local lrpath = vim.fn.systemlist { "luarocks", "path", "--lr-path" }[1]
local lrcpath = vim.fn.systemlist { "luarocks", "path", "--lr-cpath" }[1]

package.path = package.path .. ";" .. lrpath
package.cpath = package.cpath .. ";" .. lrcpath

require 'luarocks.loader'
