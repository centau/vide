local source = require "./source"
local derive = require "./derive"
local effect = require "./effect"
local untrack = require "./untrack"
local switch = require "./switch"

type Array<T> = { T }
type Source<T> = () -> T

local function show<T, Obj>(
    input: Source<T?>,
    component: (Source<T>, Source<boolean>) -> (Obj, ...number),
    fallback: ((Source<boolean>) -> (Obj, ...number))?
): Source<nil | Obj | Array<Obj>>
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

    return switch(input_is_truthy) {
        [true] = function(present)
            return component(filtered_input, present)
        end,
        [false] = fallback
    }
end

return show
