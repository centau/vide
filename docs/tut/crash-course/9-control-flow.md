# Control Flow

Eventually you will need a way to dynamically create and destroy UI elements
resulting from state changes. Vide provides functions to help you do this,
known as *control flow* functions.

These functions return a new source, which holds the instances to be displayed.
These sources can be assigned as children, meaning the displayed children
will update when the input source updates.

One of these functions is `switch()`, used to conditionally show one of a set of
components.

```lua
local vide = require(vide)
local source = vide.source
local switch = vide.switch

local function ToggleButton(p: {
    Text: string,
    Toggle: (boolean) -> boolean
})
    return create "TextButton" {
        Size = UDim2.fromOffset(300, 300),
        Text = p.Text,
        Activated = function()
            p.Toggle(not p.Toggle())
        end
    }
end

local loggedIn = source(false)

local function LoginMenu()
    return Frame {
        switch(loggedIn) {
            [true] = function()
                return ToggleButton { Text = "Log out", Toggle = loggedIn }
            end,

            [false] = function()
                return ToggleButton { Text = "Log in",  Toggle = loggedIn }
            end
        }
    }
end

mount(function() return create "ScreenGui" { LoginMenu {} } end, game.StarterGui)
```

Above is an example of using a switch to create a login menu. Each time
`loggedIn` toggles, the current button will be destroyed, and a new button
created, which the text to represent the current action, to log in or log out.

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
