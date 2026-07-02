local p = premake

local drive_pattern = "%a:"

p.modules.cmake_premake.path = {
  dirs = {},
  drive = "",
  is_absolute = false,
  mount_point = ""
}
local path = p.modules.cmake_premake.path
local utils = p.modules.cmake_premake.utils

local mount_point_prefixes = { "mnt", "media", "run/media" }

local function copy_dirs(dirs)
  local new = {}
  for i, d in ipairs(dirs) do
    new[i] = d
  end
  return new
end

local function match_mount_prefix(tmp)
  for _, prefix in ipairs(mount_point_prefixes) do
    local segments = {}
    for seg in prefix:gmatch("[^/]+") do
      table.insert(segments, seg)
    end
    local matches = true
    for i, seg in ipairs(segments) do
      if tmp[i] ~= seg then
        matches = false
        break
      end
    end
    if matches then
      return prefix, #segments
    end
  end
  return nil, 0
end

function path.create_path(path_str)
  local dirs = {}
  local drive = ""
  local is_absolute = false
  local mount_point = ""

  if path_str:sub(1,2) == "./" or path_str:sub(1,2) == ".\\" then
    is_absolute = false
    path_str = path_str:sub(3)
  elseif path_str:sub(1,1) == "/" or path_str:sub(1,1) == "\\" then
    is_absolute = true
  elseif path_str:match("^" .. drive_pattern) then
    is_absolute = true
  else
    is_absolute = false
  end

  if not is_absolute then
    path_str = utils:get_cwd() .. path_str
  end

  if path_str:contains("\\") then
    local tmp = path_str:split("\\")
    if tmp[1] and tmp[1]:match("^" .. drive_pattern) then
      drive = tmp[1]:sub(1,1):upper()
      table.remove(tmp, 1)
    end
    dirs = tmp
  else
    local tmp = path_str:split("/")
    if tmp[1] == "" then
      table.remove(tmp, 1)
    end
    local prefix, consumed = match_mount_prefix(tmp)
    if prefix then
      mount_point = prefix
      for _ = 1, consumed do
        table.remove(tmp, 1)
      end
      if tmp[1] and #tmp[1] == 1 then
        drive = tmp[1]:upper()
        table.remove(tmp, 1)
      end
    end
    dirs = tmp
  end

  return setmetatable({
    dirs = dirs,
    drive = drive,
    is_absolute = is_absolute,
    mount_point = mount_point
  }, { __index = path })
end

function path.to_windows_path(self)
  local path_str = ""
  if self.drive ~= "" then
    path_str = path_str .. self.drive:upper() .. ":\\"
  end
  for i, dir in ipairs(self.dirs) do
    if dir == "." then
      path_str = path_str .. utils:get_cwd() .. "\\"
    elseif dir:contains(".") and i == #self.dirs then
      path_str = path_str .. dir
    else
      path_str = path_str .. dir .. "\\"
    end
  end
  return path_str
end

function path.go_back(self)
  local new_dirs = copy_dirs(self.dirs)
  if #new_dirs > 0 then
    table.remove(new_dirs, #new_dirs)
  end
  return setmetatable({
    dirs = new_dirs,
    drive = self.drive,
    is_absolute = self.is_absolute,
    mount_point = self.mount_point
  }, { __index = path })
end

function path.add(self, dir)
  local new_dirs = copy_dirs(self.dirs)
  table.insert(new_dirs, dir)
  return setmetatable({
    dirs = new_dirs,
    drive = self.drive,
    is_absolute = self.is_absolute,
    mount_point = self.mount_point
  }, { __index = path })
end

function path.to_unix_path(self, is_absolute)
  local path_str = ""
  if self.mount_point ~= "" then
    path_str = path_str .. "/" .. self.mount_point .. "/"
  end
  if self.drive ~= "" then
    path_str = path_str .. self.drive:lower() .. "/"
  end
  for i, dir in ipairs(self.dirs) do
    if dir == "." and not is_absolute then
      path_str = path_str .. utils:get_cwd() .. "/"
    elseif dir:contains(".") and i == #self.dirs then
      path_str = path_str .. dir
    else
      path_str = path_str .. dir .. "/"
    end
  end
  return path_str
end

return path