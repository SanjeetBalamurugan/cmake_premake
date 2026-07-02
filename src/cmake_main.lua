local p = premake
local cmake_premake = p.modules.cmake_premake

cmake_premake.cmake_projects = {}

function cmake_premake.include_proj(project_dir)
  if project_dir:sub(1, 1) == "." and project_dir ~= _WORKING_DIR then
    project_dir = project_dir .. "/"
  end

  if project_dir:split("/")[#project_dir] ~= "CMakeLists.txt" then
    if project_dir:sub(#project_dir, #project_dir) == "/" then
      project_dir = project_dir.."CMakeLists.txt"
    else
      project_dir = project_dir .. "/CMakeLists.txt"
    end
  end

  if table.contains(cmake_premake.cmake_projects, project_dir) then
    return
  end
  table.insert(cmake_premake.cmake_projects, project_dir)
end

return cmake_premake
