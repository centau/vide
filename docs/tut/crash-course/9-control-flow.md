# Control Flow

Eventually you will need a way to dynamically create and destroy UI elements
resulting from source updates. Vide provides functions to help you do this,
known as *control flow* functions.

These functions return new sources, which hold the instances to be displayed.
These sources can be assigned as children, meaning the displayed children
will update when the input source updates.

Control flow functions are special, because they run their components in a new
reactive scope, which can be destroyed independently of the reactive scope that
called the control flow function itself. This means that parts of your app can
be independently created then destroyed and cleaned.

## show()

The most basic control flow function is `show()`, which is used to conditionally
show a component.

```lua
local source = vide.source
local show = vide.show

local function JoinMenu()
    local joined = source(false)

    local function JoinButton()
        return Button {
            Activated = function() joined(true) end
        }
    end

    return create "Frame" {
        show(function() return not joined() end, JoinButton)
    }
end
```

This will make a button to join if you have not joined already.

You can also pass a third argument, a fallback to show if the condition is falsey.

```lua
local function JoinMenu()
    local joined = source(false)

    local function JoinButton()
        return Button {
            Activated = function() joined(true) end
        }
    end

    local function LeaveButton()
        return Button {
            Activated = function() joined(false) end
        }
    end

    return create "Frame" {
        show(joined, LeaveButton, JoinButton)
    }
end
```

## switch()

Similar to `show()`, `switch()`, also condtionally displays one instance at a
time. It is more flexible since it can show one of many components, based on a
table used to map a source value to a component.

```lua
local source = vide.source
local switch = vide.switch

local function JoinMenu()
    local joined = source(false)

    local function JoinButton()
        return Button {
            Activated = function() joined(true) end
        }
    end

    local function LeaveButton()
        return Button {
            Activated = function() joined(false) end
        }
    end

    return create "Frame" {
        switch(joined) {
            [true] = LeaveButton,
            [false] = JoinButton
        }
    }
end
```

Above is an example of using a switch to create a join menu. Each time
`joined` toggles, the current button will be destroyed, and a new button
created, which the text to represent the current action, to join or leave.

The callbacks given to control flow functions are ran in a new reactive-scope,
so any cleanups registered will be ran when the input is changed and a new
output is created.

Another control flow function, `indexes()`, is used to create elements from an
input table.

Often, you will have a table of values that will be displayed in a similar
manner. Rather than manually looping over each value to generate a corresponding
UI element, `indexes()` can autmatically run a transform function for each
index and value, generating a UI element.

```lua
local todoList = {
    "Finish the crash course",
    "Star vide's GitHub"
}

local elements = indexes(todoList, function(todo, i)
    return create "TextLabel" {
        Text = function()
            return i .. ": " .. todo()
        end,

        LayoutOrder = i
    }
end)

mount(function()
    return create "ScreenGui" {
        create "UIListLayout" {}, elements
    }
end, game.StarterGui)
```

For each unique index in the passed table, the transform function will be called
with 1. a source containing the value of the index, 2. the index itself.

When the value at an index is changed, the function is not reran. Instead, the
given source is updated instead.

`indexes()` is said to map each *index* in a table to a UI element, each index
has a single corresponding element.

An element is only destroyed if the value of an index is set to `nil`.
