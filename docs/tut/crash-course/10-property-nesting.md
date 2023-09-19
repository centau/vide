# Nested Properties

Often when creating components from existing components, you can find yourself
repetitively passing through properties such as size or position.

Example below:

```lua
function Background(props: {
    Color: Color3,
    AnchorPoint: UDim2,
    Position: UDim2,
    Size: UDim2
})
    return create "Frame" {
        Color = props.Color
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size
    }
end

function Menu(props: {
    Color = props.Color
    AnchorPoint: UDim2,
    Position: UDim2,
    Size: UDim2
})
    return Background {
        Color = props.COlor,
        AnchorPoint = props.AnchorPoint,
        Position = props.Position,
        Size = props.Size
    }
end
```

One way this can be avoided is by using *property nesting*. In Vide, passing a
table value inside `props` has special semantics. Any key with a table value is
not assigned like a property, instead the table is iterated and processed just
like the outer table is. Any properties in the nested table will be assigned
to the instance just the same.

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

function Background(props: Layout & { Color: Color3 })
    return create "Frame" {
        Color = props.Color,
        props.Layout
    }
end

function Menu(props: Layout & { Color: Color3 })
    return Background {
        Color = props.Color,
        Layout = props.Layout
    }
end
```

Here we created a nested group with the key `Layout` that can accept
layout-related properties. Any name could be chosen for the key.
This allows us to write much more concise syntax that is also typecheckable.

In another example we use a key named `Children` to pass arrays of instances to
be parented.

```lua
type Children = {
    -- allows us to also optionally pass a source that returns an array of children instead
    Children = Array<Instance> | () -> Array<Instance>
}

local function List(props: Children & Layout)
    return create "Frame" {
        props.Children,
        props.Layout,
        create "UIListLayout" {}
    }
end

List {
    Layout = {
        Position = UDim2.new()
    },

    Children = {
        create "TextLabel" { Text = "1" },
        create "TextLabel" { Text = "2" }
    }
}
```

Deeper nested properties are guaranteed to be set after shallower nested
properties, this can be used to create overridable default properties.

```lua
local function List(props: Children & Layout)
    return create "Frame" {
        props.Children,
        props.Layout,

        -- can be overriden by `props.Layout`
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromScale(0.5, 0),

        create "UIListLayout" {}
    }
end
```
