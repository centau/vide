# Introduction

This is a brief tutorial designed to give you a quick run through the usage of
Vide.

Vide is heavily inspired by [Solid](https://www.solidjs.com/).

This tutorial assumes familiarity with Luau and Roblox GUI.

## Why Vide?

Creating UI is a slow and tedious process. The purpose of Vide is to make UI
declarative and concise, making it faster to create and more importantly easier
to maintain. Vide achieves this using a reactive style of programming which
allows you to focus on the flow of data through your application without
worrying about manually updating UI instances.

Some of the main focuses behind Vide's design choices:

- Concise syntax.
- Being completely typecheckable.
- Independence from instance lifetimes.
- Real reactivity.

## Structure Of A Vide App

The entry point for all Vide apps is the `mount()` function. This function
sets up Vide's reactivity system. It takes and calls a function that should
create your entire app, and will apply its result to a target.

In Vide, your app should be composed of functions, each function creates a
specific part of your app, and can be reused if needed. These functions are
called *components*.

```lua
local function App()
    return {
        PlayerStats(),
        Inventory(),
        Settings()
    }
end

mount(App, game.StarterGui)
```
