print("Pulling changes...")

local url = "https://bryangreener.github.io/ws_inv/projects/"

shell.run("wget", url .. "projects.txt", "projects.txt")
shell.run("wget", url .. "timestamp.txt", "timestamp.txt")

for line in io.lines("projects.txt") do
    if fs.exists(line) and not fs.isDir(line) then
        fs.delete(line)
    end
    local dir = fs.getDir(line)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local new_fp = fs.combine(fs.getDir(line), fs.getName(line))
    shell.run("wget", url .. new_fp, new_fp)
end

-- Should only be one line in this file.
local ts_file = fs.open("timestamp.txt", "r")
print("TIMESTAMP: " .. ts_file.readAll())
ts_file.close()

fs.delete("projects.txt")
fs.delete("timestamp.txt")

print("Pulled changes.")
