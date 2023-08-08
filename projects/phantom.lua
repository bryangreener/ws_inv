-- Collect list of peripherals from the modem then convert to table.
local peripherals = {}
function get_peripherals(name, p)
    peripherals[name] = p
end
peripheral.find("redstoneIntegrator", get_peripherals)

-- Helper function for inverting a table (flipping inside out)
function invert_table(t)
    local out = {}
    for k, v in pairs(t) do
        out[v] = k
    end
    return out
end

local periph_map = {
    ["redstoneIntegrator_13"]=0,
    ["redstoneIntegrator_12"]=1,
    ["redstoneIntegrator_11"]=2,
    ["redstoneIntegrator_16"]=3,
    ["redstoneIntegrator_15"]=4,
    ["redstoneIntegrator_14"]=5,
    ["redstoneIntegrator_17"]=6,
    ["redstoneIntegrator_18"]=7,
    ["redstoneIntegrator_10"]=8,
}

local periph_map_i = invert_table(periph_map)

local octave_map = {
    [3]={0, 1, 2},
    [4]={3, 4, 5},
    [5]={6, 7, 8},
}

local octave_map_i = {
    [0"]=3,
    [1"]=3,
    [2"]=3,
    [3"]=4,
    [4"]=4,
    [5"]=4,
    [6"]=5,
    [7"]=5,
    [8"]=5,
}

local note_map_to_octave_idx = {
    ["C"]=0,
    ["C#"]=0,
    ["D"]=0,
    ["D#"]=0,
    ["E"]=1,
    ["F"]=1,
    ["F#"]=1,
    ["G"]=1,
    ["G#"]=2,
    ["A"]=2,
    ["A#"]=2,
    ["B"]=2,
}

local note_map_to_side_name = {
    ["C"]="top",
    ["C#"]="left",
    ["D"]="back",
    ["D#"]="right",
    ["E"]="top",
    ["F"]="left",
    ["F#"]="back",
    ["G"]="right",
    ["G#"]="top",
    ["A"]="left",
    ["A#"]="back",
    ["B"]="right",
}

-- Returns a peripheral ID, name, and side associated with the note and octave.
function get_peripheral_from_note_and_octave(note, octave)
    local oct_idx = note_map_to_octave_idx[note]
    if oct_idx == nil then error("Invalid note: " .. note) end
    
    local octs = octave_map[octave]
    if octs == nil then error("Invalid octave: " .. octave) end
    
    local p_id = octs[oct_idx + 1]
    if p_id == nil then error("Invalid oct_idx: " .. oct_idx + 1) end

    local p_name = periph_map_i[p_id]
    if p_name == nil then error("Invalid peripheral ID: " .. p_id) end

    local p_side = note_map_to_side_name[note]
    if p_side == nil then error("Error getting side from note: " .. note) end

    return p_id, p_name, p_side
end

-- Peripheral class that stores a side of a Redstone Integrator block as an instance.
local Peripheral = {}
function Peripheral.__init__(base, id, name, side)
    local p = peripherals[name]
    self = {
        id=id,
        name=name,
        side=side,
        p=p,
    }
    setmetatable(self, {__index=Peripheral})
    return self
end
setmetatable(Peripheral, {__call=Peripheral.__init__})

function Peripheral:set_output(val)
    self.p.setOutput(self.side, val) -- must be self.p. since we arent subclassing
end

-- A class that stores note info for playing.
local Note = {}
function Note.__init__(base, name, octave)
    local p_id, p_name, p_side, p
    if name ~= "X" then
        p_id, p_name, p_side = get_peripheral_from_note_and_octave(name, octave)
        p = Peripheral(p_id, p_name, p_side)
    end
    self = {name=name, octave=octave, p=p}
    setmetatable(self, {__index=Note})
    return self
end
setmetatable(Note, {__call=Note.__init__})

function Note:play()
    if self.name ~= "X" then
        self.p:set_output(true) -- must be self.p: since we are subclassing
    end
end

function Note:stop()
    if self.name ~= "X" then
        self.p:set_output(false) -- must be self.p: since we are subclassing
    end
end

local Chord = {}
function Chord.__init__(base, notes, time_ms)
    local _notes = {}
    local _ignore_flag = false
    for v in string.gmatch(notes, "[^,]+") do
        local octave = string.match(v, "%d+")
        local note = string.gsub(v, octave, "")
        _notes[#_notes + 1] = Note(note, octave)
    end
    self = {notes=_notes, time_ms=time_ms}
    setmetatable(self, {__index=Chord})
    return self
end
setmetatable(Chord, {__call=Chord.__init__})

function Chord:play()
    for _, note in pairs(self.notes) do
        note:play()
    end
    os.sleep(self.time_ms)
    for _, note in pairs(self.notes) do
        note:stop()
    end
end


track = {
    Chord("F4,A4,D5", 2),
    Chord("F4,A4,D5", 0.166),
    Chord("E4,G#4,C#5", 0.166),
    Chord("D#4,G4,C5", 0.166),
    Chord("D4,F#4,B4", 0.166),
    Chord("D4,F4,A#4", 2),
    Chord("D4,F#4,B4", 0.166),
    Chord("D#4,G4,C5", 0.166),
    Chord("E4,G#4,C#5", 0.166),
    Chord("F4,A4,D5", 0.166),
    Chord("F4,A4,D5", 2),
    Chord("F4,A4,D5", 0.166),
    Chord("E4,G#4,C#5", 0.166),
    Chord("D#4,G4,C5", 0.166),
    Chord("D4,F#4,B4", 0.166),
    Chord("D4,F4,A#4", 1.33),
    Chord("C4,D#4,G#4", 0.166),
    Chord("D4,F4,A#4", 0.5),
    Chord("D4,F4,A#4", 0.166),
    Chord("D4,F#4,B4", 0.166),
    Chord("D#4,G4,C5", 0.166),
    Chord("E4,G#4,C#5", 0.166),
    Chord("F4,A4,D5", 0.5),
    Chord("F3,A3,D4", 0.166),
    Chord("F3,A3,D4", 0.5),
    Chord("F3,A3,D4", 0.5),
    Chord("X3", 0.5),
    Chord("F3,A3,D4", 0.166),
    Chord("F3,A3,D4", 0.5),
    Chord("F3,A3,D4", 0.5),
    Chord("X3", 0.5),
    Chord("F3,A3,D4", 0.166),
    Chord("F3,A3,D4", 0.5),
    Chord("F3,A3,D4", 0.5),
    Chord("X3", 0.5),
}

for _, chord in pairs(track) do
    chord:play()
    os.sleep(chord.time_ms)
end