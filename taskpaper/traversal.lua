local M = {}

-- Turn a serialized path (separated by ':') into a table.
function M.parse_path(path_string)
  local path = {}
  for part in path_string:gmatch('[^:]+') do
    path[#path + 1] = tonumber(part) or part
  end
  return path
end

-- Populate a thing's children's paths.
--
-- Populated paths will be strings separated by colons.
function M.populate_paths(thing)
  -- General approach:
  --    1. if we don't know this thing's path, tell its parent to
  --       populate its children's paths.
  --    2. populate this thing's children's paths once we know its path.
  --
  -- Eventually we'll get down to a file, which has a file path.

  if not thing.path then
    thing.parent:populate_paths()
  end

  for i, child in ipairs(thing.children) do
    child.path = thing.path .. ':' .. i
  end
end

-- Returns the thing at the given path.
-- If `path` is a string, first parses it via `parse_path`.
--
-- If `leave_untraversed_count` is given, returns the thing that many
-- steps from the end of the path, along with the untraversed portion of
-- `path`.
--
-- For example, providing `leave_untraversed_count=1` will return the
-- parent of the thing at `path`, plus the index of the thing in that
-- parent's children.
function M.lookup(thing, path, leave_untraversed_count)
  leave_untraversed_count = leave_untraversed_count or 0

  if type(path) == 'string' then
    path = M.parse_path(path)
  end

  if #path == leave_untraversed_count then -- we're looking at the thing we wanted to find
    return thing, path
  elseif #path < leave_untraversed_count then
    error(string.format("path is not long enough to leave %d steps untraversed", leave_untraversed_count))
  end

  return M.lookup(thing.children[path[1]], table.move(path, 2, #path, 1, {}), leave_untraversed_count)
end

local function crawler(thing)
  return function ()
    coroutine.yield(thing)
    if thing.children then
      for _, child in ipairs(thing.children) do
        crawler(child)()
      end
    end
  end
end

function M.crawl(thing)
  local co = coroutine.create(crawler(thing))

  return function ()
    local _, res = coroutine.resume(co)
    return res
  end
end

return M
