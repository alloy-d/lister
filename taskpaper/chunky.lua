local tplines = require 'taskpaper.lines'
local tpmeta = require 'taskpaper.tables'

local bless = tpmeta.bless

local chunky = {}

local function Project (header, depth)
  if not header then
    return nil
  end

  return bless{
    kind = "project",
    name = header,
    parent = nil,
    _depth = depth,
  }
end

local function Task (text, depth, tags)
  if not text then
    return nil
  end

  return bless{
    kind = "task",
    text = text,
    tags = tags,
    parent = nil,
    _depth = depth,
  }
end

local function Note (text, depth)
  if not text then
    -- Happens for empty lines, e.g.
    return nil
  end

  return bless{
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
  local root = bless{
    kind = "root",
    parent = nil,
    _depth = 1,
  }
  -- Create a dummy previous item that could never have children.
  -- This lets us avoid a bunch of special-casing for dealing with the
  -- first item.
  local previous = {
    _depth = math.huge,
    parent = root,
  }

  -- We'll use this awkward variable to track whether we might be
  -- in the middle of a note separated with a (single) blank line.
  -- If we see multiple blank lines, we'll split those into separate
  -- notes.
  local empty_lines_since_last_note = 0

  local function register_parent(parent, item)
    item.parent = parent
    if not parent.children then
      parent.children = {}
    end
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
      empty_lines_since_last_note = empty_lines_since_last_note + 1
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
    elseif item.kind == "note" and previous.kind == "note" and
        item._depth >= previous._depth and empty_lines_since_last_note <= 1 then
      -- Notes could contain indented lines.  To preserve the indent,
      -- we need to add it explicitly, since the parser can't
      -- distinguish between indent and depth in the hierarchy.
      local note_line = item.lines[1]
      if item._depth > previous._depth then
        note_line = string.rep(' ', (item._depth - previous._depth)) .. note_line
      end

      -- If we've passed an empty line since the last note, then let's
      -- explicitly add it here to preserve it.  We do it here so that
      -- we only add an empty line if the note continues; otherwise,
      -- we'd risk adding empty lines in other situations where the
      -- input might have legimate empty space, like separating a note
      -- from a following project header.
      if empty_lines_since_last_note > 0 then
        table.insert(previous.lines, "")
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
    if item and item.kind == "note" then
      empty_lines_since_last_note = 0
    end
  end

  return root
end

return chunky
