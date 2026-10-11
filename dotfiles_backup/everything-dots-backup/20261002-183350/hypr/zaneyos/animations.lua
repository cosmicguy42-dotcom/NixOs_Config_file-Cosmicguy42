local cfg = ZANEYOS or {}
local animation_cfg = cfg.animation or {}
local bezier_entries = animation_cfg.bezier or {}
local animation_entries = animation_cfg.animation or {}

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function split_csv(entry)
  local parts = {}
  for value in tostring(entry or ""):gmatch("([^,]+)") do
    local cleaned = trim(value:gsub("%s*#.*$", ""))
    if cleaned ~= "" then
      table.insert(parts, cleaned)
    end
  end
  return parts
end

local function to_boolean(value)
  local normalized = trim(tostring(value or "")):lower()
  if normalized == "1" or normalized == "true" or normalized == "yes" or normalized == "on" then
    return true
  end
  if normalized == "0" or normalized == "false" or normalized == "no" or normalized == "off" then
    return false
  end
  return nil
end

local function parse_curve(entry)
  local parts = split_csv(entry)
  if #parts < 5 then
    return nil
  end

  local x1 = tonumber(parts[2])
  local y1 = tonumber(parts[3])
  local x2 = tonumber(parts[4])
  local y2 = tonumber(parts[5])
  if not (x1 and y1 and x2 and y2) then
    return nil
  end

  return {
    name = parts[1],
    points = {
      { x1, y1 },
      { x2, y2 },
    },
  }
end

local function parse_animation(entry)
  local parts = split_csv(entry)
  if #parts < 4 then
    return nil
  end

  local enabled = to_boolean(parts[2])
  if enabled == nil then
    enabled = true
  end

  local style = nil
  if #parts > 4 then
    style = trim(table.concat(parts, ", ", 5))
    if style == "" then
      style = nil
    end
  end

  local parsed = {
    leaf = parts[1],
    enabled = enabled,
    speed = tonumber(parts[3]) or parts[3],
    bezier = parts[4],
  }

  if style then
    parsed.style = style
  end

  return parsed
end

hl.config({
  animations = {
    enabled = animation_cfg.enabled ~= false,
  },
})

for _, entry in ipairs(bezier_entries) do
  local curve = parse_curve(entry)
  if curve then
    hl.curve(curve.name, {
      type = "bezier",
      points = curve.points,
    })
  end
end

for _, entry in ipairs(animation_entries) do
  local parsed = parse_animation(entry)
  if parsed then
    hl.animation(parsed)
  end
end
