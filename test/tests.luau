local testkit = require "./testkit"
local TEST, CASE, CHECK, FINISH = testkit.test()

local mock = require "./mock"
local Instance, Signal = mock.Instance, mock.Signal
local Vector2, UDim2 = mock.Vector2, mock.UDim2

local vide = require "../src/init"
local graph = require "../src/graph"
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
        local destroy = vide.mount(fn :: any)
        destroy()
    end
end

local NIL = nil :: any

vide.strict = false

TEST("graph", function()
    local create_node = graph.create_node
    local push_child_to_scope = graph.push_child_to_scope
    local update_descendants = graph.update_descendants
    local push_child = graph.push_child
    local get_scope = graph.get_scope
    local push_scope = graph.push_scope
    local pop_scope = graph.pop_scope
    local get_children = graph.get_children
    local push_cleanup = graph.push_cleanup
    local destroy = graph.destroy

    local function node<T>(owner: Node<any>?, v: T?)
        return create_node(owner or false, function(x) return not x end, v or false :: any)
    end

    local function scope(owner: Node<any>?)
        return create_node(owner or false, false, false)
    end

    local function cleanup(fn: () -> ())
        local node = assert(get_scope())
        push_cleanup(node, fn)
    end

    do CASE "link nodes"
        local a = node()
        local b = node()
        local c = node()

        push_scope(c)

        push_child_to_scope(a)
        push_child_to_scope(b)

        pop_scope()

        CHECK(get_children(a)[1] == c)
        CHECK(get_children(b)[1] == c)
    end

    do CASE "rerun linked nodes"
        local root = node()
        local a = node()
        local b = node(root)
        local c = node(root)

        local count = 0

        local function effect(x)
            push_child_to_scope(a)
            push_child_to_scope(b)
            count += 1
            return not x
        end

        c.effect = effect

        push_scope(c)

        effect(c.cache)

        pop_scope()
        
        CHECK(count == 1)
        update_descendants(a)
        CHECK(count == 2)
        update_descendants(b)
        CHECK(count == 3)
    end

    do CASE "diamond graph"
        -- a -> b -> d
        --   -> c
        local root = node()
        local a, b, c, d = node(), node(root), node(root), node(root)

        local b_cnt, c_cnt, d_cnt = 0, 0, 0
        function b.effect(x) b_cnt += 1; return not x end
        function c.effect(x) c_cnt += 1; return not x end
        function d.effect(x) d_cnt += 1; return not x end

        push_scope(b); push_child_to_scope(a); pop_scope()
        push_scope(c); push_child_to_scope(a); pop_scope()
        push_scope(d); push_child_to_scope(b); push_child_to_scope(c); pop_scope()

        update_descendants(a)

        CHECK(b_cnt == 1)
        CHECK(c_cnt == 1)
        CHECK(d_cnt == 1)
    end

    do CASE "duplicate child on rerun"
        local root = node()
        local a, b, c = node(root), node(root), node(root)

        function c.effect(x)
            push_child_to_scope(a)
            push_child_to_scope(b)
            return not x
        end

        push_scope(c); assert(type(c.effect) == "function" and c.effect)(NIL); pop_scope()

        update_descendants(a)

        CHECK(#get_children(a) == 1)
        CHECK(#get_children(b) == 1)
    end

    do CASE "case 1"
        -- construct graph

        local items = node(nil, { "a", "b" })
        local selected = node(nil, "a")

        local root = scope()

        local scope1 = scope(root)
        local scope2 = scope(root)

        local items_updated

        local bind1
        local bind2

        local cleaned = {} :: { [any]: any }

        local function clean(s)
            cleanup(function()
                cleaned[s] = true
            end)
        end

        do push_scope(root) 
            clean "root"
            items_updated = node(root)
            push_child_to_scope(items_updated) -- should not

            do push_scope(items_updated)
                push_child_to_scope(items)

                do push_scope(root)
                    do push_scope(scope1)
                        clean "scope1"
                        bind1 = node(scope1)

                        do push_scope(bind1)
                            clean "bind1"
                            push_child_to_scope(selected)
                        pop_scope() end
                    pop_scope() end

                    do push_scope(scope2)
                        clean "scope2"
                        bind2 = node(scope2)
                        do push_scope(bind2)
                            clean "bind2"
                            push_child_to_scope(selected)
                        pop_scope() end
                    pop_scope() end
                pop_scope() end
            pop_scope() end 
        pop_scope() end
        

        -- verify graph

        do
            local c = get_children(items_updated)
            CHECK(#c == 0)
        end
    
        do
            local c = get_children(root)
            CHECK(#c == 0)
            -- CHECK(table.find(c, items_updated))
            -- CHECK(table.find(c, scope1 :: Node<any>))
            -- CHECK(table.find(c, scope2 :: Node<any>))
        end

        do
            local c = get_children(selected)
            CHECK(#c == 2)
            CHECK(table.find(c, bind1 :: any))
            CHECK(table.find(c, bind2 :: any))
        end

        do
            local c = get_children(scope1)
            CHECK(#c == 0)
            --CHECK(table.find(c, bind1))
        end

        do
            local c = get_children(scope2)
            CHECK(#c == 0)
            --CHECK(table.find(c, bind2))
        end

        -- destroy

        --CHECK(table.find(get_children(root), scope1 :: Node<any>))

        destroy(scope1)
        CHECK(cleaned.scope1)
        CHECK(cleaned.bind1)
        scope1 = NIL
        bind1 = NIL
        bind2 = NIL
        gc()
        CHECK(#get_children(root) == 0)
        CHECK(#get_children(selected) == 1)
    end

    do CASE "nodes garbage collection"
        local wref = weak { node(nil, 1) }
        destroy(wref[1])
        gc()
        CHECK(not wref[1])
    end

    do CASE "recursive update"
        --[[

        A -> B + C
        D -> E + F

        B updates D

        depth=1
        B, C
        ^

        depth=2
        E, F
        ^

        depth=2
        _, F
           ^

        depth=1
        _, _   <- attempt to update_descendants nothing
           ^        

        ]]

        local root = node()
        local a, b, c, d, e, f = node(root), node(root), node(root), node(root), node(root), node(root)

        function b.effect(x)
            update_descendants(d)
            return not x
        end

        push_child(a, b); push_child(a, c)
        push_child(d, e); push_child(d, f)

        update_descendants(a)

        CHECK(true)
    end
end)

TEST("mount()", function()
    local mount = vide.mount
    local create = vide.create
    local source = vide.source
    local cleanup = vide.cleanup

    local screen = create "ScreenGui" {}

    local text = source "foo"
    local count = 0

    local unmount = mount(function()
        cleanup(function()
            count += 1
        end)

        return create "TextLabel" {
            Name = "TextLabel",
            Text = text
        }
    end, screen)

    local label = screen:FindFirstChild "TextLabel" :: TextLabel
    CHECK(label)
    CHECK(label.Text == "foo")

    text "bar"
    CHECK(label.Text == "bar")
    CHECK(count == 0)

    unmount()
    CHECK(count == 1)
end)

TEST("root()", function()
    local root = vide.root
    local cleanup = vide.cleanup

    local count = 0

    root(function(destroy)
        cleanup(function() count += 1 end)
        destroy()
    end)

    CHECK(count == 1)
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

        effect(function() c(); count += 1 end)

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

        local destroy = vide.mount(function()
            local _b = derive(function()
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

    -- do CASE "behavior of effect within an effect"
    --     local num = source(1)

    --     local ran = table.create(100, 0)
    --     local cleaned = table.create(100, 0)

    --     local destroy = vide.mount(function()
    --         local owner = derive(function()
    --             local i = num()

    --             return untrack(function()
    --                 return derive(function()
    --                     ran[i] += 1
    --                     cleanup(function()
    --                         cleaned[i] += 1
    --                     end)
    --                     return i
    --                 end)
    --             end)
    --         end)

    --         local child1 = owner()
    --         num(2)
    --         CHECK(cleaned[1] == 1)
    --         local child2 = owner()

    --         CHECK(child1() == 1)
    --         CHECK(child2() == 2)
    --     end)

    --     destroy()
        
    --     CHECK(ran[1] == 1)
    --     CHECK(ran[2] == 1)
    --     CHECK(cleaned[1] == 1)
    --     CHECK(cleaned[2] == 1)
    -- end

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
    local derive = vide.derive

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

    do CASE "rerun on derived source change"
        local num = source(0)

        local text = derive(function() return tostring(num()) end)
        
        local count = 0
        effect(function()
            text()
            count += 1
        end)

        num(1)

        CHECK(count == 2)
    end

    do CASE "cache"
        local num = source(0)

        local count

        effect(function(x: number)
            num()
            count = x + 1
            return x + 1
        end, 0)

        num(1)

        CHECK(count == 2)
    end
end))

TEST("cleanup()", wrap_root(function()
    local root = vide.root
    local source = vide.source
    local effect = vide.effect
    local cleanup = vide.cleanup

    do CASE "root cleanup"
        local count = 0

        local destroy = vide.mount(function()
            cleanup(function()
                count += 1
            end)
        end)

        CHECK(count == 0)
        destroy()
        CHECK(count == 1)
    end

    do CASE "cleanup on rerun"
        local src = source(1)

        local effected = 0
        local cleaned = 0

        effect(function()
            src()
            effected += 1
            cleanup(function()
                cleaned += 1  
            end)
        end)

        CHECK(effected == 1)
        CHECK(cleaned == 0)

        src(2)

        CHECK(effected == 2)
        CHECK(cleaned == 1)
    end

    do CASE "multiple cleanup"
        local src = source(1)

        local queue = {}
    
        effect(function()
            src()
            cleanup(function() table.insert(queue, 1) end)
            cleanup(function() table.insert(queue, 2) end)
        end)

        CHECK(testkit.seq(queue, {}))
        src(2)
        CHECK(testkit.seq(queue, { 1, 2 }))
        src(3)
        CHECK(testkit.seq(queue, { 1, 2, 1, 2 }))
    end

    do CASE "cleanup objects"
        local ran = {}

        root(function(destroy)
            effect(function()
                cleanup { disconnect = function() ran.disconnect = true end }
                cleanup { Disconnect = function() ran.Disconnect = true end }
                cleanup { destroy = function() ran.destroy = true end }
                cleanup { Destroy = function() ran.Destroy = true end }
                destroy()
            end)
        end)

        CHECK(ran.disconnect)
        CHECK(ran.Disconnect)
        CHECK(ran.destroy)
        CHECK(ran.Destroy)
    end
end))

TEST("create()", wrap_root(function()
    local create = vide.create
    local source = vide.source
    local cleanup = vide.cleanup

    do CASE "apply default properties"
        local defaults = require "../src/defaults"
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

        local destroy = vide.mount(function()
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

    do CASE "bind same source to multiple instance properties"
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
        local _, wref, destroy = vide.root(function(destroy)
            local frame = create "Frame" { Name = "Parent" }
            local parent = source(frame :: Frame?)

            local wref = weak {
                create "TextLabel" { Parent = parent, Name = "Child" }
            }

            gc()
            CHECK(wref[1])

            parent(nil)

            return wref, destroy
        end)

        gc()
        CHECK(wref[1])

        destroy()
        destroy = NIL

        gc()
        CHECK(not wref[1])
    end

    do CASE "recursive create"
        local set_test_to_true = vide.action(function(self) (self :: any).test = true end)

        local f2
    
        local to_apply = {
            { a = 1 },
            set_test_to_true,
            b = function() f2 = create "Frame" { a = 2 } end,
        } :: { [number|string]: unknown }

        -- do -- confirm iteration order
        --     local t = {}
        --     for i in to_apply do
        --         table.insert(t, i)
        --     end
        --     assert(t[1] == "a")
        -- end

        local f = create "Frame" (to_apply)

        CHECK((f :: any).a == 1)
        CHECK((f :: any).test == true )

        CHECK((f2 :: any).a == 2)
    end

    do CASE "nested children effect"
        local a = create "Frame" { Name = "a" }
        local b = create "Frame" { Name = "b" }
        local c = create "Frame" { Name = "c" }
        local d = create "Frame" { Name = "d" }
        local e = create "Frame" { Name = "e" }
        
        local children = source {
            a,
            { b, c, { d } },
            { { e } }
        }
        
        local obj = create "Frame" {
            children
        }

        CHECK(obj:FindFirstChild("a"))
        CHECK(obj:FindFirstChild("b"))
        CHECK(obj:FindFirstChild("c"))
        CHECK(obj:FindFirstChild("d"))
        CHECK(obj:FindFirstChild("e"))

        children {
            b,
            { c, a },
            { { d } }
        }

        CHECK(obj:FindFirstChild("a"))
        CHECK(obj:FindFirstChild("b"))
        CHECK(obj:FindFirstChild("c"))
        CHECK(obj:FindFirstChild("d"))
        CHECK(not obj:FindFirstChild("e"))
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

TEST("show()", wrap_root(function()
    local untrack = vide.untrack
    local cleanup = vide.cleanup
    local source = vide.source
    local effect = vide.effect
    local show = vide.show
    local root = vide.root

    do CASE "main"
        -- uses switch() internally, more extensive testing of scoping not needed
        local value = source("truey" :: unknown)
        local function one() return 1 end
        local function two() return 2 end

        local output = show(value, one, two)

        CHECK(output() == 1)
        value(nil)
        CHECK(output() == 2)
    end

    do CASE "alt"
        local visible = vide.source(true)
        local count = vide.source(0)

        local outer = 0
        local inner = 0
        local destroyed = 0

        root(function()
            effect(function()
                visible()
                outer += 1

                untrack(function()
                    effect(function()
                        count()

                        inner += 1

                        cleanup(function()
                            destroyed += 1
                        end)
                    end)
                    return nil
                end)
            end)
        end)

        CHECK(outer == 1)
        CHECK(inner == 1)
        CHECK(destroyed == 0)

        count(count() + 1)
        CHECK(outer == 1)
        CHECK(inner == 2)
        CHECK(destroyed == 1)

        visible(false)
        CHECK(outer == 2)
        CHECK(inner == 3)
        CHECK(destroyed == 2)

        count(count() + 1)
        CHECK(outer == 2)
        CHECK(inner == 4)
        CHECK(destroyed == 3)
    end
end))

TEST("switch()", wrap_root(function()
    local source = vide.source
    local switch = vide.switch
    local effect = vide.effect
    local cleanup = vide.cleanup

    do CASE "update on source change"
        local input = source(true)

        local output = switch(input) {
            [true] = function() return 1 end,
            [false] = function() return 0 end
        }

        local count = 0

        effect(function() output(); count += 1 end)

        CHECK(count == 1)
        CHECK(output() == 1)
    
        input(false)
        CHECK(output() == 0)
        CHECK(count == 2)
    
        input(false)
        CHECK(output() == 0)
        CHECK(count == 2)
    
        input(NIL)
        CHECK(output() == nil)
    end

    do CASE "same component different map"
        local input = source(0)

        local function component()
            return {}
        end

        local output = switch(input) {
            [1] = component,
            [2] = component
        }

        CHECK(output() == nil)

        input(1)
        local instance = output()
        CHECK(instance)

        input(2)
        CHECK(output() == instance)

    end

    do CASE "scoped switch"
        local input = source(true)

        local owner_count = 0
        local switch0_count = 0
        local switch1_count = 0

        cleanup(function() owner_count += 1 end)

        local output = switch(input) {
            [true] = function() 
                cleanup(function() switch1_count += 1 end)
                return 1
            end,

            [false] = function() 
                cleanup(function() switch0_count += 1 end)
                return 0
            end
        }

        CHECK(output() == 1)
        input(false)
        CHECK(switch1_count == 1)
        CHECK(switch0_count == 0)
        input(true)
        CHECK(switch1_count == 1)
        CHECK(switch0_count == 1)
        input(NIL)
        CHECK(switch1_count == 2)
        CHECK(switch0_count == 1)
        CHECK(owner_count == 0)
    end

    do CASE "reactive stack resets after error"
    local scopes = require "../src/graph".scopes
        local input = source(1)

        local n0 = scopes.n

        local ok = pcall(function()
            switch(input) {
                error :: any
            }
        end)

        CHECK(not ok)

        local n1 = scopes.n

        CHECK(n0 == n1)
    end

    do CASE "strict"
        vide.strict = true

        local input = source(0)
        local output = switch(input) {
            [0] = function() return 0 end,
            [1] = function() return 1 end,
        }

        CHECK(output() == 0)
        input(1)
        CHECK(output() == 1)

        vide.strict = false
    end
end))

TEST("indexes()", wrap_root(function()
    local create = vide.create
    local source = vide.source
    local effect = vide.effect
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

        local count = table.create(3, 0)

        local _, output = vide.root(function()
            local output = indexes(input, function(v, i)
                count[i] += 1
                return v
            end)

            return output
        end)

        input { 1, 2, 4 }

        CHECK(output()[1]() == 1)
        CHECK(output()[2]() == 2)
        CHECK(output()[3]() == 4)

        CHECK(count[1] == 1)
        CHECK(count[2] == 1)
        CHECK(count[3] == 1)
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

    do CASE "reactive stack resets after error"
        local scopes = require "../src/graph".scopes

        local input = source { 1 }

        local n0 = scopes.n

        local ok = pcall(function()
            indexes(input, function()
                error("")
                return NIL
            end)
        end)

        CHECK(not ok)

        local n1 = scopes.n

        CHECK(n0 == n1)
    end

    -- practical example based on the graph - recursive update test
    do CASE "recursive update"
        local items = source { 1 }

        local updated = table.create(100, 0)

        indexes(items, function(item)
            effect(function()
                item()
                updated[1] += 1    
            end)

            effect(function()
                item()
                updated[2] += 1    
            end)

            return {}
        end)

        effect(function()
            items()
            updated[3] += 1
        end)

        effect(function()
            items()
            updated[4] += 1
        end)

        items { 2 }

        CHECK(updated[1] == 2)
        CHECK(updated[2] == 2)
        CHECK(updated[3] == 2)
        CHECK(updated[4] == 2)
    end

    do CASE "strict"
        vide.strict = true

        local input = source{1}
        local output = indexes(input, function(v)
            return { v }
        end)

        CHECK(output()[1][1]() == 1)
        input{2}
        CHECK(output()[1][1]() == 2)

        vide.strict = false
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

        local count = table.create(3, 0)

        local output = values(input, function(v, i)
            count[v] += 1
            return i
        end)

        input { 1, 3, 2 }

        CHECK(output()[1]() == 1)
        CHECK(output()[2]() == 3)
        CHECK(output()[3]() == 2)

        CHECK(count[1] == 1)
        CHECK(count[2] == 1)
        CHECK(count[3] == 1)
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

    do CASE "reactive stack resets after error"
        local scopes = require "../src/graph".scopes

        local input = source { 1 }

        local n0 = scopes.n

        local ok = pcall(function()
            values(input, function()
                error("")
                return NIL
            end)
        end)

        CHECK(not ok)

        local n1 = scopes.n

        CHECK(n0 == n1)
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
    local source = vide.source
    local effect = vide.effect
    local derive = vide.derive
    local untrack = vide.untrack
    local cleanup = vide.cleanup
    local root = vide.root

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

    do CASE "derived source"
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

        local _, output, destroy = root(function(destroy)
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

            return output, destroy
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

TEST("changed()", wrap_root(function()
    local root = vide.root
    local create = vide.create
    local source = vide.source
    local changed = vide.changed

    do CASE "outputs"
        local output = source(nil)

        local text = create "TextLabel" {
            Text = "a",
            changed("Text", output)
        }

        CHECK(output() == "a")
        text.Text = "b"
        CHECK(output() == "b")
    end

    do CASE "connection disconnected"
        local _, text, destroy = root(function(destroy)
            local output = source(nil)

            return create "TextLabel" {
                Text = "a",
                changed("Text", output)
            }, destroy
        end)

        destroy() -- changed() should of disconnect connection

        -- check if instance can gc
        local wref = weak { text }
        text = NIL
        gc()
        CHECK(not wref[1])
    end
end))

TEST("batch()", wrap_root(function()
    local source = vide.source
    local derive = vide.derive
    local effect = vide.effect
    local batch = vide.batch

    do CASE "evaluation deferred"
        local a = source(0)

        local count = { b = 0, b2 = 0, c = 0 }

        local b = derive(function()
            count.b += 1
            return a() + 1
        end)

        local b2 = derive(function()
            count.b2 += 1
            return a() + 2
        end)

        local c = derive(function()
            count.c += 1
            return b() + b2()
        end)

        batch(function()
            a(1)
            CHECK(count.b == 1)
            CHECK(count.b2 == 1)
            CHECK(count.c == 1)
        end)

        CHECK(count.b == 2)
        CHECK(count.b2 == 2)
        CHECK(count.c == 2)

        CHECK(b() == 2)
        CHECK(c() == 5)
    end

    do CASE "recursive call"
        local a1 = source(0)
        local a2 = source(0)
        local a3 = source(0)

        local count = { b1 = 0, b2 = 0, b3 = 0 }

        local b1 = derive(function()
            count.b1 += 1
            return a1() + 1
        end)

        local b2 = derive(function()
            count.b2 += 1
            return a2() + 1
        end)

        local b3 = derive(function()
            count.b3 += 1
            return a3() + 1
        end)

        batch(function()
            a1(1)
            batch(function()
                a2(2)
            end)
            a3(3)
            CHECK(count.b1 == 1)
            CHECK(count.b2 == 1)
            CHECK(count.b3 == 1)
        end)

        CHECK(count.b1 == 2)
        CHECK(count.b2 == 2)
        CHECK(count.b3 == 2)

        CHECK(b1() == 2)
        CHECK(b2() == 3)
        CHECK(b3() == 4)
    end

    do CASE "subsequent updates do not batch"

        local a = source(0)
        local b = source(0)
        local c = source(0)
        local d_n = 0

        effect(function()
            b()
            c()
            d_n += 1
        end)

        effect(function()
            b(a())
            c(a())
        end)
        
        batch(function()
            a(1)
        end)

        CHECK(d_n == 3)

    end

    do CASE "recursive queue flush diamond A,B,C,D"
        --[[

        a > b > d
          > c >

        ]]

        local a = source(0)

        local b = source(0)
        local c = source(0)
        local d = source(0)

        local count = { b = 0, c = 0, d = 0 }
        effect(function()
            batch(function()
                b(a() % 2 == 0 and 1 or 0)
                c(a() * 2)
            end)
            count.b += 1
            count.c += 1
        end)

        effect(function()
            batch(function()
                d(b() + c())
            end)
            count.d += 1
        end)

        a(1)
        CHECK(count.b == 2)
        CHECK(count.c == 2)
        CHECK(count.d == 2)
        CHECK(d() == 2)

        a(3)
        CHECK(count.b == 3)
        CHECK(count.c == 3)
        CHECK(count.d == 3)
        CHECK(d() == 6)
    end

    do CASE "recursive queue flush diamond A,B,C,D,E"
        --[[
        where b and c batches d
        
        a > b >     e
          > c > d >
        
        ]]

        local a = source(0)

        local b = source(0)
        local c = source(0)
        local d = source(0)
        local e = source(0)

        local count = { b = 0, c = 0, d = 0, e = 0 }
        effect(function()
            batch(function()
                b(a() % 2 == 0 and 1 or 0)
                c(a() * 2)
            end)
            count.b += 1
            count.c += 1
        end)

        effect(function()
            batch(function()
                d(c() * 2)
            end)
            count.d += 1
        end)

        effect(function()
            batch(function()
                e(b() + d())
            end)
            count.e += 1
        end)

        CHECK(e() == 1)

        a(1)

        CHECK(count.b == 2)
        CHECK(count.c == 2)
        CHECK(count.d == 2)
        CHECK(count.e == 3)
        CHECK(e() == 4)

        a(3)
        CHECK(count.b == 3)
        CHECK(count.c == 3)
        CHECK(count.d == 3)
        CHECK(count.e == 4)
        CHECK(e() == 12)

    end

    do CASE "recursive queue flush diamond A,B,C,D,E,F,G"
        --[[

        a > b > d > E > G
          > c ^   > F  

        ]]

        local a = source(0)

        local b = source(0)
        local c = source(0)
        local d = source(0)
        
        local e = source(0)
        local f = source(0)
        local g = source(0)

        local count = { b = 0, c = 0, d = 0, e = 0, f = 0, g = 0 }
        effect(function()
            batch(function()
                b(a() % 2 == 0 and 1 or 0)
                c(a() * 2)
            end)
            count.b += 1
            count.c += 1
        end)

        effect(function()
            batch(function()
                d(b() + c())
            end)
            count.d += 1
        end)

        effect(function()
            batch(function()
                e(d() % 2 == 0 and 1 or 0)
                f(d() * 2)
            end)
            count.e += 1
            count.f += 1
        end)

        effect(function()
            batch(function()
                g(e() + f())
            end)
            count.g += 1
        end)

        a(1)
        CHECK(count.b == 2)
        CHECK(count.c == 2)
        CHECK(count.d == 2)
        CHECK(count.e == 2)
        CHECK(count.f == 2)
        CHECK(count.g == 2)
        CHECK(d() == 2)
        CHECK(g() == 5)

        a(3)
        CHECK(count.b == 3)
        CHECK(count.c == 3)
        CHECK(count.d == 3)
        CHECK(count.e == 3)
        CHECK(count.f == 3)
        CHECK(count.g == 3)
        CHECK(d() == 6)
        CHECK(g() == 13)


    end

end))

TEST("read()", wrap_root(function()
    local source = vide.source
    local effect = vide.effect
    local read = vide.read :: any -- todo

    do CASE "read primitive"
        CHECK(read(1) == 1)
    end

    do CASE "read source"
        local src = source(1) :: () -> number
        CHECK(read(src) == 1)
    end

    do CASE "push_child_to_scope source"
        local src = source(0)

        local count = 0
        effect(function()
            read(src)
            count += 1
        end)

        src(1)
        CHECK(count == 2)
    end
end))

TEST("context()", function()
    local root = vide.root
    local context = vide.context
    local effect = vide.effect
    local untrack = vide.untrack
    local show = vide.show

    do CASE "set context"
        local ctx = context()

        root(function()
            ctx(1, function()
                CHECK(ctx() == 1)

                effect(function()
                    CHECK(ctx() == 1)
                end)
            end)
        end)
    end

    do CASE "set context outside of scope"
        local ctx = context()

        local ok = pcall(function()
            ctx(1, function() end)
        end)
        
        CHECK(not ok)
    end

    do CASE "get default context"
        local ctx = context(1)

        CHECK(ctx() == 1)

        root(function()
            local v = ctx(2, function()
                CHECK(ctx() == 2)
                return ctx()
            end)

            CHECK(v == 2)
            CHECK(ctx() == 1)
        end)
    end

    do CASE "context cascade"
        local ctx = context(1)
        local ctx2 = context()

        root(function()
            ctx(2, function()
                ctx2(true, function()
                    show(function() return true end, function()
                        ctx(3, function()
                            effect(function()
                                CHECK(ctx() == 3)
                                untrack(function()
                                    effect(function()
                                        CHECK(ctx() == 3)
                                    end)
                                    CHECK(ctx2() == true)
                                    return {}
                                end)
                            end)
                            CHECK(ctx() == 3)
                        end)
                        CHECK(ctx() == 2)
                        return {}
                    end)
                end)
                CHECK(ctx() == 2)
            end)

            CHECK(ctx() == 1)
        end)
    end

    do CASE "nil context"
        local ctx = context(nil)

        root(function()
            CHECK(ctx() == nil)
            ctx(nil, function()
                CHECK(ctx() == nil)
                ctx(true :: any, function()
                    CHECK(ctx() == true)
                    ctx(nil, function()
                        effect(function()
                            untrack(function()
                                effect(function()
                                    CHECK(ctx() == nil)
                                end)
                                return {}
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end
end)

TEST("nested effects cases", function()
    local vide = require "../src/init"
    local source = vide.source
    local effect = vide.effect
    local untrack = vide.untrack
    local cleanup = vide.cleanup
    local root = vide.root

    local ran = 0
    local cleaned = 0

    local function Count()
        local count = source(0)

        effect(function()
            count()
            ran += 1
            cleanup(function() cleaned += 1 end)
        end)

        return nil
    end

    local function App(destroy)
        local name = source "a"

        effect(function()
            name()
            untrack(Count)
        end)

        CHECK(ran == 1)
        CHECK(cleaned == 0)

        name "b"

        CHECK(ran == 2)
        CHECK(cleaned == 1)

        destroy()

        CHECK(ran == 2)
        CHECK(cleaned == 2)
    end

    root(App)
end)

TEST("graph edge cases", wrap_root(function()
    local source = vide.source
    local derive = vide.derive
    local effect = vide.effect
    local root = vide.root

    do CASE "diamond A,B,C,D"
        --[[

        a > b > d
          > c >

        ]]

        local a = source(0)

        local b = derive(function() return (a() % 2 == 0) and 1 or 0 end)
        local c = derive(function() return a() * 2 end)
        local d = derive(function() return b() + c() end)

        local count = { b = 0, c = 0, d = 0 }
        effect(function() b(); count.b += 1 end)
        effect(function() c(); count.c += 1 end)
        effect(function() d(); count.d += 1 end)

        a(1)
        CHECK(count.b == 2)
        CHECK(count.c == 2)
        CHECK(count.d == 2)
        CHECK(d() == 2)

        a(3)
        CHECK(count.b == 2)
        CHECK(count.c == 3)
        CHECK(count.d == 3)
        CHECK(d() == 6)
    end

    do CASE "diamond A,B,C,D,E"
        --[[

        a > b   >   e
          > c > d >

        ]]

        local a = source(0)

        local b = derive(function() return (a() % 2 == 0) and 1 or 0 end)
        local c = derive(function() return a() * 2 end)
        local d = derive(function() return c() * 2 end)
        local e = derive(function() return b() + d() end)

        local count = { b = 0, c = 0, d = 0, e = 0 }
        effect(function() b(); count.b += 1 end)
        effect(function() c(); count.c += 1 end)
        effect(function() d(); count.d += 1 end)
        effect(function() e(); count.e += 1 end)

        CHECK(e() == 1)

        a(1)

        CHECK(count.b == 2)
        CHECK(count.c == 2)
        CHECK(count.d == 2)
        CHECK(count.e == 3) -- todo: redundant re-eval
        CHECK(e() == 4)

        a(3)
        CHECK(count.b == 2)
        CHECK(count.c == 3)
        CHECK(count.d == 3)
        CHECK(count.e == 4)
        CHECK(e() == 12)
    end

    do CASE "repeated read"
        local a = source(0)
        local b = derive(function() return a() + a() end)

        local count = 0
        effect(function() b(); count += 1 end)

        a(1)
        CHECK(b() == 2)
        CHECK(count == 2)
    end

    do CASE "do not destroy children"
        local parent = source(0)   

        local _,
            destroy,
            parent_to_destroy,
            update_parent_to_destroy
        = root(function(destroy)
            local src = source(0)
            return
                destroy,
                derive(function() return src() end),
                src
        end)

        local count = 0

        effect(function()
            count += 1
            parent()
            parent_to_destroy()
        end)

        parent(parent() + 1)
        CHECK(count == 2)
        update_parent_to_destroy(1)
        CHECK(count == 3)

        destroy()
        
        update_parent_to_destroy(2)
        CHECK(count == 3)
        
        parent(parent() + 1)
        CHECK(count == 4)
    end

    do CASE "double destroy"
        -- issue:
        -- parent evaluates
        -- child A queued
        -- child B queued
        -- child A destroys child B
        -- child B reevaluates due to already being queued
        -- parent destroys, destroys child B - uh oh

        local _,
            destroy_parent,
            parent,
            update_parent
        = root(function(destroy)
            local src = source(0)
            return
                destroy,
                derive(function() return src() end),
                src
        end)

        local _, destroy_child, _child_B = nil, function() end, nil

        local count_A = 0
    
        -- child_A
        effect(function()
            count_A += 1
            parent()
            destroy_child()
        end)

        local count_B = 0
        destroy_child, _child_B = root(function(destroy)
            return
                destroy,
                derive(function() count_B += 1; return parent() end)
        end)

        update_parent(parent() + 1)
        CHECK(count_A == 2)
        CHECK(count_B == 1) -- child B should not run again
        destroy_parent() -- should not error
        CHECK(true)
    end
end))

TEST("strict", wrap_root(function()
    vide.strict = true

    local root = vide.root
    local show = vide.show
    local create = vide.create
    local source = vide.source
    local derive = vide.derive
    local effect = vide.effect
    local indexes, values = vide.indexes, vide.values
    local untrack = vide.untrack

    do CASE "error on derived callback yield"
        local src = source(1)

        local ok = pcall(function()
            local _derived = derive(function()
                coroutine.yield()
                return src()
            end)
        end)

        CHECK(not ok)
    end

    do CASE "error on effecter callback yield"
        local src = source(1)

        local ok = pcall(function()
            effect(function()
                coroutine.yield()
                src()
            end)
        end)

        CHECK(not ok)
    end

    do CASE "run derived callback twice"
        local src = source(1)
        local count = 0

        local _ = derive(function()
            count += 1
            return src()
        end)

        CHECK(count == 2)
        src(2)
        CHECK(count == 4)
    end

    do CASE "run effect callback twice"
        local src = source(1)
        local count = 0

        effect(function()
            count += 1
            src()
        end)

        CHECK(count == 2)
        src(2)
        CHECK(count == 4)
    end

    do CASE "indexes() error if primitive"
        local src = source { 1 }

        local ok = pcall(function()
            indexes(src, function() return 1 end)
        end)

        CHECK(not ok)
    end

    do CASE "values() error if duplicate"
        local src = source { 1, 2, 1 }

        local ok = pcall(function()
            values(src, function() return {} end)
        end)

        CHECK(not ok)
    end

    do CASE "duplicate properties"
        local ok = pcall(function()
            create "TextLabel" {
                {
                    Name = "foo"
                },
                {
                    Name = "bar"
                }
            }
        end)

        CHECK(not ok)

        ok = pcall(function()
            create "TextLabel" {
                {
                    Name = "foo",
                    {
                        Name = "bar"
                    }
                }
            }
        end)

        CHECK(ok)
    end

    do CASE "effect counter"
        local src = source(true)

        local count = 0

        effect(function(x: number)
            src()
            count = x + 1
            return count
        end, count)

        CHECK(count == 2)
        src(not src())
        CHECK(count == 4)
    end

    do CASE "effect using derived source"
        local input = source(true)

        local output = derive(function()
            return input()
        end)

        local count = 0

        effect(function()
            output()
            count += 1
        end)

        CHECK(count == 2)

        input(false)

        CHECK(count == 4)
    end

    do CASE "destruction of active scope"
        local src = source(false)

        root(function()
            show(src, function()
                src(false)
                return {}
            end)
        end)

        local ok = pcall(function()
            src(true)
        end)

        CHECK(not ok)
    end

    -- todo: review intended behavior here
    -- do CASE "destruction of active scope in indexes"
    --     local src = source {}

    --     local tmp
    --     root(function()
    --         effect(function()
    --             untrack(function()
    --                 tmp = indexes(src, function()
    --                     vide.cleanup(function() print "test" end)
    --                     src {}
    --                     print "updated"
    --                     vide.cleanup(function() print "test2" end)
    --                     print "end"
    --                     return {}
    --                 end)
    --                 return nil
    --             end)
    --         end)
    --     end)

    --     print "setting"

    --     local ok = pcall(function()
    --         src { 1 }
    --         print "done"
    --     end)

    --     print(#tmp())

    --     CHECK(not ok)
    -- end
end))

local ok = FINISH()
if not ok then error("Tests failed", 0) end

return nil
