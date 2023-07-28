------------------------------------------------------------------------------------------
-- vide/derive.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
type Unwrapper = graph.Unwrapper
local create = graph.create
local captureAndLink = graph.captureAndLink

local function derive<T>(deriveValue: (Unwrapper) -> T, cleanup: (T) -> ()?): State<T>
    local node = create((nil :: any) :: T)
    
    if cleanup then
        local fn = deriveValue
        local last: T? = nil
        deriveValue = function(from)
            if last ~= nil then cleanup(last) end
            last = fn(from)
            return last :: T
        end 
    end

    local value: T = captureAndLink(node, deriveValue)
    rawset(node, "__cache", value)

    return node :: State<T>
end

return derive
