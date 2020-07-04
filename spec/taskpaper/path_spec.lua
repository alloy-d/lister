local taskpaper = require 'taskpaper'

local examples = require 'spec.taskpaper.examples'

describe('paths', function ()
  describe('generated', function ()
    local chunk = taskpaper.parse(examples.chunk)
    chunk.path = "(chunk)"

    local expectations = {
      {"(chunk):1", chunk.children[1].path},
      {"(chunk):3", chunk.children[3].path},
      {"(chunk):3:1", chunk.children[3].children[1].path},
      {"(chunk):3:3:1", chunk.children[3].children[3].children[1].path},
      {"(chunk):3:6:2", chunk.children[3].children[6].children[2].path},
    }

    for _, pair in ipairs(expectations) do
      assert.same(table.unpack(pair))
    end
  end)

  describe('accessed', function ()
  end)
end)
