------------------------------------------------------------------------------------------
-- vide/apply.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local applyProperties = require(script.Parent.applyProperties)

local function apply<T>(instance: T & Instance)
    return function(properties: { [any]: unknown }): T
        return applyProperties(instance, properties)
    end
end

return apply
