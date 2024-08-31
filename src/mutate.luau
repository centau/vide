if not game then script = require "test/relative-string" end

local untrack = require(script.Parent.untrack)

local function mutate<T>(source: () -> T, mutate: (T) -> any?)
    local value = untrack(source)
    local packed = table.pack(mutate(value))
    if packed.n > 0 then
        return source(unpack(packed, 1, packed.n))
    end

    source(value)
end

return mutate