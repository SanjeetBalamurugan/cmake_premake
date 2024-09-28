local p = premake

p.modules.cmake_premake.files = {}
local files = p.modules.cmake_premake.files
local io = require("io")

function files.file_exists(file_name)
  local f = io.open(file_name, "r")
  if f then f:close() end
  return f ~= nil
end

function files.getLines(file)
  if not files.file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end

  return lines
end

return files
