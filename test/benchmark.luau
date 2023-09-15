local testkit = require("test/testkit")
local BENCH, START = testkit.benchmark()

local vide = require "src/init"
local source = vide.source
local derive = vide.derive
local indexes = vide.indexes
local values = vide.values
local cleanup = vide.cleanup
local create = vide.create

local function TITLE(name: string)
    print()
    print(testkit.color.white(name))
end

local N = 2^18 -- 262144

local function WRAP_BENCH(name: string, fn: () -> ())
    local _, destroy = vide.root(function()
        BENCH(name, fn)
    end)
    destroy()
end

TITLE "sources"

WRAP_BENCH("create source", function()
    local cache = table.create(N)

    for i = 1, START(N) do
        cache[i] = source(1)
    end
end)

WRAP_BENCH("get value", function()
    local src = source(1)

    for i = 1, START(N) do
        src()
    end
end)

WRAP_BENCH("set value", function()
    local src = source(1)

    for i = 1, START(N) do
        src(i)
    end
end)

WRAP_BENCH("derive 1 source", function()
    local cache = table.create(N)
    local src = source(1)

    for i = 1, START(N) do
        cache[i] = derive(function()
            return src()
        end)
    end
end)

WRAP_BENCH("derive 4 sources", function()
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

WRAP_BENCH("update 1->1 graph", function()
    local src = source(1)

    local _derived = derive(function() return src() end)

    for i = 1, START(N) do
        src(i)
    end
end)

WRAP_BENCH("update 1->1 graph with cleanup", function()
    local src = source(1)

    derive(function()
        cleanup(function() end)
        return src()
    end)

    for i = 1, START(N) do
        src(i)
    end
end)

WRAP_BENCH("update 1->1000 graph", function()
    local src = source(-1)

    for i = 1, 1000 do
        derive(function() return src() end)
    end

    src(0)

    for i = 1, START(10) do
        src(i)
    end
end)

WRAP_BENCH("update 1->1->1->1...1000 graph", function()
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

-- todo: repeat with batching
WRAP_BENCH("update 1000->1 graph", function()
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
        for idx = 1, 1000 do
            srcs[idx](i)
        end
    end
end)

-- todo: optimize, repeat with batching
WRAP_BENCH("update 1000x 1->1 common extern. graph", function()
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

WRAP_BENCH("apply 0 properties", function()
    local apply = require "src/apply"
    local instance = create("Frame") {}

    for i = 1, START(N) do
        apply(instance, {})
    end
end)

WRAP_BENCH("apply 8 properties", function()
    local apply = require "src/apply"
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

WRAP_BENCH("bind property", function()
    local apply = require "src/apply"

    local instance = create("Frame") {}
    local src = source(1)

    for i = 1, START(N) do
        apply(instance, {
            Text = src
        })
    end

    return nil
end)

WRAP_BENCH("update binding", function()
    local apply = require "src/apply"

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

TITLE "indexes()"

N /= 1024

WRAP_BENCH("indexes() all new", function()
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

WRAP_BENCH("indexes() no change", function()
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

WRAP_BENCH("indexes() all change", function()
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

WRAP_BENCH("indexes() all remove", function()
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

WRAP_BENCH("values() all new", function()
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

WRAP_BENCH("values() no change", function()
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

WRAP_BENCH("values() all change", function()
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

WRAP_BENCH("values() all remove", function()
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

N *= 1024

TITLE "cleanup"

WRAP_BENCH("register new cleanup", function()
    local cleanup = cleanup

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

TITLE "aggregate"

do
    -- the purpose of the two following benchmarks is to measure the overhead of
    -- aggregate construction
    WRAP_BENCH("set explicit mock vector2", function()
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

    WRAP_BENCH("set aggregate mock vector2", function()
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

-- innacurate due to no Vector3 in vanilla Luau
-- mock vector is 200x slower than native vector 

-- WRAP_BENCH("spring update", function()
--     local root, source, spring = vide.root, vide.source, vide.spring

--     local src = source(0)

--     root(function()
--         for i = 1, N do
--             spring(src)
--         end

--         START(N)

--         src(1)

--         return nil
--     end)
-- end)

-- N /= 1024

-- WRAP_BENCH("spring step", function()
--     local root, source, spring = vide.root, vide.source, vide.spring

--     local src = source(0)

--     root(function()
--         for i = 1, N do
--             spring(src)
--         end

--         src(1)

--         START(N)

--         vide.step(1/60)

--         return nil
--     end)
-- end)

return nil
