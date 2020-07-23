local function indent(depth)
  -- Here's a hacky way to let us use spaces in testing but tabs by
  -- default.  taskpaper.vim only recognizes tasks that are indented
  -- with tabs,aseemingly for compatibility with old versions of
  -- Taskpaper.
  local indent_string = TASKPAPER_INDENT_STRING or "\t" -- luacheck: ignore
  return depth and string.rep(indent_string, depth) or ""
end

local formatters = {}
local format -- top-level formatting function; declared here for use in helpers

local function format_header(header, depth)
  return string.format("%s%s:", indent(depth), header)
end

function formatters.project(project, depth)
  depth = depth or 0
  return format_header(project.name, depth) .. "\n" .. formatters.root(project, depth + 1)
end

function formatters.note(note, depth)
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

function formatters.task(task, depth)
  local result = string.format("%s- %s", indent(depth), task.name)
  if task.tags then
    for _, tag in ipairs(task.tags) do
      result = result .. " " .. format_tag(tag)
    end
  end

  if task.children then
    result = result .. "\n" .. formatters.root(task, depth + 1)
  end

  return result
end

-- Formats a taskpaper tree from the root.
--
-- Also used to format the contents of other things with children, like
-- projects and tasks.
function formatters.root(root, depth)
  depth = depth or 0
  local formatted = {}

  for i, item in ipairs(root.children or {}) do
    -- Add a blank line between project headers or notes if anything
    -- precedes them.
    if i ~= 1 and (item.kind == "project" or item.kind == "note") then
      table.insert(formatted, "")
    end

    table.insert(formatted, format(item, depth))
  end

  return table.concat(formatted, "\n")
end

formatters.file = formatters.root

-- Formats a taskpaper thing.
format = function (thing, depth)
  depth = depth or 0

  local formatter = formatters[thing.kind]
  if not formatter then
    error(string.format("kind is unformattable: '%s'", thing.kind))
  end

  return formatter(thing, depth)
end

return {
  format = format,
}
