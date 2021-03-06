local taskpaper = require 'taskpaper'
local traversal = require 'lister.things.traversal'

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

local they = it

describe('paths', function ()
  describe('generated', function ()
    they('match what we expect', function ()
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
    they('get the nodes we expect', function ()
      local chunk = taskpaper.parse(examples.chunk)

      local function check(path, expectation)
        assert_subtable(expectation, (chunk:lookup(path)))
      end

      check(":1",     Note())
      check(":3",     Project({name = "Project"}))
      check(":3:3:1", Note())
      check(":3:6:2", Task({name = "do more things"}))
    end)
  end)
end)

describe('lineage', function ()
  it('shows the steps of nameable things to an item', function ()
    local chunk = taskpaper.parse(examples.chunk)
    chunk.name = "(chunk)"

    local function check (path, expected_lineage)
      local item = chunk:lookup(path)
      assert.same(expected_lineage, item.lineage,
          string.format('correct lineage at %s', path))
    end

    check(":1",     {"(chunk)"})
    check(":3:1",   {"(chunk)", "Project"})
    check(":3:3:1", {"(chunk)", "Project", "do another thing"})
    check(":3:6:2", {"(chunk)", "Project", "Subproject"})
  end)
end)

describe('crawling', function ()
  it('returns a sequence of things in depth-first order', function ()
    local chunk = taskpaper.parse(examples.chunk)
    local expectations = {
      {kind = "root"},
      Note(),
      Task({name = "test a top-level task"}),
      Project({name = "Project"}),
      Note(),
      Task({name = "do a thing"}),
      Task({name = "do another thing"}),
      Note(),
      Note({lines = {"This next thing is not special, but it comes after this note."}}),
      Task({name = "do a final thing"}),
      Project({name = "Subproject"}),
      Note({lines = {"This project is a part of that other project."}}),
      Task({name = "do more things"}),
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

describe('filtering', function ()
  it('returns a sequence of things passing a test, in depth-first order', function ()
    local chunk = taskpaper.parse(examples.chunk)
    local expectations = {
      Project({name = "Project"}),
      Project({name = "Subproject"}),
    }

    local function test(thing)
      return thing.kind == "project"
    end

    local i = 0
    for thing in traversal.filter(chunk, test) do
      i = i + 1
      if expectations[i] then
        assert_subtable(expectations[i], thing)
      end
    end

    assert.is_true(i >= #expectations, 'iterator returned at least as many things as expected')
  end)
end)
