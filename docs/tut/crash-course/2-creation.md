# [Creating UI Elements](./index.md)

Instances are created using [`create()`](../../api/creation.md#create).

```lua
local vide = require(path_to_vide)
local create = vide.create
```

`create()` returns a constructor for a given class which then takes a table of
properties to assign when creating a new instance for that class.

```lua
local frame = create "Frame" {
    Name = "Background",
    Position = UDim2.fromScale(0.5, 0.5)
}
```

String keys are assigned as properties and integer keys are assigned as child
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

To connect to an event, just set the event property name to a function.

All event arguments are passed into the function.

```lua
create "TextButton" {
    Activated = function()
        print "clicked!"
    end
}
```

In short:

- String keys = properties
  - Function values = events
  - Non-function values = property values
- Numeric keys = children

--------------------------------------------------------------------------------

### [&larr; Introduction](./1-introduction.md) | [Components &rarr;](./3-components.md)
