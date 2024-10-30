# Reactivity API: Control Flow

<br/>

## show()

Shows one of two components depending on an input source.

- **Type**

    ```luau
    function show<T>(source: () -> unknown, component: () -> T): () -> T?
    function show<T, U>(source: () -> unknown, component: () -> T, fallback: () -> U): () -> T | U
    ```

- **Details**

    Returns a source holding an instance of the currently shown component.

    When the input source changes from a falsey to a truthy value, the
    component will be reran under a new stable scope. If it changes from a
    truthy to falsey value, the stable scope the component was created in will
    be destroyed, and the returned source will output `nil`, or a fallback
    component if given.

    The fallback component is also ran under a new stable scope, and destroyed
    when the input source switches back to truthy.

## switch()

Shows one of a set of components depending on an input source and a mapping table.

- **Type**

    ```luau
    function switch<K, V>(source: () -> K): (map: Map<K, () -> V>) -> V?
    ```

- **Details**

    Returns a source holding an instance of the currently shown component.

    When the input source changes, the new value will be used to lookup a given
    mapping table to get a component, which will be ran under a new stable
    scope. If the input source changes, the stable scope the component was
    created in will be destroyed, and a new component created under a new
    stable scope. If no component is found for an input value, the switch will
    output `nil`.

- **Example**

    ```luau
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

    ```luau
    function indexes<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: () -> VI, index: KI) -> VO
    ): Array<VO>

- **Details**

    Returns a source holding an array of instances currently shown.

    When the input source changes, each *index* in the new table is compared with
    the last input table.

    - For any new index, the `transform` function is ran under a new stable
      scope to produce a new instance.
    - For any removed index, the stable scope for that index is destroyed.
    - Unchanged indexes are untouched.

    The transform function is called only ever *once* for each index in the
    source table.

    1. First argument is a *source containing the index's value*.
    2. Second argument is the *index itself*.

    Anytime an existing index's value changes, the transform function is not
    rerun, instead the source value for that index will update, causing anything
    depending on it to update too.

- **Example**

    The intended purpose of this function is to map each index in a table to
    a UI element.

    ```luau
    type Item = {
        name: string,
        icon: number
    }

    local items = source {} :: () -> Array<Item>

    local displays = indexes(items, function(item, i)
        return ItemDisplay {
            Name = function()
                return i .. ": " .. item().name
            end,

            Image = function()
                return "rbxassetid://" .. item().icon
            end,
        }
    end)
    ```

## values()

Maps each value in a table source to an object.

- **Type**

    ```luau
    function values<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: VI, index: () -> KI) -> VO
    ): Array<VO>

- **Details**

    Returns a source holding an array of instances currently shown.

    When the input source changes, each *value* in the new table is compared with
    the last input table. Similar to `indexes()` but for values instead of indexes.

    - For any new value, the `transform` function is ran under a new stable
      scope to produce a new instance.
    - For any removed value, the stable scope for that value is destroyed.
    - Unchanged values are untouched.

    The transform function is only ever called *once* for each value in the
    source table.

    1. First argument is the *value itself*.
    2. Second argument is a *source containing the value's index*.

    Anytime an existing value's index changes, the transform function is not
    rerun, instead the source index for that value will update, causing anything
    depending on it to update too.

    ::: warning
    Having primitive values in the input source table can cause unexpected
    behavior, as duplicate values can result in multiple tranforms being ran for
    a single value, meaning there can be multiple source indexes bound to the
    same UI element. Strict mode has checks for this.
    :::

- **Example**

    The intended purpose of this function is to map each value in a table to
    a UI element.

    ```luau
    type Item = {
        name: string,
        icon: number
    }

    local items = source {} :: () -> Array<Item>

    local displays = values(items, function(item, i)
        return ItemDisplay {
            Name = function()
                return i() .. ": " .. item.Name
            end

            Image = "rbxassetid://" .. item.icon,
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
    has primitive values. It maps an index to a UI element.

    e.g.
    - List of character or weapon stats.

    In most cases, both functions will appear to have the same behavior.
    The main difference is performance, picking the right function to use can
    result in less property updates and less re-renders. One case to note is
    that `values()` works nicely when animating re-ordering of instances, since
    the value is not destroyed when indexes are changed, and the source index
    can be used to animate a change in position for the UI element.

--------------------------------------------------------------------------------
