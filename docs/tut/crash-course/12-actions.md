# Actions

Actions are special callbacks that you can pass along with properties,
to run some code on an instance receiving them.

```luau
local action = vide.action

create "TextLabel" {
    Text = "test",

    action(function(instance)
        print(instance.Text)
    end)
}

-- will print "test"
```

Actions can be wrapped with functions for reuse. Below is an example of an
action used to listen for property changes:

```luau
local action = vide.action
local source = vide.source
local effect = vide.effect
local cleanup = vide.cleanup

local function changed(prop: string, callback: (new) -> ())
    return action(function(instance)
        local connection = instance:GetPropertyChangedSignal(prop):Connect(function()
            callback(instance[property])
        end)

        -- remember to clean up the connection when the reactive scope the action
        -- is ran in is destroyed, so the instance can be garbage collected
        cleanup(connection)
    end)
end

local output = source ""

local instance = create "TextBox" {
    changed("Text", output)
}

effect(function()
    print(output())
end)

instance.Text = "foo" -- "foo" will be printed by the effect
```

The source `output` will be updated with the new property value any time it is
changed externally.
