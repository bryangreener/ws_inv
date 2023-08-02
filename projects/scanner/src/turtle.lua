local utils = require("utils")
local Orientation = require("orientation")

local Turtle = {}

local function get_gps_pos()
    local x, y, z = gps.locate()
    if x == nil or y == nil or z == nil then
        error("GPS Error")
    end
    return vector.new(x, y, z)
end

local function get_new_pos(orientation, curr_pos)
    local card = orientation:get()
    local x = curr_pos.x
    local y = curr_pos.y
    local z = curr_pos.z

    if card == "n" then
        z = z - 1    
    elseif card == "e" then
        x = x + 1
    elseif card == "s" then
        z = z + 1
    elseif card == "w" then
        x = x - 1
    else
        error("get_new_pos: ValueError: invalid cardinal direction: " .. card)
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
--      orientation [Orientation]: Current orientation of the turtle. Nil until calibrated.
--      on_move_cb: See this class's "Args" section.
--
-- Args:
--      on_move_cb [function(vector, Orientation)]: Optional callback function reference.
--          Called whenever the turtle moves to a new block.
--      home_pos [vector]: Optional vector specifying the home position of the Turtle.
--          If not specified, the current position of the turtle is used.
function Turtle.__init__(base, on_move_cb, home_pos)
    self = {
        home_pos=home_pos,
        curr_pos=nil,
        orientation=nil,
        on_move_cb=on_move_cb
    }
    setmetatable(self, {__index=Turtle})
    return self
end
setmetatable(Turtle, {__call=Turtle.__init__})

function Turtle:__tostring()
    return (
        "<Turtle: home_pos=%s, curr_pos=%s, orientation=%s>"
    ):format(
        tostring(self.home_pos),
        tostring(self.curr_pos),
        tostring(self.orientation)
    )
end

-- Handles events where the turtle has moved to a new coordinate.
-- Calls the on_move_cb callback if it is not nil
function Turtle:on_move()
    if self.on_move_cb ~= nil then
        self.on_move_cb(self.curr_pos, self.orientation)
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
    local res = self.turn_right()
    if not res then return res end
    return self.turn_right()
end

-- Moves turtle forward 1 block.
function Turtle:forward()
    local res = turtle.forward()
    if not res then
        return res
    end
    self.curr_pos = get_new_pos(self.orientation, self.curr_pos)

    self.on_move()

    return res
end

-- Moves turtle backward 1 block. Does not turn the turtle.
function Turtle:back()
    -- Change orientation to look behind us but dont actually turn
    -- since turning costs time. This just allows our position updating function
    -- to work properly.
    self.orientation:rotate(2)
    local res = turtle.back()
    -- Calculate new position while orientation is looking backward
    -- but do not set it in case we failed to move.
    local curr_pos = get_new_pos(self.orientation, self.curr_pos)
    -- Reset orientation to original position before checking errors
    self.orientation:rotate(-2)

    -- Now check if our movement failed.
    if not res then
        return res
    end

    -- Successful movement. Now we can set the new position.
    self.curr_pos = curr_pos

    self.on_move()
    
    return res
end

-- Moves the turtle left one block. Turtle turns to face left.
function Turtle:left()
    local res = self.turn_left()
    if not res then
        return res
    end
    return self.forward()
end

-- Moves the turtle right one block. Turtle turns to face right.
function Turtle:right()
    local res = self.turn_right()
    if not res then
        return res
    end
    return self.forward()
end

-- Returns the current vector position of the turtle from memory.
function Turtle:get_curr_pos()
    return self.curr_pos
end

-- Turns a turtle to the specified cardinal direction.
function Turtle:turn_to(dest)
    local delta = self.orientation.get_rotation_delta(nil, dest)
    if delta < 0 then
        return self.turn_left(math.abs(delta))
    else
        return self.turn_right(math.abs(delta))
    end
end

function Turtle:move_to(dest, axis)
    if utils.isempty(axis) then
        self:move_to(dest, "x")
        self:move_to(dest, "z")
    else
        c0 = self.curr_pos[axis]
        c1 = dest[axis]
        local d_c = c1 - c0
        local sign = "+"
        if d_c < 0 then
            sign = "-"
        end
        self.turn_to(self.orientation:axis_and_sign_to_cardinal(axis, sign))

        while d_c ~= 0 do
            if not self.forward() then
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
    return self.move_to(self.home_pos)
end

-- Returns the current vector position of the turtle.
-- If specified or curr_pos is nil then GPS will be used to get the current
-- position of the turtle.
function Turtle:get_pos(gps_override)
    local x, y, z
    -- If curr_pos is nil, then we MUST use GPS to get pos.
    if self.curr_pos == nil then
        gps_override = true
    end
    if gps_override == nil then
        gps_override = false
    end

    if gps_override then
        return get_gps_pos()
    end
    return self.get_curr_pos()
end

-- Returns whether the turtle is facing the specified cardinal direction.
function Turtle:is_facing(d)
    if utils.isempty(d) then
        error("ValueError: d is nil/empty")
    end
    if d ~= nil then
        d = string.lower(d)
    end
    return self.orientation.get() == d
end

-- Calibrates the turtle by calculating the current position and orientation.
--
-- Attempts to move the turtle in each of the cardinal directions. As soon as it can
-- move in any direction, it returns back to the starting position and uses the deltas
-- to calculate orientation. This function uses the GPS to determine current position.
function Turtle:calibrate()
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
    local v = (
        (d_x + math.abs(d_x) * 2) +
        (d_z + math.abs(d_z) * 3)
    )
    self.orientation = Orientation{v=v}

    if self.home_pos == nil then
        self.back()
        self.home_pos = self.curr_pos
    else
        self.go_home()
    end

    return true
end

return Turtle
