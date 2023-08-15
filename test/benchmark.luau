local BENCH, START = require("test/testkit").benchmark()

-- try prevent inlining by wrapping in a closure referencing an upvalue that
-- cannot be determined at compile-time
local function NO_INLINE(fn)
    local r = math.random()
    return function(x)
        local _ = r
        fn(x)
    end
end

local vide = require "src/init"

local N = 2^18 -- 262144[

BENCH("create state", function()
    local cache = table.create(N)
    local source = vide.source

    for i = 1, START(N) do
        cache[i] = source(1)
    end
end)

BENCH("get value", function()
    local state = vide.source(1)

    for i = 1, START(N) do
        state()
    end
end)

BENCH("set value", function()
    local state = vide.source(1)

    for i = 1, START(N) do
        state(i)
    end
end)

BENCH("derive 1 state", function()
    local cache = table.create(N)
    local state = vide.source(1)
    local derive = vide.derive

    for i = 1, START(N) do
        cache[i] = derive(function()
            return state()
        end)
    end
end)

BENCH("derive 4 states", function()
    local cache = table.create(N)
    local state = vide.source(1)
    local state2 = vide.source(2)
    local state3 = vide.source(3)
    local state4 = vide.source(4)
    local derive = vide.derive

    for i = 1, START(N) do
        cache[i] = derive(function()
            return state() + state2() + state3() + state4()
        end)
    end
end)

BENCH("set derived value", function()
    local state = vide.source(1)
    local _derived = vide.derive(state)

    for i = 1, START(N) do
        state(i)
    end
end)

BENCH("apply 0 properties", function()
    local apply = require "src/apply"
    local instance = vide.create("Frame") {}

    for i = 1, START(N) do
        apply(instance, {})
    end
end)

BENCH("apply 8 properties", function()
    local apply = require "src/apply"
    local instance = vide.create("Frame") {}

    for i = 1, START(N) do
        apply(instance, {
            Name = i,
            Name2 = i,
            Name3 = i,
            Name4 = i,
            Name5 = i,
            Name6 = i,
            Name7 = i,
            Name8 = i,
        })
    end
end)

BENCH("bind source", function()
    local apply = require "src/apply"
    local instance = vide.create("Frame") {}
    local state = vide.source(1)

    for i = 1, START(N) do
        apply(instance, {
            Name = state
        })
    end
end)

BENCH("update binding", function()
    local apply = require "src/apply"
    local instance = vide.create("Frame") {}
    local state = vide.source(1)

    apply(instance, {
        Name = state
    })

    for i = 1, START(N) do
        state(i)
    end
end)

BENCH("indexes() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local state = vide.source(data)

    local _list = vide.indexes(state, function(v, i)
        return {}
    end)

    --state(state()) -- fill double buffer

    START(N)

    state(data)
end)

BENCH("indexes() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local state = vide.source(data)

    local _list = vide.indexes(state, function(v, i)
        return {}
    end)

    --state(state()) -- fill double buffer

    for i, v in data do
        data[i] = v + 1
    end

    START(N)

    state(data)
end)

BENCH("indexes() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local state = vide.source(data)

    local _list = vide.indexes(state, function(v, i)
        return {}
    end)

    table.clear(data)

    START(N)

    state(data)
end)

BENCH("values() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local state = vide.source(data)

    local _list = vide.values(state, function(v, i)
        return {}
    end)

    state(state()) -- fill double buffer

    START(N)

    state(data)
end)

BENCH("values() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local state = vide.source(data)

    local _list = vide.values(state, function(v, i)
        return {}
    end)

    state(state()) -- fill double buffer

    for i = 1, N do
        local r = math.random(1, #data)
        data[i], data[r] = data[r], data[i]
    end

    START(N)

    state(data)
end)

BENCH("values() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local state = vide.source(data)

    local _list = vide.values(state, function(v, i)
        return {}
    end)

    table.clear(data)

    START(N)

    state(data)
end)

BENCH("register new cleanup", function()
    local cleanup = vide.cleanup

    local cleaner = function() end

    local callers = {}

    for i = 1, N do
        callers[i] = function(fn, v)
            fn(v)
            return i -- return unique upvalue to ensure unique closure
        end
    end

    for i = 1, START(N) do
        callers[i](cleanup, cleaner)
    end
end)

-- cleanup cleanups from previous benchmark
;(collectgarbage :: any)("collect")
vide.step(0) 

BENCH("repeat cleanup", function()
    local cleanup = vide.cleanup

    local foo = NO_INLINE(function(i)
        cleanup(function()
            -- return i -- uncomment to include overhead of closure creation
        end)
    end)

    for i = 1, START(N) do
        foo(i)
    end
end)

-- cleanup cleanups from previous benchmark
;(collectgarbage :: any)("collect")
vide.step(0) 

BENCH("cleanup gc check", function()
    local cleanup = vide.cleanup

    local cleaner = function() end

    local callers = table.create(N)

    for i = 1, N do
        callers[i] = function()
            cleanup(cleaner)
            return i
        end

        callers[i]()
    end

    START(N)

    vide.step(0)
end)

BENCH("cleanup gc removal", function()
    START(N)

    vide.step(0) -- cleanup from previous benchmark
end)

return nil
