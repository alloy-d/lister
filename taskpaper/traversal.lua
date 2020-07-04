local M = {}

-- Turn a serialized path (separated by ':') into a table.
local function parse_path(path_string)
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
function M.lookup(thing, path)
  if type(path) == 'string' then
    path = parse_path(path)
  end

  if #path == 0 then -- we're looking at the thing we wanted to find
    return thing
  end

  return M.lookup(thing.children[path[1]], table.move(path, 2, #path, 1, {}))
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
