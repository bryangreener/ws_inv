print("Pulling changes...")

local url = "https://bryangreener.github.io/ws_inv/projects"

shell.run("wget", url .. "projects.txt", "projects.txt")

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

fs.delete("projects.txt")

print("Pulled changes.")
