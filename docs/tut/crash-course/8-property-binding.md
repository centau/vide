# Property Binding

Explicitly creating effects to update properties can become verbose when there
are a lot of properties to update. Vide provides a way to *implicitly* create
an effect to update properties on source update.

```lua
local create = vide.create
local source = vide.source

local function Counter()
    local count = source(0)

    return create "TextButton" {
        Text = function()
            return "count: " .. count()
        end,

        Activated = function()
            count(count() + 1)
        end
    }
end
```

This example is equivalent to the example seen on the previous page.

Instead of explicitly creating an effect, assigning a (non-event) property
a function will implicitly create a side-effect to update that property anytime
a dependent source is updated.

Just like effects, the function is ran immediately in a reactive scope to set
the property initially and determine what sources are being depended on.

This allows you as the programmer to not need to manually update UI as the state
of your program changes. You just define how the data sources map to UI, and
Vide's reactive system will automatically update any properties depending on
those sources that were updated.

## Children Binding

Children can also be set in a similar manner. A source passed as a child (passed
with a number key instead of string key) can return an instance or an array of
instances. Vide will automatically unparent removed instances and parent new
instances when that source's stored instances change.

```lua
local items = source {
    create "TextLabel" { Text = "A" }
}

local function List(props: { children: () -> { Instance } })
    return create "Frame" {
        create "UIListLayout" {},
        props.children
    }
end

local list = List { children = items } -- creates a list with a single text label "A"

items {
    create "TextLabel" { Text = "B" },
    create "TextLabel" { Text = "C" }
}

-- this will automatically unparent the text label "A", and parent the labels "B" and "C".
```
