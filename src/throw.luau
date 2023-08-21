local function get_path(s)
    if string.sub(s, #s - 4, #s) == ".luau" then
        s = string.sub(s, 1, #s - 5)
        print("test, ", s)
    end

    return string.split(s, string.match(s, "%w+/") and "/" or ".")
end

local root do
    local path = get_path(debug.info(1, "s"))
    root = path[#path - 1]
end

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
