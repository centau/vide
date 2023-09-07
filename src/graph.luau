if not game then script = require "test/relative-string" end

local throw = require(script.Parent.throw)
local flags = require(script.Parent.flags)

export type Scope = {
    parent: Scope | false,
    cleanups: { () -> () } | false,
    [number]: Scope -- children
}

export type StartNode<T> = {
    cache: T,
    [number]: Node<T>
}

export type Node<T> = StartNode<T> & {
    scope: Scope,
    effect:  (T) -> (),
}

-- flag used to detect when node reference capturing is active
local reff = false
-- array of all nodes referenced since above flag was set
local refs = {} :: { StartNode<unknown> }

local scopes = { n = 0 } :: { [number]: Scope, n: number }

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

local function get_scope(): Scope
    return scopes[scopes.n]
end

local function open_scope(scope: Scope)
    local n = scopes.n + 1
    scopes.n = n
    scopes[n] = scope
end

local function close_scope()
    local n = scopes.n
    scopes.n = n - 1
    scopes[n] = nil
end

local function add_cleanup(scope: Scope, cleanup: () -> ())
    if scope.cleanups then
        table.insert(scope.cleanups, cleanup)
    else
        scope.cleanups = { cleanup }
    end
end

local function run_cleanups(scope: Scope)
    if scope.cleanups then
        for _, fn in next, scope.cleanups do
            fn()
        end
        table.clear(scope.cleanups)
    end
end

--[[

Each node side-effect is registered with a corresponding weak key.
This makes the lifetime of the side-effect tied to the key's.
The main usecase of this is to tie a side-effect to an instance, while allowing
the instance to be garbage collected even when the node still exists.

The weak key is passed as an argument to its side-effect callback.

]]

local function run_effect<T>(node: Node<T>)
    node.effect(node.cache)
end

local function add_child(parent: StartNode<any>, child: Node<any>)
    table.insert(parent, child)
end

local function add_children(parent: Node<any>, children: { Node<any> })
    for _, child in next, children do
        table.insert(parent, child)
    end
end

local function destroy(scope: Scope)
    run_cleanups(scope)
    for _, child in ipairs(scope) do
        destroy(child)
    end
end

-- runs node effects, recalculates descendants and runs descendant effects
local function update<T>(node: StartNode<T>)
    for _, child in ipairs(node) do
        local scope = child.scope
        assert(scope)
        open_scope(scope :: Scope)
        run_cleanups(scope :: Scope)
        run_effect(child)
        update(child)
        close_scope()
    end
end

-- detect what nodes were referenced in the given callback and returns them in an array
local function capture<T, U>(fn: (U?) -> T, arg: U?): ({ StartNode<unknown> }, T)
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

local function capture_parents<T, U>(child: Node<T>, fn: (U?) -> T, arg: U?): T
    local refs, result = capture(fn, arg)

    for _, parent in next, refs do
        add_child(parent, child)
    end

    return result
end

local function track<T>(node: StartNode<T>)
    if reff then table.insert(refs, node :: Node<any>) end
end

local function create_scope(): Scope
    return {
        parent = get_scope() or false,
        cleanups = false
    }
end

local function create_node<T>(value: T): Node<T>
    return {
        scope = create_scope(),
        cache = value,
        effect = function() end,
    }
end

local function create_start_node<T>(value: T): StartNode<T>
    return { cache = value }
end

return table.freeze {
    open_scope = open_scope,
    close_scope = close_scope,
    get_scope = get_scope,
    add_cleanup = add_cleanup,
    destroy = destroy,
    run_cleanups = run_cleanups,
    track = track,
    update = update,
    add_child = add_child,
    add_children = add_children,
    capture = capture,
    capture_parents = capture_parents,
    create_node = create_node,
    create_start_node = create_start_node,
    create_scope = create_scope,
    refs = refs
}
