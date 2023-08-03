# Strict Mode

Vide has a special mode called "strict mode" which is used for debugging.

The purpose of strict mode is to help ensure stateful code is *pure*
(deterministic and free from side effects) or if there are side-effects, that
they are cleaned up correctly.

Vide is set to strict by doing:

```lua
local vide = require(path_to_vide)
vide.strict = true
```

What strict mode will do:

1. Run derived callbacks twice when re-evaluating.
2. Run watcher callbacks twice when a state changes.
3. Throw an error if yields occur where they are not allowed.
4. Checks for `map()` returning primitive values.
5. Better error reporting and stack traces.

It is recommend to develop UI with strict mode and to disable it when pushing to
production.

--------------------------------------------------------------------------------
