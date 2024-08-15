if not game then script = require "test/relative-string" end

local flags = require(script.Parent.flags)
local throw = require(script.Parent.throw)
local graph = require(script.Parent.graph)

local function batch(setter: () -> ())
    local already_batching = flags.batch
    local flush

    if not already_batching then
        flags.batch = true
        flush = graph.flush_update_queue()
    end

    local ok, err: string? = pcall(setter)

    if not already_batching then
        flush()
        flags.batch = false
    end

    if not ok then throw(`error occured while batching updates: {err}`) end
end

return batch
