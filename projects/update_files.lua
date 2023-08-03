local url = "https://bryangreener.github.io/ws_inv/projects/"

if not fs.exists("projects") then
    fs.makeDir("projects")
end

function wget(src, dest)
    local w = window.create(term.current(), 1, 1, 1, 1, false)
    term.redirect(w)
    term.write("Downloading...")
    shell.run("wget", src, dest)
    w.clear()
    term.clear()
    term.redirect(term.native())
    print("=> " .. dest)
end

-- First check if we even need to pull any changes.
wget(url .. "git_hash.txt", "projects/new_git_hash.txt")
if not fs.exists("projects/git_hash.txt") then
    fs.move("projects/new_git_hash.txt", "projects/git_hash.txt")
    fs.delete("projects/new_git_hash.txt")
else
    local prev_hash_file = fs.open("projects/git_hash.txt", "r")
    local prev_hash = prev_hash_file.readAll()
    prev_hash_file.close()

    local new_hash_file = fs.open("projects/new_git_hash.txt", "r")
    local new_hash = new_hash_file.readAll()
    new_hash_file.close()

    fs.delete("projects/git_hash.txt")
    fs.move("projects/new_git_hash.txt", "projects/git_hash.txt")

    if prev_hash == new_hash then
        print("No remote changes to fetch.")
        return nil
    end
end

-- Now pull the changes.
print("Pulling changes...")
wget(url .. "files.txt", "projects/files.txt")
wget(url .. "timestamp.txt", "projects/timestamp.txt")

for line in io.lines("projects/files.txt") do
    if fs.exists(line) and not fs.isDir(line) then
        fs.delete(line)
    end
    local dir = fs.getDir(line)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local new_fp = fs.combine(fs.getDir(line), fs.getName(line))
    wget(url .. new_fp, new_fp)
end

-- Should only be one line in this file.
local ts_file = fs.open("projects/timestamp.txt", "r")
print("TIMESTAMP: " .. ts_file.readAll())
ts_file.close()

print("Pulled changes.")
