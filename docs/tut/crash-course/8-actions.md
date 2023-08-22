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
local function changed(property: string, callback: (new) -> ())
    return action(function(instance)
        instance:GetPropertyChangedSignal(property):Connect(function()
            callback(instance[property])
        end)
    end)
end

local output = source ""

create "TextBox" {
    changed("Text", output)
}
```

The source `output` will be updated with the new property value any time it is
changed externally.
