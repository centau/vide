--------------------------------------------------------------------------------
-- vide.luau
-- v0.1.0
--------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local create = require(script.create)
local source = require(script.source)
local watch = require(script.watch)
local cleanup, clean_garbage = require(script.cleanup)()
local derive = require(script.derive)
local map = require(script.map)
local spring, update_springs = require(script.spring)()
local action = require(script.action)()

local flags = require(script.flags)

local vide = {
    -- core
    create = create,
    source = source,
    watch = watch,
    cleanup = cleanup,
    derive = derive,
    map = map,

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
