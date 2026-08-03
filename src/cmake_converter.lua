local p = premake

local cmake_premake = p.modules.cmake_premake
local token_type = p.modules.cmake_premake.TokenType
local utils = p.modules.cmake_premake.utils
local pprint = p.modules.cmake_premake.pprint

local cmake_function = {
  "cmake_minimum_required",
  "project",
  "file",
  "add_executable",
  "target_compile_options",
  "target_include_directories",
  "target_compile_definitions",
  -- "find_package", -- TODO: Need to implement,
  "set",
  "add_library"
  -- "include"
}

function cmake_premake.cmake_parser(tokens, startIdx, parsed)
  local token = tokens[startIdx]

  if token.type == token_type.KEYWORD and table.contains(cmake_function, token.value) then
    local keyword_name = token.value
    local parameters = {}

    local i = startIdx + 1
    while i <= #tokens do
      local t = tokens[i]
      if t.type == token_type.CLOSECURLY then
        i = i + 1
        break
      elseif t.type ~= token_type.OPENCURLY then
        table.insert(parameters, t.value)
      end
      i = i + 1
    end

    table.insert(
      parsed,
      {
        name = keyword_name,
        parameters = parameters
      }
    )

    return i
  end

  return startIdx + 1
end

local function strip_quotes(value)
  local stripped = value:gsub('^"(.*)"$', "%1")
  return stripped
end

local function resolve_file_variable(filevar, variables)
  local name_parts = {}
  for match in string.gmatch(filevar, "%${(.-)}") do
    table.insert(name_parts, match)
  end
  local name = table.concat(name_parts, " ")

  for _, v in ipairs(variables) do
    if v.type == "file" and v.name == name then
      return v.files
    end
  end

  return nil
end

local function strip_noise_tokens(tokens)
  local out = {}
  for _, token in ipairs(tokens) do
    if token.type ~= token_type.WHITESPACE and token.type ~= token_type.COMMENT then
      table.insert(out, token)
    end
  end
  return out
end

function cmake_premake.cmake_converter(tokens)
  local premake_script = ""
  local indent_level = 0

  local parsed = {}
  local variables = p.modules.cmake_premake.globalVariables
  local cmake_projects = {}

  local function add_indent(level)
    return string.rep("  ", level)
  end

  local function addLine(line)
    premake_script = premake_script .. add_indent(indent_level) .. line .. "\n"
  end

  local function add_files(files, variables)
    addLine("files {")
    indent_level = indent_level + 1
    for _, filevar in ipairs(files) do
      local resolved = resolve_file_variable(filevar, variables)
      if resolved then
        for _, file in ipairs(resolved) do
          addLine('"' .. strip_quotes(file) .. '",')
        end
      else
        addLine('"' .. strip_quotes(filevar) .. '",')
      end
    end
    indent_level = indent_level - 1
    addLine("}")
  end

  local new_tokens = strip_noise_tokens(tokens)

  local index = 1
  while index <= #new_tokens do
    index = cmake_premake.cmake_parser(new_tokens, index, parsed)
  end

  local handlers = p.modules.cmake_premake.createHandlers(addLine, cmake_projects)
  print(pprint.prettyPrint(parsed))
  for _, call in ipairs(parsed) do
    local handler = handlers[call.name]
    if handler then
      handler(call.parameters)
    end
  end

  for _, project in ipairs(cmake_projects) do
    addLine("project '" .. project.name .. "'")
    indent_level = indent_level + 1

    add_files(project.files, variables)

    if #project.target_include_directories > 0 then
      addLine("includedirs {")
      indent_level = indent_level + 1
      for _, dir in ipairs(project.target_include_directories) do
        addLine('"' .. dir .. '",')
      end
      indent_level = indent_level - 1
      addLine("}")
    end

    if #project.target_compile_options > 0 then
      addLine("buildoptions {")
      indent_level = indent_level + 1
      for _, opt in ipairs(project.target_compile_options) do
        addLine('"' .. strip_quotes(opt) .. '",')
      end
      indent_level = indent_level - 1
      addLine("}")
    end

    if #project.target_compile_definitions > 0 then
      addLine("defines {")
      indent_level = indent_level + 1
      for _, def in ipairs(project.target_compile_definitions) do
        addLine('"' .. strip_quotes(def) .. '",')
      end
      indent_level = indent_level - 1
      addLine("}")
    end

    indent_level = indent_level - 1
  end

  print(premake_script)
  return premake_script
end

return cmake_premake