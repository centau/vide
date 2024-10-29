---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
next:
  text: 'Introduction'
  link: '/tut/crash-course/1-introduction'

hero:
  name: "Vide"
  tagline: A reactive UI and state library for Luau.
  image:
    src: /logo.svg
  actions:
    - theme: brand
      text: Crash Course
      link: /tut/crash-course/1-introduction
    - theme: alt
      text: API Reference
      link: /api/reactivity-core

features:
  - title: Reactive State Management
    details: Built upon Solid and makes building reactive applications simple.
  - title: Declarative and simple syntax
    details: Syntax designed to be minimal while also being easy to understand.
  - title: Fully Luau typecheckable
    details: Luau's typechecker catches type errors before you even begin testing.
---

<div class="advertising">

## Quick Look

Store your state to be used by UI in Sources which can be changed by any code:

```luau
-- We can create some new state.
local health = source(100)

-- and read and write to it like a function
print(health()) --> 100
health(50)
print(health()) --> 50
```

You can use sources to compute new derived values with functions:

```luau
local health = source(100)
local maxHealth = source(100)

-- We can use a function to derive new data from some state
local function percentageHealth()
    return `{ health() / maxHealth() * 100 }%`
end

print(percentageHealth()) --> 100%
health(50)
print(percentageHealth()) --> 50%
```

Use effects to react to changes to the sources used:

```luau
local health = source(100)
local maxHealth = source(100)

-- We'll create a new scope for handling effects.
local destroy = root(function()
    -- We can create an effect that will re-run whenever it's values change.
    effect(function()
        print(`{ health() / maxHealth() * 100 }%`)
    end)
end)

-- Effects will respond to any changes in the state it reads from.
health(50) --> effect prints 50%
-- Destroys the scope and the effect preventing it from running again.
destroy()
```

You can use sources to build instances that will react to these sources:

```luau
-- We create a scope that will mount the UI to Players.LocalPlayer.PlayerGui
mount(function()
    local health = source(100)
    local maxHealth = source(100)

    local function percentageHealth()
        return health() / maxHealth()
    end

    -- This will create a Frame with the given properties.
    return create "Frame" {
        Name = "Health",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Color3.fromHex("#000000"),

        -- We can add children directly to another object.
        create "Frame" {
            Name = "Fill",
            -- ... and we can set properties to effects which automatically update the property.
            Size = function()
                return UDim2.fromScale(percentageHealth(), 1)
            end,
            BackgroundColor3 = Color3.fromHex("#ff0000"),
        }
    }
end, Players.LocalPlayer.PlayerGui)
```

## Install

Vide can be installed via Wally and Github. There is currently no official Vide rbxm.

:::tabs
== Wally

Make sure you have wally installed on your computer.<br>
Add the following line to your `wally.toml` and then re-install your packages
```toml
[dependencies]
vide = centau/vide@0.3.1
```

== Git

Make sure you have Git installed on your computer.<br>
Run the following command in the directory you want to have Vide installed at
```sh
git submodule add https://github.com/centau/vide.git
```

== Build

Download vide onto your computer

```sh
git clone https://github.com/centau/vide.git & cd vide
```

then use a syncing tool to build Vide into a rbxm

```sh
rojo build -o build.rbxm
```

which you can then insert into Roblox Studio

:::

</div>