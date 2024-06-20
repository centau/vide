# Creating UI

Instances are created using `create()`.

`create()` returns a constructor for a class which then takes a table of
properties to assign when creating a new instance for that class.

Luau allows us to omit parentheses `()` when calling functions with string or
table literals which is recommended to use for brevity.

```lua
local create = vide.create

return create "ScreenGui" {
    create "Frame" {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.4, 0.7),

        create "TextLabel" {
            Text = "hi"
        },

        create "TextLabel" {
            Text = "bye"
        },

        create "TextButton" {
            Text = "click me",

            Activated = function()
                print "clicked!"
            end
        }
    }
}
```

Assign a value to a string key to set a property, and assign a value to a
number key to set a child. Events can be connected to by assigning a function
to a string key.
