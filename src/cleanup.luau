if not game then script = require "test/relative-string" end

-- todo: verify correct behavior in non-standard usage
local free_ids = {} :: { number }
local id_to_ref = {} :: { [number]: string }
local ref_to_id = {} :: { [string]: number }
local cleanup_callbacks = {} :: { [number]: () -> () }
local cleanup_callers = {} :: { [number]: () -> () }

setmetatable(cleanup_callers :: any, { __mode = "vs" })

-- todo: rare case where mem address is reused by another function on same line

local function cleanup(callback: () -> ())
    local caller = debug.info(2, "f") :: () -> ()
    local line = debug.info(2, "l") :: number
    local ref = tostring(caller) .. "\0" .. line

    local id = ref_to_id[ref]

    if id then
        cleanup_callbacks[id]()
    else
        id = table.remove(free_ids) or #cleanup_callbacks + 1
        id_to_ref[id :: any] = ref -- todo
        ref_to_id[ref] = id
        cleanup_callers[id :: any] = caller -- todo
    end

    cleanup_callbacks[id] = callback
end

-- todo: investigate behavior if cleanup called within cleanup
-- todo: verify no memory leakage

local function clean_garbage()
    for id = 1, #cleanup_callbacks do
        if cleanup_callers[id] == nil then -- caller was garbage collected
            local callback = cleanup_callbacks[id]

            cleanup_callbacks[id] = nil
            table.insert(free_ids, id)
            ref_to_id[id_to_ref[id]] = nil
            id_to_ref[id] = nil

            local ok, err: string? = pcall(callback)
            if not ok then warn(`error occured during cleanup: {err}`) end
        end
    end
end

return function() return cleanup, clean_garbage end
