local taskpaper = require 'taskpaper'

local examples = require 'spec.taskpaper.examples'
local helpers = require 'spec.taskpaper.helpers'

local assert_subtable = helpers.assert_subtable

local function builder (kind)
  return function (additions)
    additions = additions or {}
    additions.kind = kind
    return additions
  end
end

local Note, Task, Project = builder('note'), builder('task'), builder('project')

describe('paths', function ()
  describe('generated', function ()
    it('match what we expect', function ()
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
  end)

  describe('accessed', function ()
    it('get the nodes we expect', function ()
      local chunk = taskpaper.parse(examples.chunk)

      local function check(path, expectation)
        assert_subtable(expectation, chunk:lookup(path))
      end

      check(":1",     Note())
      check(":3",     Project({name = "Project"}))
      check(":3:3:1", Note())
      check(":3:6:2", Task({text = "do more things"}))
    end)
  end)
end)

describe('crawling', function ()
  it('returns a sequence of things in depth-first order', function ()
    local chunk = taskpaper.parse(examples.chunk)
    local expectations = {
      {kind = "root"},
      Note(),
      Task({text = "test a top-level task"}),
      Project({name = "Project"}),
      Note(),
      Task({text = "do a thing"}),
      Task({text = "do another thing"}),
      Note(),
      Note({lines = {"This next thing is not special, but it comes after this note."}}),
      Task({text = "do a final thing"}),
      Project({name = "Subproject"}),
      Note({lines = {"This project is a part of that other project."}}),
      Task({text = "do more things"}),
      Note({lines = {"This is a final note in the first project."}}),
      Note({lines = {"And with this note, we have completed our example!"}}),
    }

    local i = 0
    for thing in chunk:crawl() do
      i = i + 1
      if expectations[i] then
        assert_subtable(expectations[i], thing)
      end
    end

    assert.is_true(i >= #expectations, 'iterator returned at least as many things as expected')
  end)
end)
