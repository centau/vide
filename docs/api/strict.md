# Strict Mode

<br/>

## strict

A flag that users can set to enable or disable strict mode (disabled by default).

### Type

```ts
boolean strict = false
```

### Details

The purpose of strict mode is to help ensure stateful code is *pure* (deterministic and free from side effects).

Setting this flag is global for all scripts requiring the same instance of the Vide module.

What strict mode will do:

1. Run derived callbacks twice when calculating state value.
2. Run watcher callbacks twice each time state changes.
3. Throw an error if a derived callback yields.
4. Throw an error if a watcher callback yields.

It is recommend to develop UI with strict mode set to `true`
and to set it back to false when pushing to production.

Using strict mode will help identify potential non-deterministic code and side-effects by running code
multiple times in places where it would only run once.

Strict mode will also ensure that watcher side effects are self contained in the sense that they clean themselves up
properly when ran multiple times in quick succession, in case any asynchronous operation is performed.

Yielding within derived or watcher callbacks can cause undefined behavior as the reactive graph is not designed
to work with asynchronous code. Strict mode can identify and throw an error when asynchronous code is detected.
This isn't done during runtime as these checks are computationally expensive.

### Example

```lua
vide.strict = true -- this only needs to be done once, preferably in the first module to require Vide

local state = wrap()

watch(function()
    local cleanup = doAsyncOperation(state.Value)

    return function()
        cleanup()
    end
end)

state.Value = 1 -- this will cause the watcher to be ran twice, identifying if cleanup occurs properly
```
