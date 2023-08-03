# [Components](./index.md)

Components are custom-made reusable pieces of UI made from other pieces of UI.

Using components you make your application more modular and better organized.

Components leverage functions to create self-contained UI that can even have
its own state and behavior.

```lua
local function Button(props: {
    Position: UDim2,
    Text: string,
    Callback: () -> ()
})
    return create "TextButton" {
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        Size = UDim2.fromOffset(400, 250),

        Position = props.Position,
        Text = props.Text,
        Callback = props.Callback
    }
end

local button = Button {
    Position = UDim2.new(),
    Text = "Click me!",

    Callback = function()
        print "clicked"
    end
}
```

Above is a simple example of a button component with its background color set to
a dark grey and with a fixed size.

A single parameter `props` is used to pass properties to the component.

Components allow you to *encapsulate* behavior. You can only modify the
component in ways that you allow in the component.

This also promotes code reusability. Anytime you want a new button all you do
is call `Button {}` instead of creating and setting every property each time.

This can be extended to much more complicated UI.

--------------------------------------------------------------------------------

### [&larr; Element Creation](./2-creation.md) | [State &rarr;](./4-state.md)

