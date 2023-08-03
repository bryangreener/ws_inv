local config = {}

local utils = require("utils")

local DEFAULT_CONFIG_PATH = "tmp.cfg"
local CONFIG_CAST_MAP = {
    rx=tonumber,
    tx=tonumber,
    protocol=tostring,
}
local DEFAULT_CONFIG = {
    rx=123,
    tx=456,
    protocol="workshop_inventory",
}

local function key_exists(k)
    return CONFIG_CAST_MAP[k] ~= nil
end

local function parse_item(out_table, k, v)
    if not key_exists(k) then
        print(("KeyError in config: %s"):format(k))
        return out_table
    end
    
    local res = CONFIG_CAST_MAP[k](v)
    if res == nil then
        print(("TypeError for config value: {%s: %s} (%s)"):format(k, v, type(v)))
        return out_table
    end
    out_table[k] = res
    return out_table
end

function config.load(path)
    local res = utils.copy_table(DEFAULT_CONFIG)
    
    if utils.isempty(path) then
        path = DEFAULT_CONFIG_PATH
    end    

    for line in io.lines(path) do
        local k, v = table.unpack(utils.split(line, "="))
        res = parse_item(res, k, v)
    end
    return res
end

return config