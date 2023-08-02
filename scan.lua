local inventory = require("inventory")
local Turtle = require("turtle")

local SCANNER_DEFAULT_MODE = "snake"

local home_x = -421
local home_y = 60
local home_z = 1719
local home_pos = nil


local dest_pos = nil

local Scanner = {}

local function default_on_move_cb(pos, orientation)
    print("on_move_cb: " .. textutils.serialize(pos)
end

local function scan_snake(_turtle, start_pos, end_pos)
    print(("Scanning: mode=snake, start=%s, end=%s"):format(tostring(start_pos), tostring(end_pos)))
    local res = true
    local dir_x = ((pos_1.x - pos_0.x) < 0) and -1 or 1

    for x=math.abs(pos_0.x),math.abs(pos_1.x)+1 do
        res = _turtle:move_to(vector.new(x, pos_0.y, _turtle:get_pos().z))
        if not res then break end

        if (x - pos_0.x) % 2 == 0 then
            res = _turtle:move_to(vector.new(x, pos_0.y, pos_1.z + 1))
            if not res then break end
        else
            _turtle:move_to(vector.new(x, pos_0.y, pos_0.z))
            if not res then break end
        end
    end

    if not res then
        print("ScannerError: Scanning failed.")
        return res
    end
    
    print("Scanning complete.")
    return res
end


function Scanner.__init__(base, args)
    local home_pos
    local on_move_cb
    local mode

    print("Scanner: Initializing...")

    -- If all three of x, y, and z are specified for home position, use them.
    -- Otherwise, we will just use the current position as the home position.
    if args.home_x ~= nil and args.home_y ~= nil and args.home_z ~= nil then
        home_pos = vector.new(args.home_x, args.home_y, args.home_z)
    end

    if args.on_move_cb == nil then
        on_move_cb = default_on_move_cb
    end

    if utils.isempty(args.mode) then
        mode = SCANNER_DEFAULT_MODE
    end

    local _turtle = Turtle(on_move_cb, home_pos)

    self = {
        turtle=_turtle,
        mode=mode,
    }
    setmetatable(self, {__index=Scanner})

    print("Scanner: Initialized.")
    return self
end
setmetatable(Scanner, {__call=Scanner.__init__})

function Scanner:__tostring()
    return (
        "<Scanner:\n\tturtle=%s\n\tmode=%s>"
    ):format(tostring(self.turtle), mode)
end

function Scanner:scan(mode, end_pos, start_pos)
    if utils.isempty(mode) then
        mode = self.mode
    end

    -- end_pos is required
    if end_pos == nil then
        print("ScannerError: scan:: end_pos must be a vector. Got nil.")
        return false
    end

    -- start_pos can be nil if we just want to use current turtle pos
    if start_pos == nil then
        start_pos = self.turtle:get_pos()
    end

    if mode == "snake" then
        return scan_snake(self.turtle, start_pos, end_pos)
    else
        print("ScannerError: scan:: Invalid scan mode: " .. mode)
        return false
    end
end

print(turtle.getFuelLevel())
scan_init()

local tmp = vector.new(-436, home_pos.y, 1737)
scan_rect(home_pos, tmp)

print("Found " .. inventory_count .. " inventories.")