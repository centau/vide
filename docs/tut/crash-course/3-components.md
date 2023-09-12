# Components

Components are custom-made reusable pieces of UI made from other pieces of UI.

By using components you can make your application more modular and better
organized.

```lua [Button.luau]
local vide = require(vide)
local create = vide.create

local function Button(props: {
    Position: UDim2,
    Text: string,
    Activated: () -> ()
})
    return create "TextButton" {
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        Size = UDim2.fromOffset(200, 150),

        Position = props.Position,
        Text = props.Text,
        Activated = props.Activated
    }
end

return Button
```

```lua [App.luau]
local vide = require(vide)
local create = vide.create

local Button = require(Button)

local function App()
    return create "ScreenGui" {
        Button {
            Position = UDim2.fromOffset(200, 200),
            Text = "click me!",

            Activated = function()
                print "clicked"
            end
        }
    }
end

root(App).Parent = game.StarterGui
```

Above is a simple example of a button component with a set color and size,
being reused across files.

A single parameter `props` is used to pass properties to the component.

Components allow you to *encapsulate* behavior. You can only modify the
component in ways that you allow in the component.

This also promotes code reusability. Anytime you want a new button all you do
is call `Button {}` instead of creating and setting every property each time.
When changing the button in future, any changes to the button file will be
reflected anywhere the button is used throughout your app.

This can be extended to much more complicated UI.
