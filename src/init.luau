--------------------------------------------------------------------------------
-- vide.luau
-- v0.1.0
--------------------------------------------------------------------------------

if not game then script = require "test/relative-string" end

local create = require(script.create)
local apply = require(script.apply)
local source = require(script.source)
local watch = require(script.watch)
local cleanup, clean_garbage = require(script.cleanup)()
local untrack = require(script.untrack)
local derive = require(script.derive)
local indexes, values = require(script.maps)()
local spring, update_springs = require(script.spring)()
local action = require(script.action)()
local throw = require(script.throw)
local flags = require(script.flags)

export type Source<T> = source.Source<T>

local function step(dt: number)
    if game then
        debug.profilebegin("VIDE STEP")
        debug.profilebegin("VIDE SPRING")
    end

    update_springs(dt)

    if game then
        debug.profileend()
        debug.profilebegin("VIDE GARBAGE CLEANUP")
    end

    clean_garbage()

    if game then
        debug.profileend()
        debug.profileend()
    end
end

local stepped = game and game:GetService("RunService").Heartbeat:Connect(function(dt: number)
    task.defer(step, dt)
end)

local vide = {
    -- core
    create = create,
    source = source,
    watch = watch,
    derive = derive,
    indexes = indexes,
    values = values,

    -- util
    cleanup = cleanup,
    untrack = untrack,

    -- animations
    spring = spring,

    -- actions
    action = action,

    -- flags
    strict = (nil :: any) :: boolean,

    -- temporary
    apply = function(instance: Instance)
        return function(props: { [any]: any })
            apply(instance, props)
            return instance
        end
    end,

    -- runtime
    step = function(dt: number)
        if stepped then
            stepped:Disconnect()
            stepped = nil
        end
        step(dt)
    end
}

do
    local set = false

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
                if set then throw "strict mode has already been set" end
                set = true
                flags.strict = value :: boolean
            else
                throw(`{tostring(index)} is not a valid member of vide`)
            end
        end
    })
end

return vide
