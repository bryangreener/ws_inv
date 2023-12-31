local utils = require("utils.utils")
local Orientation = require("turtle.orientation")

local TURTLE_DEFAULT_GPS = true

local Turtle = {}

-- Uses the GPS API to get the current position of the turtle.
--
-- Returns:
--      vector: The current turtle position as a vector instance.
local function get_gps_pos()
    local x, y, z = gps.locate()
    if x == nil or y == nil or z == nil then
        error("GPS Error")
    end
    return vector.new(x, y, z)
end

-- Gets the current turtle position after having moved.
--
-- The cardinal direction is used to determine which axis we moved along and the
-- direction along that axis.
--
-- Args:
--      cardinal [str]: The cardinal direction that the turtle is facing.
--      prev_pos [vector]: The previous position of the turtle.
--
-- Returns:
--      vector: The new turtle's position as a vector instance.
local function get_new_pos(cardinal, prev_pos)
    local x = prev_pos.x
    local y = prev_pos.y
    local z = prev_pos.z

    if cardinal == "n" then
        z = z - 1
    elseif cardinal == "e" then
        x = x + 1
    elseif cardinal == "s" then
        z = z + 1
    elseif cardinal == "w" then
        x = x - 1
    elseif cardinal == "up" then
        y = y + 1
    elseif cardinal == "down" then
        y = y - 1
    else
        error("get_new_pos: ValueError: invalid cardinal direction: " .. cardinal)
    end

    return vector.new(x, y, z)
end

-- Custom Turtle wrapper class.
--
-- Provides additional functionality around the turtle API.
--
-- Members:
--      home_pos: See this class's "Args" section.
--      curr_pos [vector]: The current position of the turtle. Nil until calibrated.
--      orientation [Orientation]: Current orientation of the turtle.
--          Nil until calibrate() is run.
--      on_move_cb: See this class's "Args" section.
--
-- Args:
--      on_move_cb [function(Turtle, vector, Orientation)]: Optional callback function reference.
--          Called whenever the turtle moves to a new block.
--      home_pos [vector]: Optional vector specifying the home position of the Turtle.
--          If not specified, the current position of the turtle is used.
function Turtle.__init__(base, args)
    local self = {
        home_pos=nil,
        curr_pos=nil,
        orientation=nil,
        pre_move_cb=nil,
        on_move_cb=nil,
        gps=nil,
    }
    setmetatable(self, {__index=Turtle, __tostring=Turtle.__tostring})

    if args ~= nil then
        self.home_pos = args.home_pos
        self.pre_move_cb = args.pre_move_cb
        self.on_move_cb = args.on_move_cb
        self.gps = args.gps
    end

    if self.gps == nil then
        self.gps = TURTLE_DEFAULT_GPS
    end

    if not self.gps then
        print("WARNING: Using Turtle without GPS.")
        print("Coordinates for movement are relative to turtle start position:")
        print("    -x=left, +x=right")
        print("    -z=forward, +z=back")
    end

    return self
end
setmetatable(Turtle, {__call=Turtle.__init__})

-- Overrides the tostring() method with a custom string.
function Turtle.__tostring(o)
    return (
        "<Turtle: home_pos=%s, curr_pos=%s, orientation=%s>"
    ):format(
        tostring(o.home_pos),
        tostring(o.curr_pos),
        tostring(o.orientation)
    )
end

-- Handles events where the turtle is about to move to a new coordinate.
-- The turtle has not actually moved yet, but the turtle HAS rotated to face
-- the new direction.
function Turtle:pre_move()
    if self.pre_move_cb ~= nil then
        self.pre_move_cb(self, self.curr_pos, self.orientation)
    end
end

-- Handles events where the turtle has moved to a new coordinate.
-- Calls the on_move_cb callback if it is not nil.
function Turtle:on_move()
    if self.on_move_cb ~= nil then
        self.on_move_cb(self, self.curr_pos, self.orientation)
    end
end

-- Turns turtle to the left n times.
function Turtle:turn_left(n)
    local res
    if n == nil or n < 1 then
        n = 1
    end
    for i=1,n do
        res = turtle.turnLeft()
        if not res then
            return res
        end
        self.orientation:rotate(-1)
    end
    return res
end

-- Turns turtle to the right n times.
function Turtle:turn_right(n)
    local res
    if n == nil or n < 1 then
        n = 1
    end
    for i=1,n do
        res = turtle.turnRight()
        if not res then
            return res
        end
        self.orientation:rotate(1)
    end
    return res
end

-- Helper function to turn twice so the turtle is facing opposite direction.
function Turtle:turn_back()
    local res = self:turn_right()
    if not res then return res end
    return self:turn_right()
end

-- Moves turtle forward 1 block.
function Turtle:forward()
    self:pre_move()

    local res = turtle.forward()
    if not res then
        return res
    end
    self.curr_pos = get_new_pos(self.orientation:get(), self.curr_pos)

    self:on_move()

    return res
end

-- Moves turtle backward 1 block. Does not turn the turtle.
function Turtle:back()
    self:pre_move()

    -- Change orientation to look behind us but dont actually turn since turning costs
    -- time. This just allows our position updating function to work properly.
    local o = Orientation{cardinal=self.orientation:get()}
    o:reverse()
    local res = turtle.back()
    -- Calculate new position while orientation is reversed
    -- but do not set it in case we failed to move.
    local curr_pos = get_new_pos(o:get(), self.curr_pos)

    -- Now check if our movement failed.
    if not res then
        return res
    end

    -- Successful movement. Now we can set the new position.
    self.curr_pos = curr_pos

    self:on_move()
    
    return res
end

-- Moves the turtle left one block. Turtle turns to face left.
function Turtle:left()
    local res = self:turn_left()
    if not res then
        return res
    end
    return self:forward()
end

-- Moves the turtle right one block. Turtle turns to face right.
function Turtle:right()
    local res = self:turn_right()
    if not res then
        return res
    end
    return self:forward()
end

function Turtle:up()
    self:pre_move()

    local res = turtle.up()
    if not res then
        return res
    end
    self.curr_pos = get_new_pos("up", self.curr_pos)

    self:on_move()

    return res
end

function Turtle:down()
    self:pre_move()

    local res = turtle.down()
    if not res then
        return res
    end
    self.curr_pos = get_new_pos("down", self.curr_pos)

    self:on_move()

    return res
end

-- Returns the current vector position of the turtle from memory.
function Turtle:get_curr_pos()
    return self.curr_pos
end

-- Turns a turtle to the specified cardinal direction.
function Turtle:turn_to(dest)
    local delta = self.orientation:get_rotation_delta(nil, dest)
    if delta == 0 then
        return true
    elseif delta < 0 then
        return self:turn_left(math.abs(delta))
    else
        return self:turn_right(math.abs(delta))
    end
end

function Turtle:move_to(dest, axis)
    if utils.isempty(axis) then
        if not self:move_to(dest, "x") then
            return false
        end
        if not self:move_to(dest, "z") then
            return false
        end
        if not self:move_to(dest, "y") then
            return false
        end
    else
        c0 = self.curr_pos[axis]
        c1 = dest[axis]
        local d_c = c1 - c0
        if d_c == 0 then
            return true
        end

        local sign = (d_c < 0) and "-" or "+"

        local move_fn
        if axis == "x" or axis == "z" then
            move_fn = self.forward
        else
            move_fn = (sign == "+") and self.up or self.down
        end
        
        if axis ~= "y" then
            if not self:turn_to(self.orientation:axis_and_sign_to_cardinal(axis, sign)) then
                return false
            end
        end

        while d_c ~= 0 do
            if not move_fn(self) then
                print("TurtleError: Movement blocked.")
                return false
            end
            d_c = d_c - (d_c / math.abs(d_c))
        end
    end
    return true
end

-- Moves the turtle to its home position.
function Turtle:go_home()
    if self.home_pos == nil then
        print("go_home: turtle is not yet calibrated!")
        return false
    end
    return self:move_to(self.home_pos)
end

-- Returns the current vector position of the turtle.
-- If specified or curr_pos is nil then GPS will be used to get the current
-- position of the turtle.
function Turtle:get_pos(override)
    local x, y, z
    -- If curr_pos is nil, then we MUST get a new position.
    if self.curr_pos == nil then
        override = true
    end
    if override == nil then
        override = false
    end

    -- If override is specified, then we get a fresh location.
    if override then
        if self.gps then
            return get_gps_pos()
        else
            return vector.new(0, 0, 0)
        end
    end
    -- Otherwise, we just return the current position.
    return self:get_curr_pos()
end

-- Returns whether the turtle is facing the specified cardinal direction.
function Turtle:is_facing(d)
    if utils.isempty(d) then
        error("ValueError: d is nil/empty")
    end
    if d ~= nil then
        d = string.lower(d)
    end
    return self.orientation:get() == d
end

-- Calibrates the turtle by calculating the current position and orientation.
--
-- Attempts to move the turtle in each of the cardinal directions. As soon as it can
-- move in any direction, it returns back to the starting position and uses the deltas
-- to calculate orientation.
-- This function uses the GPS to determine current position.
function Turtle:calibrate()
    -- calibrate without GPS if GPS mode is disabled.
    if not self.gps then
        print("Calibrating without GPS.")
        self.curr_pos = vector.new(0, 0, 0)
        self.orientation = Orientation{cardinal="n"}
        if self.home_pos == nil then
            self.home_pos = self.curr_pos
        end
        return true
    end

    -- otherwise, use GPS to calibrate.

    self.curr_pos = vector.new(gps.locate())
    self.orientation = nil

    for i=1,4 do
        if turtle.forward() then
            break
        else
            turtle.turnLeft()
        end
    end
    local new_pos = vector.new(gps.locate())
    if new_pos:equals(self.curr_pos) then
        print("TurtleError: Turtle failed to move during calibration.")
        return false
    end

    local d_x = new_pos.x - self.curr_pos.x
    local d_z = new_pos.z - self.curr_pos.z
    local axis = (
        (d_x + math.abs(d_x) * 2) +
        (d_z + math.abs(d_z) * 3)
    )
    self.orientation = Orientation{axis=axis}
    -- Since we moved forward 1, we need to update the current position.
    self.curr_pos = new_pos

    -- Return back to origin of calibration.
    if self.home_pos == nil then
        self:back()
        self.home_pos = self.curr_pos
    else
        self:go_home()
    end

    return true
end

-- Direct wrappers around turtle API functions.
Turtle.craft = turtle.craft
Turtle.dig = turtle.dig
Turtle.dig_up = turtle.digUp
Turtle.dig_down = turtle.digDown
Turtle.place = turtle.place
Turtle.place_up = turtle.placeUp
Turtle.place_down = turtle.placeDown
Turtle.drop = turtle.drop
Turtle.drop_up = turtle.dropUp
Turtle.drop_down = turtle.dropDown
Turtle.select = turtle.select
Turtle.get_item_count = turtle.getItemCount
Turtle.get_item_space = turtle.getItemSpace
Turtle.detect = turtle.detect
Turtle.detect_up = turtle.detectUp
Turtle.detect_down = turtle.detectDown
Turtle.compare = turtle.compare
Turtle.compare_up = turtle.compareUp
Turtle.compare_down = turtle.compareDown
Turtle.suck = turtle.suck
Turtle.suck_up = turtle.suckUp
Turtle.suck_down = turtle.suckDown
Turtle.get_fuel_level = turtle.getFuelLevel
Turtle.refuel = turtle.refuel
Turtle.compare_to = turtle.compareTo
Turtle.transfer_to = turtle.transferTo
Turtle.get_selected_slot = turtle.getSelectedSlot
Turtle.get_fuel_limit = turtle.getFuelLimit
Turtle.equip_left = turtle.equipLeft
Turtle.equip_right = turtle.equipRight
Turtle.inspect = turtle.inspect
Turtle.inspect_up = turtle.inspectUp
Turtle.inspect_down = turtle.inspectDown
Turtle.get_item_detail = turtle.getItemDetail

return Turtle
