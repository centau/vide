# State

State in Vide are the core of reactivity in Vide.

State contain values that can change, and when they do change, automatically
update anything that is using it.

A state object in Vide can be created using
[`source()`](../../api/reactivity-core.md#source).

```lua
local source = vide.source
```

```lua
local count = source(0)
```

The value of a state can be set by calling it with an argument, and can be read
by calling it with no arguments.

```lua
count(count() + 1) -- increment count state by 1
```

Below is an example of a counter component that has state.

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

Any time the source value is set, anything depending on it will automatically be
updated using the new value.

Vide detects when you assign a function to a property. This is known
as *binding* and doing so will cause the property to *automatically* update
whenever a state in that function is updated, by rerunning the function and
assigning its return value. You can only bind non-event
properties, otherwise the function is connected as the event callback.

You as the programmer do not have to worry about manually updating variables or
UI instances, you can just focus on defining how the data maps to UI and
everything will update when changes occur.

Each call of `Counter {}` will create a new counter element, each with their own
independent count state.
