local tplines = require 'taskpaper/lines'

local chunky = {}

local function Project (header, depth)
  if not header then
    return nil
  end

  return {
    kind = "project",
    name = header,
    parent = nil,
    children = {},
    _depth = depth,
  }
end

local function Task (text, depth, tags)
  if not text then
    return nil
  end

  return {
    kind = "task",
    text = text,
    tags = tags,
    parent = nil,
    children = {},
    _depth = depth,
  }
end

local function Note (text, depth)
  if not text then
    -- Happens for empty lines, e.g.
    return nil
  end

  return {
    kind = "note",
    lines = { text },
    parent = nil,
    _depth = depth,
  }
end

local function print_thing(thing, label) -- luacheck: ignore
  if not thing then
    print(label, nil)
    return
  end

  local repr = thing.text
  repr = repr or thing.lines and table.concat(thing.lines, "\n")
  repr = repr or thing.name

  print(label, thing.kind, repr)
end

function chunky.parse (chunk)
  local root = {
    kind = "root",
    parent = nil,
    _depth = 1,
    children = {},
  }
  -- Create a dummy previous item that could never have children.
  -- This lets us avoid a bunch of special-casing for dealing with the
  -- first item.
  local previous = {
    _depth = math.huge,
    parent = root,
  }

  local function register_parent(parent, item)
    item.parent = parent
    table.insert(parent.children, item)
  end

  for line in chunk:gmatch('[^\n]*') do
    local item
    item = Project(tplines.parse_header(line))
    item = item or Task(tplines.parse_task(line))
    item = item or Note(tplines.parse_note(line))

    -- We'll have to start with some special handling for notes.
    --
    -- If this line has nothing in it but the previous line was a note,
    -- then this line might represent a blank line in the note.
    if previous.kind == "note" and not item then
      table.insert(previous.lines, "")
      goto skip -- don't update previous item.

    -- Otherwise, if this line was empty, just forget about it.
    elseif not item then
      goto skip

    -- Now we get to the rest of the special note handling.
    -- If this line is a note and the last line was a note, then let's
    -- treat them as a single note.
    --
    -- Note that the first line of a note gets processed below, in the
    -- general process for dealing with any kind of line.
    elseif item.kind == "note" and previous.kind == "note" and item._depth >= previous._depth then
      -- Notes could contain indented lines.  To preserve the indent,
      -- we need to add it explicitly, since the parser can't
      -- distinguish between indent and depth in the hierarchy.
      local note_line = item.lines[1]
      if item._depth > previous._depth then
        note_line = string.rep(' ', (item._depth - previous._depth)) .. note_line
      end
      table.insert(previous.lines, note_line)
      goto skip -- don't update previous item.

    -- Items with depth 1 are top-level items.
    elseif item._depth == 1 then
      register_parent(root, item)

    -- If the depth is greater than the previous item's, then this item
    -- is a child of the previous item.
    elseif item._depth > previous._depth then
      register_parent(previous, item)

    -- Otherwise, this item a child of one of the previous item's
    -- ancestors.
    elseif item._depth <= previous._depth then
      local ancestor = previous.parent
      while ancestor and ancestor._depth >= item._depth do
        ancestor = ancestor.parent
      end
      register_parent(ancestor, item)
    end

    previous = item

    ::skip::
  end

  return root
end

return chunky
