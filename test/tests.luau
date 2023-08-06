local testkit = require("test/testkit")
local TEST, CASE, CHECK, FINISH, SKIP = testkit.test()

local Signal = require "test/goodsignal"
local mock = require "test/mock"


local Instance, Vector3, Color3, Vector2, UDim2 =
    mock.Instance, mock.Vector3, mock.Color3, mock.Vector2, mock.UDim2

local vide = require "src/init"

-- force run garbage collector cycles
local function gc(n: number?)
    for i = 1, n or 3 do
        (collectgarbage :: any)("collect")
    end
end

local function weak<T>(t: T & {}): T
    setmetatable(t :: {}, { __mode = "kv" })
    return t
end

TEST("graph", function()
    local graph = require "src/graph"
    local create = graph.create
    local get = graph.get
    local set = graph.set
    local capture = graph.capture
    local capture_and_link = graph.capture_and_link
    local link = graph.link
    local set_effect = graph.set_effect

    do CASE "Node creation"
        local node = create(1)
        CHECK(get(node) == 1)
    end

    do CASE "Node value"
        local node = create(0)
        set(node, 1)
        CHECK(get(node) == 1)
        set(node, 2)
        CHECK(get(node) == 2)
    end

    do CASE "Capture nodes"
        local node1 = create(nil)
        local node2 = create(nil)
        local nodes = capture(function()
            return get(node1), get(node2)
        end)
        CHECK(nodes[1] == node1)
        CHECK(nodes[2] == node2)
    end

    do CASE "Linking nodes"
        local parent = create(1)
        local child = create(0)

        link(parent, child, function() 
            return get(parent)
        end)

        set(parent, get(parent) + 1)
        CHECK(get(child) == 2) -- child should automatically update
    end

    do CASE "Capture and link nodes"
        local parent = create(1)
        local child = create()

        child.cache = capture_and_link(child, function()
            return tostring(get(parent))
        end)

        set(parent, 2)
        CHECK(get(child) == "2")
    end

    --[[
    do CASE "Scoped captures"
        local a = create(0)
        local b = create(nil :: any)

        local count = 0
        
        b.cache = capture_and_link(b, function()
            count += 1
            local data = get(a)
            local c = create(data)
            get(c)
            return c
        end)

        local c = get(b)

        CHECK(count == 1)
        set(c, 1)
        CHECK(count == 1)
        set(a, 1)
        CHECK(count == 2)
    end
    ]]

    do CASE "Nodes garbage collection"
        local wref = weak { create(1) }
        gc()
        CHECK(not wref[1])
    end

    do CASE "Node effect garbage collection"
        do
            local wref

            do
                local function factory(p) -- factory function to prevent closure caching
                    return function()
                        return get(p)
                    end
                end

                local node = create(1)
                
                do
                    local effect1 = factory(node)
                    local effect2 = factory(node)

                    wref = weak { e1 = effect1, e2 = effect2, n = node}

                    set_effect(node, effect1, {})
                    set_effect(node, effect2, true)
                end

                gc()
                CHECK(not wref.e1) -- effect1 should gc since nothing is referencing table `t`
                CHECK(wref.e2) -- effect2 should not gc as `true` is not garbage collectable
            end

            gc()
            CHECK(not wref.n and not wref.e2) -- node should now gc along with effect2
        end

        do
            local wref

            do -- same test but for multiple nodes referenced by watcher
                local function factory(a, b)
                    return (function(c, d)
                        return function()
                            return get(c), get(d)
                        end
                    end)(a, b)
                end

                local node1 = create(1)
                local node2 = create(1)

                do 
                    local effect = factory(node1, node2)

                    wref = weak { n1 = node1, n2 = node2, e = effect }

                    local t1 = {}
                    set_effect(node1, effect, t1)
                    set_effect(node2, effect, t1)
                end

                gc()
                CHECK(not wref.e)
            end

            gc()
            CHECK(not wref.n1)
            CHECK(not wref.n2)
        end
    end
end)

TEST("source()", function()
    local source = vide.source
    local watch = vide.watch

    do CASE "Create source"
        local state = source(1)
        CHECK(state() == 1)
    end

    do CASE "Set and get source value"
        local state = source(1)
        state(2)
        CHECK(state() == 2)
    end

    do CASE "Does not update if same value"
        local state = source(1)

        local updates = -1
        watch(function()
            state()
            updates += 1
        end)

        CHECK(updates == 0)
        state(1)
        CHECK(updates == 0)
        state(2)
        CHECK(updates == 1)
    end

    do CASE "Does update if same value is table"
        local state = source {}

        local updates = -1
        watch(function()
            state()
            updates += 1
        end)

        CHECK(updates == 0)
        state(state())
        CHECK(updates == 1)
    end
end)

TEST("derive()", function()
    local source = vide.source
    local derive = vide.derive

    do CASE "Derive new value on source change"
        local inputA = source(1)
        local inputB = source(2)

        local output = derive(function()
            return tostring(inputA() + inputB())
        end)

        CHECK(output() == "3")
        inputA(2)
        CHECK(output() == "4")
    end

    do CASE "Derive transformed source"
        local input = source(1)

        local transform = function()
            return tostring(input())
        end

        local output = derive(function()
            return tonumber(transform())
        end)

        CHECK(output() == 1)
        input(2)
        CHECK(output() == 2)
    end

    --[[
    do CASE "Cleanup"
        local count, set = source(1)

        local derived = derive(function(from)
            return { Value = from(count), Destroyed = false }
        end, function(v)
            v.Destroyed = true
        end)

        local first = derived()
        CHECK(first.Destroyed == false)
        set(2)
        local _ = derived() -- trigger recalc
        CHECK(first.Destroyed == true)
    end
    ]]

    do CASE "Garbage collection"
        do -- check that `b` does not allow gc of `a`
            local wref, b
            
            do
                local a = source(1)
    
                b = derive(function()
                    return a()
                end)

                wref = weak { a }
            end

            gc()
            CHECK(wref[1])
            b()
        end

        do -- check that `a` allows gc of `b`
            local a = source(1)

            local wref

            do
                local b = derive(function()
                    return a()
                end)

                wref = weak { b }
            end

            gc()
            CHECK(not wref[1])
        end
    end

    do CASE "Garbage collection 2"
        -- creats a chain `a -> b -> c` where `a` is the source
        local function setup()
            local a = source(0)

            local b = derive(function()
                return a()
            end)

            local c = derive(function()
               return b()
            end)

            return weak { a, b, c }, a, b, c
        end

        do -- check that `b` and `c` can gc if `a` is referenced
            local wref, _a = setup()

            gc()
            CHECK(not wref[2])
            CHECK(not wref[3])
        end

        do -- check that `a` and `b` wont gc if `c` is referenced
            local weak, _a, _b, _c = setup()

            _a, _b = nil :: any, nil :: any

            gc()
            CHECK(weak[1])
            CHECK(weak[2])
        end

        do -- check that `b` wont gc if `a` and `c` are referenced
            local weak, a, _b, c = setup()

            _b = nil :: any

            gc()
            CHECK(weak[2])

            a(2)
            CHECK(c() == 2)
        end
    end
end)

TEST("watch()", function()
    local source = vide.source
    local watch = vide.watch
    local cleanup = vide.cleanup

    do CASE "Capture states"
        local a = source(1)
        local b = source(1)

        local runcount = -1
        watch(function()
            a()
            b()
            runcount += 1
        end)

        CHECK(runcount == 0)
        a(2)
        CHECK(runcount == 1)
        b(2)
        CHECK(runcount == 2)
    end

    do CASE "Stop watch"
        local a = source(1)

        local runcount = -1
        local unwatch = watch(function()
            a()
            runcount += 1
        end)
        
        unwatch()
        a(2)
        CHECK(runcount == 0)
    end

    do CASE "Side-effect cleanup"
        local state = source(1)

        local effect_runcount = 0
        local cleanup_runcount = 0

        local unwatch = watch(function()
            state()
            effect_runcount += 1
            cleanup(function() cleanup_runcount += 1 end)
        end)

        CHECK(effect_runcount == 1)
        CHECK(cleanup_runcount == 0)
        state(2)
        CHECK(effect_runcount == 2)
        CHECK(cleanup_runcount == 1)

        unwatch()
        unwatch = nil :: any
        gc()
        vide.step(0)

        CHECK(effect_runcount == 2)
        CHECK(cleanup_runcount == 2)
    end

    do CASE "Garbage collection"
        local function factory(p)
            return function()
                p()
            end
        end

        do -- state prevents gc of watcher
            local state = source(1)

            local wref

            do
                local effect = factory(state)
                watch(effect)
                wref = { effect }
            end

            gc()
            CHECK(wref[1])
        end

        do -- watcher can gc if stopped
            local state = source(1)
            
            local wref, unwatch

            do
                local effect = factory(state)
                unwatch = watch(effect)
                wref = weak { effect }
            end

            gc()
            CHECK(wref[1])

            unwatch()
            unwatch = nil :: any -- unwatch holds ref to effect

            gc()
            CHECK(not wref[1])

        end

        do -- state can gc with watcher
            local wref

            do
                local state = source(1)
                local effect = factory(state)
                watch(effect)
                wref = weak { state }
            end

            gc()
            CHECK(not wref[1])
        end
    end
end)

TEST("cleanup()", function()
    local source = vide.source
    local watch = vide.watch
    local cleanup = vide.cleanup

    do CASE "Cleanup runs for watcher"
        local state = source(1)

        local watched = 0
        local cleaned = 0

        local stop = watch(function()
            state()
            watched += 1
            cleanup(function()
                cleaned += 1  
            end)
        end)

        CHECK(watched == 1)
        CHECK(cleaned == 0)

        state(2)

        CHECK(watched == 2)
        CHECK(cleaned == 1)

        stop()

        do -- vide detects by iterating through and checking for gc'd refs
            stop = nil :: any
            gc()
            vide.step(0)
        end

        CHECK(watched == 2)
        CHECK(cleaned == 2)
    end

    do CASE "Scoped"
        local function setup()
            local state = source(1)
            local obj = { cleaned = 0 }

            local _stop = watch(function()
                state()
                cleanup(function()
                    obj.cleaned += 1
                end)
            end)

            return state, obj
        end

        local stateA, objA = setup()
        local stateB, objB = setup()

        CHECK(objA.cleaned == 0)
        CHECK(objB.cleaned == 0)

        stateA(2)

        CHECK(objA.cleaned == 1)
        CHECK(objB.cleaned == 0)

        stateB(2)

        CHECK(objA.cleaned == 1)
        CHECK(objB.cleaned == 1)

        do
            stateA = nil :: any
            stateB = nil :: any
            gc()
            vide.step(0)
        end

        CHECK(objA.cleaned == 2)
        CHECK(objB.cleaned == 2)
    end

    do CASE "Multiple cleanup"
        local state = source(1)

        local queue = {}
    
        watch(function()
            state()
            cleanup(function() table.insert(queue, 1) end)
            cleanup(function() table.insert(queue, 2) end)
        end)

        CHECK(testkit.seq(queue, {}))
        state(2)
        CHECK(testkit.seq(queue, { 1, 2 }))
        state(3)
        CHECK(testkit.seq(queue, { 1, 2, 1, 2 }))

        do
            state = nil :: any
            gc()
            vide.step(0)
        end

        -- todo: guarantee call order when gc? (currently not)
        --testkit.print2(queue)
        --CHECK(testkit.seq(queue, { 1, 2, 1, 2, 1, 2 }))
    end
end)

TEST("create()", function()
    local create = vide.create
    local source = vide.source

    do CASE "Apply default properties"
        local defaults = require("src/defaults")
        local frame = create "Frame" {} :: Instance & { BorderSizePixel: any, BorderColor3: any }
        CHECK(frame.BorderSizePixel == defaults.Frame.BorderSizePixel)
        CHECK(frame.BorderColor3 == defaults.Frame.BorderColor3)
    end

    do CASE "Set properties"
        local text = create "TextLabel" {
            Name = "Label",
            Text = "test"
        }
        CHECK(text.Name == "Label")
        CHECK(text.Text == "test")
    end

    do CASE "Set nested properties"
        local text = create "TextLabel" {
            { Name = "Label" },
            Group = { Text = "test" }
        }
        CHECK(text.Name == "Label")
        CHECK(text.Text == "test")
    end

    do CASE "Independent"
        local frame = create "Frame"
        CHECK(frame {} ~= frame {})
    end

    do CASE "Set children"
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
            Children = {
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

    do CASE "Binding properties to state"
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

    do CASE "Binding garbage collection"
        do -- instance should gc when unparented
            local state = source("Hi")

            local wref = weak {
                create "TextLabel" {
                    Text = state,
                }
            }

            gc()
            CHECK(not wref[1])
        end

        do -- instance should not gc when parented
            local state = source("Hi")

            local parent = create "Frame" {}

            local wref = weak {
                create "TextLabel" {
                    Parent = parent,
                    Text = state,
                }
            }

            gc()
            CHECK(wref[1])

            wref[1].Parent = nil
            wref[1].Parent = parent

            gc()
            CHECK(wref[1])

            wref[1]:Destroy()

            gc()
            CHECK(not wref[1])
        end
        
        do -- instance does not allow gc of state
            local label
            local wref

            do
                local state = source("Hi")
                label = create "TextLabel" {
                    Name = state,
                }
                wref = weak { state :: any, label }

            end

            gc()
            CHECK(wref[2])
            CHECK(wref[1])
        end
        
        do -- state and instance should gc once both exit scope
            local wref
    
            do
                local text = source("Hi")

                local box = create "TextLabel" {
                    Text = text,
                }

                wref = weak { text = text, box = box}
            end

            gc()
            CHECK(not wref.text)
            CHECK(not wref.box)
        end
        
        do -- binding should gc despite state still existing after instance is gc
            local state = source("Hi")

            local node = require "src/graph".capture(state)[1]

            local wref

            do
                local instance = create "TextLabel" {
                    Text = state,
                }

                wref = weak {
                    instance = instance,
                    binding = next(node.effects)
                }
            end
            
            CHECK(wref.binding)

            gc()
            CHECK(not wref.instance)
            CHECK(not wref.binding)
        end
    end

    do CASE "Bind same state to multiple instance properties"
        local state = source "1"

        local text = create "TextBox" {
            Name = state,
            Text = state,
            PlaceholderText = state
        }

        state "2"

        CHECK(text.Name == "2")
        CHECK(text.Text == "2")
        CHECK(text.PlaceholderText == "2")
    end

    do CASE "Bind children"
        local state = source()

        local a, b, c = 
            create "TextLabel" { Name = "A" },
            create "TextLabel" { Name = "B" },
            create "TextLabel" { Name = "C" }

        local frame = create "Frame" {
            state
        }
  
        state { a, b }

        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "B")

        -- check that b is removed and c is added while a remains untouched
        
        state { a, c }

        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "C")
        CHECK(not frame:FindFirstChild "B")

        state(nil)

        CHECK(#frame:GetChildren() == 0)
    end

    --[[
    do CASE "Parent set to nil by state does not allow gc"
        local frame = create "Frame" { Name = "Parent" }
        local parent = source(frame :: Frame?)

        local wref = weak {
            create "TextLabel" { Parent = parent, Name = "Child" }
        }

        gc()
        CHECK(wref[1])

        parent(nil)

        gc()
        CHECK(wref[1])

        wref[1]:Destroy()

        gc()
        CHECK(not wref[1])
    end
    ]]

    do CASE "GC test"
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
end)

-- todo: more comprehensive tests for maps

TEST("indexes()", function()
    local source = vide.source
    local indexes = vide.indexes

    do CASE "Use state"
        local input = source { 1, 2, 3 }

        local output = indexes(input, function(v, k)
            return tostring(v())    
        end)

        CHECK("" .. input()[1] == output()[1])
        CHECK("" .. input()[2] == output()[2])
        CHECK("" .. input()[3] == output()[3])
    end

    do CASE "Cache result"
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

    do CASE "Removal reflected"
        local input = source { 1, 2, 3 }

        local output = indexes(input, function(v, i)
            return v 
        end)

        input { 1, 2 }

        local t = output()

        CHECK(t[1]() == 1)
        CHECK(t[2]() == 2)
        CHECK(t[3] == nil)
    end

--[[
    do CASE "Bind children"
        local state, set = source { "A", "B", "C" }

        local derived = map(state, function(i, v)
            return create "TextLabel" {
                Name = v,
                Text = tostring(i)
            }
        end)

        local frame = create "Frame" {
            Name = "21",
            [Children] = derived
        }

        local function find(childname: string): TextLabel
            return frame:FindFirstChild(childname) :: TextLabel
        end

        CHECK(find "A".Text == "1")
        CHECK(find "B".Text == "2")
        CHECK(find "C".Text == "3")

        set { "A", "C", "D" }

        CHECK(find "A".Text == "1")
        CHECK(not find "B")
        CHECK(find "C".Text == "2")
        CHECK(find "D".Text == "3")
    end

    do CASE "Use optional destructor"
        local state, set = source { 1, 2, 3 }
        local derived = map(state, function(i, v)
            return { Value = v, Destroyed = false }
        end, function(v)
            v.Destroyed = true
        end)

        local first = derived()

        CHECK(first[1].Destroyed == false)

        set { 1, 2, 4 }

        local _ = derived()

        CHECK(first[1].Destroyed == false)
        CHECK(first[2].Destroyed == false)
        CHECK(first[3].Destroyed == true)
    end

    do CASE "Garbage collection"
        do -- check that `derived` does not allow gc of `state`
            local state = source {}

            local derived = map(state, function(i, v)
                return v
            end)

            wref.state, state = state, nil :: any
            wref.derived = derived

            gc()
            CHECK(wref.state) 
        end

        do -- check that `state` allows gc of `derived`
            local state = source {}

            local derived = map(state, function(i, v)
                return i, v
            end) :: State?

            wref.state = state
            wref.derived, derived = derived, nil

            gc()
            CHECK(not wref.derived)
        end
    end]]
end)

TEST("values()", function()
    local source = vide.source
    local values = vide.values

    do CASE "Use state"
        local input = source { 1, 2, 3 }

        local output = values(input, function(v, k)
            return tostring(v)    
        end)

        CHECK("" .. input()[1] == output()[1])
        CHECK("" .. input()[2] == output()[2])
        CHECK("" .. input()[3] == output()[3])
    end

    do CASE "Cache result"
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

    do CASE "Removal reflected"
        local input = source { 1, 2, 3 }

        local output = values(input, function(v, i)
            return { v = v, i = i }
        end)

        input { 1, 2 }

        local t = output()

        CHECK(t[1].v == 1)
        CHECK(t[2].v == 2)
        CHECK(t[3] == nil)
    end

    do CASE "Removal reflected 2"
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
end)

TEST("spring()", function()
    local create = vide.create
    local source = vide.source
    local spring = vide.spring
    local watch = vide.watch

    do CASE "Update state (on next hearbeat resumption cycle)"
        local value = source(10)
        local springed = spring(value, 1, 1)

        value(20)
        CHECK(springed() == 10)
        vide.step(1/60)
        CHECK(springed() ~= 10)
        CHECK(springed() > 10)
    end

    do CASE "Garbage collection"
        do -- `output` should not allow gc of `input`
            local input = source(10)
            local _output = spring(input)

            local wref = weak { input }
            input = nil :: any

            gc()
            CHECK(wref[1])
        end

        do -- `input` should allow gc of `output`
            local input = source(10)
            local output = spring(input)
        
            local wref = weak { output }
            output = nil :: any
            
            gc()
            CHECK(not wref[1])
        end
    end


    do CASE "Garbage collection (binded)"
        local input = source(10)
        local output = spring(input, 1, 1)

        local _label = create "TextLabel" {
            Text = output
        }

        local wref = { output }
        output = nil :: any

        gc()
        CHECK(wref[1]) -- `output` should not gc
    end

    do CASE "Spring finished"
        local input = source(0)
        local output = spring(input)

        input(1)
        vide.step(1e9) -- spring alpha at ~1

        local count = -1
        watch(function()
            output()
            count += 1
        end)

        vide.step(1) -- spring should be internally removed from spring queue
        CHECK(count == 0)

        --

        gc() -- perform full gc
        input(2) -- spring should be re-added to spring queue
        vide.step(0) -- process spring queue
        CHECK(count == 1) -- check spring was rescheduled correctly
    end
end)

TEST("Events", function()
    local create = vide.create

    local function Thing(props)
        local instance = Instance.new("Thing") :: any
        instance.Signal = Signal.new()

        local clone = create(instance)(props)

        return clone
    end

    do CASE "Connect event"
        local connected = false

        local val = Thing {
            Signal = function(newval)
                connected = true
                CHECK(newval == 1)
            end
        }

        -- testkit.print2(getmetatable(val))

        CHECK(not connected)
        val.Value = 1; val.Signal:Fire(val.Value)
        CHECK(connected)
    end
end)

TEST("actions", function()
    local create = vide.create
    local action = vide.action

    do CASE "Run action"
        local ran = false

        create "Frame" {
            action(function(self)
                ran = true
            end, 1)
        }

        CHECK(ran)
    end

    do CASE "Priorities"
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

TEST("strict", function()
    vide.strict = true

    local source = vide.source
    local derive = vide.derive
    local watch = vide.watch

    do CASE "Error on derived callback yield"
        local state = source(1)

        local ok = pcall(function()
            local _derived = derive(function()
                coroutine.yield()
                return state()
            end)
        end)

        CHECK(not ok)
    end

    do CASE "Error on watcher callback yield"
        local state = source(1)

        local ok = pcall(function()
            local _derived = watch(function()
                coroutine.yield()
                state()
            end)
        end)

        CHECK(not ok)
    end

    do CASE "Run derived callback twice"
        local state = source(1)
        local runcount = 0

        local _ = derive(function()
            runcount += 1
            return state()
        end)

        CHECK(runcount == 2)
        state(2)
        CHECK(runcount == 4)
    end

    do CASE "Run watcher callback twice"
        local state = source(1)
        local runcount = 0

        watch(function()
            runcount += 1
            state()
        end)

        CHECK(runcount == 2)
        state(2)
        CHECK(runcount == 4)
    end

    -- todo: add case for strict mode bindings
end)

local ok = FINISH()
if not ok then error("Tests failed", 0) end

return nil
