# todo

- strict mode
  - warn when map returns primitive

- Implement from solid
  - onCleanup
  - Index
  - For
  - untrack
  - batch
  - async/loading/suspense
  - define order with nested properties

```lua
type Action<T> = {
    type: T,
    priority: number,
    callback: (Instance) -> ()
}

local function action(priority: number, fn: (Instance) -> ()): Action

end

local function changed(property: string, callback: () -> ())
    return action(1, function(instance)
        instance:GetPropertyChangedSignal(property):Connect(callback)
    end) :: Action<"Changed">
end

create "TextBox" {
    Text = "test",

    changed "Text" < function(self, data)

    end
}
```

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

