local p = premake

local cmake_premake = p.modules.cmake_premake
local token_type = p.modules.cmake_premake.TokenType
local utils = p.modules.cmake_premake.utils

function cmake_premake.cmake_converter(tokens, path_table)
  local premake_script = ""
  local includes = ""
  local variables = {}

  if utils:is_unix() then
  variables["PROJECT_SOURCE_DIR"] = path_table:go_back():to_unix_path(true)
  else
    variables["PROJECT_SOURCE_DIR"] = path_table:go_back():to_windows_path(true)
  end
  -- add an indent to the string
  local function add_indent(indent_level)
    return string.rep("  ", indent_level)
  end

  local indent_level = 0

  local function addLine(line)
    premake_script = premake_script..add_indent(indent_level)..line.."\n"
  end

  local function addInclude(line)
    includes = includes..line.."\n"
  end

  local function addVariable(at)
    local variable_name = tokens[at].value
    local is_end_curly = false
    local values = {}

    at = at + 1
    while not is_end_curly do
      local val = tokens[at].value
      if val == ")" then
        is_end_curly = true
        goto continue
      elseif val == "" then
        goto continue
      end

      table.insert(values, val)
        ::continue::
      at = at + 1
    end

    variables[variable_name] = values
  end

  local function looped(at, is_recursive_search)
    local files = ""
    local is_end_curly = false
    while not is_end_curly do
      local val = tokens[at].value
      if val == ")" then
        files = files..'}'
        is_end_curly = true
      elseif val == "" then
        goto continue
      elseif val:sub(1,2) == '${' then
        local match = val:match("%${(.-)}")
        if utils.array_contains(variables, match) then
          if type(variables[match]) == "table" then
            for _, value in ipairs(variables[match]) do
              files = files..'"'..value..val:sub(#value + 5)..'",'
            end
          else
            files = files..'"'..variables[match]..val:sub(#match + 5)..'",'
          end
        end
      else
        if is_recursive_search then
          val = val:gsub("%*", "**")
        end
        files = files..'"'..val..'",'
      end
            ::continue::
        at = at + 1
    end
    return files
  end

  for i, token in ipairs(tokens) do
    if token.type == token_type.COMMENT or token.type == token_type.WHITESPACE then
      goto continue
    elseif token.type == token_type.KEYWORD then
      local value = token.value
      if value == "cmake_minimum_required" then
        addLine("-- "..value.." "..tokens[i+2].value.." "..tokens[i+4].value)
      elseif value == "project" then
        addLine("project \""..tokens[i+2].value.."\"")
        p.modules.cmake_premake.curr_proj = tokens[i+2].value
        indent_level = 1
        addLine('kind "ConsoleApp"')

        local language = tokens[i+3]
        if language == "C" or language == "CXX" then
          if language == "CXX" then
            language = "C++"
          end
          addLine("language \""..language.."\"")
        else
          addLine("language \"C++\"")
        end
      elseif value == "set" then
        local set_var = tokens[i+2].value
        if set_var == "CMAKE_CXX_STANDARD" then
          addLine('cppdialect "C++'..tokens[i+4].value..'"')
        else
          addVariable(i+2)
        end
      elseif value == "file" then
        local is_recursive_search = false
        if tokens[i+2].value == "GLOB_RECURSE" then
          is_recursive_search = true
        end
        local files = "files {"..looped(i+3, is_recursive_search)
        addLine(files)
      elseif value == "add_executable" then
        local at = i + 3
        if tokens[at + 2].value == "PUBLIC" or tokens[at].value == "PRIVATE" then
          at = at + 1
        end
        local files = "files {"..looped(at, false)
        addLine(files)
      elseif value == "include_directories" or value == "target_include_directories" then
        local at = i + 2
        if tokens[at + 2].value == "PUBLIC" or tokens[at].value == "PRIVATE" then
          at = at + 3
        end
        local include_directories = "includedirs {"..looped(at, false)

        addLine(include_directories)
      elseif value == "add_subdirectory" then
        addInclude('include "'..tokens[i+2].value..'"')
      elseif value == "target_link_libraries" then
        local at = i +4
        if tokens[at].value == "PUBLIC" or tokens[at].value == "PRIVATE" then
          at = at + 1
        end
        local target_link_libraries = "links {"..looped(at)
        addLine(target_link_libraries)
      elseif value == "target_compile_options" then
        local at = i + 4
        if tokens[at].value == "PUBLIC" or tokens[at].value == "PRIVATE" then
          at = at + 1
        end

        local target_compile_options = "buildoptions {"..looped(at, false)
        addLine(target_compile_options)
      end
    end
      ::continue::
  end
  premake_script = premake_script..includes
  return premake_script
end

return cmake_premake
