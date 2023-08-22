# Element Creation API

<br/>

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


    - If a table index is a string:
      - If its value is a table then it will attempt to perform aggregate
        initialization.
      - If its value is a function then it will either bind that property to
        the function or connect it if the property type is a `RBXScriptSignal`.
      - If the value is not a function then the property will be set to that
        value.
    - If a table index is a number:
      - If its value is a table then that table will be recursively 
      - processed just like the outer table.
      - If its value is a function then it will parent and bind any instances
        returned by that function as children.
      - If its value is an instance then it will be parented to the instance.

- **Example**

    Basic element creation.

    ```lua
    local frame = create "Frame" {
        Name = "NewFrame",
        Position = UDim2.fromScale(1, 0)
    }
    ```

    A component using property nesting/grouping.

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
            instance:GetPropertyChangedSignal("property"):Connect(function()
                callback(instance[property])
            end)
        end)
    end

    local output = source ""

    create "TextBox" {
        -- will update the `output` source anytime the text property is changed
        changed("Text", output)
    }
    ```
