# Reactivity API: Utility

<br/>

## isState()

Determines if a given value is a state object or not.

### Type

```lua
function isState(value: unknown): boolean
```

### Example

```lua
local value = wrap()

print(isState(value)) -- true

value = 0

print(isState(value)) -- false
```

-------------------------------------------------------------------

<br/>

## unwrap()

Unwraps a state and returns its stored value.

### Type

```lua
function unwrap<T>(value: T | State<T>): T
```

### Details

If given a state, the state's stored value will be returned.

Unwrapping a state within a derived callback will not trigger updates.

Can be given a non-state value, in which case the same value will just be returned.

### Example

```lua
local state = wrap(1)

print(unwrap(state)) -- 1

print(unwrap(1)) -- 1
```

-------------------------------------------------------------------

<br/>

## readonly()

Creates a new derived state with the same value as the state being derived from.

Used to create readonly states.

### Type

```lua
function readonly<T>(state: State<T>): State<T>
```

### Example

```lua
local count = wrap(1)
local read = readonly(count)

print(read.Value) -- 1

count.Value += 1

print(read.Value) -- 2

read.Value += 1 -- error
```

-------------------------------------------------------------------

<br/>

## mutate()

Mutates a given state's value and updated any derived states.

### Type

```lua
function mutate<T>(value: T | State<T>): T
```

### Details

Since states only update derived states if a new value is set (tables are compared by reference),
this function serves as a way to trigger derived state updates if a state's value is not changed but
instead mutated.

Can also take non-state as an argument.

### Example

```lua
local state = wrap { Count = 1 }

local derived = derive(function()
    return state.Value.Count
end)

mutate(state, function(value)
    value.Count += 1
end)

print(derived.Value) -- 2
```

<details><summary>Motivation for this function</summary>

```lua
local state = wrap { Count = 1 }

local derived = derive(function()
    return state.Value.Count
end)

state.Value.Count += 1

print(derived.Value) -- still 1 because `state.Value` was never set with a new value so change wasn't detected

local value = state.Value
value.Count += 1
state.Value = value

print(derived.Value) -- still 1 because although `state.Value` was set, when the new value set was compared,
-- it was still the same as the previous (tables are compared by reference not their contents)
-- and so no update was made
```

</details>

-------------------------------------------------------------------
