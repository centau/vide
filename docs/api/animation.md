# Animation API

<br/>

## spring()

Returns a new state with an animated value of the original.

### Type

```lua
function spring<T>(state: State<T>, period: number, dampingRatio: number = 1): State<T>
```

### Details

The output state's value is updated every frame based on the current input state's value.

The change is physically simulated according to a [spring](https://en.wikipedia.org/wiki/Simple_harmonic_motion).

`period` is the amount of time in seconds it takes for the spring to complete one full cycle

`dampingRatio` is relared to the amount of resistant force applied to the spring.

- \>1 = Overdamped (Not currently supported)
- 1 = Critically damped
- <1 = Underdamped
- 0 = Undamped

Velocity is conserved between input state updates for smooth animation.

### Example

```lua
local state = wrap(1)

local springed = spring(state, 1, 1)
```

<details><summary>Example of an animated counter</summary>

```lua
local count = wrap(1000)

local function Counter(props)
    local tweenedCount = spring(count, 0.5, 1)

    return create("TextLabel") {
        Text = "Count: " .. tweenedCount
    }
end
```

</details>

-------------------------------------------------------------------
