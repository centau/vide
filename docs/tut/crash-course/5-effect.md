# Effect

An effect is a function that is run anytime a source updates. They are called
effects because they can produce side-effects when reacting to source changes.

Effects are created using `effect()`.

```lua
local vide = require(vide)
local source = vide.source
local effect = vide.effect

local function Counter()
    local count = source(0)

    effect(function()
        print("count has updated to: " .. count())
    end)

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

This will print to the terminal anytime the count is changed.

`effect()` creates an explicit side-effect. There are other side-effects in the
above code sample. The setting of `Text = count` creates another side-effect;
the updating of the Text property anytime the count is changed.

All observable changes to the user are considered to be side-effects of the
reactive system.
