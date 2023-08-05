-- This adds this file's directory to the package.path.
-- Using "require()" in subdirectories requires they reference modules
-- as if from this file's path.
-- For example, in projects/turtle/orientation.lua we include projects/utils/utils.lua
-- like so:
--      local utils = require("utils.utils")
package.path = package.path .. ";../?.lua"

local utils = require("utils.utils")
local Turtle = require("turtle.turtle")

local function on_move_cb(_turtle, pos, orientation)
    if _turtle:detect() then
        _turtle:dig()
    end

    if _turtle:detect_up() then
        _turtle:dig_up()
    end

    if _turtle:detect_down() then
        _turtle:dig_down()
    end
end

local t = Turtle(on_move_cb=on_move_cb, gps=false)
t:calibrate()

