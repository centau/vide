# Derived Source

You can create new sources from existing sources. This is known as *deriving
sources*.

A function that wraps a source effectively becomes a new source. If a source
used inside a function is updated, the whole function can be re-ran to recompute
its value.

```lua
local vide = require(vide)
local source = vide.source

local function Counter()
    local count = source(0)

    local function doubled()
        return count() * 2
    end

    return create "TextButton" {
        Position = UDim2.fromOffset(300, 300),
        Size = UDim2.fromOffset(200, 50),

        Text = doubled,

        Activated = function()
            count(count() + 1)
        end
    }
end

mount(function() return create "ScreenGui" { Counter {} } end, game.StarterGui)
```

Now the counter will increment in 2s each time it is clicked.

Sometimes when using expensive computations to derive state, you only want to
recalculate it once when a source state has changed. Although not needed in
most cases, you can use `derive()` to create a new source that will cache its
value, only recomputing when an input source has changed.

```lua
local vide = require(vide)
local source = vide.source
local derive = vide.derive

local function Counter()
    local count = source(0)

    local factorial = derive(function()
        local n = 1
        for i = 2, count() do
            n *= i
        end
        return n
    end)

    return create "TextButton" {
        Position = UDim2.fromOffset(300, 300),
        Size = UDim2.fromOffset(200, 50),

        Text = function()
            return factorial() + factorial() + factorial()
        end,

        Activated = function()
            count(count() + 1)
        end
    }
end
```

This can improve performance in cases where a source is read from multiple times
between recalculations. In the above example, the factorial is only ever
calculated once each time the count changes.
