# Types API

<br/>

## State\<T>

A type representing a Vide state object.

### Type

```lua
type State<T> = {
    Value: T,
    value: T
}
```

### Example

```lua
local state: State<number> = wrap(1)

local derived: State<string> = "Count: " .. state
```

-------------------------------------------------------------------

<br/>

## Prop\<T>

A utility type representing a union of a value and a state.

### Type

```lua
type Prop<T> = T | State<T>
```

### Example

```lua
type BackgroundProps = {
    Position: Prop<UDim2>,
    Size: Prop<UDim2>
}
local function Background(props: { Position: Prop<UDim2> })
    return create("Frame") {
        Position = props.Position
        Size = props.Size
    }
end
```

-------------------------------------------------------------------
