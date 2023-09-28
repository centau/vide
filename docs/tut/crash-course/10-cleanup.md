# Cleanup

Sometimes you may need to do some cleanup when destroying a component or after
a side-effect from a source update. Vide provides a function `cleanup()` which
is used to register a cleanup callback for the next time the reactive scope
it is called in re-runs.

```lua
local mount = vide.mount
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
            return "seconds: " .. math.floor(count())
        end,
    }
end

local unmount = mount(Timer)

unmount() -- all registered cleanups are ran, heartbeat connection stopped
```

In the above example, this allows us to disconnect the heartbeat connection
when the timer component is destroyed, whether that is from unmounting the app
or if it is dynamically created by a control-flow function, which will be
covered next.

This is another reason why `mount()` is used at the top level of your app, so
that any registered cleanups created by your app components can be ran when
they are destroyed.

The reactive graph for the above example:

```mermaid
%%{init: {
    "theme": "base",
    "themeVariables": {
        "primaryColor": "#1B1B1F",
        "primaryTextColor": "#fff",
        "primaryBorderColor": "#1B1B1F",
        "lineColor": "#79B8FF",
        "tertiaryColor": "#161618",
        "tertiaryBorderColor": "#161618"
    }
}}%%

graph

subgraph mount
    direction LR
    cleanup([cleanup]) ~~~ count 
    count --> bind["effect (text binding)"]
end
```
