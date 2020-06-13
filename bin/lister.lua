#!/usr/bin/env lua
local argparse = require 'argparse'

local taskpaper = require 'taskpaper'

local parser = argparse()
    :name("lister")
    :description("List management.")

parser:option("-d --dir", "The root directory to search within.", os.getenv("HOME"))

parser:command_target("command")
parser:command("list-files lsf", [[
List the files that would be searched for projects and tasks.

Uses $HOME by default, but can be changed with --dir.]])

local fmt = parser:command("format fmt", [[
Print the given file(s) with automatic formatting.

Writes to standard out by default, but can format the file in-place with -i.]])
fmt:argument("file", "The taskpaper file to format."):args("+")
fmt:option("-i --in-place", "Rewrite the file instead of printing to stdout."):args(0)

local args = parser:parse()

local function find_files (dir)
  local files = {}
  local cmd = io.popen(string.format("find '%s' -name '*.taskpaper'", dir))
  for line in cmd:lines() do
    files[#files + 1] = line
  end
  cmd:close()
  return files
end

local function format_single_file (file, in_place)
  local tree = taskpaper.load_file(file)
  if in_place then
    local f = io.open(file, 'w')
    f:write(taskpaper.format(tree))
    f:close()
  else
    print(tree.path .. ":\n")
    print(taskpaper.format(tree, 1))
    print("\n")
  end
end
local function format (files, in_place)
  for i = 1, #files do
    format_single_file(files[i], in_place)
  end
end

if args.command == "list-files" then
  local files = find_files(args.dir)
  for i = 1, #files do
    print(files[i])
  end
elseif args.command == "format" then
  format(args.file, args.in_place)
end
