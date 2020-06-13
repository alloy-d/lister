local chunky = require 'taskpaper.chunky'

local M = {}

function M.load_file (filename)
  local f = io.open(filename, 'r')
  local contents = f:read('a')
  f:close()

  local parsed = chunky.parse(contents)
  parsed.kind = "file"
  parsed.path = filename

  return parsed
end

return M
