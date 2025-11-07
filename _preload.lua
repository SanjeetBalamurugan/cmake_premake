local p = premake
p.modules.cmake_premake = {}
local cmake_premake = p.modules.cmake_premake

local io = require("io")

cmake_premake._VERSION = 1.1

p.api.register {
  name = "executable_sufffix",
  scope = "config",
  kind = "string"
}

local args = _ARGS
local includes = ""
local main_script = _MAIN_SCRIPT

newaction {
  trigger = "translate-cmake",
  shortname = "cmake-premake",
  description = "Convert CMakeLists.txt to a premake5.lua file",
  onStart = function()
    print("Starting translate-cmake v" .. cmake_premake._VERSION .. ".0")
  end,

  execute = function()
    local projects = cmake_premake.cmake_projects

    for _, project in ipairs(projects) do
      local cmake_lists = cmake_premake.files.getLines(project)
      print(cmake_lists, project)
      local tokens = cmake_premake.cmake_tokenizer(cmake_lists)
      local final = cmake_premake.cmake_converter(tokens)
    end
  end,

  onEnd = function()
    print("Ending translate-cmake")
  end
}

-- utils
include "utils/files.lua"
include "utils/utils.lua"
include "utils/path.lua"

-- cmake essentials
include "src/cmake_main.lua"
include "src/cmake_tokenizer.lua"
include "src/cmake_converter.lua"

return cmake_premake
