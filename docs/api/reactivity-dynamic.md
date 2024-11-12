# Reactivity: Dynamic Scoping

Dynamic scoping is the act of creating and destroying new scopes in response to
source updates. Vide provides functions for some common use-cases to do this.

## show() <Badge type="tip" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">REACTIVE</a></Badge>

Shows a component if the source is truthy. Optionally shows a fallback component
if the source is falsey.

- **Type**

    ```luau
    function show<T>(source: () -> unknown, component: () -> T): () -> T?
    function show<T, U>(source: () -> unknown, component: () -> T, fallback: () -> U): () -> T | U
    ```

- **Details**

    Creates a reactive scope internally to detect source updates.

    The component is run in a stable scope when truthy, otherwise the stable
    scope is destroyed.

    Returns a source holding an instance of the currently shown component or
    `nil` if no component is currently shown.

## switch() <Badge type="tip" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">REACTIVE</a></Badge>

Shows one of a set of components depending on a source and a mapping table.

- **Type**

    ```luau
    function switch<K, V>(source: () -> K): (map: Map<K, () -> V>): () -> V?
    ```

- **Details**

    Creates a reactive scope internally to detect source updates.

    When the source updates, its value is inputted into a map to get a component
    constructor. This component is then run in a stable scope. The previous
    stable scope is destroyed.

    Returns a source holding an instance of the currently shown component or
    `nil` if no component is currently shown.

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

## indexes() <Badge type="tip" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">REACTIVE</a></Badge>

Shows a component for each index in a table.

- **Type**

    ```luau
    function indexes<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: () -> VI, index: KI) -> VO
    ): Array<VO>

- **Details**

    Creates a reactive scope internally to detect source updates.

    When the source table updates, a component is generated for each index in
    the table.

    - For any added index, the `transform` function is run in a new stable
      scope to produce an instance that is cached.
    - For any removed index, the stable scope for that index is destroyed.

    The `transform` function is called with:

    1. A *source containing the index's value*.
    2. The *index itself*.

    Anytime an existing index's value changes, the `transform` function is not
    rerun, instead, that index's corresponding source is updated with the new
    value.

    Returns a source holding an array of instances currently shown.

- **Example**

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

## values() <Badge type="tip" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">REACTIVE</a></Badge>

Shows a component for each value in a table.

- **Type**

    ```luau
    function values<KI, VI, VO>(
        source: () -> Map<KI, VI>,
        transform: (value: VI, index: () -> KI) -> VO
    ): Array<VO>

- **Details**

    Operates with the same idea as `indexes()`, but applied to values instead of
    indexes.

    Creates a reactive scope internally to detect source updates.

    When the source table updates, a component is generated for each value in
    the table.

    - For any added value, the `transform` function is run in a new stable scope
      to produce an instance that is cached.
    - For any removed value, the stable scope for that value is destroyed.
  
    The `transform` function is called with:

    1. The *value itself*.
    2. A *source containing the value's index*.

    Anytime an existing value's index changes, the `transform` function is not
    rerun, instead, that value's corresponding source is updated with the new
    index.

    Returns a source holding an array of instances currently shown.
 
    ::: warning
    Having the same values appear multiple times in the input source table can
    cause unexpected behavior. Strict mode has checks for this.
    :::

- **Example**

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

    In most cases, both functions will produce the same observed result.
    The main difference is performance, picking the right function to use can
    result in less property updates and less re-renders. One case to note is
    that `values()` works nicely when animating re-ordering of instances, since
    the source index can be used to animate a change in position for the UI
    element.

--------------------------------------------------------------------------------
