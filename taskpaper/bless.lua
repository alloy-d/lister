local metatables = require 'taskpaper.metatables'

-- Sets the appropriate metatable for the given table, then returns it.
local function bless (table)
  local metatable = metatables[table.kind]
  if not metatable then
    error(string.format("no metatable for kind '%s'", table.kind))
  end

  setmetatable(table, metatable)
  return table
end

return bless
