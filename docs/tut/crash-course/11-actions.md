# Actions

Actions in Vide are special callbacks that you can pass along with properties,
which will be called when those properties are being processed with the instance
being assigned to, allowing you to run custom code.

```lua
local action = vide.action
```

```lua
create "TextLabel" {
    Text = "test",

    action(function(instance)
        print(instance.Text)
    end)
}

-- will print "test"
```

Actions can be wrapped with functions to re-use specific behaviors. Below is
an example of an action used to listen for property changes:

```lua
local action = vide.action
local cleanup = vide.cleanup

local function changed(property: string, callback: (new) -> ())
    return action(function(instance)
        local con = instance:GetPropertyChangedSignal(property):Connect(function()
            callback(instance[property])
        end)

        -- remember to clean up the connection when the reactive scope the action
        -- is ran in is destroyed, so the instance can be garbage collected
        cleanup(function()
            con:Disconnect()
        end)
    end)
end

local output = source ""

local instance = create "TextBox" {
    changed("Text", output)
}

instance.Text = "foo"

print(output()) -- "foo"
```

The source `output` will be updated with the new property value any time it is
changed externally.
