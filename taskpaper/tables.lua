local printer = require 'taskpaper.printer'

local M = {}

local function index(thing, key)
  if key == 'path' then
    thing.parent:populate_paths()
    return thing.path -- should be set by now
  end

  -- For anything besides the path, index the metatable directly.
  return rawget(getmetatable(thing), key)
end

local function populate_paths(thing)
  -- General approach:
  --    1. if we don't know this thing's path, tell its parent to
  --       populate its children's paths.
  --    2. populate this thing's children's paths once we know its path.
  --
  -- Eventually we'll get down to a file, which has a file path.

  if not thing.path then
    thing.parent:populate_paths()
  end

  for i, child in ipairs(thing.children) do
    child.path = thing.path .. ':' .. i
  end
end

local metatables = {
  root = {
    kind = "root",
    totaskpaper = printer.format,
    populate_paths = populate_paths,
    __index = index,
  },
  project = {
    kind = "project",
    totaskpaper = printer.format_project,
    populate_paths = populate_paths,
    __index = index,
  },
  task = {
    kind = "task",
    totaskpaper = printer.format_task,
    populate_paths = populate_paths,
    __index = index,
  },
  note = {
    kind = "note",
    totaskpaper = printer.format_note,
    populate_paths = populate_paths,
    __index = index,
  },
}

-- Sets the appropriate metatable for the given table, then returns it.
function M.bless(table)
  local metatable = metatables[table.kind]
  setmetatable(table, metatable)
  return table
end

local function filter_by_tag(self, tag)
end
local function filter (self, criteria)
end

return M
