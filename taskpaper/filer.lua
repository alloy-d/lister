local chunky = require 'taskpaper.chunky'
local printer = require 'taskpaper.printer'
local bless = require('lister.things').bless

local M = {}

function M.load_file (filename)
  local f = io.open(filename, 'r')
  local contents = f:read('a')
  f:close()

  local parsed = chunky.parse(contents)
  parsed.kind = "file"
  parsed.path = filename

  return bless(parsed)
end

function M.write (self)
  local f = assert(io.open(self.path, 'w'))

  f:write(printer.format(self))

  f:close()
end

return M
