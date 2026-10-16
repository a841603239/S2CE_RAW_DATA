module((...), package.seeall)

function traceback(out_func)
  for level = 1, 10 do
    local info = debug.getinfo(level, "Sl")
    if not info then
      break
    end
    if info.what == "C" then
      out_func(level, "C function")
    else
      out_func(string.format("[%s]:%d", info.short_src, info.currentline))
    end
  end
  out_func([[


]])
end

function TruncToInt(number)
  return number - number % 1
end

function RoundToInt(number)
  number = number + 0.5
  return number - number % 1
end

function RupToInt(number)
  if number % 1 > 0 then
    return number - number % 1 + 1
  else
    return number
  end
end

function Clamp(number, min, max)
  if max < number then
    return max
  elseif number < min then
    return min
  end
  return number
end

function Max(a, ...)
  local max = a
  for i, v in ipairs({
    ...
  }) do
    if max < v then
      max = v
    end
  end
  return max
end

function Min(a, ...)
  local min = a
  for i, v in ipairs({
    ...
  }) do
    if min > v then
      min = v
    end
  end
  return min
end

function outputbitfield(b)
  local s = ""
  for i = 0, 7 do
    if 0 < bit.band(bit.lshift(1, 7 - i), b) then
      s = s .. "1"
    else
      s = s .. "0"
    end
  end
  return s
end

function Require(pack)
  pack = string.lower(pack)
  if package.loaded[pack] == nil then
    require(pack)
  end
  return package.loaded[pack]
end

function UnRequire(pack)
  pack = string.lower(pack)
  package.loaded[pack] = nil
  _G[pack] = nil
end

function UnRequireAll()
  for k, v in ipairs(package.loaded) do
    package.loaded[k] = nil
    _G[k] = nil
  end
end

function NamespaceFile(pack)
  local f
  for c in string.gmatch(package.path, "[^;]+") do
    local fname = string.gsub(c, "?", pack)
    f = loadfile(fname)
    if f ~= nil then
      break
    end
  end
  if f == nil then
    error("Unable to create namespace from file " .. pack)
  end
  t = {}
  setmetatable(t, {
    __index = getfenv(1)
  })
  setfenv(f, t)
  f()
  return t
end

function PrintTable(t, printf, prefix)
  if t ~= nil then
    if prefix == nil then
      prefix = ""
    end
    for k, v in pairs(t) do
      if type(v) == "table" then
        printf(prefix .. tostring(k) .. "...")
        PrintTable(v, printf, prefix .. "..")
      else
        printf(prefix .. " " .. k .. ", " .. tostring(v))
      end
    end
  end
end

function CopyTable(src)
  local dest = {}
  if src ~= nil then
    for i, v in ipairs(src) do
      if type(v) == "table" then
        dest[i] = CopyTable(v)
      else
        dest[i] = v
      end
    end
    for k, v in pairs(src) do
      if type(v) == "table" then
        dest[k] = CopyTable(v)
      else
        dest[k] = v
      end
    end
  end
  setmetatable(dest, getmetatable(src))
  return dest
end

function CopyIntoTable(src, dest, ignore_field)
  if src ~= nil then
    for i, v in ipairs(src) do
      if type(ignore_field) == "number" and i == ignore_field then
      elseif type(v) == "table" then
        if dest[i] == nil then
          dest[i] = {}
        end
        CopyIntoTable(v, dest[i], ignore_field)
      else
        dest[i] = v
      end
    end
    for k, v in pairs(src) do
      if type(ignore_field) == "string" and k == ignore_field then
      elseif type(v) == "table" then
        if dest[k] == nil then
          dest[k] = {}
        end
        CopyIntoTable(v, dest[k], ignore_field)
      else
        dest[k] = v
      end
    end
  end
end

function CompareByValue(value1, value2)
  if type(value1) == "table" then
    if type(value2) ~= "table" then
      return false
    end
    if value1.CoreUtils_CompareByValue_TemporaryMarker ~= nil or value2.CoreUtils_CompareByValue_TemporaryMarker ~= nil then
      return value1.CoreUtils_CompareByValue_TemporaryMarker == value2 and value2.CoreUtils_CompareByValue_TemporaryMarker == value1
    end
    value1.CoreUtils_CompareByValue_TemporaryMarker = value2
    value2.CoreUtils_CompareByValue_TemporaryMarker = value1
    local equals = true
    for k, v in pairs(value1) do
      if CompareByValue(v, value2[k]) ~= true then
        equals = false
        break
      end
    end
    if equals == true then
      for k, v in pairs(value2) do
        if value1[k] == nil then
          equals = false
          break
        end
      end
    end
    value1.CoreUtils_CompareByValue_TemporaryMarker = nil
    value2.CoreUtils_CompareByValue_TemporaryMarker = nil
    return equals
  else
    return value1 == value2
  end
end

function PickFGColour(rgb)
  if (rgb.R + rgb.G + rgb.B) / 3 > 140 then
    return {
      r = 0,
      g = 0,
      b = 0,
      a = 255
    }
  else
    return {
      r = 255,
      g = 255,
      b = 255,
      a = 255
    }
  end
end
