local testkit = require("./testkit")
local BENCH, START = testkit.benchmark()

local vide = require "../../vide"
local source = vide.source
local derive = vide.derive
local effect = vide.effect
local indexes = vide.indexes
local values = vide.values
local batch = vide.batch
local cleanup = vide.cleanup
local untrack = vide.untrack
local create = vide.create
local context = vide.context

assert(not vide.strict)

local function TITLE(name: string)
    print()
    print(testkit.color.white(name))
end

local function ROOT_BENCH(name: string, fn: () -> ())
    vide.root(function(destroy)
        BENCH(name, fn)
        return destroy
    end)()
end

local N = 2^18 -- 262144

TITLE "sources"

BENCH("create source", function()
    local cache = table.create(N)

    for i = 1, START(N) do
        cache[i] = source(1)
    end
end)

BENCH("get value", function()
    local src = source(1)

    for i = 1, START(N) do
        src()
    end
end)

BENCH("set value", function()
    local src = source(1)

    for i = 1, START(N) do
        src(i)
    end
end)

ROOT_BENCH("derive 1 source", function()
    local cache = table.create(N)
    local src = source(1)

    for i = 1, START(N) do
        cache[i] = derive(function()
            return src()
        end)
    end
end)

ROOT_BENCH("derive 4 sources", function()
    local cache = table.create(N)
    local src = vide.source(1)
    local src2 = vide.source(2)
    local src3 = vide.source(3)
    local src4 = vide.source(4)

    for i = 1, START(N) do
        cache[i] = derive(function()
            return src() + src2() + src3() + src4()
        end)
    end
end)

TITLE "graphs"

ROOT_BENCH("update 1->1 graph", function()
    local src = source(1)

    local _derived = derive(function() return src() end)

    for i = 1, START(N) do
        src(i)
    end
end)

ROOT_BENCH("update 1->1 graph with cleanup", function()
    local src = source(1)

    derive(function()
        cleanup(function() end)
        return src()
    end)

    for i = 1, START(N) do
        src(i)
    end
end)

ROOT_BENCH("update 1->1000 graph", function()
    local src = source(-1)

    for i = 1, 1000 do
        derive(function() return src() end)
    end

    src(0)

    for i = 1, START(10) do
        src(i)
    end
end)

ROOT_BENCH("update 1->1->1->1...1000 graph", function()
    local src = source(-1)

    local last = src
    for i = 1, 1000 do
        local l = last
        last = derive(function() return l() end)
    end

    src(0)

    for i = 1, START(10) do
        src(i)
    end
end)

-- todo: why does it hang at 1k? it didn't before
ROOT_BENCH("update 500->1 graph", function()
    local srcs = {}
    for i = 1, 500 do
        srcs[i] = source(0)
    end

    derive(function()
        for i = 1, 500 do
            srcs[i]()
        end
        return false
    end)

    for i = 1, START(1) do
        for idx = 1, 500 do
            srcs[idx](i)
        end
    end
end)

ROOT_BENCH("update 1000->1 graph (batched)", function()
    local srcs = {}
    for i = 1, 1000 do
        srcs[i] = source(0)
    end

    derive(function()
        for i = 1, 1000 do
            srcs[i]()
        end
        return false
    end)

    for i = 1, START(1) do
        batch(function()
            for idx = 1, 1000 do
                srcs[idx](i)
            end
        end)
    end
end)

-- todo: optimize this case
ROOT_BENCH("update 1000 1->1 common extern. graph", function()
    local ext = source(-1)

    local srcs = {}
    for i = 1, 1000 do
        srcs[i] = source(0)
        derive(function() return srcs[i]() + ext() end)
    end

    ext(0)

    for i = 1, START(10) do
        for idx = 1, 1000 do
            srcs[idx](i)
        end
    end
end)

TITLE "property apply"

ROOT_BENCH("apply 0 properties", function()
    local apply = require "../src/apply"
    local instance = create("Frame") {}

    for i = 1, START(N) do
        apply(instance, {})
    end
end)

ROOT_BENCH("apply 8 properties", function()
    local apply = require "../src/apply"
    local instance = create("Frame") {}

    for i = 1, START(N) do
        apply(instance, {
            Text = i,
            Text2 = i,
            Text3 = i,
            Text4 = i,
            Text5 = i,
            Text6 = i,
            Text7 = i,
            Text8 = i,
        })
    end
end)

ROOT_BENCH("bind property", function()
    local apply = require "../src/apply"

    local instance = create("Frame") {}
    local src = source(1)

    for i = 1, START(N) do
        apply(instance, {
            Text = src
        })
    end

    return nil
end)

ROOT_BENCH("update binding", function()
    local apply = require "../src/apply"

    local instance = create("Frame") {}
    local src = source(1)

    apply(instance, {
        Text = src
    })

    for i = 1, START(N) do
        src(i)
    end

    return nil
end)

TITLE "switch()"

ROOT_BENCH("switch()", function()
    local M = 2^8

    local map = {}
    for i = 1, M do
        map[i] = function() return i end
    end

    local input = source(0)
    vide.switch(input)(map)

    for i = 1, START(N) do
        input(bit32.band(i, M - 1) + 1) -- i % m + 1
    end
end)

TITLE "indexes()"

N /= 1024

ROOT_BENCH("indexes() all new", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = source(data)

    START(N)

    local _list = indexes(src, function(v, i)
        return {}
    end)

    return nil
end)

ROOT_BENCH("indexes() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = source(data)

    local _list = indexes(src, function(v, i)
        return {}
    end)

    START(N)

    src(data)

    return nil
end)

ROOT_BENCH("indexes() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = source(data)

    local _list = indexes(src, function(v, i)
        return {}
    end)

    --src(src()) -- fill double buffer

    for i, v in data do
        data[i] = v + 1
    end

    START(N)

    src(data)
end)

ROOT_BENCH("indexes() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = source(data)

    local _list = indexes(src, function(v, i)
        return {}
    end)

    table.clear(data)

    START(N)

    src(data)

    return nil
end)

TITLE "values()"

ROOT_BENCH("values() all new", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = source(data)

    START(N)
    
    local _list = values(src, function(v, i)
        return {}
    end)

    return nil
end)

ROOT_BENCH("values() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = source(data)

    local _list = values(src, function(v, i)
        return {}
    end)

    src(src()) -- fill double buffer

    START(N)

    src(data)
end)

ROOT_BENCH("values() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = source(data)

    local _list = values(src, function(v, i)
        return {}
    end)

    src(src()) -- fill double buffer

    for i = 1, N do
        local r = math.random(1, #data)
        data[i], data[r] = data[r], data[i]
    end

    START(N)

    src(data)
end)

ROOT_BENCH("values() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = source(data)

    local _list = values(src, function(v, i)
        return {}
    end)

    table.clear(data)

    START(N)

    src(data)
end)

TITLE "context()"

ROOT_BENCH("set context", function()
    local ctx = context()

    for i = 1, START(N) do
        ctx(i, function() end)
    end
end)

ROOT_BENCH("get context (depth=1)", function()
    local ctx = context()

    local function run()
        for i = 1, START(N) do
            ctx()
        end
    end

    ctx(1, function()
        run()
    end)
end)

local depth = 10
ROOT_BENCH(`get context (depth={depth})`, function()

    local ctx = context()

    local function run()
        for i = 1, START(N) do
            ctx()
        end
    end

    local function nest_effect(fn)
        untrack(function()
            effect(fn)
            return nil
        end)
    end
    
    local f = run
    for i = 1, depth - 1 do
        local f_inner = f
        f = function()
            nest_effect(f_inner)
        end
    end

    ctx(1, function()
        f()
    end)
end)

TITLE "spring()"

ROOT_BENCH("spring update", function()
    local root, source, spring = vide.root, vide.source, vide.spring

    local src = source(0)

    root(function()
        for i = 1, N do
            spring(src)
        end

        START(N)

        src(1)

        return nil
    end)
end)

ROOT_BENCH("spring step", function()
    local root, source, spring = vide.root, vide.source, vide.spring

    local src = source(0)

    root(function()
        for i = 1, N do
            spring(src)
        end

        src(1)

        START(N)

        vide.step(1/60)

        return nil
    end)
end)

TITLE "aggregate"

do
    -- the purpose of the two following benchmarks is to measure the overhead of
    -- aggregate construction
    ROOT_BENCH("set explicit vector", function()
        local apply = require "../src/apply"

        local label = create "TextLabel" {
            AnchorPoint = vector.create(1, 1, 1)
        }

        for i = 1, START(N) do
            apply(label, {
                AnchorPoint = vector.create(i, i, i)
            })
        end
    end)

    ROOT_BENCH("set aggregate vector", function()
        local apply = require "../src/apply"

        local label = create "TextLabel" {
            AnchorPoint = vector.create(1, 1, 1)
        }

        for i = 1, START(N) do
            apply(label, {
                AnchorPoint = { i, i, i }
            })
        end
    end)
end

return nil
