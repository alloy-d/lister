local chunky = require 'taskpaper.chunky'
local filer = require 'taskpaper.filer'
local mutation = require 'taskpaper.mutation'
local printer = require 'taskpaper.printer'
local traversal = require 'taskpaper.traversal'
local bless = require 'taskpaper.bless'

local metatables = require 'taskpaper.metatables'

local function hook_up (func, name, kinds)
  for _, kind in ipairs(kinds) do
    metatables[kind][name] = func
  end
end

hook_up(filer.write,              'write',          {'file'})

hook_up(printer.format,           'totaskpaper',    {'root', 'project', 'task', 'note'})
hook_up(traversal.populate_paths, 'populate_paths', {'root', 'project', 'task'})
hook_up(traversal.crawl,          'crawl',          {'root', 'project', 'task'})
hook_up(traversal.lookup,         'lookup',         {'root', 'project', 'task'})
hook_up(mutation.remove,          'remove',         {'root'})
hook_up(mutation.append,          'append',         {'root'})

return {
  bless = bless,
  format = printer.format,
  parse = chunky.parse,
  load_file = filer.load_file,
}
