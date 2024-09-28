local p = premake

local cmake_premake = p.modules.cmake_premake
local token_type = p.modules.cmake_premake.TokenType
local utils = p.modules.cmake_premake.utils

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

    print(keyword_name, #parameters)
  else
    startIdx = startIdx + 1
  end

  return startIdx
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

  local new_tokens = {}
  for _, token in ipairs(tokens) do
    if token.type == token_type.WHITESPACE or token.type == token_type.COMMENT then
      goto continue
    end
    table.insert(new_tokens, token)
    ::continue::
  end

  print("\n\n", #new_tokens, "\n", #tokens)

  while index <= #new_tokens do
    print(index)
    index = cmake_premake.cmake_parser(new_tokens, index)
  end

  return premake_script
end

return cmake_premake
