local derive = require "./derive"
local untrack = require "./untrack"

local function show<T, U>(source: () -> T?, component: (() -> T) -> U, fallback: (() -> U)?): () -> U?
    local truthy = derive(function()
        return not not source()
    end)

    -- seemingly redundant derivation to extend the reactive graph so that
    -- the propogation of the source's update is delayed, giving time for
    -- the show() scope to be destroyed before potential effects registered
    -- by the component can run when they should not run
    -- todo: are there cases this method does not cover?
    local derived = derive(function()
        return source()
    end)

    return derive(function()
        return
            if truthy() then untrack(function() return component(derived :: () -> T) end)
            elseif fallback then untrack(fallback)
            else nil
    end)
end

return show :: (
    ( <T, U>(source: () -> T?, component: (() -> T) -> U) -> () -> U? )
)
