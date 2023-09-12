# Reactivity API: Utility

## cleanup()

Runs a callback anytime a reactive scope is re-ran.

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

    ```lua
    local data = source(1)

    derive(function()
        local label = create "TextLabel" { Text = data() }

        cleanup(function()
            label:Destroy()
        end)

        return label
    end)
    ```

## untrack()

Runs a given function where any sources read will not track its reactive scope.

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
