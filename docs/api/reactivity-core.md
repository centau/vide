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

Runs a callback on source update.

- **Type**

    ```lua
    function effect(source: () -> ()): Uneffect

    type Uneffect = () -> ()
    ```

- **Details**

    The source callback is ran immediately to determine what states are
    referenced.

    Any time a source referenced in the callback is changed, the callback will
    be reran.

    Also returns a function that when called, stops the effecter immediately.

    ::: warning
    `source()` cannot yield.
    :::

- **Example**

    ```lua
    local state = source(1)

    effect(function()
        print(state())
    end)

    -- prints 1

    state(state() + 1)

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

## indexes()

Maps each index in a table source to an object.

- **Type**

    ```lua
    function indexes<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: () -> VI, index: KI) -> VO
    ): Array<VO>

- **Details**

    The transform function is called only ever *once* for each index in the
    source table. The first argument is a source containing the index's value
    and the second argument is just the index.

    Anytime a new index is added, the transform function will be called again
    for that new index.

    Anytime an existing index value changes, the transform function is not rerun,
    instead the source value for that index will update, causing anything
    depending on it to update too.

    Returns a state containing an array of all objects returned by the
    transform.

    ::: warning
    `transform()` cannot yield.
    :::

- **Example**

    The intended purpose of this function is to map each index in a table to
    a UI element.

    ```lua
    type Item = {
        name: string,
        icon: number
    }

    local items = source {} :: () -> Array<Item>

    local displays = indexes(items, function(item, i)
        return ItemDisplay {
            Name = function()
                return item().name
            end,

            Image = function()
                return "rbxassetid://" .. item().icon
            end,

            LayoutOrder = i
        }
    end)
    ```

## values()

Maps each value in a table source to an object.

- **Type**

    ```lua
    function values<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: VI, index: () -> KI) -> VO
    ): Array<VO>

- **Details**

    The transform function is called only ever *once* for each value in the
    source table. The first argument is the index's value and
    the second argument is a source containing the index.

    Anytime a new value is added, the transform function will be called again
    for that new value.

    Anytime an existing value's index changes, the transform function is not
    rerun, instead the source index for that value will update, causing anything
    depending on it to update too.

    Returns a state containing an array of all objects returned by the
    transform.

    ::: warning
    `transform()` cannot yield.
    :::

    ::: warning
    Having primitive values in the source table can cause unexpected behavior,
    as duplicate primitives can result in multiple index sources being bound
    to the same UI element.
    :::

- **Example**

    The intended purpose of this function is to map each value in a table to
    a UI element.

    ```lua
    type Item = {
        name: string,
        icon: number
    }

    local items = source {} :: () -> Array<Item>

    local displays = values(items, function(item, i)
        return ItemDisplay {
            Name = item.Name

            Image = "rbxassetid://" .. item.icon,

            LayoutOrder = i
        }
    end)
    ```

- **Extra**

    When should you use `indexes()` and `values()`?

    `values()` should be used when you have a fixed set of objects where the
    same objects can be re-arranged in the source table. It maps a value to a
    UI element.

    e.g.
    - List of all players.
    - Inventory of items.
    - Chat message history.
    - Toast notifications.

    `indexes()` should be used in other cases, especially when your source table
    has primitive value. It maps an index to a UI element.

    e.g.
    - List of character or weapon stats.

    In most cases, both functions will appear to have the same behavior.
    The main difference is performance, picking the right function to use can
    result in less property updates and less re-renders.

--------------------------------------------------------------------------------
