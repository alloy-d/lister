local function indent(depth)
  -- Here's a hacky way to let us use spaces in testing but tabs by
  -- default.  taskpaper.vim only recognizes tasks that are indented
  -- with tabs,aseemingly for compatibility with old versions of
  -- Taskpaper.
  local indent_string = TASKPAPER_INDENT_STRING or "\t" -- luacheck: ignore
  return depth and string.rep(indent_string, depth) or ""
end

local format -- top-level formatting function; declared here for use in helpers

local function format_header(header, depth)
  return string.format("%s%s:", indent(depth), header)
end

local function format_project(project, depth)
  depth = depth or 0
  return format_header(project.name, depth) .. "\n" .. format(project, depth + 1)
end

local function format_note(note, depth)
  local lines
  if not depth or depth == 0 then
    lines = note.lines
  else
    lines = {}
    for i=1, #note.lines do
      lines[i] = indent(depth) .. note.lines[i]
    end
  end

  return table.concat(lines, "\n")
end

local function format_tag(tag)
  local formatted = "@" .. tag.name
  if tag.values then
    formatted = formatted .. "(" .. table.concat(tag.values, ", ") .. ")"
  end
  return formatted
end

local function format_task(task, depth)
  local result = string.format("%s- %s", indent(depth), task.text)
  if task.tags then
    for _, tag in ipairs(task.tags) do
      result = result .. " " .. format_tag(tag)
    end
  end

  if task.children then
    result = result .. "\n" .. format(task, depth + 1)
  end

  return result
end

-- Prints a taskpaper tree.
format = function (tree, depth)
  depth = depth or 0
  local formatted = {}

  for i = 1, #tree.children do
    local item = tree.children[i]

    -- Add a blank line between project headers or notes if anything
    -- precedes them.
    if i ~= 1 and (item.kind == "project" or item.kind == "note") then
      table.insert(formatted, "")
    end

    if item.kind == "project" then
      table.insert(formatted, format_project(item, depth))
    elseif item.kind == "task" then
      table.insert(formatted, format_task(item, depth))
    elseif item.kind == "note" then
      table.insert(formatted, format_note(item, depth))
    end
  end

  return table.concat(formatted, "\n")
end

return {
  format_task = format_task,
  format_note = format_note,
  format_project = format_project,
  format = format,
}
