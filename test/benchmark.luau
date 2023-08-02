------------------------------------------------------------------------------------------
-- benchmark.lua
------------------------------------------------------------------------------------------

local BENCH, START = require("test/testkit").benchmark()

local vide = require "src/init"

local N = 1e6

BENCH("Create state", function()
    local cache = table.create(N)
    local source = vide.source

    for i = 1, START(N) do
        cache[i] = source(1)
    end
end)

BENCH("Get state value", function()
    local state = vide.source(1)

    for i = 1, START(N) do
        state()
    end
end)

BENCH("Set state value", function()
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

BENCH("Derive 2 states", function()
    local cache = table.create(N)
    local state = vide.source(1)
    local state2 = vide.source(2)
    local derive = vide.derive

    for i = 1, START(N) do
        cache[i] = derive(function()
            return state() + state2()
        end)
    end
end)

BENCH("Set state value derived", function()
    local state = vide.source(1)
    local _derived = vide.derive(state)

    for i = 1, START(N) do
        state(i)
    end
end)

BENCH("Apply 4 properties", function()
    local apply = require "src/apply"
    local instance = vide.create("Frame") {}

    for i = 1, START(N) do
        apply(instance, {
            Name = i,
            Name2 = i,
            Name3 = i,
            Name4 = i
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

return nil
