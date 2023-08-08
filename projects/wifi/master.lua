require("utils")

local uuid = gen_uuid()
local protocol = "workshop_inventory"
local rx = 123
local done = false
local slaves = {}

peripheral.find("modem", rednet.open)
rednet.host(protocol, os.getComputerLabel())

repeat
    local id, msg = rednet.receive(protocol)
    if id ~= nil and msg ~= nil then
        --msg is expected to be a UUID string
        if slaves[id] ~= nil then
            error("Slave ID already exists: " .. id)
        end
        slaves[id] = msg
        done = true
    end
until done

for k, v in pairs(slaves) do
    rednet.send(k, uuid, protocol)
    print("Slave added: " .. k .. " => " .. v)
end
