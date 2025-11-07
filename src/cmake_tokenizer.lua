local io = require "io"
local p = premake
local cmake = p.modules.cmake_premake

cmake.TokenType = {
  KEYWORD = "KEYWORD",
  IDENTIFIER = "IDENTIFIER",
  STRING = "STRING",
  COMMENT = "COMMENT",
  WHITESPACE = "WHITESPACE",
  OPENCURLY = "OPENCURLY",
  CLOSECURLY = "CLOSECURLY"
}

function cmake.cmake_tokenizer(cmake_script)
  local tokens = {}
  local inStr = false
  local inComment = false
  local token_curr = ""
  local inArgs = false

  for _, line in pairs(cmake_script) do
    for c in line:gmatch(".") do
      if inComment then
        token_curr = token_curr .. c
        table.insert(tokens, { type = cmake.TokenType.COMMENT, value = token_curr })
        token_curr = ""
        inComment = false
        break
      elseif inStr then
        token_curr = token_curr .. c
        if c == "\"" then
          table.insert(tokens, { type = cmake.TokenType.STRING, value = token_curr })
          token_curr = ""
          inStr = false
          break
        end
      elseif c == "\"" then
        token_curr = "\""
        inStr = true
      elseif c == "#" then
        token_curr = "#"
        inComment = true
      elseif c == "(" and not inStr then
        if #token_curr > 0 then
          table.insert(tokens, { type = cmake.TokenType.KEYWORD, value = token_curr })
          token_curr = ""
        end
        table.insert(tokens, { type = cmake.TokenType.OPENCURLY, value = "(" })
        inArgs = true
      elseif c == ")" and not inStr then
        if #token_curr > 0 then
          table.insert(tokens, { type = cmake.TokenType.IDENTIFIER, value = token_curr })
          token_curr = ""
        end
        table.insert(tokens, { type = cmake.TokenType.CLOSECURLY, value = ")" })
        inArgs = false
        break
      elseif c == " " and inArgs then
        if #token_curr > 0 then
          table.insert(tokens, { type = cmake.TokenType.IDENTIFIER, value = token_curr })
          token_curr = ""
        end

        table.insert(tokens, { type = cmake.TokenType.WHITESPACE, value = token_curr })
      else
        token_curr = token_curr .. c
      end
    end
  end

  return tokens
end

return cmake
