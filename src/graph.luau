if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)
local on_gc = require(script.Parent.on_gc)()

export type Node<T> = {
    cache: T,
    effect:  () -> (),
    children: { Node<T> } | false, -- weak values
    cleanups: { () -> () } | false
}

-- flag used to detect when node reference capturing is active
local reff = false
-- array of all nodes referenced since above flag was set
local refs = {} :: { Node<unknown> }

local scopes = { n = 0 } :: { [number]: Node<unknown>, n: number }

local WEAK_VALUES = { __mode = "v" }
local EVALUATION_ERR = "error while evaluating source:\n\n"

setmetatable(refs :: any, WEAK_VALUES)

-- runs a given callback in a context that Luau does not allow yielding in
local check_for_yield: <T...>(fn: (T...) -> unknown, T...) -> () do
    local t = { __mode = "kv" }
    setmetatable(t, t)

    check_for_yield = function(fn, ...: any)
        local args = { ... }

        t.__unm = function(_)
            fn(unpack(args))
        end

        local ok, err = pcall(function()
            local _ = -t
        end)

        if not ok then
            if err == "attempt to yield across metamethod/C-call boundary" or err == "thread is not yieldable" then
                throw(EVALUATION_ERR .. "cannot yield when deriving node in watcher")
            else
                throw(EVALUATION_ERR .. err)
            end
        end
    end
end

local function get_scope(): Node<unknown>
    return scopes[scopes.n]
end

local function open_scope(node: Node<unknown>)
    local n = scopes.n + 1
    scopes.n = n
    scopes[n] = node
end

local function close_scope()
    local n = scopes.n
    scopes.n = n - 1
    scopes[n] = nil
end

local function add_cleanup(node: Node<unknown>, cleanup: () -> ())
    if node.cleanups then
        table.insert(node.cleanups, cleanup)
    else
        node.cleanups = { cleanup }
    end
end

local function run_cleanups(node: { cleanups: { () -> () } | false})
    if node.cleanups then
        for _, fn in next, node.cleanups do
            fn()
        end
        table.clear(node.cleanups)
    end
end

--[[

Each node side-effect is registered with a corresponding weak key.
This makes the lifetime of the side-effect tied to the key's.
The main usecase of this is to tie a side-effect to an instance, while allowing
the instance to be garbage collected even when the node still exists.

The weak key is passed as an argument to its side-effect callback.

]]

local function set_effect<T>(node: Node<unknown>, fn: () -> ())
    node.effect = fn
end

local function run_effect(node: Node<unknown>)
    node.effect()
end

-- retrieves a node's cached value
-- add self to refs if ref capture flag is enabled
local function get<T>(node: Node<T>): T
    if reff then table.insert(refs, node) end
    return node.cache
end

-- links two nodes as parent-child
local function set_child(parent: Node<unknown>, child: Node<unknown>)
    if parent.children then
        table.insert(parent.children, child)    
    else
        parent.children = { child }
        setmetatable(parent.children :: any, WEAK_VALUES)
    end
end

local function create_and_open_scope(node: Node<unknown>)
    local parent = scopes[scopes.n]
    if parent then
        set_child(parent, node)
        node.effect = function()
            return parent
        end
    else
        node.cleanups = {}
        local cleanups = node.cleanups :: { () -> () }
        on_gc(node, function()
            run_cleanups({ cleanups = cleanups })
        end)
    end
    open_scope(node)
end

-- runs node effects, recalculates descendants and runs descendant effects
local function update(node: Node<unknown>)
    open_scope(node)
    run_cleanups(node)
    run_effect(node)
    close_scope()
    if node.children then
        for _, child in node.children do
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
    child.effect = function()
        child.cache = derive()
    end
    set_child(parent, child)
end

-- detect what nodes were referenced in the given callback and returns them in an array
local function capture<T, U>(fn: (U?) -> T, arg: U?): ({ Node<unknown> }, T)
    if reff then throw("recursive capture detected") end

    table.clear(refs)
    reff = true

    local ok: boolean, result: T|string
    
    if arg == nil then
        ok, result = pcall(fn)
    else
        ok, result = pcall(fn, arg)
    end

    reff = false

    if not ok then throw(EVALUATION_ERR .. result :: string) end

    return refs, result :: T
end

-- captures and links any detected nodes
local function capture_and_link<T>(child: Node<T>, derive: () -> T): T
    local nodes, value = capture(derive, nil)

    child.effect = function()
        child.cache = derive()
    end
    for _, parent: Node<unknown> in next, nodes do
        set_child(parent, child)
    end

    return value :: T
end

local function create<T>(value: T): (Node<T>, () -> T)
    local node = {
        cache = value,
        effect = function() end,
        children = false :: false,
        cleanups = false :: false
    }

    local function read_node_value()
        return get(node)
    end

    return node, read_node_value
end

return table.freeze {
    create_and_open_scope = create_and_open_scope,
    open_scope = open_scope,
    close_scope = close_scope,
    get_scope = get_scope,
    add_cleanup = add_cleanup,
    run_cleanups = run_cleanups,
    set_effect = set_effect,
    get = get,
    set = set,
    link = link,
    set_child = set_child,
    capture = capture,
    capture_and_link = capture_and_link,
    create = create :: (<T>(value: T) -> (Node<T>, () -> T)) & (<T>() -> (Node<T>, () -> T)),
    refs = refs
}
