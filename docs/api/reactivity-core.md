# Reactivity API: Core

<br/>

:::warning
Yielding is not allowed in any stable or reactive scope. Strict mode will check
for this.
:::

## root()

Creates and runs a function in a new stable scope.

- **Type**

    ```lua
    function root<T...>(fn: (destroy: () -> ()) -> T...): T...
    ```

- **Details**

    Returns the result of the given function.

    Creates a new stable scope, where creation of effects can be tracked and
    properly disposed of.

    A function to destroy the root is passed into the callback, which will run
    any cleanups and allow derived sources created to garbage collect.

## source()

Creates a new source with the given value.

- **Type**

    ```lua
    function source<T>(value: T): (T?) -> T
    ```

- **Details**

    Calling the returned source with no argument will return its stored value,
    calling with an argument will set a new value.

- **Example**

    ```lua
    local count = source(0)

    count() -- 0

    count(count() + 1) -- 1
    ```

## effect()

Runs a side-effect in a new reactive scope on source update.

- **Type**

    ```lua
    function effect(callback: () -> ())
    ```

- **Details**

    Any time a source referenced in the callback is updated, the callback will
    be reran.

    The callback is ran once immediately.

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

Derives a new source in a new reactive scope from existing sources.

- **Type**

    ```lua
    function derive<T>(source: () -> T): () -> T
    ```

- **Details**

    The derived source will have its value recalculated when any source source
    it derives from is updated.

    Anytime its value is recalculated it is also cached, subsequent calls will
    retun this cached value until it recalculates again.

    The callback is ran once immediately.

- **Example**

    ```lua
    local count = source(0)
    local text = derive(function() return `count: {count()}` end)

    text() -- "count: 0"

    count(1)

    text() -- "count: 1"
    ```

--------------------------------------------------------------------------------
