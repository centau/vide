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
