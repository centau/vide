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

```lua
local count = source(0)

local text = function()
    return "count: " .. tostring(count())
end

print(text()) -- "count: 0"
count(1)
print(text()) -- "count: 1"
```

You may be wondering why we are using sources instead of plain variables to do
this. The reason is that Vide has an entire reactive system based on sources.
You can write functions to automatically run each time a source is updated. This
can be to update properties, create new instances, print to the terminal, etc.
How this is done will be covered next.
