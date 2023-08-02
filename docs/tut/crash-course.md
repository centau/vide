# Vide Crash Course

This is a brief tutorial designed to give you a quick run through the usage of
Vide.

Vide is largely inspired by Solid and Fusion.

<br>

## Why Vide?

Creating UI is a slow and tedious process. The purpose of Vide is to make UI
declarative and concise, making it faster to create and more importantly easier
to maintain. Vide achieves this using a reactive style of programming which
allows you to focus on the flow of data through your application without
worrying about manually updating UI instances.

## Creating UI Instances

Instances are created using [`create()`](../api/creation#create).

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

String keys are assumed to be properties, integer keys are assumed to be
children.

```lua
create "ScreenGui" {
    Parent = game.StarterGui,

    create("Frame") {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.4, 0.7),

        create("TextLabel") {
            Text = "hi"
        },

        create("TextLabel") {
            Text = "bye"
        }
    }
}
```

To connect to an event, just set the event property name to a function.

```lua
create "TextButton" {
    Activated = function()
        print "clicked!"
    end
}
```

All event arguments are passed into the function.

<br>

## State

State in Vide are special objects that store data.

A state object in Vide can be created using
[`source()`](../api/reactivity-core#source).

```lua
local source = vide.source
```

```lua
local visible = source(false)

local image = create("ImageLabel") {
    Visible = visible -- bind property to state
}

visible(false) -- image label is hidden

visible(true) -- image label is shown
```

`source()` creates a new data source which can be set by calling it with the new
value to set.

Any time the value is set, anything depending on it will automatically be
updated using the new value.

Vide detects when you assign a state object as a property value. This is known
as *binding* and doing so will cause the property to *automatically* update
whenever that state object's value is changed.

You as the programmer do not have to worry about manually updating variables or
UI instances, you can just focus on defining how the data maps to UI and
everything will update when changes occur.

<br>

## Derived State

You can create new state from other states. This is known as *deriving state*.

```lua
local count = source(0)

local function text()
    return "count: " .. count()
end

create "TextLabel" {
    Text = text
}
```

To read from a state, you call without any arguments which returns its stored
value.

Assigning a non-event property a function will bind that property to that
function, anytime a state being read from inside that function is changed, the
function will be re-ran and the property value updated.

Sometimes when using expensive computations to derive state, you only want to
recalculate it when a source state has changed.

```lua
local derive = vide.derive
```

```lua
local count = wrap(0)

local factorial = derive(function()
    local n = 1
    for i = 2, count() do
        n *= i
    end
    return n
end)
```

`derive()` will cache and return the same value until a source state has
changed, where it will recompute and cache a new value.

```lua
create "TextLabel" {
    Text = function()
        "factorial: " .. factorial()
    end
}

count(3) -- displays "factorial: 6"
count(4) -- displays "factorial: 24"
```

<br>

## Components

Components are custom-made reusable pieces of UI made from other pieces of UI.

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

Above is a simple example of a frame component with its background color set to
black.

A single parameter `args` is used to pass properties to the component.

Components allow you to *encapsulate* behavior. You can only modify the
component in ways that you allow in the component.

This also promotes code reusability. Anytime you want a black frame all you do
is call `Background {}` instead of creating a new frame and settings it color
each time.

<br>

## Stateful components

Often, you need components that maintain their own internal state, such as a
toggle-able button or a counter.

Below you can see how a simple counter component can be implemented.

```lua
local function Counter()
    local count = source(0)

    return create "TextButton" {
        Text = function()
            return "count: " .. count()
        end

        Activated = function()
            count(count() + 1)
        end,
    }
end
```

Each time you call `Counter {}`, it will create a new counter component which
each maintains their own count state.

Clicking on the UI element will automatically increment and display its count.

## Nested Properties and Typechecking

When a key is assigned a table, Vide does not attempt to assign it to a
property, instead, the table is iterated and processed just like the nesting
table.

Below is an example of how you can use this to pass groups of similar properties
together such as position and size, while also using typechecking.

```lua
type Layout = {
    Layout = {
        Position: UDim2?,
        Size: UDim2?,
        AnchorPoint: Vector2?
    }
}

local function Button(args: Layout & {
    Text: string,
    Callback: () -> ()
})
    local count = source(0)

    return create "TextButton" {
        Text = args.Text
        Activated = args.Callback,
        Layout = args.Layout
    }
end

Button {
    Text = "Click me!",
    
    Callback = function()
        print "clicked me!"
    end,

    Layout = {
        Position = UDim2.new(),
        Size = UDim2.new()
    }
}
```

Here the button component is assigned a position and size as if you passed those
properties directly.

The same can be done for properties such as children.

```lua
type Children = {
    Children = Array<Instance>
}

local function List(args: Children & Layout)
    return create "Frame" {
        Layout = args.Layout,
        Children = args.Children,

        create "UIListLayout" {}
    }
end

List {
    Layout = {
        Position = UDim2.new()
    },

    Children = {
        create "TextLabel" { Text = "1" }
    }
}
```

## Tables of data

Vide has functions for dealing with table states.

Below is an example using the above `List` class.

```lua
type Item = {
    Name: string,
    Icon: number    
}

local items = source({} :: Array<Item>)

List {
    Children = map(items, function(item, i)
        return create "ImageLabel" {
            Image = function()
                return "rbxassetid://" .. item().Icon
            end,

            LayoutOrder = i
        }
    end)
}
```

Here we map each element in `items` to a value returned by a callback.

The callback is called only *once* per key. The first argument given to the
callback is a state that has the value of the table key's value.

Anytime the value of the corresponding table key changes, the state value
changes too. This saves us from having to recreate a UI element any time a
table index changes.

## WIP
