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

## map()

Maps each value in a table state to a new table state.

- ### Type

    ```lua
    function map<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: () -> VI, index: KI) -> VO
    ): Map<KI, VO>

- ### Details

    The transform function is called only ever *once* for each index in the
    source table. The first argument is a state containing the index's value and
    the second argument is just the index.

    Anytime a new index is added, the transform function will be called again for
    that new index.

    Anytime an existing index changes, the transform function is not rerun,
    instead the passed state for that index will update, causing anything
    depending on it to update too.

    Returns a state containing the mapped key-value pairs.

    > ⚠️ Non-yielding.

- ### Example

    ```lua
    type Item = {
        name: string,
        icon: number
    }

    local items = source {} :: () -> Array<Item>

    local displays = map(numbers, function(item, i)
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
