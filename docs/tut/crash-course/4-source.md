# Source

*Sources* in Vide are special objects that store a single value. They are the
core of reactivity in Vide, as updates to a source can automatically update
properties or other sources depending on that source.

A source in Vide can be created using
[`source()`](../../api/reactivity-core.md#source).

```lua
local source = vide.source

local count = source(0)
```

The value passed to `source()` is the initial value of the source.

The value of a source can be set by calling it with an argument, and can be read
by calling it with no arguments.

```lua
count(count() + 1) -- increment source by 1
```

Below is an example of a stateful counter component.

```lua
local function Counter()
    local count = source(0)

    return create "TextButton" {
        Text = count,

        Activated = function()
            count(count() + 1)
        end
    }
end
```

Vide detects when you assign a function to a property. This is known
as *binding* and doing so will cause the property to *automatically* update
whenever a source in that function is updated, by rerunning the function and
assigning its return value. You can only bind non-event
properties, otherwise the function is connected as the event callback.

You as the programmer do not have to worry about manually updating variables or
UI instances, you can just focus on defining how the data maps to UI and
everything will update when changes occur.

Each call of `Counter {}` will create a new counter element, each with their own
independent count.

Since sources are just functions, you can pass an external source to a component
like so:

```lua
local function Text(p: {
    Text: () -> string
})
    return create "TextLabel" {
        Text = p.Text
    }
end

local text = source "hi"

Text {
    Text = text
}
```
