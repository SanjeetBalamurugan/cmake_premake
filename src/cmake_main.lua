local p = premake
local cmake_premake = p.modules.cmake_premake

cmake_premake.cmake_projects = {}

function string.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function cmake_premake.include_proj(project_dir, project_name)
  local io = require("io")
  if io.open("./"..project_name) ~= nil then
    print("cmake_premake: found "..project_name..".lua so including it")
    include(project_name)
  end

  if project_dir:sub(1,1) == "." and project_dir ~= _WORKING_DIR then
    project_dir = project_dir.."/"
  end

  if project_dir:split("/")[#project_dir] ~= "CMakeLists.txt" then
    project_dir = project_dir.."/CMakeLists.txt"
  end

  -- print(project_dir)
  table.insert(cmake_premake.cmake_projects, project_dir)
end

return cmake_premake
