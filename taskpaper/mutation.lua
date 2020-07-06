local M = {}

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

  return table.remove(parent.children, path_in_parent[1])
end

return M
