# Reactivity API: Core

<br/>

## root()

Creates and runs a function in a new reactive scope.

- **Type**

    ```lua
    function root<T>(fn: () -> T): (T, () -> ())
    ```

- **Details**

    Creates a new root reactive scope, where creation and derivations of sources
    can be tracked and properly disposed of.

    Returns the result of the given function.

    Also returns a function to destroy the root, which will run any cleanups
    and allow derived sources created to garbage collect.

    ::: warning
    `fn()` cannot yield.
    :::

## source()

Creates a new source with the given value.

- **Type**

    ```lua
    function source<T>(value: T): (T?) -> T
    ```

- **Details**

    Calling the returned source with no argument will return its stored value,
    calling with an argument will set a new value.

    Reading from the source from within a reactive scope will cause changes
    to that source to be tracked and anything depending on it to update.

- **Example**

    ```lua
    local count = source(0)

    count() -- 0

    count(count() + 1) -- 1
    ```

## effect()

Runs a side-effect on source update.

- **Type**

    ```lua
    function effect(callback: () -> ())
    ```

- **Details**

    The callback is ran immediately.

    Any time a source referenced in the callback is changed, the callback will
    be reran.

    ::: warning
    `callback()` cannot yield.
    :::

- **Example**

    ```lua
    local num = source(1)

    effect(function()
        print(num())
    end)

    -- prints 1

    num(num() + 1)

    -- prints 2
    ```

## derive()

Derives a new source from existing sources.

- **Type**

    ```lua
    function derive<T>(source: () -> T): () -> T
    ```

- **Details**

    The derived source will have its value recalculated when any source source
    it derives from is updated.

    Anytime its value is recalculated it is also cached, subsequent calls will
    retun this cached value until it recalculates again.

    Takes a callback that is immediately run to determine what sources are being
    referenced.

    ::: warning
    `source()` cannot yield.
    :::

- **Example**

    ```lua
    local count = source(0)
    local text = derive(function() return `count: {count()}` end)

    text() -- "count: 0"

    count(1)

    text() -- "count: 1"
    ```

--------------------------------------------------------------------------------
