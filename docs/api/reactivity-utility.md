# Reactivity API: Utility

## cleanup()

Runs a callback anytime a reactive scope is reran or destroyed.

- **Type**

    ```lua
    function cleanup(callback: () -> ())
    ```

- **Example**

    ```lua
    local data = source(1)

    effect(function()
        local label = create "TextLabel" { Text = data() }

        cleanup(function()
            label:Destroy()
        end)
    end)
    ```

## untrack()

Runs a given function where any sources read will not be tracked by a reactive
scope.

- **Type**

    ```lua
    function untrack<T>(source: () -> T): T
    ```

- **Details**

    Updates made to a source passed to `untrack()` will not cause updates to
    anything depending on that source.

- **Example**

    ```lua
    local a = source(0)
    local b = source(0)

    local sum = derive(function()
        return a() + untrack(b)
    end)

    print(sum()) -- 0
    b(1)
    print(sum()) -- 0
    a(1)
    print(sum()) -- 2
    ```

## read()

Utility used to read a value that is either a primitive or a source. Sources
read can still be tracked inside a reactive scope.

- **Type**

    ```lua
    function read<T>(value: T | () -> T): T
    ```

--------------------------------------------------------------------------------
