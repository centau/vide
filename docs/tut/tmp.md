```lua
local function Text(args)
    return create("TextLabel") {
        [Layout] = {
            Size = scale(1),
            args[Layout]
        }
    }
end

Text {
    [Layout] = {
        Position = scale(0.5, 0.1)
    }
}
```

```lua
a
```
