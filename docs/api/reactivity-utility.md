# Reactivity: Utility

## cleanup()

Queues a callback to run when a scope is reran or destroyed.

- **Type**

    ```luau
    function cleanup(v: Function | Disconnectable | Destroyable)

    type Function = () -> ()
    type Destroyable = { destroy: () -> () }
    type Disconnectable = { disconnect: () -> () }
    ```

- **Example**

    ```luau
    local count = source(0)

    local destroy = root(function()
        effect(function()
            count()

            cleanup(function()
                print "cleaned"
            end)
        end)
    end

    -- nothing printed yet
    count(1) -- prints "cleaned"
    count(2) -- prints "cleaned"
    destroy() -- prints "cleaned"
    ```

## untrack() <Badge type="info" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">STABLE</a></Badge>

Runs a function in a new stable scope.

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
    b(1) -- untracked so reactive scope created by derive() does not rerun
    print(sum()) -- 0
    a(1) -- reactive scope created by derive() reruns
    print(sum()) -- 2
    ```

## read()

Utility used to read a value that is either a primitive or a source.

- **Type**

    ```luau
    function read<T>(value: T | () -> T): T
    ```

## batch()

Runs a function where any source updates made within the function do not
trigger effects until after the function ends.

- **Type**

    ```luau
    function batch(fn: () -> ())
    ```

- **Details**

    Improves performance when an effect depends on multiple sources, and those
    sources need to be updated.

- **Example**

    ```luau
    local a = source(0)
    local b = source(0)

    effect(function()
        print(a() + b())
    end)

    -- prints "0"

    batch(function()
        a(1) -- no print
        b(2) -- no print
    end)

    -- prints "3"
    ```

## context() <Badge type="info" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">STABLE</a></Badge>

Creates a new context.

- **Type**

    ```luau
    function context<T>(default: T): Context<T>

    type Context<T> =
        () -> T -- get
        & <U>(T, () -> U) -> U -- set
    ```

- **Details**

    Calling `context()` returns a new context function.
    Call this function with no arguments to get the context value.
    Call this function with a value and a function to create a new context with
    the given value.

    The new context is run under a stable scope.

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

