local BENCH, START = require("test/testkit").benchmark()

local vide = require "src/init"

local N = 2^18 -- 262144

-- todo: wide and deep graph benchmarks

BENCH("create source", function()
    local source = vide.source

    local cache = table.create(N)

    for i = 1, START(N) do
        cache[i] = source(1)
    end
end)

BENCH("get value", function()
    local src = vide.source(1)

    for i = 1, START(N) do
        src()
    end
end)

BENCH("set value", function()
    local src = vide.source(1)

    for i = 1, START(N) do
        src(i)
    end
end)

BENCH("derive 1 source", function()
    local derive = vide.derive

    local cache = table.create(N)
    local src = vide.source(1)

    vide.root(function()
        for i = 1, START(N) do
            cache[i] = derive(function()
                return src()
            end)
        end
        return nil
    end)
end)

BENCH("derive 4 sources", function()
    local derive = vide.derive

    local cache = table.create(N)
    local src = vide.source(1)
    local src2 = vide.source(2)
    local src3 = vide.source(3)
    local src4 = vide.source(4)

    vide.root(function()
        for i = 1, START(N) do
            cache[i] = derive(function()
                return src() + src2() + src3() + src4()
            end)
        end

        return nil
    end)
end)

-- todo: why is this so fast?
BENCH("set derived value", function()
    local src = vide.source(1)

    vide.root(function()
        local _derived = vide.derive(src)

        for i = 1, START(N) do
            src(i)
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

BENCH("bind source", function()
    local apply = require "src/apply"

    local instance = vide.create("Frame") {}
    local src = vide.source(1)

    vide.root(function()
        for i = 1, START(N) do
            apply(instance, {
                Text = src
            })
        end

        return nil
    end)
end)

BENCH("update binding", function()
    local apply = require "src/apply"

    local instance = vide.create("Frame") {}
    local src = vide.source(1)

    vide.root(function()
        apply(instance, {
            Text = src
        })

        for i = 1, START(N) do
            src(i)
        end

        return nil
    end)
end)

N /= 1024

BENCH("indexes() all new", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = vide.source(data)

    vide.root(function() 
        START(N)

        local _list = vide.indexes(src, function(v, i)
            return {}
        end)

        return nil
    end)
end)

BENCH("indexes() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = vide.source(data)

    vide.root(function() 
        local _list = vide.indexes(src, function(v, i)
            return {}
        end)

        START(N)

        src(data)

        return nil
    end)
end)

BENCH("indexes() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = vide.source(data)


    vide.root(function()
        local _list = vide.indexes(src, function(v, i)
            return {}
        end)

        --src(src()) -- fill double buffer

        for i, v in data do
            data[i] = v + 1
        end

        START(N)

        src(data)

        return nil
    end)
end)

BENCH("indexes() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = i
    end

    local src = vide.source(data)

    vide.root(function()
        local _list = vide.indexes(src, function(v, i)
            return {}
        end)

        table.clear(data)

        START(N)

        src(data)

        return nil
    end)
end)

BENCH("values() all new", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = vide.source(data)

    vide.root(function()
        START(N)
        
        local _list = vide.values(src, function(v, i)
            return {}
        end)

        return nil
    end)
end)

BENCH("values() no change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = vide.source(data)

    vide.root(function()
        local _list = vide.values(src, function(v, i)
            return {}
        end)

        src(src()) -- fill double buffer

        START(N)

        src(data)

        return nil
    end)
end)

BENCH("values() all change", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = vide.source(data)

    vide.root(function()
        local _list = vide.values(src, function(v, i)
            return {}
        end)

        src(src()) -- fill double buffer

        for i = 1, N do
            local r = math.random(1, #data)
            data[i], data[r] = data[r], data[i]
        end

        START(N)

        src(data)

        return nil
    end)
end)

BENCH("values() all remove", function()
    local data = {}

    for i = 1, N do
        data[i] = {}
    end

    local src = vide.source(data)

    vide.root(function()
        local _list = vide.values(src, function(v, i)
            return {}
        end)

        table.clear(data)

        START(N)

        src(data)

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
