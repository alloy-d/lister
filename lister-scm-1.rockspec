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
  "lua >= 5.3",
  "argparse",
}
build_dependencies = {
  "busted",
  "fennel ~> 0.4.2",
}
build = {
  type = "make",
  build_variables = {
    CFLAGS = "$(CFLAGS)",
  },
  install_variables = {
    PREFIX = "$(PREFIX)",
    BINDIR = "$(BINDIR)",
    LUADIR = "$(LUADIR)",
  },
}
