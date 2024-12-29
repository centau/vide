# Concepts Summary

A summary of all the concepts covered during the crash course.

## Source

A source of data.

Stores a single value that can be updated.

Created with `source()`.

## Derived Source

A new source composed of other sources.

Created with a plain function or with `derive()`.

## Effect

Anything that happens in response to a source update.

Created with `effect()`.

## Stable Scope

One of the two types of Vide scopes.

Created by:

- `root()`
- `untrack()`
- `show()`
- `indexes()`
  
Stable scopes do not track sources and never rerun.

New stable or reactive scopes can be created within a stable scope.

## Reactive Scope

Created by:

- `effect()`
- `derive()`

Reactive scopes do track sources and will rerun when those sources update.

Reactive scopes cannot be created within a reactive scope, but stable scopes
can be created within a reactive scope.

## Scope Cleanup

When a scope is rerun or destroyed, all scopes created within it are
automatically destroyed.

Any functions queued by `cleanup()` are also ran.

## Reactive Graph

The combination of stable and reactive scopes can viewed graphically, called a
*reactive graph*. This can be a more intuitive way to think of the
relationships between effects and the sources they depend on.

### Code

```luau
local count = source(0)

root(function()
    local text = derive(function()
        return "count: " .. count()
    end)

    effect(function()
        print(text())
    end)
end)
```

### Graph resulting from code

```mermaid
%%{init: {
    "theme": "base",
    "themeVariables": {
        "primaryColor": "#111720",
        "primaryTextColor": "#fff",
        "primaryBorderColor": "#111720",
        "lineColor": "#79B8FF",
        "tertiaryColor": "#0d131b",
        "tertiaryBorderColor": "#202530"
    }
}}%%

graph LR

subgraph root
    text --> effect
end

count --> text
```

Notes:

- Since `count` is a source, not an effect, it can exist
  outside of scopes.
- An update to `count` will cause `text` to rerun, which
  then causes `effect` to rerun.
- When the root scope is destroyed, `text` and
  `effect` will be destroyed alongside it, since they were created within it.
  `count` will be untouched and future updates to `count` will have no effect.
