local url = "https://bryangreener.github.io/ws_inv/projects/update_files.lua"
shell.run("wget", url, "update_files.lua")
shell.run("update_files.lua")
fs.delete("update_files.lua")
