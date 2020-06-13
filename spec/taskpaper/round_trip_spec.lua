local taskpaper = require 'taskpaper'

local binstring = require 'luassert.formatters.binarystring'

describe("round trip", function ()
  setup(function ()
    assert:add_formatter(binstring)
  end)
  teardown(function ()
    assert:remove_formatter(binstring)
  end)

  it("parses and reformats well-formed taskpaper to the same string", function ()
    local example = [[
- do this top-level task

A project:
  - do this thing for the project
  - do this other thing for the project

  These next tasks are important because they test more complex
  parts of the system like tags and task-level notes.
  - do a thing with tags @tag @some-numbers(1, 2)
  - do a thing with a note
    This is the note that goes with this thing.

Let's hope this works out OK!]]

    assert.same(example, taskpaper.format(taskpaper.parse(example)))
  end)
end)
