local function throw(msg: string)
    local stack = 1

    while debug.info(stack, "s") == debug.info(1, "s") do
        stack += 1    
    end

    error(msg, stack)
end

return throw
