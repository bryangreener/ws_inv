local utils = require("utils.utils")

local Orientation = {}

-- We will convert all orientations to cardinal throughout this program.
local cardinal_directions = {
    ["n"]=1,
    ["e"]=2,
    ["s"]=3,
    ["w"]=4,
}
-- Convert to array representation
local cardinal_directions_arr = utils.invert_table(cardinal_directions)

local axis_to_cardinal = {
    ["-z"]="n",
    ["+x"]="e",
    ["+z"]="s",
    ["-x"]="w",
}
local cardinal_to_axis = utils.invert_table(axis_to_cardinal)

local axis_to_int = {
    ["-z"]=2,
    ["+x"]=3,
    ["+z"]=4,
    ["-x"]=1,
}
local int_to_axis = utils.invert_table(axis_to_int)

local cardinal_to_int = {}
for k, v in pairs(cardinal_to_axis) do
    cardinal_to_int[k] = axis_to_int[v]
end
local int_to_cardinal = utils.invert_table(cardinal_to_int)

-- Must supply a table with one of cardinal or axis.
-- Axis may be either a string or numerical representation (i.e. -x or 1)
-- Examples:
---     local o0 = Orientation{cardinal="n"}
---     local o1 = Orientation{axis="-x"}
---     local o2 = Orientation{axis=1}
function Orientation.__init__(base, args)
    local self = {cardinal=nil}
    setmetatable(self, {__index=Orientation, __tostring=Orientation.__tostring})

    assert(args ~= nil)
    assert(args.cardinal ~= nil or args.axis ~= nil)

    if args.cardinal ~= nil then
        assert(type(args.cardinal) == "string")
        self.cardinal = string.lower(args.cardinal)
    end

    if args.axis ~= nil then
        assert(type(args.axis) == "string" or type(args.axis) == "number")
        if type(args.axis) == "string" then
            self.cardinal = axis_to_cardinal[string.lower(args.axis)]
        elseif type(args.axis) == "number" then
            self.cardinal = int_to_cardinal[args.axis]
        end
    end

    assert(not utils.isempty(self.cardinal))

    return self
end
setmetatable(Orientation, {__call=Orientation.__init__})

function Orientation.__tostring(o)
    return ("<Orientation: cardinal=%s>"):format(o.cardinal)
end

-- We only want to use cardinal directions so this is the only variable we expose.
function Orientation:get()
    return self.cardinal
end

-- Sets the cardinal direction.
function Orientation:set(cardinal)
    assert(not utils.isempty(cardinal))
    cardinal = string.lower(cardinal)
    assert(cardinal_directions[cardinal] ~= nil)
    self.cardinal = cardinal
end

-- n is the number of 90 degree turns to make.
-- positive n will be clockwise (right), negative is CCW (left).
-- Updates the local cardinal direction and returns it.
function Orientation:rotate(n)
    assert(type(n) == "number")
    if n ~= 0 then
        local res = ((cardinal_directions[self.cardinal] + n) - 1) % 4

        self.cardinal = cardinal_directions_arr[res+1]
    end
end

-- Easy helper function to reverse our orientation (look behind).
function Orientation:reverse()
    self:rotate(2)
end

-- Returns the number of 90 degree rotations needed to go from cardinal direction
-- a to cardinal direction b.
function Orientation:get_rotation_delta(curr, dest)
    if utils.isempty(curr) then
        curr = self.cardinal
    end
    assert(not utils.isempty(dest))

    local delta
    local i_0 = cardinal_directions[curr]
    local i_1 = cardinal_directions[dest]
    
    -- Handle wraparound cases to speed up movements.
    -- This makes it so instead of turning three times one direction, we can instead
    -- just turn once in the opposite direction to reach the same orientation.
    if i_0 == 1 and i_1 == 4 then
        delta = -1
    elseif i_0 == 4 and i_1 == 1 then
        delta = 1
    else
        delta = i_1 - i_0
    end

    -- Always ensure we turn the same direction when turning twice.
    -- This just helps with consistency and debugging.
    if math.abs(delta) == 2 then
        delta = 2
    end

    return delta
end

function Orientation:axis_and_sign_to_cardinal(axis, sign)
    assert(not utils.isempty(axis))
    assert(not utils.isempty(sign))
    axis = string.lower(axis)

    assert(axis == "x" or axis == "z")
    assert(sign == "-" or sign == "+")
    
    return axis_to_cardinal[sign .. axis]
end

return Orientation
