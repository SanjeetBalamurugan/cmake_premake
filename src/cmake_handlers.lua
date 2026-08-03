local p = premake

local cmake_premake = p.modules.cmake_premake
local pprint = p.modules.cmake_premake.pprint

p.modules.cmake_premake.globalVariables = {}
local GlobalVariables = p.modules.cmake_premake.globalVariables

local visibility_keywords = {"PUBLIC", "PRIVATE", "INTERFACE"}

local function contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function strip_quotes(str)
    if type(str) ~= "string" then
        return str
    end
    return (str:gsub('^"(.*)"$', "%1"))
end

function cmake_premake.createHandlers(addLine, cmake_projects)
    local handlers = {}

    handlers.cmake_minimum_required = function(parameters)
        addLine("-- cmake_minimum_required " .. table.concat(parameters, " "))
    end

    handlers.project = function(parameters)
        local name = parameters[1]

        local version = 1.0
        local language = "C++"

        for i = 2, #parameters do
            if parameters[i] == "VERSION" and parameters[i + 1] then
                version = tonumber(parameters[i + 1])
            elseif parameters[i] == "LANGUAGES" and parameters[i + 1] then
                if parameters[i + 1] == "CXX" then
                    language = "C++"
                else
                    language = parameters[i + 1]
                end
            end
        end

        addLine('workspace "' .. name .. '"')
        addLine('   configurations { "Debug", "Release" }')
        addLine('   language "' .. language .. '"')
        addLine("-- CMake Project Version: " .. tostring(version))
    end

    handlers.file = function(parameters)
        local mode = parameters[1]
        local variable_name = parameters[2]
        local files = {}

        for i = 3, #parameters do
            table.insert(files, parameters[i])
        end

        table.insert(
            GlobalVariables,
            {
                name = variable_name,
                type = "file",
                is_glob_recursive = (mode == "GLOB_RECURSE"),
                files = files
            }
        )
    end

    handlers.add_executable = function(parameters)
        local exec_name = parameters[1]
        local files = {}

        for i = 2, #parameters do
            table.insert(files, parameters[i])
        end

        table.insert(
            cmake_projects,
            {
                name = exec_name,
                files = files,
                target_compile_options = {},
                target_include_directories = {},
                target_compile_definitions = {}
            }
        )
    end

    local function find_project(exec_name)
        for _, prj in ipairs(cmake_projects) do
            if prj.name == exec_name then
                return prj
            end
        end
        return nil
    end

    handlers.target_compile_options = function(parameters)
        local exec_name = parameters[1]
        local prj = find_project(exec_name)
        if not prj then
            return
        end

        local compile_options = {}
        for i = 2, #parameters do
            if not contains(visibility_keywords, parameters[i]) then
                table.insert(compile_options, parameters[i])
            end
        end
        prj.target_compile_options = compile_options
    end

    handlers.target_include_directories = function(parameters)
        local exec_name = parameters[1]
        local prj = find_project(exec_name)
        if not prj then
            return
        end

        local include_dirs = {}
        for i = 2, #parameters do
            if not contains(visibility_keywords, parameters[i]) then
                table.insert(include_dirs, strip_quotes(parameters[i]))
            end
        end
        prj.target_include_directories = include_dirs
    end

    handlers.target_compile_definitions = function(parameters)
        local exec_name = parameters[1]
        local prj = find_project(exec_name)
        if not prj then
            return
        end

        local compile_definitions = {}
        for i = 2, #parameters do
            if not contains(visibility_keywords, parameters[i]) then
                table.insert(compile_definitions, parameters[i])
            end
        end
        prj.target_compile_definitions = compile_definitions
    end

    handlers.set = function(parameters)
        local name = parameters[1]
        local value = parameters[2]

        if name == "CMAKE_CXX_STANDARD" then
            addLine('   cppdialect "C++' .. value .. '"')
        elseif name == "CMAKE_CXX_STANDARD_REQUIRED" then
            addLine("   -- CMAKE_CXX_STANDARD_REQUIRED = " .. value)
        elseif name == "CMAKE_EXPORT_COMPILE_COMMANDS" and value == "ON" then
            addLine("   -- CMAKE_EXPORT_COMPILE_COMMANDS = ON")
        elseif #parameters > 2 then
            local values = {}
            for i = 2, #parameters do
                table.insert(values, parameters[i])
            end
            table.insert(
                GlobalVariables,
                {
                    name = name,
                    files = values
                }
            )
        else
            table.insert(
                GlobalVariables,
                {
                    name = name,
                    value = value
                }
            )
        end
    end

    handlers.add_library = function(parameters)
        if not parameters or #parameters == 0 then
            return
        end

        local library_name = parameters[1]
        local files = {}
        local kind = "StaticLib"

        local function getGlobalVariable(var_name)
            local clean_name = var_name:match("%${(.*)}") or var_name
            for _, var in ipairs(GlobalVariables or {}) do
                if type(var) == "table" and var.name == clean_name then
                    return var
                end
            end
            return nil
        end

        for i = 2, #parameters do
            local token = parameters[i]

            if token == "STATIC" then
                kind = "StaticLib"
            elseif token == "SHARED" then
                kind = "SharedLib"
            elseif token == "OBJECT" then
                kind = "StaticLib"
            else
                local var = getGlobalVariable(token)
                if var then
                    if type(var.files) == "table" then
                        for _, f in ipairs(var.files) do
                            table.insert(files, f)
                        end
                    elseif var.value then
                        table.insert(files, var.value)
                    end
                elseif not token:match("^%${.*}$") then
                    table.insert(files, token)
                end
            end
        end

        table.insert(
            cmake_projects,
            {
                name = library_name,
                kind = kind,
                files = files,
                target_compile_options = {},
                target_include_directories = {},
                target_compile_definitions = {}
            }
        )
    end

    return handlers
end

return cmake_premake
