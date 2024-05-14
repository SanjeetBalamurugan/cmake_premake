local p = premake
p.modules.cmake_premake = {}
local cmake_premake = p.modules.cmake_premake

local io = require("io")

cmake_premake._VERSION = 1.0

p.api.register {
  name = "executable_sufffix",
  scope = "config",
  kind = "string"
}

newaction {
  trigger = "translate-cmake",
  shortname = "cmake-premake",
  description = "Convert CMakeLists.txt to a premake5.lua file",
  onStart = function ()
    print("Starting translate-cmake")
  end,

  execute = function ()
    for _, project in ipairs(cmake_premake.cmake_projects) do
      local tokens = cmake_premake.cmake_tokenizer(project)
      local path_table = cmake_premake.path.create_path(project)

      local premake_file = cmake_premake.cmake_converter(tokens, path_table)
      local out_file = io.open(cmake_premake.curr_proj..".lua", "w+")
      out_file:write(premake_file)
      out_file:close()
      print("Converted project "..cmake_premake.curr_proj.." to "..cmake_premake.curr_proj..".lua")

      include(cmake_premake.curr_proj..".lua")
    end
  end,

  onEnd = function ()
    print("Ending translate-cmake")
  end
}

-- utils
include "utils/utils.lua"
include "utils/path.lua"

-- cmake essentials
include "src/cmake_main.lua"
include "src/cmake_tokenizer.lua"
include "src/cmake_converter.lua"

return cmake_premake
