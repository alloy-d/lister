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

function M.write_to_file (thing, filename, front_matter)
  local _
  local f, err = io.open(filename, 'w')
  if not f then
    return nil, err
  end

  if front_matter then
    _, err = f:write(front_matter .. "\n")
    if err then
      goto cleanup
    end
  end

  _, err = f:write(printer.format(thing))

  ::cleanup::
  f:close()

  if err then
    return nil, err
  end

  return true
end

function M.write (self, front_matter)
  return M.write_to_file(self, self.name, front_matter)
end

return M
