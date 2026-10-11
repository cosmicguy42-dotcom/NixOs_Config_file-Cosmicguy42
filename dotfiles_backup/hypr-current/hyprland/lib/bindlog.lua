-- Records every keybind as the config loads (combo, action, arguments,
-- description, source line) and writes ~/.local/state/nothing/binds.json so
-- Nothing Settings can show what each bind does and let you edit it.
-- Must be required before any hl.bind call.

local info = setmetatable({}, { __mode = "k" }) -- dispatcher userdata -> { name, args }

local function wrap(tbl, prefix)
    for name, fn in pairs(tbl) do
        if type(fn) == "function" then
            tbl[name] = function(...)
                local d = fn(...)
                if d ~= nil then
                    info[d] = { name = prefix .. name, args = { ... } }
                end
                return d
            end
        elseif type(fn) == "table" then
            wrap(fn, prefix .. name .. ".")
        end
    end
end
wrap(hl.dsp, "")

NOTHING_BINDS = {}
local submap = ""

local define_submap = hl.define_submap
hl.define_submap = function(name, fn)
    return define_submap(name, function(...)
        local prev = submap
        submap = name
        local r = fn(...)
        submap = prev
        return r
    end)
end

local function norm(combo)
    local mods, key = {}, nil
    for raw in string.gmatch(combo, "[^+]+") do
        local up = raw:gsub("^%s+", ""):gsub("%s+$", ""):upper()
        if up == "SUPER" or up == "SHIFT" or up == "CTRL" or up == "CONTROL" or up == "ALT" then
            mods[#mods + 1] = (up == "CONTROL") and "CTRL" or up
        else
            key = up
        end
    end
    table.sort(mods)
    return table.concat(mods, "+") .. "|" .. (key or "")
end

local bind = hl.bind
hl.bind = function(combo, action, opts)
    local src = debug.getinfo(2, "Sl")
    local e = {
        combo = combo,
        id = norm(combo),
        description = opts and opts.description or "",
        submap = submap,
        source = (src.short_src or ""):gsub("^.*/hypr/", "") .. ":" .. (src.currentline or 0),
        locked = opts and opts.locked or false,
        repeating = opts and opts.repeating or false,
        mouse = opts and opts.mouse or false,
    }
    if type(action) == "function" then
        e.kind = "lua"
    else
        local i = info[action]
        e.kind = "dsp"
        e.dsp = i and i.name or "?"
        e.args = i and i.args or {}
    end
    NOTHING_BINDS[#NOTHING_BINDS + 1] = e
    return bind(combo, action, opts)
end

local unbind = hl.unbind
hl.unbind = function(combo, ...)
    local id = norm(combo)
    for i = #NOTHING_BINDS, 1, -1 do
        if NOTHING_BINDS[i].id == id then
            table.remove(NOTHING_BINDS, i)
        end
    end
    return unbind(combo, ...)
end

-- Empty submap used by Settings while recording a new key combo, so no
-- existing bind fires. Settings always resets it (and times out after 10 s).
hl.define_submap("nothing-capture", function() end)

-- Minimal JSON encoder
local function json(v)
    local t = type(v)
    if t == "string" then
        return '"' .. v:gsub('[%c"\\]', function(c)
            return string.format("\\u%04x", c:byte())
        end) .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "table" then
        if #v > 0 or next(v) == nil then
            local out = {}
            for _, x in ipairs(v) do out[#out + 1] = json(x) end
            return "[" .. table.concat(out, ",") .. "]"
        end
        local out = {}
        for k, x in pairs(v) do out[#out + 1] = json(tostring(k)) .. ":" .. json(x) end
        return "{" .. table.concat(out, ",") .. "}"
    end
    return "null"
end

function nothing_dump_binds()
    local dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/nothing"
    os.execute('mkdir -p "' .. dir .. '"')
    local f = io.open(dir .. "/binds.json", "w")
    if f then
        f:write(json(NOTHING_BINDS))
        f:close()
    end
end
