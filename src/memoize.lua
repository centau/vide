--------------------------------------------------------------------------------------------------------------
-- vide/memoize.lua
--------------------------------------------------------------------------------------------------------------

local function memoize<X, Y>(f: (X) -> Y): ((X) -> Y, { [X]: Y })
    local cache: { [X]: Y } = {}

    return function(x: X): Y
        local y: Y? = cache[x]

        if not y then
            y = f(x)
            cache[x] = y
        end

        return y :: Y
    end, cache
end

return memoize

