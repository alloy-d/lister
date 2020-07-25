local chunky = require 'taskpaper.chunky'
local printer = require 'taskpaper.printer'
local bless = require('lister.things').bless

local M = {}

function M.load_file (filename)
  local f, err = io.open(filename, 'r')
  if not f then
    return nil, err
  end

  local contents = f:read('a')
  f:close()

  local parsed = chunky.parse(contents)
  parsed.kind = "file"
  parsed.name = filename

  return bless(parsed)
end

function M.write (self)
  local _
  local f, err = io.open(self.name, 'w')
  if not f then
    return nil, err
  end

  _, err = f:write(printer.format(self))

  f:close()

  if err then
    return nil, err
  end

  return true
end

return M
