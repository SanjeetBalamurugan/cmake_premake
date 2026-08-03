local p = premake

p.modules.cmake_premake = p.modules.cmake_premake or {}
p.modules.cmake_premake.pprint = {}
local pprint = p.modules.cmake_premake.pprint

function pprint.prettyPrint(val, indent)
    indent = indent or ""
    if type(val) == "table" then
        local str = "{\n"
        for k, v in pairs(val) do
            local key = type(k) == "string" and string.format("[%q]", k) or "[" .. k .. "]"
            str = str .. indent .. "  " .. key .. " = " .. pprint.prettyPrint(v, indent .. "  ") .. ",\n"
        end
        return str .. indent .. "}"
    elseif type(val) == "string" then
        return string.format("%q", val)
    else
        return tostring(val)
    end
end

return pprint
