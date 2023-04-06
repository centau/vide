------------------------------------------------------------------------------------------
-- benchmark.lua
------------------------------------------------------------------------------------------

local BENCH, START = require("test/testkit").getBenchmarkTools()

local vide = require "src/init"
type State<T> = vide.State<T>

local function gc(n: number?)
    for i = 1, n or 3 do
        (collectgarbage :: any)("collect")
    end
end

local N = 1e5

gc()

BENCH("Create state", function()
    local cache = table.create(N)
    local wrap = vide.wrap

    for i = 1, START(N) do
        cache[i] = wrap(1)
    end
end)

gc()

BENCH("Get state value", function()
    local state = vide.wrap(1)
    local unwrap = vide.unwrap

    for i = 1, START(N) do
        unwrap(state)
    end
end)

gc()

BENCH("Set state value", function()
    local _, set = vide.wrap(1)

    for i = 1, START(N) do
        set(i)
    end
end)

gc()

BENCH("Derive state", function()
    local cache = table.create(N)
    local state = vide.wrap(1)
    local derive = vide.derive

    for i = 1, START(N) do
        cache[i] = derive(function(from)
            return from(state)
        end)
    end
end)

gc()

BENCH("Derive state (2)", function()
    local cache = table.create(N)
    local state = vide.wrap(1)
    local state2 = vide.wrap(2)
    local derive = vide.derive

    for i = 1, START(N) do
        cache[i] = derive(function(from)
            return from(state) + from(state2)
        end)
    end
end)

gc()

BENCH("Derive state (shorthand)", function()
    local cache = table.create(N)
    local state = vide.wrap(1)

    for i = 1, START(N) do
        cache[i] = state + 1
    end
end)

gc()

BENCH("Derive state (shorthand 2)", function()
    local cache = table.create(N)
    local state = vide.wrap(1)
    local state2 = vide.wrap(2)

    for i = 1, START(N) do
        cache[i] = state + state2
    end
end)

gc()

BENCH("Derived state update", function()
    local stateA, setA = vide.wrap(1)
    local stateB = vide.derive(function(from) return from(stateA) end)
    local unwrap = vide.unwrap

    for i = 1, START(N) do
        setA(i)
        unwrap(stateB)
    end
end)

gc()

BENCH("Derived state update (shorthand)", function()
    local stateA, setA = vide.wrap(1)
    local stateB = stateA + 1
    local unwrap = vide.unwrap

    for i = 1, START(N) do
        setA(i)
        unwrap(stateB)
    end
end)

gc()

BENCH("Apply single property", function()
    local instance = vide.create("Frame") {}
    local apply = vide.apply

    for i = 1, START(N) do
        apply(instance) {
            Name = i
        }
    end
end)

gc()

BENCH("Bind state", function()
    local instance = vide.create("Frame") {}
    local state = vide.wrap(1)
    local apply = vide.apply

    for i = 1, START(N) do
        apply(instance) {
            Name = state
        }
    end
end)

return nil
