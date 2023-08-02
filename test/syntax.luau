local vide = require "src/init"
local source = vide.source
local derive = vide.derive
local map = vide.map
local create = vide.create

type Action<T> = {
    type: T,
    priority: number,
    callback: (Instance) -> ()
}

local function processor(priority: number, fn: (Instance) -> ()): Action<any>

end

local function Changed(property: string, callback: () -> ())
    return processor(1, function(instance)
        instance:GetPropertyChangedSignal(property):Connect(callback)
    end) :: Action<"Changed">
end

local function Cleanup(t: {})

end

function TextInput(p: {
    OnInput: Action<"Changed">
})
    create "TextBox" {
        Text = "test",

        Changed("Text", function()

        end),

        Cleanup {

        },

        create("Frame") {}
    }
end
