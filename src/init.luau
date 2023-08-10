--------------------------------------------------------------------------------
-- vide.luau
-- v0.1.0
--------------------------------------------------------------------------------

if not game then script = require "test/relative-string" end

local create = require(script.create)
local source = require(script.source)
local watch = require(script.watch)
local cleanup, clean_garbage = require(script.cleanup)()
local derive = require(script.derive)
local indexes, values = require(script.maps)()
local spring, update_springs = require(script.spring)()
local action = require(script.action)()

local throw = require(script.throw)
local flags = require(script.flags)

local vide = {
    -- core
    create = create,
    source = source,
    watch = watch,
    cleanup = cleanup,
    derive = derive,
    indexes = indexes,
    values = values,

    -- animations
    spring = spring,

    -- actions
    action = action,

    -- flags
    strict = (nil :: any) :: boolean,

    -- runtime
    step = function(dt: number)
        -- debug.profilebegin("VIDE STEP")
        -- debug.profilebegin("VIDE SPRING")
        update_springs(dt)
        -- debug.profileend()
        -- debug.profilebegin("VIDE GARBAGE CLEANUP")
        clean_garbage()
        -- debug.profileend()
        -- debug.profileend()
    end
}

setmetatable(vide :: any, {
    __index = function(_, index: unknown): ()
        if index == "strict" then
            return flags.strict
        else
            throw(`{tostring(index)} is not a valid member of vide`)
        end
    end,

    __newindex = function(_, index: unknown, value: unknown)
        if index == "strict" then
            if value ~= true then throw "strict mode can only be set to true" end
            flags.strict = true
        else
            throw(`{tostring(index)} is not a valid member of vide`)
        end
    end
})

if game then
    game:GetService("RunService").Heartbeat:Connect(function(dt: number)
        task.defer(vide.step, dt)
    end)
end

return vide
