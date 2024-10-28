-- FILE MANIPULATION FUNCTIONS
local function file_exists(filepath)
    local f = io.open(filepath, "r")
    if f ~= nil then 
        io.close(f)
        return true
    end
    return false
end

local function storeFile(filepath, content)
    local writefile = fs.open(filepath, "w")
    writefile.write(content)
    writefile.close()
end

local function downloadfile(filepath, url)
    if not http.checkURL(url) then
        print("ERROR: URL '" .. url .. "' is blocked. Unable to fetch.")
        return false
    end

    local result = http.get(url)
    if result == nil then
        print("ERROR: Unable to reach '" .. url .. "'")
        return false
    end

    storeFile(filepath, result.readAll())
    return true
end

-- MAIN PROGRAM
local args = {...}

local base_url = "https://raw.githubusercontent.com/luiz00martins/cc-ut/main/"
local files = {
    ["init.lua"] = "cc-ut/init.lua",
    ["utils.lua"] = "cc-ut/utils.lua",
    ["test.lua"] = "cc-ut/test.lua",
    ["example.lua"] = "cc-ut/example.lua"
}

if args[1] == "install" or args[1] == nil then
    print("Installing cc-ut...")
    fs.makeDir("cc-ut")

    for file, path in pairs(files) do
        print("Downloading " .. file .. "...")
        if not downloadfile(path, base_url .. file) then
            return false
        end
    end
    print("cc-ut successfully installed!")

elseif args[1] == "update" then
    print("Updating cc-ut...")
    for file, path in pairs(files) do
        print("Updating " .. file .. "...")
        if not downloadfile(path, base_url .. file) then
            return false
        end
    end
    print("cc-ut successfully updated!")

elseif args[1] == "remove" then
    print("Removing cc-ut...")
    fs.delete("cc-ut")
    print("cc-ut successfully removed!")

else
    print("Invalid argument: " .. args[1])
    print("Usage: ccpt-install [install|update|remove]")
end

