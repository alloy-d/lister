local assert = require('luassert')

local M = {}

function M.assert_subtable(base, supertable, path)
  path = path or ""

  assert.equals("table", type(base))
  assert.equals("table", type(supertable), "expected table at " .. path)

  for key, value in pairs(base) do
    local path = string.format('%s[%s]', path, key) -- luacheck: ignore

    assert.not_equals(nil, supertable[key], "missing value at " .. path)

    if type(value) == "table" then
      M.assert_subtable(value, supertable[key], path)
    else
      assert.same(value, supertable[key], "value mismatch at " .. path)
    end
  end
end

return M
