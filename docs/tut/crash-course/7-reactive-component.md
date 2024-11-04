# Reactive Components

Reactive components in Vide are created using sources and effects - sources to
store the data, and effects to display the data.

```luau
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

Above is an example of a counter component, that when clicked, will increment
its internal count, and automatically update its text to reflect that count.

Each instance of `Counter()` will maintain its own independent count, since the
count source is created inside the component.

External sources can also be passed into components for them to use.

```luau
local function Counter(props: { count: () -> number })
    local count = props.count

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

local count = source(0)

Counter {
    count = count
}

count(1) -- the Counter component will update to display this count
```

Sources can be created internally or passed in from externally, there are no
restrictions on how they are used as long as the effect using it is created
within a stable scope.
