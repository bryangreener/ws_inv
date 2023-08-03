local utils = require("utils")

local Orientation = {}

-- We will convert all orientations to cardinal throughout this program.
local cardinal_directions = {
    ["n"]=1,
    ["e"]=2,
    ["s"]=3,
    ["w"]=4,
}
local cardinal_directions_r = utils.invert_table(cardinal_directions)

local rot_to_card = {
    ["-z"]="n",
    ["+x"]="e",
    ["+z"]="s",
    ["-x"]="w",
}
local card_to_rot = utils.invert_table(rot_to_card)

local rot_to_int = {
    ["-z"]=2,
    ["+x"]=3,
    ["+z"]=4,
    ["-x"]=1,
}
local int_to_rot = utils.invert_table(rot_to_int)

local card_to_int = {}
for k, v in pairs(card_to_rot) do
    card_to_int[k] = rot_to_int[v]
end
local int_to_card = utils.invert_table(card_to_int)

-- Must supply a table with one of card, rot, or v
-- Examples:
---     local o0 = Orientation{card="n"}
---     local o1 = Orientation{rot="-x"}
---     local o2 = Orientation{v=1}
function Orientation.__init__(base, args)
    local card

    if args == nil then
        args = {}
    end
    -- Mandatory arguments
    if (args.card == nil and args.rot == nil and args.v == nil) then
        error("ValueError: Must supply one of [card, rot, v]")
    end
    if args.card ~= nil and type(args.card) ~= "string" then
        error(("ValueError: card must be a string. Got %s"):format(type(args.card)))
    end
    if args.rot ~= nil and type(args.rot) ~= "string" then
        error(("ValueError: rot must be a string. Got %s"):format(type(args.rot)))
    end
    if args.v ~= nil and type(args.v) ~= "number" then
        error(("ValueError: v must be a number. Got %s"):format(type(args.v)))
    end

    if args.card ~= nil then
        card = string.lower(args.card)
    elseif args.rot ~= nil then
        card = rot_to_card[string.lower(args.rot)]
    elseif args.v ~= nil then
        card = int_to_card[args.v]
    end

    if card == nil then
        error("ValueError: invalid inputs: " .. textutils.serialize(args))
    end

    self = {
        cardinal=card,
    }
    setmetatable(
        self,
        {
            __index=Orientation,
            __tostring=Orientation.__tostring,
        }
    )
    return self
end
setmetatable(Orientation, {__call=Orientation.__init__})

function Orientation.__tostring()
    return ("<Orientation: cardinal=%s>"):format(self.cardinal)
end

-- We only want to use cardinal directions so this is the only variable we expose.
function Orientation:get()
    return self.cardinal
end

function Orientation:update(new_card)
    self.cardinal = new_card
end

-- n is the number of 90 degree turns to make.
-- positive n will be clockwise (right), negative is CCW (left).
function Orientation:rotate(n)
    local res = ((n * 90) / (360 / #cardinal_directions_r)) % #cardinal_directions_r
    self.cardinal = cardinal_directions_r[res+1]
end

-- Returns the number of 90 degree rotations needed to go from cardinal direction
-- a to cardinal direction b.
function Orientation:get_rotation_delta(curr, dest)
    if utils.isempty(curr) then
        curr = self.cardinal
    end
    local i_0 = cardinal_directions[curr]
    local i_1 = cardinal_directions[dest]
    local delta = i_1 - i_0

    -- Handle wraparound cases to speed up movements.
    -- This makes it so instead of turning three times one direction, we can instead
    -- just turn once in the opposite direction to reach the same orientation.
    if i_0 == 1 and i_1 == 4 then
        delta = 1
    elseif i_0 == 4 and i_1 == 1 then
        delta = -1
    end

    return delta
end

function Orientation:axis_and_sign_to_cardinal(axis, sign)
    if utils.isempty(axis) then
        error("ValueError: axis is nil")
    end
    axis = string.lower(axis)

    if not (axis == "x" or axis == "z") then
        error("ValueError: invalid axis: " .. axis)
    end

    if not (sign == "-" or sign == "+") then
        error("ValueError: invalid sign: " .. sign)
    end
    
    return rot_to_card[string.lower(sign .. axis)]
end

return Orientation
