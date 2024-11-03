# Sources

Sources are special objects that store a single value and are the core of
Vide's reactivity.

A source can be created using `source()`.

```luau
local source = vide.source

local count = source(0)
```

The value passed to `source()` is the initial value of the source.

The value of a source can be set by calling it with an argument, and can be read
by calling it with no arguments.

```luau
count(count() + 1) -- increment count by 1
```

Sources can be *derived* by wrapping them in functions.

```luau
local count = source(0)

local text = function()
    return "count: " .. tostring(count())
end

print(text()) -- "count: 0"
count(1)
print(text()) -- "count: 1"
```

While the above can be achieved with plain variables, the use for sources will
be obvious in the next part.
