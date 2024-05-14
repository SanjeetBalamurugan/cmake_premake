local p = premake

-- TODO: anyone viewing this file improve the path.create_path function please

local path_separator = package.config:sub(1,1) -- Path separator (/ or \)
local drive_pattern = "%a:" -- Drive letter pattern (e.g., C:)

p.modules.cmake_premake.path = {
  dirs = {},
  drive = "",
  is_absolute = false,
  mount_point = ""
}

local path = p.modules.cmake_premake.path
local utils = p.modules.cmake_premake.utils

-- Define common mount point prefixes
local mount_point_prefixes = { "mnt", "media", "run/media" }

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

function string.contains(inputstr, delim)
  if delim == nil then
    return false
  end

  for c in inputstr:gmatch(".") do
    if c == delim then
      return true
    end
  end

  return false
end

function path.create_path(path_str)
  local dirs = {}
  local drive = ""
  local is_absolute = false
  local mount_point = ""

  -- Check if the path is absolute or relative
  if path_str:sub(1,2) == "./" or path_str:sub(1,2) == ".\\" or path_str:sub(1,1) == "/" or path_str:sub(1,1) == "\\" then
    is_absolute = true
  end

  if not is_absolute then
    -- If relative path, prepend current working directory
    path_str = utils:get_cwd()..path_str
  end

  if path_str:contains("\\") then
    local tmp = path_str:split("\\")
    if not is_absolute then
      drive = tmp[1]:sub(1,1):upper()
      table.remove(tmp, 1)
    end
    dirs = tmp
  else
    local tmp = path_str:split("/")
    if not is_absolute then
      mount_point = tmp[1]
      drive = tmp[2]:upper()
      table.remove(tmp, 1)
      table.remove(tmp, 1)
    end
    dirs = tmp
  end

  return setmetatable({ dirs = dirs, drive = drive, is_absolute = is_absolute, mount_point = mount_point }, { __index = path })
end

function path.to_windows_path(self, is_absolute)
  print("not implemented")
  local os = require("os")
  os.exit(22)
end

function path.go_back(self)
  local new = self.dirs
  table.remove(new, #new)

  return setmetatable({ dirs = new, drive = self.drive }, { __index = path })
end

function path.add(self, dir)
  local new = self.dirs
  table.insert(new, dir)

  return setmetatable({ dirs = new, drive = self.drive }, { __index = path })
end

function path.to_unix_path(self, is_absolute)
  local path_str = ""
  if self.mount_point ~= "" then
    path_str = path_str .."/"..self.mount_point .. "/"
  end

  if self.drive ~= "" then
    path_str = path_str..self.drive:lower().."/"
  end

  for i, dir in ipairs(self.dirs) do
    if dir == "." and not is_absolute then
      path_str = path_str..utils:get_cwd() .. "/"
    elseif dir:contains(".") and i == #self.dirs then
      path_str = path_str..dir
    else
      path_str = path_str..dir.."/"
    end
  end

  return path_str
end


return path

