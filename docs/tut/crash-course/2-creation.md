# Creating UI Elements

Instances are created using [`create()`](../../api/creation.md#create).

```lua
local vide = require(path_to_vide)
local create = vide.create
```

`create()` returns a constructor for a class which then takes a table of
properties to assign when creating a new instance for that class.

Luau allows us to omit parentheses `()` when calling functions with string or
table literals for brevity.

```lua
local frame = create "Frame" {
    Name = "Background",
    Position = UDim2.fromScale(0.5, 0.5)
}
```

String keys are treated as properties and integer keys are treated as child
instances.

```lua
create "ScreenGui" {
    Parent = game.StarterGui,

    create "Frame" {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.4, 0.7),

        create "TextLabel" {
            Text = "hi"
        },

        create"TextLabel" {
            Text = "bye"
        }
    }
}
```

To connect to an event, just assign the event property a function.

All event arguments are passed into the function.

```lua
create "TextButton" {
    Activated = function()
        print "clicked!"
    end
}
```

You can also use a form of aggregate initialization to create datatypes instead
of explicitly typing out the class name and constructor.

```lua
create "Frame" {
    AnchorPoint = { 0.5, 1 },
    UDim2 = { 0.5, 0, 0.5, 0}
}
```

When a property is assigned a table, Vide will inspect the type of the property
being assigned to, and call that type's default `new()` constructor with the
values from the unpacked table.
