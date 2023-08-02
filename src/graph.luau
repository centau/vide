if not game then script = (require :: any) "test/wrap-require" end

local flags = require(script.Parent.flags)

export type Node<T> = {
    cache: T,
    derive: () -> T,
    effects:  { [(unknown) -> ()]: unknown }, -- weak values
    children: { Node<T> } | false -- weak values
}

local reff = false
local refs = {} :: { Node<unknown> }

local WEAK_VALUES_RESIZABLE = { __mode = "vs" }
local EVALUATION_ERR = "error while evaluating node:\n\n"

setmetatable(refs :: any, WEAK_VALUES_RESIZABLE)

local check_for_yield do
    local t = { __mode = "kv" }
    setmetatable(t, t)

    check_for_yield = function<T..., U...>(fn: (T...) -> (), ...: any)
        local args = { ... }
        t.__unm = function()
            fn(unpack(args))
        end
        local ok, err = pcall(function()
            return -t :: any
        end)

        if not ok then
            if err == "attempt to yield across metamethod/C-call boundary" or err == "thread is not yieldable" then
                error(EVALUATION_ERR .. "cannot yield when deriving node in watcher", 3)
            else
                error(EVALUATION_ERR..err, 3)
            end
        end
    end
end

local function set_effect<T>(node: Node<unknown>, fn: (T) -> (), key: T)
    node.effects[fn :: () -> ()] = key
end

local function run_effects(node: Node<unknown>)
    for effect, key in next, node.effects do
        if flags.strict then effect(key) end
        effect(key)
    end 
end

-- retrieves a node's cached value
-- recalculates value if an ancestor was updated
local function get<T>(node: Node<T>): T
    if reff then table.insert(refs, node) end
    return node.cache
end

local function set_child(parent: Node<unknown>, child: Node<unknown>)
    if parent.children then
        table.insert(parent.children, child)    
    else
        parent.children = { child }
        setmetatable(parent.children :: any, WEAK_VALUES_RESIZABLE)
    end
end

-- runs node effects, recalculates descendants and runs descendant effects
local function update(node: Node<unknown>)
    run_effects(node)
    if node.children then
        for _, child in node.children do
            if flags.strict then check_for_yield(child.derive) end
            child.cache = child.derive()
            update(child)
        end
    end
end

-- sets a node's cached value and updates all descendants
local function set<T>(node: Node<T>, value: T)
    node.cache = value
    update(node)
end

-- links two nodes as parent-child with a function to compute a new value for child
local function link<T>(parent: Node<unknown>, child: Node<T>, derive: () -> T)
    child.derive = derive
    set_child(parent, child)
end

-- detect what nodes were referenced in the given callback and returns them in an array
local function capture<T, U>(fn: (U?) -> T, arg: U?): ({ Node<unknown> }, T)
    if flags.strict then check_for_yield(fn, arg) end

    table.clear(refs)
    reff = true

    local ok: boolean, result: T|string
    
    if arg == nil then
        ok, result = pcall(fn)
    else
        ok, result = pcall(fn, arg)
    end

    reff = false

    if not ok then error("error while detecting watcher: " .. result :: string, 0) end

    return refs, result :: T
end

-- captures and links any detected nodes
local function capture_and_link<T>(child: Node<T>, fn: () -> T): T
    local nodes, value = capture(fn, nil)

    child.derive = fn
    for _, parent: Node<unknown> in next, nodes do
        set_child(parent, child)
    end

    return value :: T
end

local function create<T>(value: T): (Node<T>, () -> T)
    local node = {
        cache = value,
        derive  = function() return nil :: any end,
        effects = setmetatable({}, WEAK_VALUES_RESIZABLE) :: any,
        children = false :: false
    }

    local function get_value()
        return get(node)
    end

    return node, get_value
end

return table.freeze {
    set_effect = set_effect,
    get = get,
    set = set,
    link = link,
    capture = capture,
    capture_and_link = capture_and_link,
    create = create :: (<T>(value: T) -> (Node<T>, () -> T)) & (<T>() -> (Node<T>, () -> T)),
}
