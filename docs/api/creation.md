# Element Creation API

<br/>

## mount()

Runs a function in a new reactive scope and optionally applies its result to a
target instance.

- **Type**
  
    ```lua
    function mount<T>(component: () -> T, target: Instance?): () -> ()
    ```

- **Details**

    The result of the function is applied to a target in the same way
    properties are using `create()`.

    The function is ran in a new reactive scope, just like
    [root()](reactivity-core.md#root).

    Returns a function that when called will destroy the reactive scope.

- **Example**

    ```lua
    local function App()
        return create "ScreenGui" {
            create "TextLabel" { Text = "Vide" }
        }
    end

    mount(App, game.StarterGui)
    ```

## create()

Creates a new UI element, applying any given properties.

- **Type**

    ```lua
    function create(class: string): (Properties) -> Instance
    function create(instance: Instance): (Properties) -> Instance

    type Properties = Map<string|number, any>
    ```

- **Details**

    The function can take either a `string` or an `Instance` as its first argument.

    - If given a `string`, a new instance with the same class name will be created.
    - If given an `Instance`, a new instance that is a clone of the given instance
    will be created.

    This returns another function that is used to apply any properties to the new
    instance.

- **Property setting rules**

    - **index is string:**
      - **value is function:**
        - **property is event:** connect function as callback
        - **property is not event:** create effect to update property
      - **value is not function:** set property to value
    - **index is number:**
      - **value is action:** run action
      - **value is table:** recurse table
      - **value is functon:** create effect to update children
      - **value is instance:** set instance as child

- **Example**

    Basic element creation.

    ```lua
    local frame = create "Frame" {
        Name = "NewFrame",
        Position = UDim2.fromScale(1, 0)
    }
    ```

    A component using property nesting.

    ```lua
    type Layout = {
        Layout = {
            Position: UDim2?,
            Size: UDim2?,
            AnchorPoint: Vector2?
        }
    }

    type Children = {
        Children = Array<Instance>
    }

    function Background(props: Layout & Children & {
        Color: Color3
    })
        return create "Frame" {
            BackgroundColor3 = props.Color,
            props.Layout,
            props.Children
        }
    end
    ```

## action()

Creates a callback that can be passed to `create()` to invoke custom actions on
instances.

- **Type**

    ```lua
    function action((Instance) -> (), priority: number = 1): Action
    ```

- **Details**

    When passed to `create()`, the given callback is called with the instance
    being created as the only argument. Actions take precedence over property
    and child assignments.

    A priority can be optionally specified to ensure certain actions run after
    other actions. Higher priority numbers are ran after lower priority numbers.

- **Example**

    An action to listen to changed properties:

    ```lua
    local function changed(property: string, callback: (new) -> ())
        return action(function(instance)
            local con - instance:GetPropertyChangedSignal(property):Connect(function()
                callback(instance[property])
            end)

            -- disconnect on reactive scope destruction to allow gc of instance
            cleanup(function()
                con:Disconnect()
            end)
        end)
    end

    local output = source ""

    create "TextBox" {
        -- will update the `output` source anytime the text property is changed
        changed("Text", output)
    }
    ```
