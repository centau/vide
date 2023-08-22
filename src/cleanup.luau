if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)

--[[

Cleanups associate a callback with an arbitrary value with an unknown lifetime.
Anytime a new callback is registered with a value that already has one registered,
the registered callback is ran and then replaced with the new one.

When the value is eventually garbage collected, Vide checks for callbacks
without an associated value, which it will then run and clear, recycling its
cleanup id.

By default the arbitrary value is the function object that calls `cleanup()`.
There are exceptions such as with `indexes()` and `values()` where the
arbitrary value is manually set to be the new source created instead of the
caller, as the same caller can be used to create multiple new objects.

todo: remove need for ref to id maps?

]]

-- maps a ref to cleanup id
local ref_to_id = {} :: { [string]: number }
-- maps a cleanup id to a ref
local id_to_ref = {} :: { [number]: string }
-- array of all cleanup callbacks
local cleanup_callbacks = {} :: { [number]: () -> () } -- always dense
-- weak array of all cleanup lifetimes
local cleanup_lifetime = {} :: { [number]: unknown } -- can be sparse
setmetatable(cleanup_lifetime :: any, { __mode = "v" })

-- detects in strict mode when multiple cleanups are registered in the same scope
local debug_caller_to_line = {} :: { [() -> ()]: number }
setmetatable(debug_caller_to_line, { __mode = "k" })

-- when active, cleanup callbacks are not automatically registered but are
-- added to an array for manual registering internally
local manual_mode = {
    caller = false :: false | () -> (),
    callbacks = {} :: { () -> () }
}

-- todo: rare case where mem address is reused by another function
-- does this case handle itself?

-- registers a callback with the given lifetime using the given ref
local function cleanup_ref(ref: string, lifetime: unknown, callback: () -> ())
    local id = ref_to_id[ref]

    if id then -- invoke previously registered callback then register new one
        cleanup_callbacks[id]()
        cleanup_lifetime[id] = lifetime -- rare case where ref is reused while lifetime is nil
    else -- no previously registered callback, add and register new one
        id = #cleanup_callbacks + 1
        ref_to_id[ref] = id
        id_to_ref[id :: any] = ref -- todo
        cleanup_lifetime[id :: any] = lifetime -- todo
    end

    cleanup_callbacks[id] = callback
end

-- registers a callback with its caller as the lifetime, and caller address as the ref
local function cleanup(callback: () -> ())
    local lifetime = debug.info(2, "f") -- `caller of cleanup() is lifetime of cleanup`

    if flags.strict then
        local line = debug.info(2, "l")
        local cur_line = debug_caller_to_line[lifetime]
        if cur_line and cur_line ~= line then
            throw "only one cleanup call is allowed per function scope"
        end
        debug_caller_to_line[lifetime] = line
    end

    if manual_mode.caller == lifetime then
        table.insert(manual_mode.callbacks, callback)
    else
        local ref = tostring(lifetime)
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
