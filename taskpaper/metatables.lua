local function index(thing, key)
  if key == 'lineage' and thing.rooted then
    return {}
  elseif key == 'path' or key == 'lineage' then
    thing.parent:populate_paths()
    return thing[key] -- should be set by now
  elseif key == 'name' and thing.nameable_by then
    return thing[thing.nameable_by]
  end

  -- For anything besides the path, index the metatable.
  return getmetatable(thing)[key]
end

local metatables = {
  file = {
    kind = "file",
    nameable_by = 'path',
    rooted = true,
    __index = index,
  },
  root = {
    kind = "root",
    nameable_by = 'path',
    rooted = true,
    __index = index,
  },
  project = {
    kind = "project",
    nameable_by = 'name',
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
