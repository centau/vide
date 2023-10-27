if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)

local function batch(setter: () -> ())
    local already_batching = flags.batch

    flags.batch = true

    local ok, err: string? = pcall(setter)

    flags.batch = false
    
    if not ok then throw(`error occured while batching updates: {err}`) end

    if not already_batching then -- todo: flush anyways?
        graph.flush_update_queue()
    end
end

return batch
