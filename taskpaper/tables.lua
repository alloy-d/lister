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

-- Turn a serialized path (separated by ':') into a table.
local function parse_path(path_string)
  local path = {}
  for part in path_string:gmatch('[^:]+') do
    path[#path + 1] = tonumber(part) or part
  end
  return path
end

-- Returns the thing at the given path.
-- If `path` is a string, first parses it via `parse_path`.
local function lookup(thing, path)
  if type(path) == 'string' then
    path = parse_path(path)
  end

  if #path == 0 then -- we're looking at the thing we wanted to find
    return thing
  end

  return lookup(thing.children[path[1]], table.move(path, 2, #path, 1, {}))
end

local metatables = {
  root = {
    kind = "root",
    totaskpaper = printer.format,
    populate_paths = populate_paths,
    lookup = lookup,
    __index = index,
  },
  project = {
    kind = "project",
    totaskpaper = printer.format_project,
    populate_paths = populate_paths,
    lookup = lookup,
    __index = index,
  },
  task = {
    kind = "task",
    totaskpaper = printer.format_task,
    populate_paths = populate_paths,
    lookup = lookup,
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
