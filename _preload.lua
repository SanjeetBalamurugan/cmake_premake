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

local args = _ARGS
local includes = ""
local main_script = _MAIN_SCRIPT

newaction {
  trigger = "translate-cmake",
  shortname = "cmake-premake",
  description = "Convert CMakeLists.txt to a premake5.lua file",
  onStart = function()
    print("Starting translate-cmake")
  end,

  execute = function()
    for _, arg in ipairs(args) do
      cmake_premake.include_proj(arg)
    end

    for _, project in ipairs(cmake_premake.cmake_projects) do
      local tokens = cmake_premake.cmake_tokenizer(project)
      local path_table = cmake_premake.path.create_path(project)

      local premake_file = cmake_premake.cmake_converter(tokens, path_table)
      local out_file = io.open(cmake_premake.curr_proj .. ".lua", "w+")
      out_file:write(premake_file)
      out_file:close()
      print("Converted project " .. cmake_premake.curr_proj .. " to " .. cmake_premake.curr_proj .. ".lua")

      includes = includes .. 'include "' .. cmake_premake.curr_proj .. '.lua"\n'
    end

    local premake_file = io.open(main_script, "a")

    for _, inc in ipairs(string.split(includes, "\n")) do
      if not cmake_premake.files.file_contains(main_script, inc) then
        premake_file:write(inc)
      end
    end
    premake_file:close()
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
