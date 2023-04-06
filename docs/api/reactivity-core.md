# Reactivity API: Core

<br/>

## wrap()

Wraps and returns any given values with reactive state objects.

### Type

```lua
function wrap<T>(value: T): State<T>
function wrap(value: ...unknown): ...State<any>

type State<T> = {
    Value: T,
    value: T
}
```

### Details

The state object has a single mutable field `.Value`.

Read operations to `.Value` are tracked and write operations can trigger
dependency updates and watchers.

### Example

```lua
local count = wrap(0)

print(count.Value) -- 0

count.Value += 1

print(count.Value) -- 1
```

-------------------------------------------------------------------

<br/>

## derive()

Derives a new reactive state object from an existing state object.

### Type

```lua
function derive<T>(
    (from) -> T,
    cleanup: (value: T) -> ()?
): State<T>

function from<T>(T | State<T>): T
```

### Details

The derived state will have its value recalculated when any state it derives from is updated.

Takes a callback that is immediately run to determine what states are being referenced. Only states referenced in the immediate function scope can trigger updates.

The state object returned by this function is readonly.

Has an optional cleanup parameter which takes a function that is called with the old value any
time the derived state recalculates a value.

An optional utility function is passed as the first argument to the callback, if given a state, the value of the state will be returned (changes to this state still triggers updates unlike `unwrap`), if given a value the value is returned.

> ⚠️ The callback cannot yield.

### Example

```lua
local count = wrap(0)
local text = derive(function() return "Count: "..count.Value end)

print(text.Value) -- "Count: 0"

count.Value += 1

print(text.Value) -- "Count: 1"
```

```lua
local count = wrap(0)
local text = derive(function(from)
    return "Count: "..from(count)
end)
```

A shorthand method for deriving states also exists, following example is equivalent to the above:

```lua
local count = wrap(0)
local text = "Count: "..count -- all binary operators are supported
```

-------------------------------------------------------------------

<br/>

## foreach()

Derives a new state object from an existing state object.
Designed to work specifically with table states.

Also works with non state tables.

### Type

```lua
function foreach<KO, VO>( -- number as first arg
    i: number,
    transform: (key: number) -> (KO, VO),
    cleanup: (KO, VO) -> ()?
): Map<KO, VO>

function foreach<KI, KO, VI, VO>( -- table as first arg
    table: Map<KI, VI>,
    transform: (key: KI, value: VI) -> (KO, VO),
    cleanup: (KO, VO) -> ()?
): Map<KO, VO>

function foreach<KI, KO, VI, VO>( -- state as first arg
    state: State<Map<KI, VI>>,
    transform: (key: KI, value: VI) -> (KO, VO),
    cleanup: (KO, VO) -> ()?
): State<Map<KO, VO>>
```

### Details

When the state being derived from is updated, the derived state will
recompute by applying its transform function to each key-value pair.

Will only be recomputed if the corresponding key differs between updates.

Has an optional cleanup function to cleanup the old key and value.

> ⚠️ The transform function cannot yield.

### Example

```lua
local numbers = wrap { 1, 2, 3 }
local plusOne = foreach(numbers, function(i, v)
    return i, v + 1
end)

print(plusOne.Value) -- { [1]: 2, [2]: 3, [3]: 4 }

-- note that assignment must take place to trigger reactive updates.
-- modifying the value without assignment `numbers.Value[2] = 5` will not trigger updates.
numbers.Value = { 1, 5, 3 }

print(plusOne.Value) -- { [1]: 2, [2]: 6, [3]: 4 }
```

-------------------------------------------------------------------

<br/>

## match()

Derives a new state object from an existing state object.
Similar to switch statements in other languages.

### Type

```lua
function match<K, V>(value: K): (transform: Map<K, V>) -> V
function Match<K, V>(state: State<K>): (transform: Map<K, V>) -> State<V>
```

### Details

When the state being derived from is updated, the derived state will
recompute by using the input value as a key to map to an output value.

### Example

```lua
local state = wrap(true)
local matched = match(state) {
    [true] = 1,
    [false] = 0
}

print(matched.Value) -- 1

state.Value = false

print(matched.Value) -- 0
```

-------------------------------------------------------------------

<br/>

## watch()

Runs a callback on state change.

### Type

```lua
function watch(callback: () -> Cleanup?): Unwatch

type Cleanup = () -> ()
type Unwatch = () -> ()
```

### Details

The callback is ran immediately to determine what states to watch.

Any time a state read in the watch callback is changed, the watcher callback will be deferred
to the end of the resumption cycle and ran.

Only states in the immediate function scope can trigger the watch callback.

Watchers are run *before* UI properties are updated.

The callback can return an optional cleanup function that is run each time the watcher is rerun.

Also returns a function that when called, stops the watcher immediately (also runs cleanup if any was given).

> ⚠️ The callback cannot yield.

### Example

```lua
local state = wrap(1)

watch(function()
    print(state.Value)
end)

-- prints 1

state.Value += 1

-- prints 2
```

-------------------------------------------------------------------
