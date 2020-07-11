local function index(thing, key)
  if key == 'path' then
    thing.parent:populate_paths()
    return thing.path -- should be set by now
  end

  -- For anything besides the path, index the metatable.
  return getmetatable(thing)[key]
end

local metatables = {
  file = {
    kind = "file",
    __index = index,
  },
  root = {
    kind = "root",
    __index = index,
  },
  project = {
    kind = "project",
    __index = index,
  },
  task = {
    kind = "task",
    __index = index,
  },
  note = {
    kind = "note",
    __index = index,
  },
}

setmetatable(metatables.file, metatables.root)

return metatables
