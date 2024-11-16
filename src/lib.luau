local version = { major = 0, minor = 3, patch = 1 }

local root = require "./root"
local mount = require "./mount"
local create = require "./create"
local apply = require "./apply"
local source = require "./source"
local effect = require "./effect"
local derive = require "./derive"
local cleanup = require "./cleanup"
local untrack = require "./untrack"
local read = require "./read"
local batch = require "./batch"
local context = require "./context"
local switch = require "./switch"
local show = require "./show"
local indexes, values = require "./maps"()
local spring, update_springs = require "./spring"()
local action = require "./action"()
local changed = require "./changed"
local throw = require "./throw"
local flags = require "./flags"

export type Source<T> = source.Source<T>
export type source<T> = Source<T>
export type Context<T> = context.Context<T>
export type context<T> = Context<T>

local function step(dt: number)
    if game then
        debug.profilebegin("VIDE STEP")
        debug.profilebegin("VIDE SPRING")
    end

    update_springs(dt)

    if game then
        debug.profileend()
        debug.profileend()
    end
end

local stepped = game and game:GetService("RunService").Heartbeat:Connect(function(dt: number)
    task.defer(step, dt)
end)

local vide = {
    version = version,

    -- core
    root = root,
    mount = mount,
    create = create,
    source = source,
    effect = effect,
    derive = derive,
    switch = switch,
    show = show,
    indexes = indexes,
    values = values,

    -- util
    cleanup = cleanup,
    untrack = untrack,
    read = read,
    batch = batch,
    context = context,

    -- animations
    spring = spring,

    -- actions
    action = action,
    changed = changed,

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
            flags.strict = value :: boolean
        else
            throw(`{tostring(index)} is not a valid member of vide`)
        end
    end
})

return vide
