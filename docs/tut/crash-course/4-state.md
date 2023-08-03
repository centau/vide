# [State](./index.md)

State in Vide are special objects that store data.

A state object in Vide can be created using
[`source()`](../../api/reactivity-core.md#source).

```lua
local source = vide.source
```

```lua
-- create a new source
local count = source(0)

-- set source value
count(10)

-- get source value
print(count()) -- "10"
```

Below is an example of a counter component that has state.

```lua
local function Counter()
    local count = source(0)

    return create "TextButton" {
        Text = count

        Activated = function()
            count(count() + 1)
        end,
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

--------------------------------------------------------------------------------

### [&larr; Components](./3-components.md) | [Derived State &rarr;](./5-derived-state.md)
