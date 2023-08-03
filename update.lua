print("Pulling changes...")

local url = "https://bryagreener.github.io/ws_inv"
local p = {}

shell.run(
    "wget",
    url .. "projects/projects.txt",
    "projects.txt"
)

for line in io.lines("projects.txt") do
    if fs.exists(line) and not fs.isDir(line) then
        fs.delete(line)
    end
    local dir = fs.getDir(line)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    shell.run(
        "wget",
        url .. fs.combine(
            fs.getDir(line),
            fs.getName(line)
        ),
        line
    )
end

print("Pulled changes.")