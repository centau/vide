# Reactivity API: Core

<br/>

## source()

Creates a new source state with the given value.

- ### Type

    ```lua
    function source<T>(value: T): (T?) -> T
    ```

- ### Details

    Calling the returned state with no arguments will return its stored value,
    calling with arguments will set a new value.

    Reading from the state from within any reactive scope will cause changes
    to that state to be tracked and anything depending on it to update.

- ### Example

    ```lua
    local count = source(0)

    count() -- 0

    count(count() + 1) -- 1
    ```

--------------------------------------------------------------------------------

## watch()

Runs a callback on state change.

- ### Type

    ```lua
    function watch(callback: () -> ()): Unwatch

    type Unwatch = () -> ()
    ```

- ### Details

    The callback is ran immediately to determine what states are referenced.

    Any time a state referenced in the callback is changed, the callback will be
    reran.

    Also returns a function that when called, stops the watcher immediately.

    > ⚠️ Non yielding.

- ### Example

    ```lua
    local state = wrap(1)

    watch(function()
        print(state.Value)
    end)

    -- prints 1

    state.Value += 1

    -- prints 2
    ```

--------------------------------------------------------------------------------

## derive()

Derives a new state from existing states.

- ### Type

    ```lua
    function derive<T>(source: () -> T): () -> T
    ```

- ### Details

    The derived state will have its value recalculated when any source state it
    derives from is updated.

    Anytime its value is recalculated it is also cached, subsequent calls will
    retun this cached value until it recalculates again.

    Takes a callback that is immediately run to determine what states are being
    referenced.

> ⚠️ Non-yielding.

- ### Example

    ```lua
    local count = wrap(0)
    local text = derive(function() return `count: {count()}` end)

    text() -- "count: 0"

    count(1)

    text() -- "count: 1"
    ```

--------------------------------------------------------------------------------

## indexes()

Maps each index in a table to an object.

- ### Type

    ```lua
    function indexes<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: () -> VI, index: KI) -> VO
    ): Array<VO>

- ### Details

    The transform function is called only ever *once* for each index in the
    source table. The first argument is a state containing the index's value and
    the second argument is just the index.

    Anytime a new index is added, the transform function will be called again for
    that new index.

    Anytime an existing index value changes, the transform function is not rerun,
    instead the passed state for that index will update, causing anything
    depending on it to update too.

    Returns a state containing an array of all objects returned by the transform.

    > ⚠️ Non-yielding.

- ### Example

    The intended purpose of this function is to map each index in a table to
    a UI element.

    ```lua
    type Item = {
        name: string,
        icon: number
    }

    local items = source {} :: () -> Array<Item>

    local displays = indexes(numbers, function(item, i)
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

--------------------------------------------------------------------------------

## values()

Maps each value in a table to an object.

- ### Type

    ```lua
    function values<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: VI, index: () -> KI) -> VO
    ): Array<VO>

- ### Details

    The transform function is called only ever *once* for each value in the
    source table. The first argument is the index's value and
    the second argument is a state containing the index.

    Anytime a new value is added, the transform function will be called again
    for that new value.

    Anytime an existing value's index changes, the transform function is not
    rerun, instead the passed state for that value will update, causing anything
    depending on it to update too.

    Returns a state containing an array of all objects returned by the transform.

    > ⚠️ Non-yielding.

- ### Example

    The intended purpose of this function is to map each value in a table to
    a UI element.

    ```lua
    type Item = {
        name: string,
        icon: number
    }

    local items = source {} :: () -> Array<Item>

    local displays = values(numbers, function(item, i)
        return ItemDisplay {
            Name = item.Name

            Image = "rbxassetid://" .. item.icon,

            LayoutOrder = i
        }
    end)
    ```

- ### Extra

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
