# Strict Mode

While developing UI with Vide, you should use Vide's strict mode, which can
be set with `vide.strict = true` once when you first require Vide. Strict mode
will add extra safety checks and emit better error traces, particularly when
errors occur in property bindings.

Strict mode will run derived sources and effects twice each time they update.
This is to help identify improper cleanup of side-effects and ensure that pure
computations are actually pure.

```lua
local source = vide.source
local effect = vide.effect

vide.strict = true

local count = source(0)

local ran = 0
effect(function()
    ran += 1
end)

print(ran) -- 2
count(1)
print(ran) -- 4
```

A full list of what strict mode will do can be found
[here](../../api/strict-mode).
