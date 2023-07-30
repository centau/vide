--------------------------------------------------------------------------------------------------------------
-- vide.lua
-- v0.1.0
--------------------------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local create = require(script.create)
local wrap = require(script.wrap)
local watch = require(script.watch)
local derive = require(script.derive)
local map = require(script.map)

-- local Changed = require(script.Change)
-- local Created = require(script.Created)

local spring, updateSprings = require(script.spring)()

local flags = require(script.flags)

type Map<K, V> = { [K]: V }
type Unwrapper = <T>(T) -> T
type Setter<T> = ( (new: T, force: true?) -> T ) & ( (update: (old: T) -> T, force: true?) -> T )

local vide = {
    -- core
    create = create,
    wrap = wrap,
    derive = derive,
    map = map,
    watch = watch,

    -- animations
    spring = spring,

    -- symbols
    -- Event = Event,
    -- Changed = Changed,
    -- Layout = Layout,
    -- Children = Children,
    -- Created = Created,

    -- flags
    strict = (nil :: any) :: boolean,

    -- test
    step = function(dt: number)
        updateSprings(dt)
    end
}

setmetatable(vide :: any, {
    __index = function(_, index: unknown)
        error(string.format("\"%s\" is not a valid member of vide", tostring(index)), 2)
    end,

    __newindex = function(_, index: unknown, value: unknown)
        if index == "strict" then
            flags.strict = if type(value) == "boolean" then value else error("strict must be a boolean", 2)
        else
            error(string.format("\"%s\" is not a valid member of vide", tostring(index)), 2)
        end
    end
})

if game then
    game:GetService("RunService").Heartbeat:Connect(function(dt: number)
        task.defer(vide.step, dt)
    end)
end

return vide
