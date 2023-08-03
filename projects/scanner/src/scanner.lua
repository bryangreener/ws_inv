local utils = require("utils")
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
    --print("on_move_cb: " .. textutils.serialize(pos))
end

local function scan_snake(_turtle, start_pos, end_pos)
    print(("Scanning: mode=snake, start=%s, end=%s"):format(tostring(start_pos), tostring(end_pos)))
    local res = true
    local dir_x = ((end_pos.x - start_pos.x) < 0) and -1 or 1

    for x=math.abs(start_pos.x),math.abs(end_pos.x)+1 do
        res = _turtle:move_to(vector.new(x, start_pos.y, _turtle:get_pos().z))
        if not res then break end

        if (x - start_pos.x) % 2 == 0 then
            res = _turtle:move_to(vector.new(x, start_pos.y, end_pos.z + 1))
            if not res then break end
        else
            _turtle:move_to(vector.new(x, start_pos.y, start_pos.z))
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

    if args == nil then
        args = {}
    end

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
    _turtle:calibrate()

    self = {
        turtle=_turtle,
        mode=mode,
    }
    setmetatable(
        self,
        {
            __index=Scanner,
            __tostring=Scanner.__tostring,
        }
    )

    print("Scanner: Initialized.")
    return self
end
setmetatable(Scanner, {__call=Scanner.__init__})

function Scanner.__tostring()
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

local scanner = Scanner()

local tmp = vector.new(-436, 60, 1737)
scanner:scan("snake", tmp)

return Scanner
