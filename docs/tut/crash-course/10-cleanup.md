# Cleanup

Sometimes you may need to do some cleanup when destroying a component or after
a side-effect from a source update. Vide provides a function `cleanup()` which
is used to queue a callback for the next time a reactive scope is rerun or
destroyed, or when a stable scope is destroyed.

```luau
local root = vide.root
local source = vide.source
local effect = vide.effect
local cleanup = vide.cleanup

local count = source(0)

local destroy = root(function()
    effect(function()
        local x = count()
        cleanup(function() print(x) end)
    end)

    cleanup(function() print "root destroyed" end)
end)

count(1) -- prints "0"
count(2) -- prints "1"
destroy() -- prints "2" and "root destroyed"
```

::: tip
Roblox instances do not need to be explicitly destroyed for their
memory to be freed, they only need to be parented to `nil`. So there is no
need to use `cleanup()` to destroy instances. However, be wary of connecting
a function that references an instance to an event from the same instance,
this causes the instance to reference itself and never be freed. In such a case
you would need to use `cleanup()` to disconnect this connection or to explicitly
destroy the instance.
:::
