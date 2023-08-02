------------------------------------------------------------------------------------------
-- vide/derive.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
local create = graph.create
local get = graph.get
local capture_and_link = graph.capture_and_link

local function derive<T>(fn: () -> T): () -> T
    local node = create((nil :: any) :: T)

    node.cache = capture_and_link(node, fn)

    return function()
        return get(node)
    end
end

return derive
