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

function table.contains(t, value)
  for _, v in ipairs(t) do
    if v == value then
      return true
    end
  end

  return false
end