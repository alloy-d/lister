local M = {}

local traversal = require 'taskpaper.traversal'

-- Takes an `additional_thing`, and appends it as a child of `thing`.
local function adopt(new_parent, new_child)
  new_parent.children[#new_parent.children + 1] = new_child
  new_child.parent = new_parent

  return new_child
end

-- Takes an `additional_thing` and appends it as a child of the thing at
-- `path` in `root`.
function M.append(root, path, additional_thing)
  local new_parent = root:lookup(path)
  return adopt(new_parent, additional_thing)
end

-- Removes the thing at `path` in `root`.
--
-- Returns the removed thing.
function M.remove(root, path)
  local parent, path_in_parent = root:lookup(path, 1)

  local child = table.remove(parent.children, path_in_parent[1])

  child.parent = nil
  traversal.unpopulate_paths(child)

  return child
end

-- Moves the thing at `from_path` in `from_root` to `to_path` in
-- `to_root`.
--
-- Returns the moved thing.
function M.move(from_root, from_path, to_root, to_path)
  -- Look up the new parent first, to handle the case where the new
  -- parent is a sibling of the thing being moved and its path is
  -- changed by the removal.
  local new_parent = to_root:lookup(to_path)

  local thing = from_root:remove(from_path)
  return adopt(new_parent, thing)
end

return M
