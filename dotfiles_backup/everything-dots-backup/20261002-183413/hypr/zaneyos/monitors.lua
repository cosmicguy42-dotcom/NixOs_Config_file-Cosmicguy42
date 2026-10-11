local cfg = ZANEYOS or {}
local monitor_lines = cfg.monitorLines or {}

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function parse_monitor(entry)
  local line = trim(entry)
  if line == "" or line:sub(1, 1) == "#" then
    return nil
  end

  line = line:gsub("^monitor%s*=%s*", "")
  local output, mode, position, scale = line:match("^([^,]*),([^,]+),([^,]+),(.+)$")
  if not output then
    return nil
  end

  return {
    output = trim(output),
    mode = trim(mode),
    position = trim(position),
    scale = trim(scale),
  }
end

for _, entry in ipairs(monitor_lines) do
  local spec = parse_monitor(entry)
  if spec then
    hl.monitor(spec)
  end
end
