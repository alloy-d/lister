local builders = {}

-- Here are some convenience functions to build up the expected data.
function builders.Note(...)
  return {
    kind = "note",
    lines = {...},
  }
end
function builders.Task(name, tags, children)
  return {
    kind = "task",
    name = name,
    tags = tags,
    children = children,
  }
end
function builders.Tag(name, ...)
  local result = { name = name }

  if select('#', ...) > 0 then
    result.values = {...}
  end

  return result
end
function builders.Project(name, children)
  return {
    kind = "project",
    name = name,
    children = children,
  }
end
function builders.Root(children)
  return {
    kind = "root",
    children = children,
  }
end

return builders
