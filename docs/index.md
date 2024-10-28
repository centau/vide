---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
next:
  text: 'Introduction'
  link: '/tut/crash-course/1-introduction'

hero:
  name: Vide
  text: ""
  tagline: A reactive UI and state library for Luau.
  image:
    src: /logo.svg
    alt: Vide
  actions:
    - theme: brand
      text: Quick Start
      link: /tut/crash-course/1-introduction
    - theme: alt
      text: API Reference
      link: /api/reactivity-core

features:
  - title: Reactively driven
    details: Powerful and modern primitives inspired by SolidJS to build fluid UI with little friction
  - title: Declarative and concise
    details: Syntax built to be minimal and clean while also obvious and easy to understand to anyone
  - title: Fully Luau Typecheckable
    details: Ensure you write correct and robust code through the Luau typechecking engine.
---

## Installation

Vide can be installed through 3 different ways.

:::tabs
== Wally

Add the following line to your `wally.toml` and then re-install your packages
```toml
[dependencies]
vide = centau/vide@0.3.1
```

== Roblox

im so sorry you have to use rojo and build it yourself or ask someone in ross to build a vide rbxm for you :sob:
cen is too busy working on system verilog

:::

## Quick Examples

A simple counter element that counts up when you click on it.

```luau
local vide = require("vide")

local source = vide.source
local create = vide.create

local function Counter()
	local count = source(0)

	return create "TextButton" {
    Size = UDim2.fromOffset(200, 50),
		Text = function()
			return `count: {count()}`
		end,

		Activated = function()
			count(count() + 1)
		end
	}
end

return Counter
```
