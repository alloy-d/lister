local taskpaper = require 'taskpaper'

local binstring = require 'luassert.formatters.binarystring'

local examples = require 'spec.taskpaper.examples'

describe("round trip", function ()
  setup(function ()
    assert:add_formatter(binstring)
  end)
  teardown(function ()
    assert:remove_formatter(binstring)
  end)

  describe("of tasks", function ()
    it("parses and reformats a task to the same string", function ()
      local tasks = {
        "- do a thing",
        "- do a thing with a @tag",
        "- do a thing with @two @tags",
        "- do a thing with @valued(1, 2) @tags",
      }

      for _, task in ipairs(tasks) do
        assert.same(task, taskpaper.parse(task):totaskpaper())
      end
    end)
  end)

  describe("of full taskpaper blob", function ()
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

      assert.same(example, taskpaper.parse(example):totaskpaper())
    end)
  end)

  describe("through a file", function ()
    it("results in the same blob", function ()
      local path = os.tmpname()

      local root = taskpaper.parse(examples.chunk)
      root.kind = "file"
      root.path = path
      root = taskpaper.bless(root)

      root:write()

      local loaded = taskpaper.load_file(path)

      assert.same(root, loaded)

      assert(os.remove(path))
    end)
  end)
end)
