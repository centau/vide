<br>

<div align="center">
    <img style="float: right;margin-top:50px" src="docs/public/logo.svg" width="110" />
</div>

<br>

### ⚠️ This library is in early stages of development with breaking changes being made often.

Vide is a reactive UI library.

- Fully Luau typecheckable
- Declarative and concise syntax.
- Minimal imports.
- Reactively driven.

## Getting started

Read the
[crash course](https://centau.github.io/vide/tut/crash-course/1-introduction)
for a quick introduction to the library.

## Code sample

```lua
local vide = require(path_to_vide)
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
