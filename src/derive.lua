------------------------------------------------------------------------------------------
-- vide/derive.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
local create = graph.create
local get = graph.get
local capture_and_link = graph.capture_and_link

local function derive<T>(fn: () -> T, cleanup: (T) -> ()?): () -> T
    local node = create((nil :: any) :: T)
    
    if cleanup then
        local f = fn
        local last: T? = nil
        fn = function()
            if last ~= nil then cleanup(last) end
            last = f()
            return last :: T
        end 
    end

    node.cache = capture_and_link(node, fn)

    return function()
        return get(node)
    end
end

return derive
