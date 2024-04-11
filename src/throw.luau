if not game then script = require "test/relative-string" end

local trace = require(script.Parent.trace)

local function throw(msg): any
    error(msg, trace() - 1)
end

return throw
