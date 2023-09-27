# Sources

*Sources* in Vide are special objects that store a single value. They are the
core of reactivity in Vide. Each source represents a source of data, and they
can be composed and derived to create new sources of data.

A source in Vide can be created using `source()`.

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

Derived sources should be pure functions. This is where the same output is
always produced for the same input no matter how many times it is reran.

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
with Vide's *reactive scopes*. When a source is read from within a reactive
scope, it can automatically rerun the scope that reads it when the source is
updated in the future.
