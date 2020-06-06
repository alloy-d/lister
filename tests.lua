local lust = require 'lust'
local describe, it, expect = lust.describe, lust.it, lust.expect

local taskpaper = require 'taskpaper'

-- These let you do something like `map(enquote, list_of_strings)` to
-- make string comparisons more clear when they involve leading or
-- trailing whitespace.
local function map (f, xs)
  local results = {}
  for i = 1, #xs do
    results[i] = f(xs[i])
  end
  return results
end
local function enquote(str)
  return string.format("'%s'", str)
end

describe('line-level taskpaper parser', function ()
  describe('headers', function ()
    local parse = taskpaper.parse_header

    it('returns nil if not given a header', function ()
      local not_headers = {
        "",
        "I am not a header.",
        "I am not a header: part II",
        "- I am a task.",
      }

      for _, not_header in ipairs(not_headers) do
        expect(parse(not_header)).to_not.exist()
      end
    end)

    it('returns the header text', function ()
      local examples = {
        ["A header:"] = "A header",
        ["  A subheader:"] = "A subheader",
        ["A tricky header: with colons:"] = "A tricky header: with colons",
      }

      for header, expected in pairs(examples) do
        expect(parse(header)).to.equal(expected)
      end
    end)

    it('returns depth', function ()
      local examples = {
        ["A header:"] = 1,
        ["  A subheader:"] = 3,
        ["\tA subheader:"] = 2,
        ["\t Please don't do this:"] = 3,
      }

      for header, expected in pairs(examples) do
        local _, depth = parse(header)
        expect(depth).to.equal(expected)
      end
    end)
  end)

  describe('tasks', function ()
    local parse = taskpaper.parse_task

    local examples = {
      ["- Test this root-level task"] = {
        depth = 1,
        text = "Test this root-level task",
      },

      ["  - Do this thing in a project"] = {
        depth = 3,
        text = "Do this thing in a project",
      },

      ["\t- Do this thing in a project"] = {
        depth = 2,
        text = "Do this thing in a project",
      },

      ["\t - Stop mixing tabs and spaces"] = {
        depth = 3,
        text = "Stop mixing tabs and spaces",
      },

      ["- Try tags @lifehacks"] = {
        depth = 1,
        text = "Try tags",
        tags = {
          lifehacks = true,
        },
      },

      ["- Try tags with values @value(bingo) @values(whee, hooray)"] = {
        depth = 1,
        text = "Try tags with values",
        tags = {
          value = "bingo",
          values = {"whee", "hooray"},
        },
      },

      ["- Test tags @with garbage @between"] = {
        depth = 1,
        text = "Test tags",
        tags = {
          with = true,
          between = true,
        }
      },
    }

    it('returns the note text', function ()
      for task, expected in pairs(examples) do
        local text = parse(task)
        expect(text).to.be(expected.text)
      end
    end)

    it('returns depth', function ()
      for task, expected in pairs(examples) do
        local _, depth = parse(task)
        expect(depth).to.be(expected.depth)
      end
    end)

    it('returns tags', function ()
      for task, expected in pairs(examples) do
        local expected_tags = expected.tags or {}

        local _, _, tags = parse(task)

        -- Make sure that we parsed all the expected tags.
        for tag, value in pairs(expected_tags) do
          expect(tags[tag]).to.exist()
          expect(tags[tag]).to.equal(value)
        end

        -- Also make sure that we didn't parse any _extra_ tags.
        for tag, _ in pairs(tags) do
          expect(expected_tags[tag]).to.exist()
        end
      end
    end)

    it('returns nil if not given a task', function ()
      local not_tasks = {
        "I am just a note.",
        "Header full of tasks:",
        "I am also a note - but a tricky one!",
      }

      for _, not_task in ipairs(not_tasks) do
        expect(parse(not_task)).to_not.exist()
      end
    end)
  end)

  describe('notes', function ()
    local parse = taskpaper.parse_note

    it('excludes surrounding whitespace', function ()
      local examples = {
        ["This is a note."] = "This is a note.",
        ["  This is another note."] = "This is another note.",
        ["\tThis is another note."] = "This is another note.",
        ["\t This is awful."] = "This is awful.",
        ["  This is weird, but fine.  "] = "This is weird, but fine."
      }

      for note, expected in pairs(examples) do
        expect(parse(note)).to.equal(expected)
      end
    end)

    it('returns note depth', function ()
      local examples = {
        ["This is a note."] = 1,
        ["  This is a note in some context."] = 3,
        ["\tThis is a note about people who use tabs."] = 2,
        ["\t This is a note about misguided people."] = 3,
      }

      for note, expected in pairs(examples) do
        local _, depth = parse(note)
        expect(depth).to.be(expected)
      end
    end)
  end)
end)
