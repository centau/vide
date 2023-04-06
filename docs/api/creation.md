# Element Creation API

<br/>

## create()

Creates a new UI element, applying any given properties.

### Type

```lua
function create(classNameOrInstance: string | Instance): (properties: Map<string, any>) -> Instance
```

### Details

The function can take either a `string` or an `Instance` as its first argument.

- If given a `string`, a new instance with the string class name will be created with default properties already applied.
- If given an `Instance`, a new instance that is a clone of the given instance will be created.

This returns another function that is used to apply any properties to the new instance.

### Example

```lua
local frame = create("Frame") {
    Name = "NewFrame",
    Position = UDim2.fromScale(1, 0)
}

-- creates a clone of `frame` with new properties applied.
local frame2 = create(frame) {
    Size = UDim2.fromOffset(50, 100)
}
```

-------------------------------------------------------------------

<br/>

## apply()

Applies any given properties to a given instance.

### Type

```lua
function apply(instance: Instance): (properties: Map<string, any>) -> Instance
```

### Details

Applies properties in the same manner as `create` for already existing existances.

Can use symbols and bind state just like `create`.

### Example

```lua
local frame = Instance.new("Frame")

apply(frame) {
    Position = UDim2.fromScale(1, 0)
}
```

-------------------------------------------------------------------

<br/>

## Layout

Symbol used to pass layout properties to elements.

### Type

```lua
type Layout = Symbol

type LayoutProps = {
    [Symbol] = {
        -- These are all properties considered to be "layout properties"
        AnchorPoint: Prop<Vector2>?;
        LayoutOrder: Prop<number>?;
        Position: Prop<UDim2>?;
        Rotation: Prop<number>?;
        Size: Prop<UDim2>?;
        SizeConstraint: Prop<Enum.SizeConstraint>?;
        Visible: Prop<boolean>?;
        ZIndex: Prop<number>?; 
    }
}

type Prop<T> = T | State<T>
```

### Details

The primary purpose of this symbol is to enable easy passthrough of layout properties
through user-defined component hierarchies.

It is recommended to only set layout properties using the `Layout` symbol when using
your own components.

### Example

```lua
local function BlackFrame(props)
    return create("Frame") {
        BackgroundColor3 = Color3.new(0, 0, 0),
        [Layout] = props[Layout]
    }
end

BlackFrame {
    [Layout] = {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(100, 50)
    }
}
```

-------------------------------------------------------------------

<br/>

## Children

Symbol used to pass child instances to elements.

### Type

```lua
type Children = Symbol

type ChildrenProps = {
    [Symbol] = ChildrenProp
}

type ChildrenProp = Prop<Instance> | Array<ChildrenProp>
```

### Details

This symbol is flexible in the way that children can be passed in the form of nested arrays.

Children can also be assigned using a state binding.

### Example

```lua
create("Frame") {
    -- all of the below are valid methods of assigning children
    [Children] = create("TextLabel") {},

    [Children] = {
        create("TextLabel") {},
        create("TextLabel") {},
    },

    [Children] = {
        create("TextLabel") {},
        {
            create("TextLabel") {},
        }
    }
}
```

-------------------------------------------------------------------

<br/>

## Event

Symbol used to connect callbacks to instance events.

### Type

```lua
type Event = Map<string, Symbol>

type EventProps = {
    [Symbol] = Prop<(...unknown) -> ()>
}
```

### Details

The `Event` symbol can be indexed to get symbols to connect to specific events.

Event parameters are passed into the callback.

When callbacks are connected by binding to a state,
connections are automatically disconnected when the state changes.

### Example

```lua
create("TextButton") {
    [Event.Activated] = function()
        print("Clicked")
    end
}
```

-------------------------------------------------------------------

<br/>

## Changed

Symbol used to connect callbacks to instance property changed events.

### Type

```lua
type Changed = Map<string, Symbol>

type ChangedProps = {
    [Symbol] = Prop<(...unknown) -> ()>
}
```

### Details

The `Changed` symbol can be indexed to get symbols to connect to specific events just like `Event`.

Event parameters are passed into the callback.

When callbacks are connected by binding to a state,
connections are automatically disconnected when the state changes.

### Example

```lua
create("TextBox") {
    [Changed.Text] = function()
        print("New text entered")
    end
}
```

-------------------------------------------------------------------

<br/>

## Bind

Symbol used to bind states to instance properties.

### Type

```lua
type Bind = Map<string, Symbol>

type BindProps = {
    [Symbol] = State<any>
}
```

### Details

The `Bind` symbol can be indexed to bind specific properties just like `Event`.

Sets the given state value to the instance property value immediately after instance creation.

When an instance property is changed, the value of the given state will automatically
be set to the new property. Effectively a shorthand for connecting a property changed event
to set state values.

### Example

```lua
local text = wrap()

local box = create("TextBox") {
    [Bind.Text] = text
}

box.Text = "New text"
print(text.Value) -- "New text"
```

-------------------------------------------------------------------

<br/>

## Created

Symbol used to run a callback once immediately after instance creation.

### Type

```lua
type Created = Symbol

type CreatedProps = {
    [Symbol] = (Instance) -> ()
}
```

### Details

The instance being defined with the `Created` symbol is passed as the first
argument to the callback.

### Example

```lua
local frame

create("Frame") {
    Name = "Background",
    [Created] = function(instance)
        frame = instance
    end
}

print(frame.Name) -- "Background"
```

-------------------------------------------------------------------
