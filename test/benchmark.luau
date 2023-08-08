------------------------------------------------------------------------------------------
-- benchmark.lua
------------------------------------------------------------------------------------------

local BENCH, START = require("test/testkit").benchmark()

local vide = require "src/init"

local N = 2^18 -- 262144

BENCH("Create state", function()
    local cache = table.create(N)
    local source = vide.source

    for i = 1, START(N) do
        cache[i] = source(1)
    end
end)

BENCH("Get value", function()
    local state = vide.source(1)

    for i = 1, START(N) do
        state()
    end
end)

BENCH("Set value", function()
    local state = vide.source(1)

    for i = 1, START(N) do
        state(i)
    end
end)

BENCH("Derive 1 state", function()
    local cache = table.create(N)
    local state = vide.source(1)
    local derive = vide.derive

    for i = 1, START(N) do
        cache[i] = derive(function()
            return state()
        end)
    end
end)

BENCH("Derive 4 states", function()
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

BENCH("Set derived value", function()
    local state = vide.source(1)
    local _derived = vide.derive(state)

    for i = 1, START(N) do
        state(i)
    end
end)

BENCH("Apply 0 properties", function()
    local apply = require "src/apply"
    local instance = vide.create("Frame") {}

    for i = 1, START(N) do
        apply(instance, {})
    end
end)

BENCH("Apply 8 properties", function()
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

BENCH("Bind state", function()
    local apply = require "src/apply"
    local instance = vide.create("Frame") {}
    local state = vide.source(1)

    for i = 1, START(N) do
        apply(instance, {
            Name = state
        })
    end
end)

BENCH("Update binding", function()
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

return nil
