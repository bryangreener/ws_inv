local utils = {}

function utils.invert_table(tab)
    local res = {}
    for k, v in pairs(tab) do
        res[v] = k
    end
    return res
end

function utils.isempty(v)
    if not v or v == "" then
        return true
    end
    return false
end

function utils.copy_table(tab)
    local res = {}
    for k, v in pairs(tab) do
        res[k] = v
    end
    return res
end

function utils.gen_uuid()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function (c)
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end

function utils.is_file(path)
    if utils.isempty(path) then return false end
    return fs.exists(path) and not fs.isDir(path)
end

function utils.file_read(path)
    if utils.isempty(path) then return nil end
    if not utils.is_file(path) then return nil end
    
    local f_in = fs.open(path, "r")
    local lines = f_in.readAll()
    f_in.close()
    return lines
end

function utils.file_write(path, lines)
    if utils.isempty(path) then return false end
    if utils.isempty(lines) then return false end
    if not utils.is_file(path) then return false end
    
    local f_out = fs.open(path, "w")
    for _, line in pairs(lines) do
        f_out.write(tostring(line))
    end
    f_out.close()
    return true
end    
    
function utils.prompt_confirm(msg)
    if utils.isempty(msg) then
        msg = "Confirm? (y/N)> "
    end
    local completion = require "cc.completion"
    write(msg)
    local res = read()
    return (res == "y" or res == "Y")
end

function utils.split(inp, sep)
    if utils.isempty(inp) then return nil end
    if utils.isempty(sep) then sep = "%s" end
    local res = {}
    for s in string.gmatch(inp, "([^" .. sep .. "]+)") do
        table.insert(res, s)
    end
    return res
end

return utils