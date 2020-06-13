rockspec_format = "3.0"
package = "lister"
version = "scm-1"
source = {
  url = "https://github.com/alloy-d/lister.git"
}
description = {
  summary = "GTD-style list management.",
  detailed = [[
    Tooling to enable broader GTD-style list management over
    a disorganized collection of taskpaper files.
  ]],
  homepage = "https://github.com/alloy-d/lister",
  license = "BSD-3-Clause",
}
supported_platforms = {"unix"}
dependencies = {
  "lua >= 5.2",
  "argparse",
}
build_dependencies = {
  "busted",
}
build = {
  type = "builtin",
  modules = {
    ["taskpaper"] = "taskpaper/init.lua",
    ["taskpaper.chunky"] = "taskpaper/chunky.lua",
    ["taskpaper.filer"] = "taskpaper/filer.lua",
    ["taskpaper.lines"] = "taskpaper/lines.lua",
    ["taskpaper.printer"] = "taskpaper/printer.lua"
  },
  install = {
    bin = {
      ["lister"] = "bin/lister.lua"
    }
  }
}
