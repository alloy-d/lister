local printer = require 'taskpaper.printer'

local builders = require 'spec.taskpaper.builders'
local Note, Project, Root, Tag, Task = builders.Note, builders.Project, builders.Root, builders.Tag, builders.Task

local function example (data)
  it('formats ' .. data.desc, function ()
    local formatted = printer.format(data.input, data.depth)
    assert.same(data.output, formatted)
  end)
end

describe('taskpaper printer', function ()
  describe('for notes', function ()
    example{
      desc = 'single-line notes',
      input = Note("just a single line"),
      output = "just a single line"
    }

    example{
      desc = 'multiline notes',
      input = Note(
        "this has one line",
        "and another line"
      ),
      output = "this has one line\nand another line"
    }

    example{
      desc = 'notes with depth',
      input = Note(
        "this note has some depth",
        "but not a lot of depth"
      ),
      depth = 1,
      output = "  this note has some depth\n  but not a lot of depth"
    }

    example{
      desc = 'notes with indented content',
      input = Note(
        "there once was a testing example",
        "its extra blank spaces were ample",
        "   these next lines have three",
        "   leading spaces, you see",
        "and that is the whole of the sample"
      ),
      depth = 4,
      output = [[
        there once was a testing example
        its extra blank spaces were ample
           these next lines have three
           leading spaces, you see
        and that is the whole of the sample]],
    }
  end)

  describe('for tasks', function ()
    example{
      desc = "a simple task",
      input = Task(
        "do something simple"
      ),
      output = "- do something simple",
    }

    example{
      desc = "a task with simple tags",
      input = Task(
        "do a thing with tags", {
          Tag("tags"),
          Tag("hooray"),
        }
      ),
      output = "- do a thing with tags @tags @hooray",
    }

    example{
      desc = "a task with valued tags",
      input = Task(
        "do this thing", {
          Tag("done", "2020-06-11"),
          Tag("values", "one", "two"),
        }
      ),
      output = "- do this thing @done(2020-06-11) @values(one, two)",
    }
  end)

  local sample_project = Project("Test printer", {
    Note("This should already be indented with depth 1."),
    Task("let's due this!", {Tag("due", "2020-06-12")}),

    Project("Test printing subprojects", {
      Task("make sure this has more depth", nil, {
        Note("This task has a note."),
      }),
      Note("This is a project-level note."),
    }),
  })
  local sample_project_printed = [[
Test printer:
  This should already be indented with depth 1.
  - let's due this! @due(2020-06-12)

  Test printing subprojects:
    - make sure this has more depth
      This task has a note.

    This is a project-level note.]]

  describe('for projects', function ()
    example{
      desc = "a project",
      input = sample_project,
      output = sample_project_printed,
    }
  end)

  describe('for general trees', function ()
    local sample_task = Task("do a standalone task")
    local sample_task_printed = "- do a standalone task"

    local sample_note = Note(
      "Let's talk about standalone notes.  You might find them",
      "at the top level of your taskpaper tree."
    )
    local sample_note_printed = [[
Let's talk about standalone notes.  You might find them
at the top level of your taskpaper tree.]]

    local sample_root = {
      sample_task,
      sample_project,
      sample_note
    }
    local sample_root_printed = table.concat({
      sample_task_printed,
      "",
      sample_project_printed,
      "",
      sample_note_printed,
    }, "\n")

    example{
      desc = "a root",
      input = Root(sample_root),
      output = sample_root_printed,
    }

    example{
      desc = "a root at depth",
      input = Root(sample_root),
      depth = 2,
      output = "    " .. sample_root_printed:gsub("\n%f[^\n]", "\n    "),
    }
  end)
end)
