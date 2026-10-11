local cfg = ZANEYOS or {}
local rules_text = cfg.windowRulesHyprlang or ""

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function parse_scalar(value)
  local cleaned = trim((value or ""):gsub("%s*#.*$", ""))
  if cleaned == "" then
    return cleaned
  end

  local lowered = cleaned:lower()
  if lowered == "on" or lowered == "true" then
    return true
  end
  if lowered == "off" or lowered == "false" then
    return false
  end

  local number = tonumber(cleaned)
  if number ~= nil then
    return number
  end

  if cleaned:match("%s=%s") then
    return trim(cleaned:gsub("%s*=%s*", " "))
  end

  return cleaned
end

local function apply_rule(rule)
  if not rule then
    return
  end
  if rule.match and next(rule.match) == nil then
    rule.match = nil
  end
  hl.window_rule(rule)
end

local function parse_rule_shorthand(line)
  local action, action_value, match_key, match_value =
    line:match("^rule%s*=%s*([%w_]+)%(([^)]*)%)%s*,%s*match:([^:]+):(.+)$")
  if not action then
    return nil
  end

  local rule = {
    match = {},
  }
  rule[action] = parse_scalar(action_value)
  rule.match[trim(match_key)] = parse_scalar(match_value)
  return rule
end

local current_rule = nil

for raw_line in tostring(rules_text):gmatch("[^\n]+") do
  local line = trim(raw_line)
  if line ~= "" and not line:match("^#") then
    if not current_rule then
      if line == "windowrule {" then
        current_rule = {
          match = {},
        }
      else
        apply_rule(parse_rule_shorthand(line))
      end
    else
      if line == "}" then
        apply_rule(current_rule)
        current_rule = nil
      else
        local key, value = line:match("^([^=]+)%s*=%s*(.+)$")
        if key and value then
          key = trim(key)
          value = trim(value)
          local match_key = key:match("^match:(.+)$")
          if match_key then
            current_rule.match[trim(match_key)] = parse_scalar(value)
          else
            current_rule[key] = parse_scalar(value)
          end
        end
      end
    end
  end
end

if current_rule then
  apply_rule(current_rule)
end
