#!/usr/bin/env lua
local argparse = require 'argparse'

local taskpaper = require 'taskpaper'
local parse_path = require('taskpaper.traversal').parse_path

local parser = argparse()
    :name("lister")
    :description("List management.")

parser:option("-d --dir", "The root directory to search within.", os.getenv("HOME"))

parser:command_target("command")
parser:command("list-files lsf", [[
List the files that would be searched for projects and tasks.

Uses $HOME by default, but can be changed with --dir.

]])

local lsp_cmd = parser:command("list-projects lsp", [[
List all projects.

]])
lsp_cmd:option("-p --show-paths", "Output paths in addition to project names."):args(0)

local show_cmd = parser:command("show", [[
Show something (or some things).

"Something" can be a file, or an item within a file, specified by its path.

For example:
  `show ~/todo.taskpaper:2` will show the second thing in ~/todo.taskpaper,
  `show ~/todo.taskpaper:2:1` will show the first thing within that thing, &c.

]])
show_cmd:argument("path", "The path to the thing(s) to show."):args("+")

local fmt_cmd = parser:command("format fmt", [[
Print the given file(s) with automatic formatting.

Writes to standard out by default, but can format the file in-place with -i.

]])
fmt_cmd:argument("file", "The taskpaper file to format."):args("+")
fmt_cmd:option("-i --in-place", "Rewrite the file instead of printing to stdout."):args(0)

local args = parser:parse()

local function map (xs, f)
  local result = {}
  for i, x in ipairs(xs) do
    result[i] = f(x)
  end
  return result
end

local function find_files (dir)
  local files = {}
  local cmd

  if os.execute("which fd > /dev/null") then
    local ignore_arg = ""
    local ignore_file = io.open(os.getenv("HOME") .. "/.lister-ignore")
    if ignore_file then
      ignore_file:close()
      ignore_arg = "--ignore-file ~/.lister-ignore"
    end

    cmd = io.popen(string.format("fd -e taskpaper --no-ignore %s --hidden . '%s'", ignore_arg, dir))
  else
    cmd = io.popen(string.format("find '%s' -name '*.taskpaper'", dir))
  end

  for line in cmd:lines() do
    files[#files + 1] = line
  end
  cmd:close()
  return files
end

local function list_projects (dir, show_paths)
  local files = find_files(dir)
  local roots = map(files, taskpaper.load_file)

  for _, root in ipairs(roots) do
    for item in root:crawl() do
      if item.kind == "project" then
        if show_paths then
          print(item.path, item.name)
        else
          print(item.name)
        end
      end
    end
  end
end

local function show (paths)
  paths = map(paths, parse_path)
  local file_cache = {}

  local function load (filename)
    if not file_cache[filename] then
      file_cache[filename] = taskpaper.load_file(filename)
    end
    return file_cache[filename]
  end

  for _, path in ipairs(paths) do
    local file = load(path[1])
    local path_in_file = table.move(path, 2, #path, 1, {})
    print(file:lookup(path_in_file):totaskpaper())
  end
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
elseif args.command == "list-projects" then
  list_projects(args.dir, args.show_paths)
elseif args.command == "show" then
  show(args.path)
elseif args.command == "format" then
  format(args.file, args.in_place)
end
