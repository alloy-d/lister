local function indent(depth)
  return depth and string.rep("  ", depth) or ""
end

local format -- top-level formatting function; declared here for use in helpers

local function format_header(header, depth)
  return string.format("%s%s:", indent(depth), header.name)
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
    result = result .. "\n" .. format(task.children, depth + 1)
  end

  return result
end

-- Prints a taskpaper tree.
format = function (tree, depth)
  depth = depth or 0
  local formatted = {}

  for i = 1, #tree do
    local item = tree[i]

    -- Add a blank line before project headers or notes.
    if i ~= 1 and (item.kind == "project" or item.kind == "note") then
      table.insert(formatted, "")
    end

    if item.kind == "project" then
      table.insert(formatted, format_header(item, depth))
      table.insert(formatted, format(item.children, depth + 1))
    elseif item.kind == "task" then
      table.insert(formatted, format_task(item, depth))
    elseif item.kind == "note" then
      table.insert(formatted, format_note(item, depth))
    end
  end

  return table.concat(formatted, "\n")
end

return {
  format_header = format_header,
  format_task = format_task,
  format_note = format_note,
  format = format,
}
