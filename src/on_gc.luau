if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)


-- array of all cleanup callbacks
local cleanup_callbacks = {} :: { [number]: () -> () } -- always dense
-- weak array of all cleanup lifetimes
local cleanup_lifetime = {} :: { [number]: unknown } -- can be sparse
setmetatable(cleanup_lifetime :: any, { __mode = "v" })

local function on_gc(lifetime: unknown, callback: () -> ())
    local id = #cleanup_callbacks + 1
    cleanup_lifetime[id :: any] = lifetime -- todo
    cleanup_callbacks[id] = callback
end

local function sweep()
    for id = #cleanup_callbacks, 1, -1 do
        if cleanup_lifetime[id] == nil then -- lifetime was garbage collected
            local callback = cleanup_callbacks[id]

            do -- swap and pop
                local max_id = #cleanup_callbacks

                cleanup_callbacks[id] = cleanup_callbacks[max_id]
                cleanup_callbacks[max_id] = nil

                cleanup_lifetime[id] = cleanup_lifetime[max_id]
                cleanup_lifetime[max_id] = nil
            end

            local ok, err: string? = pcall(callback)
            if not ok then warn(`error occured during cleanup: {err}`) end
        end
    end
end

return function() return on_gc, sweep end
