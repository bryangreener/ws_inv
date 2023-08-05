-- This adds this file's directory to the package.path.
-- Using "require()" in subdirectories requires they reference modules
-- as if from this file's path.
-- For example, in projects/turtle/orientation.lua we include projects/utils/utils.lua
-- like so:
--      local utils = require("utils.utils")
package.path = package.path .. ";../?.lua"

local utils = require("utils.utils")
local Turtle = require("turtle.turtle")

local function pre_move_cb(_turtle, pos, orientation)
    if _turtle.detect() then
        _turtle.dig("right")
    end

    if _turtle.detect_up() then
        _turtle.dig_up("right")
    end

    if _turtle.detect_down() then
        _turtle.dig_down("right")
    end
end

local t = Turtle{pre_move_cb=pre_move_cb, gps=false}
t:calibrate()

local function mine(_turtle, dest)
    local n_y = math.floor(dest.y / 3)
    local sign = dest.z / math.abs(dest.z)

    for y=1,n_y do
        _turtle:move_to(vector.new(dest.x, y, _turtle:get_pos().z))
        _turtle:move_to(vector.new(dest.x, y, dest.z * sign))
        sign = sign * -1
    end
end

mine(t, vector.new(0, 0, 0))

