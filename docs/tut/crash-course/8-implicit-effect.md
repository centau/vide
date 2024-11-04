# Implicit Effects

Explicitly creating effects to update properties is tedious. You can
*implicitly* create an effect to update properties instead.

::: code-group

```luau [Implicit Effect]
local create = vide.create
local source = vide.source

local function Counter()
    local count = source(0)

    return create "TextButton" {
        Activated = function()
            count(count() + 1)
        end,

        Text = function()
            return "count: " .. count()
        end
    }
end
```

```luau [Explicit Effect]
local create = vide.create
local source = vide.source
local effect = vide.effect

local function Counter()
    local count = source(0)

    local instance = create "TextButton" {
        Activated = function()
            count(count() + 1)
        end
    }

    effect(function()
        instance.Text = "count: " .. count()
    end)

    return instance
end
```

:::

This example is equivalent to the example seen on the previous page.

Instead of explicitly creating an effect, assigning a (non-event) property a
function will implicitly create an effect to update that property.

## Children

Children can also be set in a similar manner. A source passed as a child (passed
with a number key instead of string key) can return an instance or an array of
instances. An effect is automatically created to unparent removed instances and
parent new instances on source update.

```luau
local items = source {
    create "TextLabel" { Text = "A" }
}

local function List(props: { children: () -> { Instance } })
    return create "Frame" {
        create "UIListLayout" {},
        props.children
    }
end

local list = List { children = items } -- creates a list with text label "A"

items {
    create "TextLabel" { Text = "B" },
    create "TextLabel" { Text = "C" }
}

-- this will automatically unparent text label "A", and parent labels "B" and "C"
```
