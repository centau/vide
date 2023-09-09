if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

export type StartNode<T> = {
    cache: T,
    children: { [Node<T>]: true } | false
}

export type Node<T> =  {
    cache: T,
    children: { [Node<T>]: true } | false,
    effect:  (T) -> (),
    cleanups: { () -> () } | false,
}

local scopes = { n = 0 } :: { [number]: Node<any>, n: number }

local WEAK_VALUES = { __mode = "v" }
local EVALUATION_ERR = "error while evaluating source:\n\n"

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

local function add_child<T>(parent: Node<any>, child: Node<any>)
    if parent.children then
        parent.children[child] = true
    else
        parent.children = { [child] = true :: true }
    end
end

-- local function open_root_scope<T>(node: Node<T>)
--     assert(not scopes[1])

--     local n = scopes.n + 1
--     scopes.n = n
--     scopes[n] = node
-- end

local function open_scope<T>(node: Node<T>)
    local n = scopes.n + 1
    scopes.n = n
    scopes[n] = node

    -- local parent = scopes[n-1]
    -- assert(parent)
    -- add_child(parent, node)
end

local function close_scope()
    local n = scopes.n
    scopes.n = n - 1
    scopes[n] = nil
end

local function add_cleanup<T>(node: Node<T>, cleanup: () -> ())
    if node.cleanups then
        table.insert(node.cleanups, cleanup)
    else
        node.cleanups = { cleanup }
    end
end

local function run_cleanups<T>(node: Node<T>)
    if node.cleanups then
        for _, fn in next, node.cleanups do
            fn()
        end
        table.clear(node.cleanups)
    end
end

local function run_effect<T>(node: Node<T>)
    node.effect(node.cache)
end

local function destroy<T>(node: Node<T>)
    run_cleanups(node)
    for _, child in ipairs(node) do
        destroy(child)
    end
end


-- runs node effects, recalculates descendants and runs descendant effects
local function update<T>(node: StartNode<T>)
    if not node.children then return end

    local cache = {}
    for child in node.children do
        table.insert(cache, child)
    end

    for _, child in next, cache do
        open_scope(child)
        run_cleanups(child)
        run_effect(child)
        close_scope()
        update(child)
    end
end

local function track<T>(node: Node<T>)
    add_child(node, get_scope())
end

local function create_node<T>(value: T): Node<T>
    return {
        cache = value,
        effect = function() end,
        cleanups = false,
        children = false
    }
end

local function get_children(node: Node<unknown>): { Node<unknown> }
    if not node.children then return {} end

    local children = {}

    for child in node.children do
        table.insert(children, child)
    end

    return children
end

local function create_start_node<T>(value: T): StartNode<T>
    return { cache = value, children = false }
end

return table.freeze {
    open_root_scope = open_root_scope,
    open_scope = open_scope,
    close_scope = close_scope,
    get_scope = get_scope,
    add_cleanup = add_cleanup,
    destroy = destroy,
    run_cleanups = run_cleanups,
    track = track,
    update = update,
    add_child = add_child,
    create_node = create_node,
    create_start_node = create_start_node,
    get_children = get_children
}
