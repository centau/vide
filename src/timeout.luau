local queue = {} :: {
    { t: number, fn: () -> (), cancel: boolean }
}

local function timeout(t: number, fn: () -> ())
    local handle = { t = t, fn = fn, cancel = false }
    table.insert(queue, handle)
    return handle
end

local function update_timeouts(dt: number)
    for i = #queue, 1, -1 do
        local handle = queue[i]
        handle.t -= dt
        
        if handle.cancel or handle.t <= 0 then
            queue[i] = queue[#queue]
            queue[#queue] = nil

            if not handle.cancel then
                handle.fn()
            end
        end
    end
end

return function() return timeout, update_timeouts end
