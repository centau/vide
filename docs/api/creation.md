# Element Creation

## create()

Creates a new UI element, applying any given properties.

- **Type**

    ```luau
    function create(class: string): (Properties) -> Instance
    function create(instance: Instance): (Properties) -> Instance

    type Properties = Map<string|number, unknown>
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
      - **value is function:** create effect to update children
      - **value is instance:** set instance as child

- **Example**

    Basic element creation.

    ```luau
    local frame = create "TextButton" {
        Name = "Button",
        Size = UDim2.fromOffset(200, 160),

        Activated = function()
            print "clicked"
        end,

        create "UICorner" {}
    }
    ```

## action()

Creates a special object that can be passed to `create()` to invoke custom
actions on instances.

- **Type**

    ```luau
    function action((Instance) -> (), priority: number = 1): Action
    ```

- **Details**

    When passed to `create()`, the function is called with the instance being
    created as the only argument. Actions take precedence over property and
    child assignments.

    A priority can be optionally specified to ensure certain actions run after
    other actions. Lower priority values are ran first.

- **Example**

    An action to listen to changed properties:

    ```luau
    local function changed(property: string, fn: (new) -> ())
        return action(function(instance)
            local cn = instance:GetPropertyChangedSignal(property):Connect(function()
                fn(instance[property])
            end)

            -- disconnect on scope destruction to allow gc of instance
            cleanup(function()
                cn:Disconnect()
            end)
        end)
    end

    local output = source ""

    create "TextBox" {
        -- will update the output source anytime the text property is changed
        changed("Text", output)
    }
    ```

## changed()

A wrapper for `action()` to listen for property changes.

- **Type**

    ```luau
    function changed(property: string, fn: (unknown) -> ()): Action
    ```

- **Details**

    Will run the given function immediately and whenever the property updates.

    The function is called with the updated property value.

    Runs with an action priority of 1.

## mount() <Badge type="info" text="STABLE"><a href="/vide/api/reactivity-core#Scopes">STABLE</a></Badge>

Runs a function in a new stable scope and optionally applies its result to a
target instance.

- **Type**
  
    ```luau
    function mount<T>(component: () -> T, target: Instance?): () -> ()
    ```

- **Details**

    This is a utility for `root()` when parenting a component to an existing
    instance.

    The result of the function is applied to a target in the same way
    properties are using `create()`.

    Returns a function that when called will destroy the stable scope.

- **Example**

    ```luau
    local function App()
        return create "ScreenGui" {
            create "TextLabel" { Text = "Vide" }
        }
    end

    local destroy = mount(App, game.StarterGui)
    ```
