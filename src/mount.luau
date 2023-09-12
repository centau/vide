if not game then script = require "test/relative-string" end

local root = require(script.Parent.root)
local apply = require(script.Parent.apply)

local function mount<T>(app: () -> T, target: Instance?): () -> ()
    local _, destroy = root(function()
        local result = app()
        if target then apply(target, { result }) end
        return nil
    end)

    return destroy
end

return mount
