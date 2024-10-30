# Components

Vide encourages separating different parts of your UI into functions called
*components*.

A component is a function that creates and returns a piece of UI.

This is a way to separate your UI into small chunks that you can reuse and put
together.

::: code-group

```luau [Button.luau]
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

```luau [Menu.luau]
local create = vide.create

local Button = require(Button)

local function Menu()
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
```

:::

A single parameter `props` is used to pass properties to the component.
