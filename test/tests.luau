local testkit = require("test/testkit")
local TEST, CASE, CHECK, FINISH, SKIP = testkit.test()

SKIP"graph"

local mock = require "test/mock"
local Instance, Signal = mock.Instance, mock.Signal
local Vector2, UDim2 = mock.Vector2, mock.UDim2

local vide = require "src/init"

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

TEST("graph", function()
    local graph = require "src/graph"
    local create_node = graph.create_node
    local track = graph.track
    local update = graph.update
    local add_child = graph.add_child
    local open_root_scope = graph.open_root_scope
    local open_scope = graph.open_scope
    local close_scope = graph.close_scope
    local get_children = graph.get_children

    do CASE "node creation"
        local node = create_node(1)
        CHECK(node.cache == 1)
    end

    do CASE "link nodes"
        local a = create_node(nil)
        local b = create_node(nil)
        local c = create_node(nil)

        open_scope(c)

        track(a)
        track(b)

        close_scope()

        CHECK(get_children(a)[1] == c)
        CHECK(get_children(b)[1] == c)
    end

    do CASE "rerun linked nodes"
        local a = create_node(nil)
        local b = create_node(nil)
        local c = create_node(nil)

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

    -- todo: further tests

    do CASE "nodes garbage collection"
        local wref = weak { create_node(1) }
        gc()
        CHECK(not wref[1])
    end

    do CASE "test"
        local x = 1
    end
end)

TEST("source()", wrap_root(function()
    local source = vide.source
    local watch = vide.watch

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

        local count = -1
        watch(function()
            src()
            count += 1
        end)

        CHECK(count == 0)
        src(1)
        CHECK(count == 0)
        src(2)
        CHECK(count == 1)
    end

    do CASE "does update if same value is mutable table"
        local src = source {}

        local count = -1
        watch(function()
            src()
            count += 1
        end)

        CHECK(count == 0)
        src(src())
        CHECK(count == 1)
    end

    do CASE "does not update if same value is frozen table"
        local a = table.freeze {}
        local b = table.freeze {}

        local src = source(a)

        local count = -1
        watch(function()
            src()
            count += 1
        end)

        CHECK(count == 0)
        src(a)
        CHECK(count == 0)
        src(b)
        CHECK(count == 1)
        src(b)
        CHECK(count == 1)
    end
end))

TEST("derive()", wrap_root(function()
    local source = vide.source
    local derive = vide.derive

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

    do CASE "garbage collection"
        -- check that `b` does not allow gc of `a`        
        local a = source(1)

        local b = derive(function()
            return a()
        end)

        b = nil :: any

        local wref = weak { a }

        gc()
        CHECK(wref[1])
    end
end))

TEST("watch()", wrap_root(function()
    local source = vide.source
    local watch = vide.watch
    local cleanup = vide.cleanup

    do CASE "capture sources"
        local a = source(1)
        local b = source(1)

        local count = 0
        watch(function()
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

    do CASE "side-effect cleanup"
        local state = source(1)

        local effect_count = 0
        local cleanup_count = 0

        watch(function()
            state()
            effect_count += 1
            cleanup(function() cleanup_count += 1 end)
        end)

        CHECK(effect_count == 1)
        CHECK(cleanup_count == 0)
        state(2)
        CHECK(effect_count == 2)
        CHECK(cleanup_count == 1)
    end

    do CASE "garbage collection"
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
end))

TEST("cleanup()", wrap_root(function()
    local source = vide.source
    local watch = vide.watch
    local cleanup = vide.cleanup

    do CASE "cleanup runs for watcher"
        local state = source(1)

        local watched = 0
        local cleaned = 0

        watch(function()
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
    end

    do CASE "multiple cleanup"
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
    end
end))

TEST("create()", wrap_root(function()
    local create = vide.create
    local source = vide.source

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

                {
                    Text = "2"
                }
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

    do CASE "binding garbage collection"
        --[[
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
        ]]

        --[[
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
        ]]
        
        --[[
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
        ]]
        
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
        
        --[[
        do -- binding should gc despite state still existing after instance is gc
            local state = source("Hi")

            local node = require "src/graph".capture(state)[1]

            local wref

            do
                local instance = create "TextLabel" {
                    Text = state,
                }

                local binding = assert(node[1])

                wref = weak {
                    instance = instance,
                    binding = binding
                }
            end
            
            CHECK(wref.binding)

            gc()
            CHECK(not wref.instance)
            CHECK(not wref.binding)
        end
        ]]
    end

    do CASE "bind same state to multiple instance properties"
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

    do CASE "bind children"
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
        CHECK(t[3] == nil :: any)
        CHECK(destroyed == true)
    end

    do CASE "garbage collection"
        do -- check that `output` does not allow gc of `input`
            local input = source {}

            local _derived = indexes(input, function(v, i)
                return v
            end)

            local wref = weak { input }

            input = nil :: any

            gc()
            CHECK(wref[1]) 
        end

        do -- check that `input` allows gc of `output`
            local input = source {}

            local output = indexes(input, function(v, i)
                return v, i
            end)

            local wref = weak { output }

            output = nil :: any

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
        CHECK(t[3] == nil :: any)
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
    local watch = vide.watch

    do CASE "update source (on next step)"
        local value = source(10)
        local springed = spring(value, 1, 1)

        value(20)
        CHECK(springed() == 10)
        vide.step(1/60)
        CHECK(springed() ~= 10)
        CHECK(springed() > 10)
    end

    do CASE "garbage collection"
        --[[
        do -- `output` should not allow gc of `input`
            local input = source(10)
            local _output = spring(input)

            local wref = weak { input }
            input = nil :: any

            gc()
            CHECK(wref[1])
        end
        ]]

        do -- `input` should allow gc of `output`
            local input = source(10)
            local output = spring(input)
        
            local wref = weak { output }
            output = nil :: any
            
            gc()
            CHECK(not wref[1])
        end

        do -- spring data gc
            local capture = require "src/graph".capture

            local input = source(10)

            local wref do
                local output, data = (spring :: any)(input)
                input(input() + 1) -- schedule spring calculation
                local output_node = unpack(capture(output))
                wref = weak { output_node, data }
            end
    
            gc()
            CHECK(not wref[1])
            CHECK(not wref[2])
        end
    end

    do CASE "garbage collection (binded)"
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

    do CASE "spring finished"
        local input = source(0)
        local output = spring(input)

        input(1)
        vide.step(0.05)
        CHECK(output() ~= input()) -- check spring is moving
        vide.step(10) -- spring finished, should be internally removed from queue
        CHECK(output() == input()) -- check spring is at target

        local count = -1
        watch(function()
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
    local watch = vide.watch
    local untrack = vide.untrack

    do CASE "does not register dependency"
        local a = source(0)
        local b = source(0)

        local count = -1

        watch(function()
            count += 1
            untrack(a)
            b()
        end)

        b(1)
        CHECK(count == 1)

        a(1)
        CHECK(count == 1)

        CHECK(a() == untrack(a))
    end

    do CASE "derived state"
        local a = source(0)
        local b = source(0)
        local c = source(0)

        local d = function()
            return a() + b()
        end

        local count = -1

        watch(function()
            count += 1
            untrack(d)
            c()
        end)

        c(1)
        CHECK(count == 1)

        a(1)
        b(1)
        CHECK(count == 1)
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

TEST("strict", function()
    vide.strict = true

    local create = vide.create
    local source = vide.source
    local derive = vide.derive
    local watch = vide.watch
    local indexes, values = vide.indexes, vide.values
    local cleanup = vide.cleanup

    -- do CASE "error on derived callback yield"
    --     local state = source(1)

    --     local ok = pcall(function()
    --         local _derived = derive(function()
    --             coroutine.yield()
    --             return state()
    --         end)
    --     end)

    --     CHECK(not ok)
    -- end

    -- do CASE "error on watcher callback yield"
    --     local state = source(1)

    --     local ok = pcall(function()
    --         local _derived = watch(function()
    --             coroutine.yield()
    --             state()
    --         end)
    --     end)

    --     CHECK(not ok)
    -- end

    do CASE "run derived callback twice"
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

    do CASE "run watcher callback twice"
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

    do CASE "indexes() error if primitive"
        local state = source { 1 }

        local ok = pcall(function()
            indexes(state, function() return 1 end)
        end)

        CHECK(not ok)
    end

    do CASE "values() error if duplicate"
        local state = source { 1, 2, 1 }

        local ok = pcall(function()
            values(state, function() return {} end)
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

    do CASE "multiple cleanup per scope"
        local ok = pcall(function()
            cleanup(function() end)
            cleanup(function() end)
        end)

        CHECK(not ok)
    end
end)

local ok = FINISH()
if not ok then error("Tests failed", 0) end

return nil
