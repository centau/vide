# Derived State

You can create new state from existing states. This is known as *deriving
state*.

A function that wraps a state effectively becomes a state. If a state used
inside a function is updated, the whole function can be re-ran to recompute
its value.

```lua
local count = source(0)

local function text()
    return "count: " .. count()
end

create "TextLabel" {
    Text = text
}
```

Sometimes when using expensive computations to derive state, you only want to
recalculate it once when a source state has changed

If you wrap a source state with a regular function, its value will be recomputed
every time you call that function.
[`derive()`](../../api/reactivity-core.md#derive) accepts a functions whose
return value will be cached, so that subsequent calls of this derived state
will return the same cached value until one of its source states have changed.

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

This can improve performance for expensive calculations.

```lua
create "TextLabel" {
    Text = function()
        return "factorial squared: " .. factorial() * factorial()
    end
}

count(3) -- displays "factorial squared: 36"
count(4) -- displays "factorial squared: 576"
```
