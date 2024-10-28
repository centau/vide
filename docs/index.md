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

## Installation

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

<script setup>
import { VPButton } from "vitepress/theme"
</script>

<div style="display: flex; justify-content: end;">
<VPButton href="/tut/crash-course/1-introduction" text="Read the crash Course"/>
</div>

</div>