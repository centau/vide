# Creating UI

Instances are created using `create()`.

`create()` returns a constructor for a class which then takes a table of
properties to assign when creating a new instance for that class.

Luau allows us to omit parentheses `()` when calling functions with string or
table literals which Vide takes advantage of for brevity.

```lua
local vide = require(vide)
local mount = vide.mount
local create = vide.create

local function App()
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
end

mount(App, game.StarterGui)
```

Assign a value to a string key to set a property, and assign a value to a
number key to set a child. Events can be connected to by assigning a function
to a string key.

You can also use a shorthand to create datatypes instead of explicitly typing
out the class name and constructor. The table will be unpacked into the `.new()`
constructor of the property's type.

```lua
create "Frame" {
    AnchorPoint = { 0.5, 1 },
    UDim2 = { 0.5, 0, 0.5, 0 }
}
```
