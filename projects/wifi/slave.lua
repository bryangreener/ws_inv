require("utils")

local protocol = "workshop_inventory"
local uuid = gen_uuid()
local host_id = nil
local host_uuid = nil
local msg = {}

peripheral.find("modem", rednet.open)

host_id = rednet.lookup(protocol)

if host_id == nil then
    error("No hosts found!")
end

print("Establishing connection to host...")
rednet.send(host_id, uuid, protocol)
-- await response from host with its UUID
repeat
    local _id, _msg = rednet.receive(protocol)
    if _id ~= nil or _msg ~= nil then
        if _id == host_id then
            host_uuid = _msg
        end
    end
until host_uuid ~= nil

print("Connected to host: " .. host_id .. " => " .. host_uuid)
