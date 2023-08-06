# [Table State](./index.md)

Vide has functions for dealing with table states.

Below is an example using the above `List` class.

```lua
type Item = {
    Name: string,
    Icon: number    
}

local items = source({} :: Array<Item>)

List {
    Children = indexes(items, function(item, i)
        return create "ImageLabel" {
            Image = function()
                return "rbxassetid://" .. item().Icon
            end,

            LayoutOrder = i
        }
    end)
}
```

Here we map each element in `items` to a value returned by a callback.

The callback is called only *once* per key. The first argument given to the
callback is a state that has the value of the table key's value.

Anytime the value of the corresponding table key changes, the state value
changes too. This saves us from having to recreate a UI element any time a
table index changes.

--------------------------------------------------------------------------------

### [&larr; Derived State](./5-derived-state.md) | [Property Groups &rarr;](./7-property-groups.md)
