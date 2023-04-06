------------------------------------------------------------------------------------------
-- vide/Children.lua
------------------------------------------------------------------------------------------

if not game then
    script = (require :: any) "test/wrap-require"
    typeof = require "test/mock".typeof
end

local graph = require(script.Parent.graph)
local wrapped = graph.wrapped

local throw = require(script.Parent.throw)
local bind = require(script.Parent.bind)
local Types = require(script.Parent.Types)

type Children = Types.Children

local function setChildren(instance: Instance, children: Children)
    if typeof(children) == "Instance" then
        if children.Parent then throw(`Cannot parent instance { instance.Name }, instance already parented`) end
        children.Parent = instance
    elseif wrapped(children) then
        bind.children(children :: any, instance )
    elseif type(children) == "table" then
        for _, child: Children in next, children do
            setChildren(instance, child)
        end
    else
        throw(`Cannot parent non-instance { typeof(children) }`)
    end
end

local Children = {
    priority = 1,
    run = setChildren
} :: Types.Symbol<Children>

return Children :: unknown
