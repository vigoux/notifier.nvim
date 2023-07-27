package = "notifier.nvim"
version = "dev-1"
source = {
   url = "git+ssh://git@github.com/vigoux/notifier.nvim.git"
}
description = {
   detailed = "![Showcase](https://user-images.githubusercontent.com/39092278/186714682-f51ea665-6fca-4442-bad8-8cc7fda2f138.gif)",
   homepage = "www.github.com/vigoux/notifier.nvim",
   license = "BSD 3-Clause"
}
build = {
   type = "builtin",
   modules = {
      ["notifier.config"] = "lua/notifier/config.lua",
      ["notifier.init"] = "lua/notifier/init.lua",
      ["notifier.status"] = "lua/notifier/status.lua"
   },
   copy_directories = {
      "tests"
   }
}
