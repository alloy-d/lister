local taskpaper = require 'taskpaper'
local mutation = require 'lister.things.mutation'
local bless = require 'lister.things'.bless

local examples = require 'spec.taskpaper.examples'
local helpers = require 'spec.taskpaper.helpers'
local assert_subtable = helpers.assert_subtable

describe('mutation', function ()
  describe('by appending', function ()
    local chunk, new_item

    before_each(function ()
      chunk = taskpaper.parse(examples.chunk)
      new_item = bless{
        kind = "task",
        text = "test appending",
      }
    end)
    after_each(function ()
      chunk = nil
      new_item = nil
    end)

    it('appends', function ()
      local project_path = ':3'
      local project = chunk:lookup(project_path)
      local initial_children_count = #project.children

      chunk:append(project_path, new_item)

      assert.equal(initial_children_count + 1, #project.children, "project has an additional child")
      assert.same(new_item, project.children[#project.children])
      assert.same(project, new_item.parent)
    end)

    it('maintains original items', function ()
      chunk:append(':3', new_item)
      assert_subtable(examples.chunk_parsed, chunk.children)
    end)
  end)

  describe('by removal', function ()
    local chunk
    before_each(function ()
      chunk = taskpaper.parse(examples.chunk)
    end)
    after_each(function ()
      chunk = nil
    end)

    describe('via root', function ()
      it('removes the expected item', function ()
        -- Remove the first thing in the example chunk, a note.
        chunk:remove(":1")

        -- Make sure the following items (a task and a project) have moved
        -- up.
        assert.same("task", chunk.children[1].kind)
        assert.same("project", chunk.children[2].kind)

        -- Remove the second thing from the second thing (a project).
        local second_thing_name = chunk:lookup(":2:2").name
        local third_thing_name = chunk:lookup(":2:3").name
        chunk:remove(":2:2")
        local new_second_thing = chunk:lookup(":2:2")
        assert.not_same(second_thing_name, new_second_thing.name)
        assert.same(third_thing_name, new_second_thing.name)
      end)

      it('keeps the affected table as a sequence', function ()
        local project = chunk:lookup(":3")
        local initial_children_count = #project.children

        chunk:remove(":3:2")

        assert.equal(initial_children_count - 1, #project.children, "project has one fewer child")
        for i = 1, #project.children do
          assert.not_equal(nil, project.children[i], "no child is nil")
        end
      end)
    end)

    describe('by pruning', function ()
      it('removes the expected item', function ()
        local project = chunk.children[3]
        local item = project.children[2]

        item:prune()

        for _, child in ipairs(project.children) do
          assert.not_equal(item, child)
        end
      end)
    end)
  end)

  describe('by moving', function ()
    local chunk, task, task_initial_path, task_destination_path, task_expected_final_path
    before_each(function ()
      chunk = taskpaper.parse(examples.chunk)
      task_initial_path = ":3:3"
      task_destination_path = ":3:6"
      task_expected_final_path = ":3:5:3"
      task = chunk:lookup(task_initial_path)
    end)
    after_each(function ()
      chunk = nil
      task = nil
      task_initial_path = nil
      task_destination_path = nil
      task_expected_final_path = nil
    end)

    it('moves a thing to a different place', function ()
      local initial_parent, path_in_initial_parent = chunk:lookup(task_initial_path, 1)
      local destination_parent = chunk:lookup(task_destination_path)

      assert.same(initial_parent, task.parent)

      mutation.move(chunk, task_initial_path, chunk, task_destination_path)

      assert.not_same(initial_parent:lookup(path_in_initial_parent), task,
          "task is no longer in initial parent")
      assert.same(destination_parent.children[#destination_parent.children], task,
          "task is in new parent")
      assert.same(destination_parent, task.parent,
          "task's parent is its new project")
    end)

    it('invalidates cached paths in the moved tree', function ()
      local task_child_initial_path = task_initial_path .. ':1'

      -- Make sure the paths are set initially.
      assert.equal(task_child_initial_path, task.children[1].path)
      assert.equal(task_initial_path, task.path)

      mutation.move(chunk, task_initial_path, chunk, task_destination_path)

      assert.not_equal(task_initial_path, task.path)
      assert.not_equal(task_child_initial_path, task.children[1].path)

      assert.equal(task_expected_final_path, task.path)
    end)
  end)
end)
