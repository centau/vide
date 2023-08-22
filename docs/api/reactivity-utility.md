# Reactivity API: Utility

## cleanup()

Runs a callback anytime a function scope is re-ran.

- **Type**

    ```lua
    function cleanup(callback: () -> ())
    ```

- **Details**

    The primary purpose of this function is to provide a means of cleaning up
    side effects caused by source updates and `watch()` updates.

    The stack is inspected to find the function that calls `cleanup()`. The
    callback passed is called anytime the caller is re-ran, and when the caller
    finally garbage collects.

    ::: warning
    Only one `cleanup()` call is allowed per function scope.
    :::

- **Example**

    ```lua
    local data = source(1)

    watch(function()
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

Gets the value of a source without reactively tracking it.

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
