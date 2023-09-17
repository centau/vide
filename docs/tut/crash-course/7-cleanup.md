# Cleanup

Sometimes you may need to do some cleanup when destroying a component or after
a side-effect from a source update. Vide provides a function `cleanup()` which
is used to register a cleanup callback for the next time the reactive scope
it is called in re-runs.

```lua
local vide = require(vide)
local source = vide.source
local cleanup = vide.cleanup

local function Timer()
    local count = source(0)

    local con = game:GetService("RunService").Heartbeat:Connect(function(dt)
        count(count() + dt)
    end)

    cleanup(function()
        con:Disconnect()
    end)

    return create "TextButton" {
        Position = UDim2.fromOffset(300, 300),
        Size = UDim2.fromOffset(200, 50),

        Text = function()
            return "seconds: " .. count()
        end,
    }
end

mount(function() return create "ScreenGui" { Timer {} } end, game.StarterGui)
```

In the above example, this allows us to disconnect the heartbeat connection
when the timer component is destroyed, whether that is from unmounting the app
or if it is dynamically created by a control-flow function, which will be
covered next.
