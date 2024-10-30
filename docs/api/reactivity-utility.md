# Reactivity API: Utility

## cleanup()

Runs a callback anytime a scope is reran or destroyed.

- **Type**

    ```luau
    function cleanup(callback: () -> ())
    function cleanup(obj: Destroyable)
    function cleanup(obj: Disconnectable)

    type Destroyable = { destroy: () -> () }
    type Disconnectable = { disconnect: () -> () }
    ```

- **Example**

    ```luau
    local data = source(1)

    effect(function()
        local label = create "TextLabel" { Text = data() }

        cleanup(function()
            label:Destroy()
        end)
    end)
    ```

## untrack()

Runs a given function in a new stable scope.

- **Type**

    ```luau
    function untrack<T>(source: () -> T): T
    ```

- **Details**

    Can be used inside a reactive scope to read from sources you do not want
    tracked by the reactive scope.

- **Example**

    ```luau
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

    ```luau
    function read<T>(value: T | () -> T): T
    ```

## batch()

Runs a given function where any source updates made within the function do not
trigger effects until after the function finishes running.

- **Type**

    ```luau
    function batch(fn: () -> ())
    ```

- **Details**

    Improves performance when an effect depends on multiple sources, and those
    sources need to be updated. Updating those sources inside a batch call will
    only cause the effect to run once after the batch call ends instead of after
    each time a source is updated.

## context()

Creates a new context.

- **Type**

    ```luau
    function context<T>(default: T): Context<T>

    type Context<T> =
        () -> T -- get
        & (T, () -> ()) -> () -- set
    ```

- **Details**

    Calling `context()` returns a new context function.
    Call this function with no arguments to get the context value.
    Call this function with a value and a callback to set a new context with the
    given value.

- **Example**

    ```luau
    local theme = context()

    local function Button()
        print(theme())
    end

    root(function()
        theme("light", function()
             Button() -- prints "light"

            theme("dark", function()
                Button() -- prints "dark"
            end)
        end)
    end)
    ```

--------------------------------------------------------------------------------
