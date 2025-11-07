local p = premake

local cmake_premake = p.modules.cmake_premake
local token_type = p.modules.cmake_premake.TokenType
local utils = p.modules.cmake_premake.utils
local cmake_projects = {}
local variables = {}

local parsed = {}

local cmake_function = { "cmake_minimum_required",
  "project", "file", "add_executable",
  "target_compile_options",
  "target_include_directories",
  -- "find_package", -- TODO: Need to implement,
  "set",
  -- "include"
}

function cmake_premake.cmake_parser(tokens, startIdx)
  if tokens[startIdx].type == token_type.KEYWORD
      and table.contains(cmake_function, tokens[startIdx].value) then
    local keyword_name = tokens[startIdx].value
    local parameters = {}

    for i = startIdx + 1, #tokens do
      if tokens[i].type == token_type.CLOSECURLY then
        startIdx = startIdx + 1
        break
      elseif tokens[i].type ~= token_type.OPENCURLY then
        table.insert(parameters, tokens[i].value)
      end
      startIdx = startIdx + 1
    end

    table.insert(parsed, {
      name = keyword_name,
      parameters = parameters
    })
  else
    startIdx = startIdx + 1
  end

  return startIdx
end

function test_print()
  for key, value in pairs(parsed) do
    for k, v in pairs(value) do
      print("Key:" .. k)
      for _, j in ipairs(v) do
        print("     " .. j)
      end
    end
    print("\n")
  end
end

function cmake_premake.cmake_converter(tokens)
  local premake_script = ""
  local index = 1

  -- add an indent to the string
  local function add_indent(indent_level)
    return string.rep("  ", indent_level)
  end

  local indent_level = 0

  local function addLine(line)
    premake_script = premake_script .. add_indent(indent_level) .. line .. "\n"
  end

  local function add_files(files)
    addLine("files {")
    for _, filevar in ipairs(files) do
      local pfile = {}
      for match in string.gmatch(filevar, "${(.-)}") do
        table.insert(pfile, match)
      end
      local name = table.concat(pfile, " ")
      for _, v in ipairs(variables) do
        if v.type == "file" and v.name == name then
          for _, file in pairs(v.files) do
            addLine('"' .. file .. '",')
          end
        end
      end
    end
    addLine("}")
  end

  local new_tokens = {}
  for _, token in ipairs(tokens) do
    if token.type == token_type.WHITESPACE or token.type == token_type.COMMENT then
      goto continue
    end
    table.insert(new_tokens, token)
    ::continue::
  end

  while index <= #new_tokens do
    index = cmake_premake.cmake_parser(new_tokens, index)
  end

  for _, t in ipairs(parsed) do
    local name = t.name
    local parameters = t.parameters

    tmp = ""
    if name == "cmake_minimum_required" then
      for _, parameter in ipairs(parameters) do
        tmp = tmp .. parameter .. " "
      end

      addLine("-- cmake_minimum_required " .. tmp)
      tmp = " "
      -- elseif name == "project" then
      --   table.insert(cmake_projects, {
      --     name = parameters[1]
      --   })
    elseif name == "file" then
      local isGlobRecursive = false
      local variable_name = parameters[2]
      local files = {}

      for i = 3, #parameters do
        table.insert(files, parameters[i])
      end

      if parameters[1] == "GLOB_RECURSE" then
        isGlobRecursive = true
      end
      table.insert(variables, {
        name = variable_name,
        type = "file",
        files = files
      })
    elseif name == "add_executable" then
      local exec_name = parameters[1]
      local files = {}

      for i = 2, #parameters do
        table.insert(files, parameters[i])
      end

      table.insert(cmake_projects, {
        name = exec_name,
        files = files,
        target_compile_options = {},
        target_include_directories = {}
      })
    elseif name == "target_compile_options" then
      exec_name = parameters[1]
      compile_options = {}

      for i = 2, #parameters do
        table.insert(compile_options, parameters[i])
      end

      for _, prj in ipairs(cmake_projects) do
        if prj.name == exec_name then
          prj.target_compile_options = compile_options
        end
      end
    elseif name == "target_include_directories" then
      exec_name = parameters[1]
      include_dirs = {}

      for i = 2, #parameters do
        table.insert(include_dirs, parameters[i])
      end

      for _, prj in ipairs(cmake_projects) do
        if prj.name == exec_name then
          prj.target_include_directories = include_dirs
        end
      end
    end
  end

  print(#variables)

  for _, project in ipairs(cmake_projects) do
    addLine("project" .. " '" .. project.name .. "'")
    add_files(project.files)
  end

  print(premake_script)
  return premake_script
end

return cmake_premake
