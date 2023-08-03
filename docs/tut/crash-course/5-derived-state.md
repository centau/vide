# [Derived State](./index.md)

You can create new state from existing states. This is known as *deriving
state*.

```lua
local count = source(0)

local function text()
    return "count: " .. count()
end

create "TextLabel" {
    Text = text
}
```

Assigning a non-event property a function will bind that property to that
function, anytime a state being read from inside that function is changed, the
function will be re-ran and the property value updated.

Sometimes when using expensive computations to derive state, you only want to
recalculate it when a source state has changed.

```lua
local derive = vide.derive
```

```lua
local count = source(0)

local factorial = derive(function()
    local n = 1
    for i = 2, count() do
        n *= i
    end
    return n
end)
```

`derive()` will cache and return the same value until a source state has
changed, where it will recompute and cache a new value.

```lua
create "TextLabel" {
    Text = function()
        return "factorial: " .. factorial()
    end
}

count(3) -- displays "factorial: 6"
count(4) -- displays "factorial: 24"
```

--------------------------------------------------------------------------------

### [&larr; State](./4-State.md) | [Table State &rarr;](./6-table-state.md)
