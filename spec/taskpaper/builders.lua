local builders = {}

-- Here are some convenience functions to build up the expected data.
function builders.Note(...)
  local lines = table.pack(...)
  lines.n = nil -- table.pack() sets this, parser doesn't.
  return {
    kind = "note",
    lines = lines,
  }
end
function builders.Task(text, tags, children)
  return {
    kind = "task",
    text = text,
    tags = tags,
    children = children,
  }
end
function builders.Tag(name, ...)
  local result = { name = name }

  if select('#', ...) > 0 then
    result.values = table.pack(...)
    result.values.n = nil
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
