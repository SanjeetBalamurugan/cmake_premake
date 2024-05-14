local p = premake

p.modules.cmake_premake.files = {}
local files = p.modules.cmake_premake.files
local io = require("io")

function files.file_exists(file_name)
  local f = io.open(file_name, "r")
  if f then f:close() end
  return f ~= nil
end

function files.file_contents(file_name)
  if not files.file_exists(file_name) then
    print(file_name.." doesn't exist")
    local os = require("os")
    os.exit(1)
  end

  local tmp = ""
  for line in io.lines(file_name) do
    if tmp == "" then
      tmp = tmp..line
    else
      tmp = tmp..line.."\n"
    end
  end

  return tmp
end

function files.file_lines(file_name)
  if not files.file_exists(file_name) then
    print(file_name.." doesn't exist")
    local os = require("os")
    os.exit(1)
  end

  local lines = {}

  for line in io.lines(file_name) do
    lines[#lines+1] = line
  end

  return lines
end

function files.file_contains(file_name, str)
  local lines = files.file_lines(file_name)
  if str:sub(#str, #str) == "\n" then
    str = str:sub(1, #str-1)
  end

  for _, line in ipairs(lines) do
    if line == str then
      return true
    end
  end

  return false
end

return files
