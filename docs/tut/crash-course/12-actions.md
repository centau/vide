# Actions

Actions are special callbacks that you can pass along with properties,
to run some code on an instance receiving them.

```luau
local action = vide.action

create "TextLabel" {
    Text = "test",

    action(function(instance)
        print(instance.Text)
    end)
}

-- will print "test"
```

Actions can be wrapped with functions for reuse. Below is an example of an
action used to listen for property changes:

```luau
local action = vide.action
local source = vide.source
local effect = vide.effect
local cleanup = vide.cleanup

local function changed(property: string, callback: (new) -> ())
    return action(function(instance)
        local connection = instance:GetPropertyChangedSignal(property):Connect(function()
            callback(instance[property])
        end)

        -- remember to clean up the connection when the reactive scope the action
        -- is ran in is destroyed, so the instance can be garbage collected
        cleanup(connection)
    end)
end

local output = source ""

local instance = create "TextBox" {
    changed("Text", output)
}

effect(function()
    print(output())
end)

instance.Text = "foo" -- "foo" will be printed by the effect
```

The source `output` will be updated with the new property value any time it is
changed externally.

# draggable()

Creates an Action that makes a GuiObject draggable using input events (mouse and touch). This helper is intended for reuse across components and does not use Roblox’s deprecated `.Draggable` property.

## Type

```lua
draggable(opts: DraggableOptions?) -> Action
```
DraggableOptions
	
	•	axis: "x" | "y" | "both" (default "both")

Constrains dragging to a single axis or allows free movement.
	
	•	smoothTime: number (optional, default 0)

Enables smoothing/“weight” while dragging. 0 disables smoothing. Practical range: 0.05–0.12.
	
	•	onDragStart: (startPos: UDim2) -> () (optional)

Called when dragging begins. Receives the starting Position.
	
	•	onDrag: (newPos: UDim2) -> () (optional)

Called while dragging. Receives the updated Position.
	
	•	onDragEnd: (endPos: UDim2) -> () (optional)

Called when dragging ends. Receives the final Position.


Supported instances

draggable() must be applied to an instance that:
	•	is a GuiObject (e.g., Frame, TextButton, ImageLabel, ImageButton),
	•	has a writable Position property,
	•	exposes input events such as InputBegan and InputChanged.

If applied to a non-GuiObject, the Action should be treated as a no-op

Example: Basic draggable panel

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("vide"))
local create = vide.create
local mount = vide.mount

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function App()
	return create "ScreenGui" {
		Name = "DraggableExample",
		ResetOnSpawn = false,
		Parent = playerGui,

		create "Frame" {
			Position = UDim2.fromOffset(200, 150),
			Size = UDim2.fromOffset(420, 240),
			BackgroundTransparency = 0.1,

			create "UICorner" { CornerRadius = UDim.new(0, 16) },

			vide.draggable(), -- defaults to axis = "both"

			create "TextLabel" {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(420, 50),
				Text = "Drag this panel",
				TextSize = 20,
			},
		}
	}
end

mount(App, playerGui)
```
