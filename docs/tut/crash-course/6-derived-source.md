# Derived Source

You can create new sources from existing sources. This is known as *deriving
sources*.

A function that wraps a source effectively becomes a new source. If a source
used inside a function is updated, the whole function can be re-ran to recompute
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

If you wrap a source with a regular function, its value will be recomputed
every time you call that function.
[`derive()`](../../api/reactivity-core.md#derive) accepts a functions whose
return value will be cached, so that subsequent calls of this derived source
will return the same cached value until one of its input sources have changed.

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

This can improve performance in cases where a source is read from multiple times
between recalculations, like in the example below:

```lua
create "TextLabel" {
    Text = function()
        return "factorial squared: " .. factorial() * factorial()
    end
}

count(3) -- displays "factorial squared: 36"
count(4) -- displays "factorial squared: 576"
```

Vide knows what sources are being depended on by immediately running the
callback when deriving or binding sources. If a source is in a function but is
never referenced the first time it runs, Vide will not know to rerun the
function if that source changes.

An example to effect out for is when using sources within branches:

```lua
local condition = source(true)
local count1 = source(0)
local count2 = source(0)

local text = function()
    if condition() then
        return "text: " .. count1()
    else
        return "text: " .. count2()
    end
end
```

In the above case, only `count1` will be referenced, meaning `text` will not be
aware of `count2` even if the condition is later set to false.

All sources to be tracked must be referenced the first time the function runs.

```lua
local condition = source(true)
local count1 = source(0)
local count2 = source(0)

local text = function()
    local c1 = count1()
    local c2 = count2()

    if condition() then
        return "text: " .. c1
    else
        return "text: " .. c2
    end
end
```
