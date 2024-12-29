local action = require "./action"()
local cleanup = require "./cleanup"

local function changed<T>(property: string, callback: (T) -> ())
    return action(function(instance)
        local con = instance:GetPropertyChangedSignal(property):Connect(function()
            callback((instance :: any)[property])
        end)

        cleanup(function()
            con:Disconnect()
        end)

        callback((instance :: any)[property])
    end)
end

return changed
