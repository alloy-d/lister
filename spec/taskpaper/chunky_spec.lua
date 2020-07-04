local taskpaper = require 'taskpaper.chunky'

local examples = require 'spec.taskpaper.examples'

local function assert_subtable(base, supertable, path)
  path = path or ""

  assert.equals("table", type(base))
  assert.equals("table", type(supertable), "expected table at " .. path)

  for key, value in pairs(base) do
    local path = string.format('%s[%s]', path, key) -- luacheck: ignore

    assert.not_equals(nil, supertable[key], "missing value at " .. path)

    if type(value) == "table" then
      assert_subtable(value, supertable[key], path)
    else
      assert.same(value, supertable[key], "value mismatch at " .. path)
    end
  end
end

describe("chunk-level taskpaper parser", function ()
  it("should parse a chunk as expected", function ()
    local parsed = taskpaper.parse(examples.chunk)
    assert_subtable(examples.chunk_parsed, parsed.children)
  end)
end)
