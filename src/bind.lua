--------------------------------------------------------------------------------------------------------------
-- vide/bind.lua
--------------------------------------------------------------------------------------------------------------

local warn = warn -- todo

if not game then
    script = (require :: any) "test/wrap-require"
    warn = print
end


local graph = require(script.Parent.graph)
type State<T> = graph.State<T>
local get = graph.get
local setEffect = graph.setEffect

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

local hold: { Instance? } = {}
local weak: { Instance? } = setmetatable({}, { __mode = "v" }) :: any 
local bindcount = 0

local srcs do
    local src1 = debug.info(1, "s")
    local srctrunc = string.sub(src1, 1, #src1-4)

    srcs = {
        src1,
        srctrunc .. "applyProperties",
        srctrunc .. "create",
        srctrunc .. "apply"
    }
end

local function traceback() -- ensures trace begins outside of any vide library file
    local s = 1
    repeat
        s += 1
        local src = debug.info(s, "s")
    until not table.find(srcs, src)
    return debug.traceback("", s)
end

function setup(state: State<any>, instance: Instance, updateInstance: (Instance) -> ())
    if flags.strict then
        local fn = updateInstance
        local trace = traceback()
        updateInstance = function(instance)
            local ok, err: string? = pcall(fn, instance)
            if not ok then warn(`error occured updating state binding:\n{err}\nset from:{trace}`) end
        end
    end

    updateInstance(instance)
    setEffect(state, updateInstance, instance)

    bindcount += 1
    local key = bindcount
    
    weak[key] = instance

    local function ref()
        local _ = state -- prevent gc of state while instance exists
        local instance = weak[key] :: Instance
        hold[key] = instance.Parent and instance or nil -- prevent gc of instance while parented
    end

    ref()
    instance:GetPropertyChangedSignal("Parent"):Connect(ref)
end

local function bindProperty(state: State<unknown>, instance_STRONG: Instance, property: string)
    setup(state, instance_STRONG, function(instance)
        (instance :: any)[property] = get(state)
    end)
end

local function bindParent(state: State<Instance?>, instance_STRONG)
    instance_STRONG.Destroying:Connect(function()
        instance_STRONG = nil :: any -- allow gc when destroyed
    end)
    setup(state, instance_STRONG, function(instance)
        local _ = instance_STRONG -- state will strongly reference instance when parent is bound
        instance.Parent = get(state)     
    end)
end

local function bindChildren(state: State<{ Instance }?>, parent_STRONG: Instance)
    local currentChildrenSet: { [Instance]: true } = {} -- cache of all children parented before update
    local newChildrenSet: { [Instance]: true } = {} -- cache of all children parented after update

    setup(state, parent_STRONG, function(parent)
        local newChildren = get(state) -- all (and only) children that should be parented after this update
        if newChildren and type(newChildren) ~= "table" then
            throw(`Cannot parent instance of type { type(newChildren) } `)
        end

        if newChildren then
            for _, child in next, newChildren do
                newChildrenSet[child] = true -- record child set from this update
                if not currentChildrenSet[child] then
                    child.Parent = parent -- if child wasn't already parented then parent it
                else 
                    currentChildrenSet[child] = nil -- remove child from cache if it was already in cache
                end
            end
        end

        for child in next, currentChildrenSet do
            child.Parent = nil -- unparent all children that weren't in the new children set
        end

        table.clear(currentChildrenSet) -- clear cache, preserve capacity
        currentChildrenSet, newChildrenSet = newChildrenSet, currentChildrenSet
    end)
end

local function bindEvent(state: State<() -> ()?>, instance_STRONG: Instance, event: RBXScriptSignal)
    local current: RBXScriptConnection? = nil
    setup(state, instance_STRONG, function(instance) 
        if current then
            current:Disconnect()
            current = nil
        end
        local listener = get(state)
        if listener then
            current = event:Connect(listener)
        end
    end)
end

return {
    property = bindProperty,
    parent = bindParent,
    children = bindChildren,
    event = bindEvent
}
