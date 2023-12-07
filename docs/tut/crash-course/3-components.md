# Components

Vide encourages separating different parts of your UI into functions called
*components*.

A component is a function that creates and returns a piece of UI.

This is a way to separate your UI into small chunks that you can reuse and put
together.

::: code-group

```lua [Button.luau]
local create = vide.create

local function Button(props: {
    Position: UDim2,
    Text: string,
    Activated: () -> ()
})
    return create "TextButton" {
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(200, 150),

        Position = props.Position,
        Text = props.Text,
        Activated = props.Activated,

        create "UICorner" {}
    }
end

return Button
```

```lua [App.luau]
local create = vide.create

local Button = require(Button)

local function App()
    return create "ScreenGui" {
        Button {
            Position = UDim2.fromOffset(200, 200),
            Text = "back",
            Activated = function()
                print "go to previous page"
            end
        },

        Button {
            Position = UDim2.fromOffset(400, 200),
            Text = "next",
            Activated = function()
                print "go to next page"
            end
        }
    }
end

App().Parent = game.StarterGui
```

:::

Above is a simple example of a button component being used across files.

A single parameter `props` is used to pass properties to the component.

You can only modify the component in ways that you allow in the component,
through the `props` parameter.

To create a new button all you must do is call the `Button` function, passing in
values. This saves having to create and set every property each time. Also, when
updating the button component in future, any changes to the button file will be
seen anywhere the button is used in your app.
