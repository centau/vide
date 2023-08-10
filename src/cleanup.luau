if not game then script = require "test/relative-string" end

-- todo: verify correct behavior in non-standard usage
local cleanup_callbacks = {} :: { [string]: () -> () }
local cleanup_callers = {} :: { [string]: () -> () }

setmetatable(cleanup_callers :: any, { __mode = "vs" })

-- todo: rare case where mem address is reused by another function on same line

local function cleanup(callback: () -> ())
    local caller = debug.info(2, "f") :: () -> ()
    local line = debug.info(2, "l") :: number
    local ref = tostring(caller) .. "\0" .. line

    local fn = cleanup_callbacks[ref]
    if fn then
        fn()
    else
        cleanup_callers[ref] = caller
    end
    cleanup_callbacks[ref] = callback
end

local buffer = {}

local function clean_garbage()
    for ref, callback in next, cleanup_callbacks do
        if cleanup_callers[ref] == nil then -- caller was garbage collected
            callback()
            table.insert(buffer, ref)
        end
    end

    for _, ref in next, buffer do
        cleanup_callbacks[ref] = nil
    end

    table.clear(buffer)
end

return function() return cleanup, clean_garbage end
