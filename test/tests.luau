local testkit = require("test/testkit")
local TEST, CASE, CHECK, FINISH = testkit.test()

local mock = require "test/mock"
local Instance, Signal = mock.Instance, mock.Signal
local Vector2, UDim2 = mock.Vector2, mock.UDim2

local vide = require "src/init"
local graph = require "src/graph"
type Node<T> = graph.Node<T>

type Map<K, V> = { [K] : V }

local function gc(n: number?)
    for i = 1, n or 3 do
        (collectgarbage :: any)("collect")
    end
end

local function weak<T>(t: T & {}): T
    setmetatable(t :: {}, { __mode = "kv" })
    return t
end

local function wrap_root(fn: () -> ())
    return function()
        local _, destroy = vide.root(fn :: any)
        destroy()
    end
end

local NIL = nil

-- vide.mount(function()
--     local src = vide.source(0)

--     vide.effect(function()
--         axasd += 1
--     end)
-- end)

TEST("graph", function()
    local create_node = graph.create_node
    local create_start_node = graph.create_start_node
    local track = graph.track
    local update = graph.update
    local add_child = graph.add_child
    local get_scope = graph.get_scope
    local open_scope = graph.open_scope
    local close_scope = graph.close_scope
    local get_children = graph.get_children
    local add_cleanup = graph.add_cleanup
    local destroy = graph.destroy

    local function node<T>(v: T?)
        local n = create_node(v or false)
        n.effect = function() end
        return n
    end

    local function scope()
        return create_node(false)
    end

    local function cleanup(fn: () -> ())
        local node = assert(get_scope())
        add_cleanup(node, fn)
    end

    do CASE "link nodes"
        local a = node()
        local b = node()
        local c = node()

        open_scope(c)

        track(a)
        track(b)

        close_scope()

        CHECK(get_children(a)[1] == c)
        CHECK(get_children(b)[1] == c)
    end

    do CASE "rerun linked nodes"
        local a = node()
        local b = node()
        local c = node()

        local count = 0

        local function effect()
            track(a)
            track(b)
            count += 1
        end

        c.effect = effect

        open_scope(c)

        effect()

        close_scope()
        
        CHECK(count == 1)
        update(a)
        CHECK(count == 2)
        update(b)
        CHECK(count == 3)
    end

    do CASE "diamond graph"
        local a, b, c, d = node(), node(), node(), node()

        local b_cnt, c_cnt, d_cnt = 0, 0, 0
        function b.effect() b_cnt += 1 end
        function c.effect() c_cnt += 1 end
        function d.effect() d_cnt += 1 end

        open_scope(b); track(a); close_scope()
        open_scope(c); track(a); close_scope()
        open_scope(d); track(b); track(c); close_scope()

        update(a)

        CHECK(b_cnt == 1)
        CHECK(c_cnt == 1)
        CHECK(d_cnt == 1)
    end

    do CASE "duplicate child on rerun"
        local a, b, c = node(), node(), node()

        function c.effect()
            track(a)
            track(b)
        end

        open_scope(c); assert(c.effect)(NIL); close_scope()

        update(a)

        CHECK(#get_children(a) == 1)
        CHECK(#get_children(b) == 1)
    end

    do CASE "case 1"
        -- construct graph

        local items = node { "a", "b" }
        local selected = node "a"

        local root = scope()

        local scope1 = scope()
        local scope2 = scope()

        local items_updated

        local bind1
        local bind2

        local cleaned = {} :: { [any]: any }

        local function clean(s)
            cleanup(function()
                cleaned[s] = true
            end)
        end

        do open_scope(root) 
            clean "root"
            items_updated = node()
            items_updated.effect = function() end
            track(items_updated) -- should not

            add_child(root, items_updated)
            do open_scope(items_updated)
                track(items)

                do open_scope(root)
                    add_child(root, scope1)
                    do open_scope(scope1)
                        clean "scope1"
                        bind1 = node()
                        bind1.effect = function() end

                        add_child(scope1, bind1)
                        do open_scope(bind1)
                            clean "bind1"
                            track(selected)
                        close_scope() end
                    close_scope() end

                    add_child(root, scope2)
                    do open_scope(scope2)
                        clean "scope2"
                        bind2 = node()
                        bind2.effect = function() end
                        add_child(scope2, bind2)
                        do open_scope(bind2)
                            clean "bind2"
                            track(selected)
                        close_scope() end
                    close_scope() end
                close_scope() end
            close_scope() end 
        close_scope() end
        

        -- verify graph

        do
            local c = get_children(items_updated)
            CHECK(#c == 0)
        end
    
        do
            local c = get_children(root)
            CHECK(#c == 3)
            CHECK(table.find(c, items_updated))
            CHECK(table.find(c, scope1 :: Node<any>))
            CHECK(table.find(c, scope2 :: Node<any>))
        end

        do
            local c = get_children(selected)
            CHECK(#c == 2)
            CHECK(table.find(c, bind1))
            CHECK(table.find(c, bind2))
        end

        do
            local c = get_children(scope1)
            CHECK(#c == 1)
            CHECK(table.find(c, bind1))
        end

        do
            local c = get_children(scope2)
            CHECK(#c == 1)
            CHECK(table.find(c, bind2))
        end

        -- destroy

        CHECK(table.find(get_children(root), scope1 :: Node<any>))

        destroy(scope1)
        CHECK(cleaned.scope1)
        CHECK(cleaned.bind1)
        scope1 = NIL
        bind1 = NIL
        bind2 = NIL
        gc()
        CHECK(#get_children(root) == 2)
        CHECK(#get_children(selected) == 1)
    end

    do CASE "nodes garbage collection"
        local wref = weak { create_node(1) }
        destroy(wref[1])
        gc()
        CHECK(not wref[1])
    end
end)

TEST("source()", wrap_root(function()
    local source = vide.source
    local effect = vide.effect

    do CASE "create source"
        local src = source(1)
        CHECK(src() == 1)
    end

    do CASE "set and get source value"
        local src = source(1)
        src(2)
        CHECK(src() == 2)
    end

    do CASE "does not update if same value"
        local src = source(1)

        local count = 0
        effect(function()
            src()
            count += 1
        end)

        CHECK(count == 1)
        src(1)
        CHECK(count == 1)
        src(2)
        CHECK(count == 2)
    end

    do CASE "does update if same value is mutable table"
        local src = source {}

        local count = 0
        effect(function()
            src()
            count += 1
        end)

        CHECK(count == 1)
        src(src())
        CHECK(count == 2)
    end

    do CASE "does not update if same value is frozen table"
        local a = table.freeze {}
        local b = table.freeze {}

        local src = source(a)

        local count = 0
        effect(function()
            src()
            count += 1
        end)

        CHECK(count == 1)
        src(a)
        CHECK(count == 1)
        src(b)
        CHECK(count == 2)
        src(b)
        CHECK(count == 2)
    end
end))

TEST("derive()", wrap_root(function()
    local root = vide.root
    local source = vide.source
    local derive = vide.derive
    local effect = vide.effect
    local cleanup = vide.cleanup

    do CASE "derive new value on source change"
        local a = source(1)
        local b = source(2)

        local c = derive(function()
            return tostring(a() + b())
        end)

        CHECK(c() == "3")
        a(2)
        CHECK(c() == "4")
    end

    do CASE "derive wrapped source"
        local a = source(1)

        local b = function()
            return tostring(a())
        end

        local c = derive(function()
            return tonumber(b())
        end)

        CHECK(c() == 1)
        a(2)
        CHECK(c() == 2)
    end

    do CASE "does not update if same value"
        local num = source(0)

        local is_even = derive(function()
            return bit32.band(num(), 0b01) == 0
        end)

        local count = 0

        effect(function()
            is_even()
            count += 1
        end)
        
        num(1) -- odd
        CHECK(count == 2)
        num(2) -- even
        CHECK(count == 3)
        num(4) -- even
        CHECK(count == 3)
        num(5) -- odd
        CHECK(count == 4)
    end

    do CASE "conditional derive"
        local a = source(false)
        local b = source(false)

        local c = derive(function()
            return
                if a() then "a"
                elseif b() then "b"
                else "never"
        end)

        local count = 0

        effect(function() c() count += 1 end)

        b(true)
        CHECK(c() == "b")
        CHECK(count == 2)
        a(true)
        CHECK(c() == "a")
        CHECK(count == 3)
        b(false)
        CHECK(count == 3)
        b(true)
        CHECK(count == 3)
        a(false)
        CHECK(c() == "b")
        CHECK(count == 4)
    end

    do CASE "owner not disconnected"
        local count = 0
        local a = source(0)

        local _, destroy = root(function()

            local b = derive(function()
                cleanup(function()
                    count += 1
                end)

                return a()
            end)
        end)

        CHECK(count == 0)
        a(1) -- b clears parents (should not clear owner)
        CHECK(count == 1)
        destroy()
        CHECK(count == 2)
    end

    do CASE "garbage collection"
        -- check that `b` does not allow gc of `a`        
        local a = source(1)

        local _b = derive(function()
            return a()
        end)

        _b = NIL

        local wref = weak { a }

        gc()
        CHECK(wref[1])
    end
end))

TEST("effect()", wrap_root(function()
    local source = vide.source
    local effect = vide.effect

    do CASE "rerun on source change"
        local a = source(1)
        local b = source(1)

        local count = 0
        effect(function()
            a()
            b()
            count += 1
        end)

        CHECK(count == 1)
        a(2)
        CHECK(count == 2)
        b(2)
        CHECK(count == 3)
    end
end))

TEST("cleanup()", wrap_root(function()
    local root = vide.root
    local source = vide.source
    local effect = vide.effect
    local cleanup = vide.cleanup

    do CASE "root cleanup"
        local count = 0

        local _, destroy = root(function()
            cleanup(function()
                count += 1
            end)

            return nil
        end)

        CHECK(count == 0)
        destroy()
        CHECK(count == 1)
    end

    do CASE "cleanup on rerun"
        local state = source(1)

        local effected = 0
        local cleaned = 0

        effect(function()
            state()
            effected += 1
            cleanup(function()
                cleaned += 1  
            end)
        end)

        CHECK(effected == 1)
        CHECK(cleaned == 0)

        state(2)

        CHECK(effected == 2)
        CHECK(cleaned == 1)
    end

    do CASE "multiple cleanup"
        local state = source(1)

        local queue = {}
    
        effect(function()
            state()
            cleanup(function() table.insert(queue, 1) end)
            cleanup(function() table.insert(queue, 2) end)
        end)

        CHECK(testkit.seq(queue, {}))
        state(2)
        CHECK(testkit.seq(queue, { 1, 2 }))
        state(3)
        CHECK(testkit.seq(queue, { 1, 2, 1, 2 }))
    end
end))

TEST("create()", wrap_root(function()
    local root = vide.root
    local create = vide.create
    local source = vide.source
    local cleanup = vide.cleanup

    do CASE "apply default properties"
        local defaults = require("src/defaults")
        local frame = create "Frame" {} :: Instance & { BorderSizePixel: any, BorderColor3: any }
        CHECK(frame.BorderSizePixel == defaults.Frame.BorderSizePixel)
        CHECK(frame.BorderColor3 == defaults.Frame.BorderColor3)
    end

    do CASE "set properties"
        local text = create "TextLabel" {
            Name = "Label",
            Text = "test"
        }
        CHECK(text.Name == "Label")
        CHECK(text.Text == "test")
    end

    do CASE "set nested properties"
        local text = create "TextLabel" {
            { Name = "Label" },
            { Text = "test" }
        }
        CHECK(text.Name == "Label")
        CHECK(text.Text == "test")
    end

    do CASE "aggregate construction"
        local template = create "TextLabel" {
            AnchorPoint = Vector2.new(),
            Position = UDim2.new()
        }

        local text = create(template) {
            AnchorPoint = { 1, 2 },
            Position = { 3, 4 }
        }

        CHECK(text.AnchorPoint == Vector2.new(1, 2))
        CHECK(text.Position == UDim2.new(3, 4))
    end

    do CASE "nested precedence"
        local text = create "TextLabel" {
            {
                Text = "1",

                { Text = "2" }
            }
        }

        CHECK(text.Text == "2")
    end

    do CASE "independent"
        local frame = create "Frame"
        CHECK(frame {} ~= frame {})
    end

    do CASE "set children"
        local frame = create "Frame" {
            create "TextLabel" { Name = "A" },
            create "TextLabel" { Name = "B" },
            {
                create "TextLabel" { Name = "C" } :: any,
                create "TextLabel" { Name = "D" },
                {
                    create "TextLabel" { Name = "E" }
                }
            },
            {
                create "TextLabel" { Name = "F" } :: any,
                { create "TextLabel" { Name = "G" } }
            }
        }

        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "B")
        CHECK(frame:FindFirstChild "C")
        CHECK(frame:FindFirstChild "D")
        CHECK(frame:FindFirstChild "E")

        CHECK(frame:FindFirstChild "F")
        CHECK(frame:FindFirstChild "G")
    end

    do CASE "binding properties to source"
        local name = source("Hi")
        local text = source("Bye")

        local label = create "TextLabel" {
            Name = name,
            Text = text
        }

        CHECK(label.Name == "Hi")
        CHECK(label.Text == "Bye")

        name "Foo"
        text "Bar"

        CHECK(label.Name == "Foo")
        CHECK(label.Text == "Bar")
    end

    do CASE "binding destroy"
        local count = 0

        local _, destroy = root(function()
            local src = source(0)

            return create "TextLabel" {
                Text = function()
                    cleanup(function()
                        count += 1
                    end)

                    return src()
                end
            }
        end)

        CHECK(count == 0)
        destroy()
        CHECK(count == 1)
    end

    do CASE "bind same state to multiple instance properties"
        local src = source "1"

        local text = create "TextBox" {
            Name = src,
            Text = src,
            PlaceholderText = src
        }

        src "2"

        CHECK(text.Name == "2")
        CHECK(text.Text == "2")
        CHECK(text.PlaceholderText == "2")
    end

    do CASE "bind children"
        local children = source()

        local a, b, c = 
            create "TextLabel" { Name = "A" },
            create "TextLabel" { Name = "B" },
            create "TextLabel" { Name = "C" }

        local frame = create "Frame" {
            children
        }
  
        children { a, b }

        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "B")

        -- check that b is removed and c is added while a remains untouched
        
        children { a, c }

        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "C")
        CHECK(not frame:FindFirstChild "B")

        children(nil)

        CHECK(#frame:GetChildren() == 0)
    end

    do CASE "parent bound to source"
        local wref, destroy = root(function()
            local frame = create "Frame" { Name = "Parent" }
            local parent = source(frame :: Frame?)

            local wref = weak {
                create "TextLabel" { Parent = parent, Name = "Child" }
            }

            gc()
            CHECK(wref[1])

            parent(nil)

            return wref
        end)

        gc()
        CHECK(wref[1])

        destroy()
        destroy = NIL

        gc()
        CHECK(not wref[1])
    end

    do CASE "garbage collection test"
        local wref

        do
            local data = setmetatable({}, {})
            local proxy = setmetatable({}, { __mode = "v" })

            local ref = setmetatable({}, { __mode = "v" })

            --proxy.data = data --? (this line should not affect outcome)
            -- `data` strongly references `proxy`
            data.connection = proxy

            -- `ref` strongly references `data`
            ref[data] = proxy

            -- although `ref` is weak to values, `data` keeps `proxy` alive
            -- this forms a sort of cyclic reference that the luau gc is unable to detect

            wref = { data = data, proxy = proxy }
        end

        gc()
        CHECK(wref.data and wref.proxy)
    end
end))

TEST("indexes()", wrap_root(function()
    local create = vide.create
    local source = vide.source
    local indexes = vide.indexes
    local cleanup = vide.cleanup

    do CASE "use source"
        local input = source { 1, 2, 3 }

        local output = indexes(input, function(v, k)
            return tostring(v())    
        end)

        CHECK("" .. input()[1] == output()[1])
        CHECK("" .. input()[2] == output()[2])
        CHECK("" .. input()[3] == output()[3])
    end

    do CASE "cache result"
        local input = source { 1, 2, 3 }

        local runcount = table.create(3, 0)

        local output = indexes(input, function(v, i)
            runcount[i] += 1
            return v
        end)

        input { 1, 2, 4 }

        CHECK(output()[1]() == 1)
        CHECK(output()[2]() == 2)
        CHECK(output()[3]() == 4)

        CHECK(runcount[1] == 1)
        CHECK(runcount[2] == 1)
        CHECK(runcount[3] == 1)
    end

    do CASE "removal reflected"
        local input = source { 1, 2, 3 }

        local destroyed = false

        local output = indexes(input, function(v, i)
            local text = create "TextLabel" {
                Text = function() return tostring(v()) end
            }

            cleanup(function()
                destroyed = true
            end)

            return text
        end)

        input { 1, 2 }

        local t = output()

        CHECK(t[1].Text == "1")
        CHECK(t[2].Text == "2")
        CHECK(t[3] == NIL)
        CHECK(destroyed == true)
    end

    do CASE "garbage collection"
        do -- check that `output` does not allow gc of `input`
            local input = source {}

            local _derived = indexes(input, function(v, i)
                return v
            end)

            local wref = weak { input }

            input = NIL

            gc()
            CHECK(wref[1]) 
        end

        do -- check that `input` allows gc of `output`
            local input = source {}

            local output = indexes(input, function(v, i)
                return v, i
            end)

            local wref = weak { output }

            output = NIL

            gc()
            CHECK(not wref[1])
        end
    end

    do CASE "cleanup"
        local input = source { 1, 2, 3 }

        local count = table.create(3, 0)
        
        local output = indexes(input, function(v, i)
            cleanup(function()
                count[i] += 1
            end)

            return {}
        end)

        output()

        CHECK(count[1] == 0)
        CHECK(count[2] == 0)
        CHECK(count[3] == 0)
    end
end))

TEST("values()", wrap_root(function()
    local create = vide.create
    local source = vide.source
    local values = vide.values
    local cleanup = vide.cleanup

    do CASE "use source"
        local input = source { 1, 2, 3 }

        local output = values(input, function(v, k)
            return tostring(v)    
        end)

        CHECK("" .. input()[1] == output()[1])
        CHECK("" .. input()[2] == output()[2])
        CHECK("" .. input()[3] == output()[3])
    end

    do CASE "cache result"
        local input = source { 1, 2, 3 }

        local runcount = table.create(3, 0)

        local output = values(input, function(v, i)
            runcount[v] += 1
            return i
        end)

        input { 1, 3, 2 }

        CHECK(output()[1]() == 1)
        CHECK(output()[2]() == 3)
        CHECK(output()[3]() == 2)

        CHECK(runcount[1] == 1)
        CHECK(runcount[2] == 1)
        CHECK(runcount[3] == 1)
    end

    do CASE "removal reflected"
        local input = source { 1, 2, 3 }

        local destroyed = false

        local output = values(input, function(v, i)
            local text = create "TextLabel" {
                Text = tostring(v)
            }

            cleanup(function()
                destroyed = true
            end)

            return text
        end)

        input { 1, 2 }

        local t = output()

        CHECK(t[1].Text == "1")
        CHECK(t[2].Text == "2")
        CHECK(t[3] == NIL)
        CHECK(destroyed == true)
    end

    do CASE "removal reflected 2"
        local input = source { 1 }

        local output = values(input, function(v, i)
            return { v = v, i = i }
        end)

        input { 2, 1 }
        input { 1 }

        local t = output()

        CHECK(t[1].v == 1)
        CHECK(t[1].i() == 1)
        CHECK(t[2] == nil)
        CHECK(t[3] == nil)
    end

    do CASE "cleanup"
        local input = source { 1, 2, 3 }

        local count = table.create(3, 0)
        
        local output = values(input, function(v, i)
            cleanup(function()
                count[i()] += 1
            end)

            return {}
        end)

        output()

        CHECK(count[1] == 0)
        CHECK(count[2] == 0)
        CHECK(count[3] == 0)
    end
end))

TEST("spring()", wrap_root(function()
    local create = vide.create
    local source = vide.source
    local spring = vide.spring
    local effect = vide.effect

    do CASE "update source (on next step)"
        local value = source(10)
        local sprung = spring(value, 1, 1)

        CHECK(sprung() == 10)
        value(20)
        CHECK(sprung() == 10)
        vide.step(1/60)
        CHECK(sprung() ~= 10)
        CHECK(sprung() > 10)
    end

    do CASE "garbage collection"
        --[[
        do -- `output` should not allow gc of `input`
            local input = source(10)
            local _output = spring(input)

            local wref = weak { input }
            input = NIL

            gc()
            CHECK(wref[1])
        end
        ]]

        do -- `input` should allow gc of `output`
            local input = source(10)
            local output = spring(input)
        
            local wref = weak { output }
            output = NIL
            
            gc()
            CHECK(not wref[1])
        end

        -- do -- spring data gc
        --     local input = source(10)

        --     local wref do
        --         local output, data = (spring :: any)(input)
        --         input(input() + 1) -- schedule spring calculation
        --         local output_node = unpack(capture(output))
        --         wref = weak { output_node, data }
        --     end
    
        --     gc()
        --     CHECK(not wref[1])
        --     CHECK(not wref[2])
        -- end
    end

    do CASE "garbage collection (binded)"
        local input = source(10)
        local output = spring(input, 1, 1)

        local _label = create "TextLabel" {
            Text = output
        }

        local wref = { output }
        output = NIL

        gc()
        CHECK(wref[1]) -- `output` should not gc
    end

    do CASE "spring finished"
        local input = source(0)
        local output = spring(input)

        input(1)
        vide.step(0.05)
        CHECK(output() ~= input()) -- check spring is moving
        vide.step(10) -- spring finished, should be internally removed from queue
        CHECK(output() == input()) -- check spring is at target

        local count = -1
        effect(function()
            output()
            count += 1
        end)

        vide.step(1) -- attempt to cause another spring update
        CHECK(count == 0) -- check no update occurs as spring is finished
        --

        gc() -- perform full gc
        input(2) -- spring should be re-added to spring queue
        vide.step(0) -- process spring queue
        CHECK(count == 1) -- check spring was rescheduled correctly
    end
end))

TEST("untrack()", wrap_root(function()
    local root = vide.root
    local source = vide.source
    local derive = vide.derive
    local effect = vide.effect
    local cleanup = vide.cleanup
    local untrack = vide.untrack

    do CASE "does not register dependency"
        local a = source(0)
        local b = source(0)

        local count = 0

        effect(function()
            count += 1
            untrack(a)
            b()
        end)

        b(1)
        CHECK(count == 2)

        a(1)
        CHECK(count == 2)

        CHECK(a() == untrack(a))
    end

    do CASE "derived state"
        local a = source(0)
        local b = source(0)
        local c = source(0)

        local d = function()
            return a() + b()
        end

        local count = 0

        effect(function()
            count += 1
            untrack(d)
            c()
        end)

        c(1)
        CHECK(count == 2)

        a(1)
        b(1)
        CHECK(count == 2)
    end

    do CASE "outer scope"
        local outer_count = 0
        local inner_count = 0
        local cleaned_count = 0

        local input = source(0)

        local output, destroy = root(function()
            local output = derive(function()
                outer_count += 1

                return untrack(function()
                    return derive(function()
                        inner_count += 1
    
                        cleanup(function()
                            cleaned_count += 1
                        end)
    
                        return tostring(input())
                    end)
                end)
            end)

            return output
        end)

        CHECK(outer_count == 1)
        CHECK(inner_count == 1)
        CHECK(cleaned_count == 0)

        local output2 = output()

        CHECK(output2() == "0")

        input(1)

        CHECK(outer_count == 1)
        CHECK(inner_count == 2)
        CHECK(cleaned_count == 1)

        local output3 = output()
        CHECK(output2() == "1")
        CHECK(output3() == "1")

        CHECK(output2 == output3)

        destroy()

        CHECK(cleaned_count == 2)
    end
end))

TEST("events", function()
    local create = vide.create

    local function Thing(props)
        local instance = Instance.new("Thing")
        instance.Signal = Signal.new()

        local clone = create(instance)(props)

        return clone
    end

    do CASE "connect event"
        local connected = false

        local val = Thing {
            Signal = function(newval)
                connected = true
                CHECK(newval == 1)
            end
        }

        CHECK(not connected)
        val.Value = 1; Signal.fire(val.Signal, val.Value)
        CHECK(connected)
    end
end)

TEST("actions", function()
    local create = vide.create
    local action = vide.action

    do CASE "run action"
        local ran = false

        local frame_ref
        local frame = create "Frame" {
            action(function(self)
                frame_ref = self
                ran = true
            end, 1)
        }

        CHECK(ran)
        CHECK(frame_ref == frame)
    end

    do CASE "priorities"
        local queue = {}

        create "Frame" {
            action(function(self)
                table.insert(queue, 2)
            end, 2),

            action(function(self)
                table.insert(queue, 1)
            end, 1)
        }

        CHECK(testkit.seq(queue, { 1, 2 }))
    end
end)

-- TEST("strict", function()
--     vide.strict = true

--     local create = vide.create
--     local source = vide.source
--     local derive = vide.derive
--     local effect = vide.effect
--     local indexes, values = vide.indexes, vide.values
--     local cleanup = vide.cleanup

--     -- do CASE "error on derived callback yield"
--     --     local state = source(1)

--     --     local ok = pcall(function()
--     --         local _derived = derive(function()
--     --             coroutine.yield()
--     --             return state()
--     --         end)
--     --     end)

--     --     CHECK(not ok)
--     -- end

--     -- do CASE "error on effecter callback yield"
--     --     local state = source(1)

--     --     local ok = pcall(function()
--     --         local _derived = effect(function()
--     --             coroutine.yield()
--     --             state()
--     --         end)
--     --     end)

--     --     CHECK(not ok)
--     -- end

--     do CASE "run derived callback twice"
--         local state = source(1)
--         local runcount = 0

--         local _ = derive(function()
--             runcount += 1
--             return state()
--         end)

--         CHECK(runcount == 2)
--         state(2)
--         CHECK(runcount == 4)
--     end

--     do CASE "run effecter callback twice"
--         local state = source(1)
--         local runcount = 0

--         effect(function()
--             runcount += 1
--             state()
--         end)

--         CHECK(runcount == 2)
--         state(2)
--         CHECK(runcount == 4)
--     end

--     do CASE "indexes() error if primitive"
--         local state = source { 1 }

--         local ok = pcall(function()
--             indexes(state, function() return 1 end)
--         end)

--         CHECK(not ok)
--     end

--     do CASE "values() error if duplicate"
--         local state = source { 1, 2, 1 }

--         local ok = pcall(function()
--             values(state, function() return {} end)
--         end)

--         CHECK(not ok)
--     end

--     do CASE "duplicate properties"
--         local ok = pcall(function()
--             create "TextLabel" {
--                 {
--                     Name = "foo"
--                 },
--                 {
--                     Name = "bar"
--                 }
--             }
--         end)

--         CHECK(not ok)

--         ok = pcall(function()
--             create "TextLabel" {
--                 {
--                     Name = "foo",
--                     {
--                         Name = "bar"
--                     }
--                 }
--             }
--         end)

--         CHECK(ok)
--     end

--     do CASE "multiple cleanup per scope"
--         local ok = pcall(function()
--             cleanup(function() end)
--             cleanup(function() end)
--         end)

--         CHECK(not ok)
--     end
-- end)

local ok = FINISH()
if not ok then error("Tests failed", 0) end

return nil
