------------------------------------------------------------------------------------------
-- vide/Created.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local Types = require(script.Parent.Types)

local Created = {
    priority = 3,
    run = function(instance: Instance, callback: (Instance) -> ())
        callback(instance)
    end
} :: Types.Symbol<(Instance) -> ()>

return Created :: unknown
