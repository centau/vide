```lua
function TextInput(p: {
    DefaultText: string,
    Output: (string) -> ()
} & Layout)
    return create "TextBox" {
        Layout = p.Layout,
        Children = p.Children

        BackgroundText = DefaultText,

        [{"Changed"}] = function(self)
            p.Output(self.Text)
        end
    }
end

function Counter()
    local count = source(0)

    return create "TextButton" {
        Text = count
    }
end

source
derive
map

spring
```

onCleanup
Index
For
untrack
batch

## version 1

```lua
map(items, function(item, i)
    return Item {
        Item = item, -- primitive
        LayoutOrder = i
    }
end)
```

## version 2

```lua
each(items, function(item, i)
    return Item {
        Item = item, -- state
        LayoutOrder = i
    }
end)
```

