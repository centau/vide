if not game then script = require "test/relative-string" end

local ref_to_id = {} :: { [string]: number }
local id_to_ref = {} :: { [number]: string }
local cleanup_callbacks = {} :: { [number]: () -> () } -- always dense
local cleanup_callers = {} :: { [number]: () -> () } -- can be sparse
setmetatable(cleanup_callers :: any, { __mode = "v" })

-- todo: rare case where mem address is reused by another function on same line
-- does this case handle itself?

local function cleanup(callback: () -> ())
    local caller = debug.info(2, "f") :: () -> ()
    local line = debug.info(2, "l") :: number
    local ref = tostring(caller) .. line

    local id = ref_to_id[ref]

    if id then
        cleanup_callbacks[id]()
    else
        id = #cleanup_callbacks + 1
        ref_to_id[ref] = id
        id_to_ref[id :: any] = ref -- todo
        cleanup_callers[id :: any] = caller -- todo
    end

    cleanup_callbacks[id] = callback
end

local function clean_garbage()
    for id = #cleanup_callbacks, 1, -1 do
        if cleanup_callers[id] == nil then -- caller was garbage collected
            local callback = cleanup_callbacks[id]

            do -- swap and pop
                local max_id = #cleanup_callbacks

                cleanup_callbacks[id] = cleanup_callbacks[max_id]
                cleanup_callbacks[max_id] = nil

                cleanup_callers[id] = cleanup_callers[max_id]
                cleanup_callers[max_id] = nil

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

return function() return cleanup, clean_garbage end
