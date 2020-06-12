local taskpaper = require 'taskpaper.chunky'

local builders = require 'spec.taskpaper.builders'
local Note, Project, Tag, Task = builders.Note, builders.Project, builders.Tag, builders.Task

-- This does what I would have expected pending() to do already.
local function pend(name) -- luacheck: ignore
  pending(name, function () end)
end

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


local example = [[
This is a chunk of taskpaper.
It contains a hierarchy of notes, projects, and tasks.
- test a top-level task

Project:
  This is an imaginary project. As part of it, we will do some things in order.
  - do a thing @first
  - do another thing @second(2)
    This thing should happen after that last one,
    and it should have this note attached.

  This next thing is not special, but it comes after this note.
  - do a final thing @things-done(first, second, final)

  Subproject:
    This project is a part of that other project.
    - do more things
]]

local example_parsed = {
  Note(
    "This is a chunk of taskpaper.",
    "It contains a hierarchy of notes, projects, and tasks."
  ),
  Task("test a top-level task"),
  Project("Project", {
    Note("This is an imaginary project. As part of it, we will do some things in order."),
    Task("do a thing", {Tag("first")}),
    Task("do another thing", {Tag("second", "2")}, {
      Note(
        "This thing should happen after that last one,",
        "and it should have this note attached."
      )
    }),
    Note("This next thing is not special, but it comes after this note."),
    Task("do a final thing", {Tag("things-done", "first", "second", "final")}),
    Project("Subproject", {
      Note("This project is a part of that other project."),
      Task("do more things"),
    }),
  }),
}

describe("chunk-level taskpaper parser", function ()
  it("should parse a chunk as expected", function ()
    local parsed = taskpaper.parse(example)
    assert_subtable(example_parsed, parsed.children)
  end)
end)
