local taskpaper = require 'taskpaper.chunky'

local examples = require 'spec.taskpaper.examples'
local helpers = require 'spec.taskpaper.helpers'

describe("chunk-level taskpaper parser", function ()
  it("should parse a chunk as expected", function ()
    local parsed = taskpaper.parse(examples.chunk)
    helpers.assert_subtable(examples.chunk_parsed, parsed.children)
  end)
end)
