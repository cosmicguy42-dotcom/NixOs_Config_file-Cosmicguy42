local cfg = ZANEYOS or {}
local env_entries = cfg.env or {}

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function parse_env(entry)
  local line = trim(entry)
  if line == "" then
    return nil, nil
  end

  local key, value = line:match("^([^,=]+)%s*,%s*(.+)$")
  if key and value then
    return trim(key), trim(value)
  end

  key, value = line:match("^([^=]+)%s*=%s*(.+)$")
  if key and value then
    return trim(key), trim(value)
  end

  return nil, nil
end

for _, entry in ipairs(env_entries) do
  local key, value = parse_env(entry)
  if key and value then
    hl.env(key, value)
  end
end
