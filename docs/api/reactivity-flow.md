# Reactivity API: Control Flow

<br/>

## switch()

Changes object based on a source and a mapping table.

- **Type**

    ```lua
    function switch<K, V>(source: () -> K): (map: Map<K, () -> V>) -> V?
    ```

- **Details**

    The mapped function is ran in a new reactive scope that is destroyed when
    the source changes and maps to a different function.

    ::: warning
    Mapped functions cannot yield.
    :::

- **Example**

    ```lua
    local logged = source(false)

    local button = switch(logged) {
        [true] = function()
            return Button { Text = "Log out", Toggle = logged }
        end,

        [false] = function()
            return Button { Text = "Log in",  Toggle = logged }
        end
    }
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
