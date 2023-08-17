if not game then script = require "test/relative-string" end

local ref_to_id = {} :: { [string]: number }
local id_to_ref = {} :: { [number]: string }
local cleanup_callbacks = {} :: { [number]: () -> () } -- always dense
local cleanup_lifetime = {} :: { [number]: unknown } -- can be sparse
setmetatable(cleanup_lifetime :: any, { __mode = "v" })

local manual_mode = {
    caller = false :: false | () -> (),
    callbacks = {} :: { () -> () }
}

-- todo: rare case where mem address is reused by another function on same line
-- does this case handle itself?

local function cleanup_ref(ref: string, lifetime: unknown, callback: () -> ())
    local id = ref_to_id[ref]

    if id then
        cleanup_callbacks[id]()
        cleanup_lifetime[id] = lifetime -- rare case where ref is reused while lifetime is nil
    else
        id = #cleanup_callbacks + 1
        ref_to_id[ref] = id
        id_to_ref[id :: any] = ref -- todo
        cleanup_lifetime[id :: any] = lifetime -- todo
    end

    cleanup_callbacks[id] = callback
end

local function cleanup(callback: () -> ())
    local lifetime = debug.info(2, "f") -- `caller of cleanup() is lifetime of cleanup`
    local line = debug.info(2, "l")

    if manual_mode.caller == lifetime then
        table.insert(manual_mode.callbacks, callback)
    else
        local ref = tostring(lifetime) .. line
        cleanup_ref(ref, lifetime, callback)
    end
end

local function clean_garbage()
    for id = #cleanup_callbacks, 1, -1 do
        if cleanup_lifetime[id] == nil then -- lifetime was garbage collected
            local callback = cleanup_callbacks[id]

            do -- swap and pop
                local max_id = #cleanup_callbacks

                cleanup_callbacks[id] = cleanup_callbacks[max_id]
                cleanup_callbacks[max_id] = nil

                cleanup_lifetime[id] = cleanup_lifetime[max_id]
                cleanup_lifetime[max_id] = nil

                local ref = id_to_ref[id]
                local max_ref = id_to_ref[max_id]

                id_to_ref[id] = max_ref
                id_to_ref[max_id] = nil

                ref_to_id[max_ref] = id
                ref_to_id[ref] = nil
            end

            local ok, err: string? = pcall(callback)
            if not ok then warn(`error occured during cleanup: {err}`) end
        end
    end
end

local manual_cleanup_mode = function(caller: () -> ()?)
    if caller == nil then
        local clone = table.clone(manual_mode.callbacks)
        manual_mode.caller = false
        table.clear(manual_mode.callbacks)
        return clone
    else
        manual_mode.caller = caller
    end
    return manual_mode.callbacks
end :: ( (caller: (...any) -> ()) -> () ) & ( (nil) -> { () -> () } )

return function() return cleanup, clean_garbage, manual_cleanup_mode, cleanup_ref end
