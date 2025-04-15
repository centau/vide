local source = require "./source"
local derive = require "./derive"
local effect = require "./effect"
local untrack = require "./untrack"

local function show<T, U>(input: () -> T?, component: (() -> T) -> U, fallback: (() -> U)?): () -> U?
    local filtered_input = source()

    effect(function()
        local v = input() 
        if v then
            filtered_input(v)
        end
    end)

    local input_is_truthy = derive(function()
        return not not input()
    end)

    -- todo: is this needed?
    -- local filtered_input_is_truthy = derive(function()
    --     return not not filtered_input()
    -- end)

    return derive(function()
        return
            if input_is_truthy() then untrack(function() return component(filtered_input :: () -> T) end)
            elseif fallback then untrack(fallback)
            else nil
    end)
end

return show
