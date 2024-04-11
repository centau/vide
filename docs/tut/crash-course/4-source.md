# Sources

Sources are special objects that store a single value. They are the core of
Vide's reactivity. They are called sources because they act as sources of data.

A source can be created using `source()`.

```lua
local source = vide.source

local count = source(0)
```

The value passed to `source()` is the initial value of the source.

The value of a source can be set by calling it with an argument, and can be read
by calling it with no arguments.

```lua
count(count() + 1) -- increment count by 1
```

Sources can be *derived* by wrapping them in functions. A wrapped source
effectively becomes a new source.

```lua
local count = source(0)

local text = function()
    return "count: " .. tostring(count())
end

print(text()) -- "count: 0"
count(1)
print(text()) -- "count: 1"
```

Sources on their own aren't very special, the above can be achieved with plain
variables. The real use for sources become apparent when used in combination
with *effects*. Similar to a signal and connection, a source and effect allows
you to do things like automatically updating UI when a source is updated.
