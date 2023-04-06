------------------------------------------------------------------------------------------
-- vide/wrapped.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)

return graph.wrapped
