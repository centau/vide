# Introduction

This is a brief tutorial designed to give you a quick run through the usage of
Vide.

Vide is heavily inspired by [Solid](https://www.solidjs.com/).

## Why Vide?

Creating UI is a slow and tedious process. The purpose of Vide is to make UI
declarative and concise, making it faster to create and more importantly easier
to maintain. Vide achieves this using a reactive style of programming which
allows you to focus on the flow of data through your application without
worrying about manually updating UI instances.

Some of the main focuses behind Vide's design choices:

- Concise syntax to reduce verbosity as much as possible.
- Reducing the amount of imports needed for usage by leveraging Luau's syntax
  and semantics.
- Being completely typecheckable.
- Flexibility, particularly with integrating other libraries and allowing users
  to use their own patterns.
- Independence from instance lifetimes.
- A powerful reactive system that can surgically update properties as a result
  of state changes.

## Structure Of A Vide App

The entry point for all Vide apps is the `root()` function. This function
sets up Vide's reactivity system and allows proper disposal of your app. It
takes and calls a function that should create your entire app, then returns the
result.

In Vide, your app should be composed of functions, each function creates a
specific part of your app, and can be reused if needed. These functions are
called *components*.

```lua
local function App()
    return create "ScreenGui" {
        create "TextLabel" { Text = "hi" }
    }
end

root(App).Parent = game.StarterGui
```
