local taskpaper = {}

-- Parses a header line.
--
-- If the line is a header line, returns the header and its depth (i.e.,
-- where it started on the line).
--
-- Returns nil if the line is not a header line.
function taskpaper.parse_header (line)
  -- The header name is everything from the first non-space character
  -- to the the colon.  If the line ends in anything but a colon,
  -- then it's not a header line.
  local first, last = line:find('%S.+:$')

  if first then
    local depth = first
    local header = line:sub(first, -2)

    return header, depth
  else
    return nil
  end
end

-- Parses a task.
--
-- Returns the task text, its depth, and a list of tags.
--
-- Returns nil if the line is not a task.
function taskpaper.parse_task (line)
  local task_string = line:match('^%s*-%s+(.*%S)%s*$')

  if task_string then
    local depth = line:find('-')
    local text = task_string
    local tags = {}

    --local tag_pattern = '%s+@([-_%w]+)%(?([^%)]*)%)?'
    local tag_name_pattern = '%s+@([-_%w]+)'
    local tags_start = task_string:find(tag_name_pattern)

    if tags_start then
      -- Everything up to the first tag is the text part of the task.
      text = task_string:sub(1, tags_start - 1)

      -- We'll take everything from the first tag name to be the tags
      -- part of the task.
      local tags_string = task_string:sub(tags_start)

      -- The values of a tag are contained in balanced parentheses.
      -- Anchor it to the beginning of the string, because we'll start
      -- the search for it at the end of the tag name.
      local value_pattern = '^%b()'

      -- We'll first try to match a tag name.
      --
      -- Once we've got a tag name, we'll try to match values right
      -- after it.
      local last_tag_end = 1
      while true do
        local name_start, name_end, name = tags_string:find(tag_name_pattern, last_tag_end)
        if not name_start then break end

        -- If a tag is provided without a value, we'll just return its
        -- value as true.
        local tag_value = true

        -- Now let's see if it was provided with a value.
        local values_start, values_end = tags_string:find(value_pattern, name_end + 1)

        if values_start then
          -- The match includes the parentheses, so let's drop them.
          local values_string = tags_string:sub(values_start + 1, values_end - 1)

          -- Multiple values can be provided, separated by commas.
          local separator_pattern = "%s*,%s*"
          local next_sep_start, next_sep_end = values_string:find(separator_pattern, 1)

          if not next_sep_start then
            -- If there's just one value, let's use that directly.
            tag_value = values_string
          else
            -- Otherwise, we'll return a list of all the values.
            tag_value = {}

            -- We're doing a whole lot of gymnastics here to reuse the
            -- results of that first `values_string:find` to check for
            -- a separator.  Is it worth it?  Probably not, but by the
            -- time I wrote this comment, I was already in pretty deep.
            local position = 1
            repeat
              -- This value runs either to the next separator or until
              -- the end of the string.
              local end_of_value = (next_sep_start or 0) - 1
              local value = values_string:sub(position, end_of_value)

              table.insert(tag_value, value)

              -- Now we'll move to the end of the next separator, or to
              -- the end of the string, then find the next separator
              -- after our new position.
              position = next_sep_end and next_sep_end + 1 or #values_string
              next_sep_start, next_sep_end = values_string:find(separator_pattern, position)
            until position == #values_string
          end
        end

        tags[name] = tag_value
        last_tag_end = values_end or name_end
      end
    end

    return text, depth, tags
  else
    return nil
  end
end

-- Parses a note.
--
-- Does not validate that it is not looking at a header or a task, so
-- it _will_ parse headers and tasks as notes if asked.
function taskpaper.parse_note (line)
  -- This pattern matches everything between two non-space characters.
  --
  -- An unintentional side effect of this is that a note must contain at
  -- least two non-space characters, and therefore empty lines are not
  -- notes.
  local first, last = line:find('%S.*%S')

  if first then
    local depth = first
    local note = line:sub(first, last)

    return note, depth
  end
end

--local testfile = io.open("file.taskpaper", "r")
--for line in testfile:lines() do
  --print("passing line through:", line)
--end

return taskpaper
