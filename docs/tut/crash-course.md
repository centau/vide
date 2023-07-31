# Vide Crash Course

This is a brief tutorial designed to give you a quick run through the usage of
Vide.

Vide is largely inspired by Solid.

<br>

## Creating UI Instances

In Vide, it is intended to create all UI instances through code.

Instances are created using [`vide.create()`](../api/creation#create).

```lua
local vide = require(vide)
local create = vide.create
```

```lua
local frame = create "Frame" {
    Name = "Background",
    Position = UDim2.fromScale(0.5, 0.5)
}
```

`create()` returns a constructor for a given class which then takes a table of
properties to assign when creating a new instance for that class.

Sometimes you want to do more than setting properties, such as setting children or connecting to events.
Vide uses special keys called *symbols* which provide unique functionality like the above mentioned.

Children can be assigned to instances using the `Children` symbol.

```lua
local Children = vide.Children
```

```lua
local screenGui = create("ScreenGui") {
    Parent = game.StarterGui,

    [Children] = create("Frame") {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.4, 0.7),

        [Children] = {
            create("TextLabel") {
                Text = "Hi"
            },

            create("TextLabel") {
                Text = "Bye"
            }
        }
    }
}
```

Here, we import the symbol [`vide.Children`](../api/creation#Children).

This symbol can accept an instance, an array of instances and nested arrays of instances.
All given instances will be parented to the instance the symbol was used on.

<br>

## Connecting To Events

Built-in instance events and property changed events can be connected to using two other symbols, [`vide.Event`](../api/creation#Event) and [`vide.Changed`](../api/creation#Changed).

```lua
local Event = vide.Event
local Changed = vide.Changed
```

```lua
local textBox = create("TextBox") {
    PlaceholderText = "Enter text",
    
    [Event.Focused] = function(...)
        print("User is focusing on text box")   
    end,

    [Changed.Text] = function(newText)
        print("New text: " .. newText)
    end
}
```

Both of these symbols can be indexed into to get a specific symbol for an event to connect to.
The callback function for `Event` receives any event-specific arguments and the callback function for
`Changed` receives the new property value as the only argument (unlike `Instance:GetPropertyChangedSignal()`).

<br>

## State

*State* is the condition something is in at a specific time. The state of a program is simply the data it contains at some timepoint.

The purpose of all UI is to take some state and reflect that state visually.

In Vide, UI state is represented using special objects simply called *state*.

A state object in Vide can be created using [`vide.wrap`](../api/reactivity-core#wrap).

```lua
local wrap = vide.wrap
```

```lua
local isVisible = wrap(false)

local image = create("ImageLabel") {
    Image = "rbxassetid://xxx",
    Visible = isVisible
}

while true do
    wait(1)
    isVisible.Value = not isVisible.Value
end
```

The function `wrap` will *wrap* any given value with a state object of type `State<T>` which can be read from/wrote to through its `.value` property.

In the above code, the `ImageLabel.Visible` property is assigned a state. Now any time that state's value is assigned to, `ImageLabel.Visible` will also update with the new value assigned, without you having to explicitly set the property. The above code gives the effect of the image label toggling visibility at a 1 second interval forever.


There are a few reasons why we use state objects instead of plain variables:

1. Vide detects when you assign a state object as a property value. This is known as *binding* and doing so will cause the property to *automatically* update whenever that state object's value is changed.
2. We can create new state objects that derive from other state objects, which again, *automatically* update when the derived state objects change.

The reason why this is useful, is that you as the programmer do not have to worry about manually updating variables or UI instances, you can just focus on defining how the data maps to UI and everything will automatically update when changes occur.

<br>

## Derived State

You can create new state from other states. This is known as *deriving state*.

```lua
local derive = vide.derive
```

```lua
local count = wrap(0)

local text = derive(function(from)
    return "Count: " .. from(count)
end)

print(text.value) -- "Count: 0"

count.value += 1

print(text.value) -- "Count: 1"
```

Here we use [`vide.derive`](../api/reactivity-core#derive) to *derive* a new state `text` which depends on `count`.

A function is used to transform the value of `count`, where the value returned becomes the new value of `text`. The function receives an argument named `from` which is used to *capture* dependent states. This is used to link `count` to `text`, so that whenever `count` is updated, `text` will be too.

Whenever `count`'s value is changed, `text` will recompute its value and update anything dependent on `text`, such as UI.

States can be derived in a more concise manner when doing single operations such as concatenation:

```lua
local text = "Count: " .. count
```

You can derive new states using any Luau operator in this manner.

<br>

## Components

*Components* in UI are just custom-made reusable pieces of UI made from other pieces of UI.

The recommended way to create components is to use functions that take a table of properties as an argument and return the new UI instance.

```lua
local function Background(args)
    return create("Frame") {
        BackgroundColor3 = Color3.new(0, 0, 0),
        Position = args.Position,
        Size = args.Size
    }
end

local background = Background {
    Position = UDim2.new(),
    Size = UDim2.new()
}
```

Above is a simple example of a frame component with its background color set to black.

A single parameter `args` is used to pass properties to the component.

Components allow you to *encapsulate* behavior. You can only modify the component in ways that are defined in the component.
Looking at the above example, the only properties you are allowed to modify is `Position` and `Size`.
This is a good approach to use for organised code.

However, properties concering layout (positional and size properties) aren't usually intrinsinc to the component. In most cases the user would want to be able to pass these properties without having to manually pass each one in the component.

For these cases, the [`vide.Layout`](../api/creation#Layout) symbol can be used.

```lua
local Layout = vide.Layout
```

```lua
local function Background(props)
    return create("Frame") {
        BackgroundColor3 = Color3.new(0, 0, 0),
        [Layout] = props[Layout],
        [Children] = props[Children]
    }
end

local background = Background {
    [Layout] = {
        AnchorPoint = Vector2.new(),
        Position = UDim2.new(),
        Size = UDim2.new(),
    },

    [Children] = {
        create("TextLabel") {},
        create("ImageLabel") {}
    }
}
```

Here, the `Layout` symbol automatically assigns those layout-specific properties without having to explicitly assign each one in the component definition. This is a very common case and for this reason it is recommended to only assign layout properties using the `Layout` symbol for consistency when dealing with components.

This allows you to pass through layout properties without breaking encapsulation.

Additionally, the above example shows how children can be passed to components in a similar manner.

<br>

## Stateful components

Often, you need components that maintain their own internal state, such as a toggle button or a counter.

Below you can see how a simple counter component can be implemented.

```lua
local function Counter(props: {
    Layout: Layout
})
    -- create internal state unique to each component instance
    local count = source(0)

    return create "TextButton" {
        Text = function()
            return "Count: " .. count
        end

        Activated = function()
            count(count() + 1)
        end,

        Layout = props.Layout
    }
end

create "ScreenGui" {
    Parent = game.StarterGui,

    Counter {
        Layout = {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.fromScale(0.3, 0.1)
        }
    }
}
```

Here a reusable counter component is created, that when clicked on will increase its count and display it independent from other counter instances.

## Tables of data

basic inventory

```lua
type Item = {
    Name: string,
    Icon: number    
}

local items = wrap({} :: Array<Item>)

local function ItemSlot(args)
    return create("Frame") {
        [Layout] = args[Layout]

        [Children] = {
            create("TextLabel") {
                Name = args.Name,
                [Layout] = ...
            },

            create("ImageLabel") {
                Image = "rbxassetid://" .. args.Icon,
                [Layout] = ...
            }
        }
    }
end

local function Inventory(args)
    return create("Frame") {
        [Layout] = args[Layout],

        [Children] = {
            create("UIListLayout") {},

            map(items, function(i, item)
                return ItemSlot {
                    Name = item.Name,
                    Icon = item.Icon,
                    [Layout] = { LayoutOrder = i, ... }
                }
            end)
        }
    }
end



More comprehensive tutorials are in the works. To find out more refer to the [`API documentation`](../../README#API).
