# Effects

Effects are functions that are ran in response to source updates. They are
A source and effect is analogous to a signal and connection.

Effects are created using `effect()`.

```luau
local source = vide.source
local effect = vide.effect

local count = source(0)

effect(function()
    print("count: " .. count())
end)

-- "count: 0" printed
count(1)
-- "count: 1" printed
```

Any source read inside an effect is tracked and will rerun the effect when
that source is updated.

Derived sources are also tracked, it doesn't matter how deeply nested
inside a function a source is.

```luau
local source = vide.source
local effect = vide.effect

local count = source(1)

local doubled = function()
    return count() * 2
end

effect(function()
    print("doubled count: " .. doubled())
end)

-- "doubled count: 2" printed
count(2)
-- "doubled count: 4" printed
```

If a source is updated with the same value it already had, it will not rerun
effects depending on it.
