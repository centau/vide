local BENCH, START = require("test/testkit").benchmark()

local vide = require "src/init"

local N = 2^18 -- 262144

BENCH("create state", function()
    local source = vide.source

    local cache = table.create(N)

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
    local derive = vide.derive

    local cache = table.create(N)
    local state = vide.source(1)

    vide.root(function()
        for i = 1, START(N) do
            cache[i] = derive(function()
                return state()
            end)
        end
        return nil
    end)
end)

BENCH("derive 4 states", function()
    local derive = vide.derive

    local cache = table.create(N)
    local state = vide.source(1)
    local state2 = vide.source(2)
    local state3 = vide.source(3)
    local state4 = vide.source(4)

    vide.root(function()
        for i = 1, START(N) do
            cache[i] = derive(function()
                return state() + state2() + state3() + state4()
            end)
        end

        return nil
    end)
end)

BENCH("set derived value", function()
    local state = vide.source(1)

    vide.root(function()
        local _derived = vide.derive(state)

        for i = 1, START(N) do
            state(i)
        end

        return nil
    end)
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

    vide.root(function()
        for i = 1, START(N) do
            apply(instance, {
                Name = state
            })
        end

        return nil
    end)
end)

BENCH("update binding", function()
    local apply = require "src/apply"

    local instance = vide.create("Frame") {}
    local state = vide.source(1)

    vide.root(function()
        apply(instance, {
            Name = state
        })

        for i = 1, START(N) do
            state(i)
        end

        return nil
    end)
end)

N /= 1024

BENCH("indexes() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local state = vide.source(data)

    vide.root(function() 
        local _list = vide.indexes(state, function(v, i)
            return {}
        end)

        --state(state()) -- fill double buffer

        START(N)

        state(data)

        return nil
    end)
end)

BENCH("indexes() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local state = vide.source(data)


    vide.root(function()
        local _list = vide.indexes(state, function(v, i)
            return {}
        end)

        --state(state()) -- fill double buffer

        for i, v in data do
            data[i] = v + 1
        end

        START(N)

        state(data)

        return nil
    end)
end)

BENCH("indexes() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local state = vide.source(data)

    vide.root(function()
        local _list = vide.indexes(state, function(v, i)
            return {}
        end)

        table.clear(data)

        START(N)

        state(data)

        return nil
    end)
end)

BENCH("values() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local state = vide.source(data)

    vide.root(function()
        local _list = vide.values(state, function(v, i)
            return {}
        end)

        state(state()) -- fill double buffer

        START(N)

        state(data)

        return nil
    end)
end)

BENCH("values() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local state = vide.source(data)

    vide.root(function()
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

        return nil
    end)
end)

BENCH("values() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local state = vide.source(data)

    vide.root(function()
        local _list = vide.values(state, function(v, i)
            return {}
        end)

        table.clear(data)

        START(N)

        state(data)

        return nil
    end)
end)

N *= 1024

BENCH("register new cleanup", function()
    local cleanup = vide.cleanup

    vide.root(function()
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

        return nil
    end)
end)

do
    -- the purpose of the two following benchmarks is to measure the overhead of
    -- aggregate construction
    BENCH("set explicit mock vector2", function()
        local create = vide.create
        local apply = require "src/apply"
        local Vector2 = require "test/mock".Vector2

        local label = create "TextLabel" {
            AnchorPoint = Vector2.new(1, 1)
        }

        for i = 1, START(N) do
            apply(label, {
                AnchorPoint = Vector2.new(i, i)
            })
        end
    end)

    BENCH("set aggregate mock vector2", function()
        local create = vide.create
        local apply = require "src/apply"
        local Vector2 = require "test/mock".Vector2

        local label = create "TextLabel" {
            AnchorPoint = Vector2.new(1, 1)
        }

        for i = 1, START(N) do
            apply(label, {
                AnchorPoint = { i, i }
            })
        end
    end)
end

return nil
