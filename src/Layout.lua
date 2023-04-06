------------------------------------------------------------------------------------------
-- vide/Layout.lua
------------------------------------------------------------------------------------------

if not game then script = (require :: any) "test/wrap-require" end

local graph = require(script.Parent.graph)
local wrapped = graph.wrapped

local throw = require(script.Parent.throw)
local bind = require(script.Parent.bind)
local flags = require(script.Parent.flags)
local Types = require(script.Parent.Types)

local layoutProperties = {
    Parent = true,
    AnchorPoint = true,
    LayoutOrder = true,
    Position = true,
    Rotation = true,
    Size = true,
    SizeConstraint = true,
    Visible = true,
    ZIndex = true
}

local function setLayout(instance: Instance, properties: { [string]: unknown })
    for property, value in next, properties do
        if flags.strict and not layoutProperties[property] then
            throw(`{ property } is not a valid layout property`)
        end

        if wrapped(value) then
            bind.property(value :: graph.State<unknown>, instance, property)
        else
            (instance :: any)[property] = value
        end
    end
end

local Layout = {
    priority = 1,
    run = setLayout
} :: Types.Symbol<{ [string]: unknown }>

return Layout :: unknown
