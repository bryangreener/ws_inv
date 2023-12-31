-- This adds this file's directory to the package.path.
-- Using "require()" in subdirectories requires they reference modules
-- as if from this file's path.
-- For example, in projects/turtle/orientation.lua we include projects/utils/utils.lua
-- like so:
--      local utils = require("utils.utils")
package.path = package.path .. ";../?.lua"

local utils = require("utils.utils")
local inventory = require("utils.inventory")
local Turtle = require("turtle.turtle")

local SCANNER_DEFAULT_MODE = "snake"

local Scanner = {}

local function default_on_move_cb(pos, orientation)
    --print("on_move_cb: " .. textutils.serialize(pos))
end

local function scan_snake(_turtle, start_pos, end_pos)
    print(("Scanning: mode=snake, start=%s, end=%s"):format(tostring(start_pos), tostring(end_pos)))
    local res = true

    local step = ((end_pos.x - start_pos.x) < 0) and -1 or 1
    for x=start_pos.x,end_pos.x+1,step do
        res = _turtle:move_to(vector.new(x, start_pos.y, _turtle:get_pos().z))
        if not res then
            break
        end

        if (x - start_pos.x) % 2 == 0 then
            res = _turtle:move_to(vector.new(x, start_pos.y, end_pos.z + 1))
            if not res then
                break
            end
        else
            _turtle:move_to(vector.new(x, start_pos.y, start_pos.z))
            if not res then
                break
            end
        end
    end

    if not res then
        print("ScannerError: Scanning failed.")
        return res
    end
    
    print("Scanning complete.")
    return true
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
--      gps [bool]: Whether to enable GPS. If false, then all movement will be relative
--          to the starting position of the turtle.
function Scanner.__init__(o, args)
    local self = {turtle=nil, mode=nil}
    setmetatable(self, {__index=Scanner, __tostring=Scanner.__tostring})

    print("Scanner: Initializing...")

    if args ~= nil then
        self.turtle = Turtle{
            home_pos=args.home_pos,
            on_move_cb=args.on_move_cb,
            gps=args.gps,
        }
        self.mode = args.mode
    else
        self.turtle = Turtle()
    end

    if utils.isempty(self.mode) then
        self.mode = SCANNER_DEFAULT_MODE
    end

    self.turtle:calibrate()

    print("Scanner: Initialized.")
    return self
end
setmetatable(Scanner, {__call=Scanner.__init__})

function Scanner.__tostring(o)
    return (
        "<Scanner:\n\tturtle=%s\n\tmode=%s>"
    ):format(tostring(o.turtle), mode)
end

function Scanner:scan(end_pos, start_pos, mode)
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

    -- Move to start positon.
    if not self.turtle:move_to(start_pos) then
        print("Error moving to start position: " .. tostring(start_pos))
        return false
    end

    if mode == "snake" then
        return scan_snake(self.turtle, start_pos, end_pos)
    else
        print("ScannerError: scan:: Invalid scan mode: " .. mode)
        return false
    end
end

return Scanner
