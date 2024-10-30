# Creating UI

Instances are created using `create()`.

Parentheses `()` can be omitted when calling functions with string or
table literals for brevity.

```luau
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
