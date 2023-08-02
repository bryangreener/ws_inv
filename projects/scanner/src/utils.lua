local utils = {}

function utils.invert_table(tab)
    local res = {}
    for k, v in pairs(tab) do
        res[v] = k
    end
    return res
end

return utils