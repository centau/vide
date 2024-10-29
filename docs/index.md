---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
pageClass: home
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
      text: What is Vide?
      link: /tut/crash-course/1-introduction
    - theme: alt
      text: Crash Course
      link: /tut/crash-course/2-creation
    - theme: alt
      text: API Reference
      link: /api/reactivity-core

features:
  - title: Reactive State Management
    details: Built upon Solid and makes building reactive applications simple.
  - title: Declarative and simple
    details: Syntax designed to be minimal while also being easy to understand.
  - title: Fully Luau typecheckable
    details: Luau's typechecker catches type errors before you even begin testing.
---
