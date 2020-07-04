local printer = require 'taskpaper.printer'
local traversal = require 'taskpaper.traversal'

local M = {}

local function index(thing, key)
  if key == 'path' then
    thing.parent:populate_paths()
    return thing.path -- should be set by now
  end

  -- For anything besides the path, index the metatable directly.
  return rawget(getmetatable(thing), key)
end

local metatables = {
  root = {
    kind = "root",
    totaskpaper = printer.format,
    populate_paths = traversal.populate_paths,
    lookup = traversal.lookup,
    crawl = traversal.crawl,
    __index = index,
  },
  project = {
    kind = "project",
    totaskpaper = printer.format_project,
    populate_paths = traversal.populate_paths,
    lookup = traversal.lookup,
    crawl = traversal.crawl,
    __index = index,
  },
  task = {
    kind = "task",
    totaskpaper = printer.format_task,
    populate_paths = traversal.populate_paths,
    lookup = traversal.lookup,
    crawl = traversal.crawl,
    __index = index,
  },
  note = {
    kind = "note",
    totaskpaper = printer.format_note,
    __index = index,
  },
}

-- Sets the appropriate metatable for the given table, then returns it.
function M.bless(table)
  local metatable = metatables[table.kind]
  setmetatable(table, metatable)
  return table
end

return M
