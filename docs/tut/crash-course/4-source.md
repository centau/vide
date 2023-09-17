# Source

*Sources* in Vide are special objects that store a single value. They are the
core of reactivity in Vide, as updates to a source can automatically update
properties or other sources depending on that source.

A source in Vide can be created using `source()`.

```lua
local vide = require(vide)
local source = vide.source

local function Counter()
    local count = source(0)

    return create "TextButton" {
        Position = UDim2.fromOffset(300, 300),
        Size = UDim2.fromOffset(200, 50),

        Text = count,

        Activated = function()
            count(count() + 1)
        end
    }
end

mount(function() return create "ScreenGui" { Counter {} } end, game.StarterGui)
```

The value passed to `source()` is the initial value of the source.

The value of a source can be set by calling it with an argument, and can be read
by calling it with no arguments.

```lua
count(count() + 1) -- increment count by 1
```

Each call of `Counter {}` will create a new counter, each maintaining their
own count.

When you assign a function to a non-event property, Vide will immediately run it
and check what sources were read from. When updating those sources again after,
this function will be re-ran and its return value applied to the property.
This is known as *binding* properties.

This allows you as the programmer to not need to manually update UI as the state
of your program changes. You just define how the data maps to UI, and Vide's
reactive system will automatically update any properties depending on sources
that are updated.
