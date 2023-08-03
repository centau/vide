# [Property Groups](./index.md)

When a key is assigned a table, Vide does not attempt to assign it to a
property, instead, the table is iterated and processed just like the nesting
table.

Below is an example of how you can use this to pass groups of similar properties
together such as position and size, while also using typechecking.

```lua
type Layout = {
    Layout = {
        Position: UDim2?,
        Size: UDim2?,
        AnchorPoint: Vector2?
    }
}

local function Button(args: Layout & {
    Text: string,
    Callback: () -> ()
})
    local count = source(0)

    return create "TextButton" {
        Text = args.Text
        Activated = args.Callback,
        Layout = args.Layout
    }
end

Button {
    Text = "Click me!",
    
    Callback = function()
        print "clicked me!"
    end,

    Layout = {
        Position = UDim2.new(),
        Size = UDim2.new()
    }
}
```

Here the button component is assigned a position and size as if you passed those
properties directly.

The same can be done for properties such as children.

```lua
type Children = {
    Children = Array<Instance>
}

local function List(args: Children & Layout)
    return create "Frame" {
        Layout = args.Layout,
        Children = args.Children,

        create "UIListLayout" {}
    }
end

List {
    Layout = {
        Position = UDim2.new()
    },

    Children = {
        create "TextLabel" { Text = "1" }
    }
}
```

--------------------------------------------------------------------------------

### [&larr; Table State](./6-table-state.md)
