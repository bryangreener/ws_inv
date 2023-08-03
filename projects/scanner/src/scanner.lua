local utils = require("utils")
local inventory = require("inventory")
local Turtle = require("turtle")

local SCANNER_DEFAULT_MODE = "snake"

local home_x = -421
local home_y = 60
local home_z = 1719
local home_pos = nil


local dest_pos = nil

local Scanner = {
    turtle=nil,
    mode=nil,
}

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

-- Class that handles scanning an area with a turtle.
--
-- Members:
--      home_pos: See this class's "Args" section.
--      on_move_cb: See this class's "Args" section.
--      turtle [Turtle]: A Turtle instance controlled by this class.
--
-- Args:
--      mode [str]: The scanning mode to use.
--          Available options are: snake
--      home_pos [vector]: Optional vector defining the home position of the turtle.
--          If not specified, will use the current turtle position.
--      on_move_cb [function(vector, Orientation)]: Optional callback function reference.
--          Called whenever the turtle moves to a new block.
function Scanner.__init__(o, args)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.__tostring = Scanner.__tostring

    local home_pos
    local on_move_cb
    local mode

    print("Scanner: Initializing...")

    -- args is optional so if not passed we just set it to an empty table.
    -- This prevents the following checks from erroring.
    if args == nil then
        args = {}
    end

    if args.home_pos ~= nil then
        home_pos = args.home_pos
    end

    if args.on_move_cb ~= nil then
        on_move_cb = args.on_move_cb
    else
        on_move_cb = default_on_move_cb
    end

    if utils.isempty(args.mode) then
        mode = SCANNER_DEFAULT_MODE
    end

    self.turtle = Turtle{home_pos=home_pos, on_move_cb=on_move_cb}
    self.turtle:calibrate()

    print("Scanner: Initialized.")
    return o
end
setmetatable(Scanner, {__call=Scanner.__init__})

function Scanner.__tostring(o)
    return (
        "<Scanner:\n\tturtle=%s\n\tmode=%s>"
    ):format(tostring(o.turtle), mode)
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
