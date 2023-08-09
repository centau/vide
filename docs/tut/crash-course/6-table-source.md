# Table Source

Vide has specific functions for dealing with sources that store a table value.

Often, you will have a table of values that will be displayed in a similar
manner. Rather than manually looping over each value to generate a corresponding
UI element, Vide provides functions `indexes()` and `values()` to do this for
you.

`indexes()` maps each *index* in a table to a UI element.

```lua
local names = source { "a", "b", "c" }

local elements = indexes(names, function(name, i)
    return create "TextLabel" {
        Text = function()
            return "Name: " .. name()
        end,

        LayoutOrder = i
    }
end)
```

What happens here is the given callback is only ever ran *once* for each index
in the table. The callback receives two arguments, a *source* containing the
index's value and then the index itself.

Anytime the value at a corresponding index changes, the source for that index
value is updated, causing the UI element depending on it to update too.

`values()` behaves similarly, except it maps each *value* in a table to a UI
element.

```lua
type Item = {
    Name: string,
    Icon: number    
}

local items = source({} :: Array<Item>)

local elements = indexes(items, function(item, i)
    return create "ImageLabel" {
        Image = "rbxassetid://" .. item.Icon,
        LayoutOrder = i
    }
end)
```

The callback is again only ever ran *once* for each value in the table. The
callback receives two arguments, a value in the table and then a *source*
containing the value's corresponding index.

Any time a value in a table changes index, the source for that value is updated,
causing the UI element position to change.

In certain cases `values()` can cause less recalculation and rerenders than
`indexes()` like when items are re-arranged and shifted within a table.

It is important that each value in a table is unique when using `values()`,
and for this reason always using `indexes()` if a table contains primitive
values.

Both `indexes()` and `values()` return an array of all mapped UI elements.
