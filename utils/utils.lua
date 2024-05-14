local p = premake
local io = require "io"

p.modules.cmake_premake.utils = {}
local utils = p.modules.cmake_premake.utils

function utils.is_windows()
  return package.config:sub(1,1) == "\\"
end

function utils.is_unix()
  return not utils.is_windows()
end

function utils.table_contains(table, value)
  local found = false
  for _, v in ipairs(table) do
    if v == value then
      found = true
    end
  end

  return found
end

function utils.array_contains(array, value)
  return array[value] ~= nil
end

function utils.get_cwd()
  local command = "echo "
  if utils.is_unix() then
    command = command.."$PWD"
  elseif premake then
    return _WORKING_DIR
  else
    command = command.."%CD%"
  end

  return io.popen(command):read("l")
end

function utils.get_files(folder_path)
  local files = {}
  local command = 'dir "'..folder_path..'" /b'
  if utils.is_unix() then
    command = 'ls -pa '..folder_path.." | grep -v /"
  end

  for file in io.popen(command):lines() do
    table.insert(files, file)
  end

  return files
end

return utils
