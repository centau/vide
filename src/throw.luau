-- returns path to file as an array with each directory
-- accounts for Roblox and Luau contexts
local function get_path(s)
    if string.sub(s, #s - 4, #s) == ".luau" then
        s = string.sub(s, 1, #s - 5)
    end

    return string.split(s, string.match(s, "%w+/") and "/" or ".")
end

-- get directory of vide root
local root do
    local path = get_path(debug.info(1, "s"))
    root = path[#path - 1]
end

-- throws an error, ensuring stack trace begins at the first callsite outside
-- of all vide library files
local function throw(msg: string)
    local stack = 1

    local path = get_path(debug.info(stack, "s")) 

    while path[#path] == root or path[#path - 1] == root do
        stack += 1    
        path = get_path(debug.info(stack, "s")) 
    end

    error(msg, stack)
end

return throw
