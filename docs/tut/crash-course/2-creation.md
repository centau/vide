# Creating UI

Instances are created using `create()`.

`create()` returns a constructor for a class which then takes a table of
properties to assign when creating a new instance for that class.

Luau allows us to omit parentheses `()` when calling functions with string or
table literals which Vide takes advantage of for brevity.

```lua
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

::: warning
When creating an instance with no properties, it is important to not forget to
actually call the constructor: `create "Frame" {}` and not `create "Frame"`.
To be clear, `create "Frame"` returns a *function* which is a constructor for
that class, not an instance of that class. This would result in you attempting
to parent a function instead of an instance which is not correct.
:::
