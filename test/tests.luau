----------------------------------------------------------------------------------------------------------------------
-- unit.lua
----------------------------------------------------------------------------------------------------------------------

local TEST, CASE, CHECK, FINISH = require("test/testkit").getUnitTestTools()

local mock = require "test/mock"
local Signal = require "test/goodsignal"
local Instance, Vector3, Color3, Vector2, UDim2 = mock.Instance, mock.Vector3, mock.Color3, mock.Vector2, mock.UDim2

local vide = require "src/init"

-- force run garbage collector cycles
local function gc(n: number?)
    for i = 1, n or 3 do
        (collectgarbage :: any)("collect")
    end
end

-- weak reference table used for gc tests
local wref = setmetatable({}, { __mode = "kv" }) :: any

TEST("graph", function()
    local graph = require "src/graph"
    local create = graph.create
    local get = graph.get
    local unwrap = graph.unwrap
    local set = graph.set
    local capture = graph.capture
    local captureAndLink = graph.captureAndLink
    local link = graph.link
    local setEffect = graph.setEffect

    do CASE "Create"
        local node = create(1)
        CHECK(get(node) == 1)
    end

    do CASE "Read/write"
        local node = create(0)
        set(node, 1)
        CHECK(get(node) == 1)
        set(node, 2)
        CHECK(get(node) == 2)
    end

    do CASE "Capture"
        local node1 = create(nil)
        local node2 = create(nil)
        local nodes = capture(function(from)
            return from(node1), from(node2)
        end)
        CHECK(nodes[1] == node1)
        CHECK(nodes[2] == node2)
    end

    do CASE "Link"
        local parent = create(1)
        local child = create(nil)
        link(parent, child, function() 
            return get(parent)
        end)
        set(parent, get(parent) + 1)
        CHECK(get(child) == 2)
    end

    do CASE "Capture and link"
        local parent = create(1)
        local child = create(nil :: any)

        captureAndLink(child, function(from)
            return tostring(from(parent))
        end)

        set(parent, get(parent) + 1)
        CHECK(get(child) == "2")
    end

    do CASE "Scoped captures"
        -- table.find but uses `rawequal` since nodes have overloaded __eq metamethod
        local function rawfind(t, x)
            for i, v in ipairs(t) do
                if rawequal(x, v) then
                    return true
                end
            end
            return false
        end

        local a = graph.create(1)
        local b = graph.create(1)

        graph.link(a, b, function() return get(a) end)
        set(a, get(a) + 1) -- mark `b` for recomputation

        -- `a` and `b` should be referenced
        local captures = graph.capture(function(from) return from(b) end)

        -- check that only `b` was referenced
        CHECK(not rawfind(captures, a))
        CHECK(rawfind(captures, b))

        -- repeat for `captureAndLink`
        local c = graph.create(1)
        set(a, get(a) + 1) -- mark `b` for recomputation again
        captureAndLink(c, function(from) return from(b) end)
        -- check that only `b` was linked
        CHECK(not rawfind(assert(a.children), c))
        CHECK(rawfind(assert(b.children), c))
    end 

    do CASE "Nodes garbage collection"
        local node = create(1) :: Node?
        wref.node, node = node, nil

        gc()
        CHECK(not wref.node)
    end

    do CASE "Node effect garbage collection"
        do
            local function factory(p) -- factory function to prevent closure caching
                return function()
                    return unwrap(p)
                end
            end

            local node = create(1)
            local effect1 = factory(node)
            local effect2 = factory(node)
            wref.node = node
            wref.effect1 = effect1
            wref.effect2 = effect2

            local t = {}
            setEffect(node, effect1, t)
            setEffect(node, effect2, true)

            t = nil :: any
            effect1, effect2 = nil :: any, nil :: any

            gc()

            CHECK(not wref.effect1) -- effect1 should gc since nothing is referencing table `t`
            CHECK(wref.effect2) -- effect2 should not gc as `true` is not garbage collectable
        end
        gc()
        CHECK(not wref.node and not wref.effect2) -- node should now gc along with effect2

        do -- same test but for multiple nodes referenced by watcher
            local function factory(a, b)
                return function()
                    return get(a), get(b)
                end
            end

            local node1 = create(1)
            local node2 = graph.create(1)
            local effect = factory(node1, node2)
            wref.node1 = node1
            wref.node2 = node2
            wref.effect = effect

            local t1 = {}
            setEffect(node1, effect, t1)
            setEffect(node2, effect, t1)

            t1 = nil :: any
            effect = nil :: any
            
            gc()

            CHECK(not wref.effect)
        end

        gc()

        CHECK(not wref.node1)
        CHECK(not wref.node2)
    end
end)

TEST("wrap()", function()
    local wrap = vide.wrap
    local unwrap = vide.unwrap
    local wrapped = vide.wrapped
    local watch = vide.watch

    do CASE "Wrap value"
        local state = wrap(1)
        CHECK(wrapped(state))
        CHECK(unwrap(state) == 1)
    end

    do CASE "Setter"
        local state, set = wrap(1)
        set(2) -- set directly
        CHECK(unwrap(state) == 2)
        set(function(x) return x + 1 end) -- set via function
        CHECK(unwrap(state) == 3)
        set((wrap(4))) -- set using value of another state
        CHECK(unwrap(state) == 4)
    end

    do CASE "Does not update if same value"
        local state, set = wrap(1)

        local updates = -1
        watch(function(from)
            from(state)
            updates += 1
        end)
        set(1)
        CHECK(unwrap(state) == 1)
        CHECK(updates == 0)
        set(1, true)
        CHECK(updates == 1)
    end

    do CASE "Does not rewrap state"
        local state = wrap((wrap(1)))
        CHECK(not wrapped(unwrap(state)))
    end
end)

TEST("unwrap()", function()
    local wrap = vide.wrap
    local unwrap = vide.unwrap

    do CASE "Gets state value"
        local a = wrap(1)
        CHECK(unwrap(a) == 1)
    end

    do CASE "Allow passthrough of non-state"
        CHECK(unwrap(5) == 5)
    end
end)


TEST("wrapped()", function()
    local wrap = vide.wrap
    local wrapped = vide.wrapped

    do CASE "Check if value is a state object"
        local state = wrap()
        CHECK(wrapped(state))        
    end

    do CASE "Refuse non-state"
        CHECK(not wrapped(0))
    end
end)

TEST("derive()", function()
    local wrap = vide.wrap
    local unwrap = vide.unwrap
    local derive = vide.derive

    do CASE "Derive new value on state change"
        local state, set = wrap(1)

        local derived = derive(function(from)
            return tostring(from(state))
        end)

        CHECK(unwrap(derived) == "1") -- check initial run during detection
        set(function(x) return x + 1 end)
        CHECK(unwrap(derived) == "2") -- check actually updates
    end

    do CASE "Shorthand derivation"
        do
            local count, set = wrap(1 :: any)
            local text = "Count: " .. count
            CHECK(unwrap(text) == "Count: 1")
            set(2)
            CHECK(unwrap(text) == "Count: 2")
        end
        do
            local count, set = wrap(1 :: any)
            local text = count .. "x"
            CHECK(unwrap(text) == "1x")
            set(2)
            CHECK(unwrap(text) == "2x")
        end
        do
            local count, set = wrap(1 :: any)
            local text = count .. count
            CHECK(unwrap(text) == "11")
            set(2)
            CHECK(unwrap(text) == "22")
        end
    end

    do CASE "Derive from updated"
        do
            local a, set = wrap(1)

            local b = derive(function(from)
                return from(a) + 1
            end)

            set(2)

            local c = derive(function(from)
                return from(b) + 1
            end)

            CHECK(unwrap(c) == 4)
        end

        do
            local a, set = wrap(1)

            local b = a + 1

            set(2)

            local c = b + 1

            CHECK(unwrap(c) == 4)
        end
    end

    do CASE "Cleanup"
        local count, set = wrap(1)

        local derived = derive(function(from)
            return { Value = from(count), Destroyed = false }
        end, function(v)
            v.Destroyed = true
        end)

        local first = unwrap(derived)
        CHECK(first.Destroyed == false)
        set(2)
        local _ = unwrap(derived) -- trigger recalc
        CHECK(first.Destroyed == true)
    end

    do CASE "Garbage collection"
        do -- check that `derived` does not allow gc of `state`
            local state = wrap(1) :: State?

            local _derived = derive(function(from)
                return from(state)
            end)

            wref.state, state = state, nil

            gc()
            CHECK(not wref.state) 
        end

        do -- check that `state` allows gc of `derived`
            local state = wrap(1)

            local derived = derive(function(from)
                return from(state)
            end) :: State?

            wref.derived, derived = derived, nil

            gc()
            CHECK(not wref.derived)
        end
    end

    do CASE "Garbage collection 2"
        -- creats a chain `a -> b -> c` where `a` is the root
        local function setup()
            local weak = setmetatable({}, { __mode = "v" })

            local a, setA = wrap(1)

            local b = derive(function(from)
                return from(a)
            end)

            local c = derive(function(from)
               return from(b)
            end)

            weak.a = a
            weak.b = b
            weak.c = c

            return weak, a, b, c, setA
        end

        do -- check that b and c can gc if a is referenced
            local weak, _a = setup()

            gc()
            CHECK(not weak.b)
            CHECK(not weak.c)
        end

        do -- check that a and b wont gc if c is referenced
            local weak, _a, _b, _c = setup()

            _a, _b = nil :: any, nil :: any

            gc()
            CHECK(weak.a)
            CHECK(weak.b)
        end

        do -- check that b wont gc if a and c are referenced
            local weak, _a, _b, c, setA = setup()

            _b = nil :: any

            gc()

            setA(2)
    
            CHECK(weak.b)
            CHECK(unwrap(c) == 2)
        end
    end
end)

TEST("watch()", function()
    local wrap = vide.wrap
    local watch = vide.watch

    do CASE "Capture states"
        local a, setA = wrap(1)
        local b, setB = wrap(1)
        local runcount = 0

        watch(function(from)
            local _ = from(a) + from(b)
            runcount += 1
        end)

        CHECK(runcount == 1) -- immediate callback execution
        setA(2)
        CHECK(runcount == 2)
        setB(2)
        CHECK(runcount == 3)
    end

    do CASE "Stop watch"
        local a, setA = wrap(1)
        local b, setB = wrap(1)
        local runcount = 0

        local unwatch = watch(function(from)
            local _ = from(a) + from(b)
            runcount += 1
        end)
        
        CHECK(runcount == 1)
        unwatch()
        setA(2)
        setB(2)
        CHECK(runcount == 1)
    end

    do CASE "Side-effect cleanup"
        local state, set = wrap(1)

        local effect_runcount = 0
        local cleanup_runcount = 0

        local unwatch = watch(function(from)
            local _ = from(state)
            effect_runcount += 1
            return function() cleanup_runcount += 1 end
        end)

        CHECK(effect_runcount == 1)
        CHECK(cleanup_runcount == 0)
        set(2)
        CHECK(effect_runcount == 2)
        CHECK(cleanup_runcount == 1)
        unwatch()
        CHECK(effect_runcount == 2)
        CHECK(cleanup_runcount == 2)
    end

    do CASE "Garbage collection"
        local function factory(p)
            return function(from: any)
                from(p)
            end
        end

        do -- state prevents gc of watcher
            local state = wrap(1)
            local effect = factory(state)
        
            watch(effect)

            wref.effect = effect
            effect = nil :: any

            gc()
            CHECK(wref.effect) -- should still exist

        end

        do -- watcher can gc if stopped
            local state = wrap(1)
            local effect = factory(state)
        
            local unwatch = watch(effect)

            wref.effect = effect
            effect = nil :: any

            gc()
            CHECK(wref.effect) -- should still exist
            unwatch(); unwatch = nil :: any
            gc()
            CHECK(not wref.effect) -- should gc

        end

        do -- state can gc with watcher
            local state = wrap(1)
            local effect = factory(state)
        
            watch(effect)

            wref.state = state
            state = nil :: any

            effect = nil :: any

            gc()
            CHECK(not wref.state) -- should gc
        end

        do -- watcher can gc if no state captured
            local effect = factory()
        
            watch(effect)

            wref.effect = effect
            effect = nil :: any

            gc()
            CHECK(not wref.effect) -- should gc
        end
    end
end)

TEST("create()", function()
    local create = vide.create
    local wrap = vide.wrap
    local Children: "Children" = vide.Children :: "Children"

    do CASE "Apply default properties"
        local defaults = require("src/defaults")
        local frame = create "Frame" {} :: Instance & { BorderSizePixel: any, BorderColor3: any }
        CHECK(frame.BorderSizePixel == defaults.Frame.BorderSizePixel)
        CHECK(frame.BorderColor3 == defaults.Frame.BorderColor3)
    end

    do CASE "Assign custom properties"
        local text = create "TextLabel" {
            Name = "Label",
            Text = "test"
        }
        CHECK(text.Name == "Label")
        CHECK(text.Text == "test")
    end

    do CASE "Independent"
        local frame = create "Frame"
        CHECK(frame {} ~= frame {})
    end

    do CASE "Assign children"
        local frame = create "Frame" {
            [Children] = {
                create "TextLabel" { Name = "A" } :: any,
                create "TextLabel" { Name = "B" },
                {
                    create "TextLabel" { Name = "C" } :: any,
                    create "TextLabel" { Name = "D" },
                    {
                        create "TextLabel" { Name = "E" }
                    }
                }
            }
        }
        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "B")
        CHECK(frame:FindFirstChild "C")
        CHECK(frame:FindFirstChild "D")
        CHECK(frame:FindFirstChild "E")

        local image = create "ImageLabel" {
            [Children] = create "TextLabel" { Name = "A" }
        }
        CHECK(image:FindFirstChild "A")
    end

    do CASE "Binding properties to state"
        local name, setName = wrap("Hi")
        local text, setText = wrap("Bye")

        local label = create "TextLabel" {
            Name = name,
            Text = text
        }

        CHECK(label.Name == "Hi")
        CHECK(label.Text == "Bye")

        setName "Foo"
        setText "Bar"

        CHECK(label.Name == "Foo")
        CHECK(label.Text == "Bar")
    end

    do CASE "Binding garbage collection"
        do -- instance should gc despite property bound to state
            local state = wrap("Hi")

            do
                wref.instance = create "TextLabel" {
                    Text = state,
                }
            end

            gc()
            CHECK(not wref.instance)
        end

        do -- instance should NOT gc despite property bound to state when parented
            local state = wrap("Hi")

            local parent = create "Frame" {}

            do
                wref.instance = create "TextLabel" {
                    Parent = parent,
                    Text = state,
                }
            end

            gc()
            CHECK(wref.instance)

            wref.instance.Parent = nil
            wref.instance.Parent = parent

            gc()
            CHECK(wref.instance)

            wref.instance:Destroy()

            gc()
            CHECK(not wref.instance)
        end
        
        do -- state should not gc once exits scope while instance still exists
            local _label

            do
                local state = wrap("Hi")
                wref.state = state

                _label = create "TextLabel" {
                    Name = state,
                }
            end

            gc()
            CHECK(wref.state)
        end
        
        do -- state and instance should gc once both exit scope
            do
                local text = wrap("Hi")

                local box = create "TextLabel" {
                    Text = text,
                }

                wref.text = text
                wref.box = box
            end

            gc()
            CHECK(not wref.state)
            CHECK(not wref.box)

        end
        
        do -- binding should gc despite state still existing after instance is gc
            local state = wrap("Hi")

            do
                local instance = create "TextLabel" {
                    Text = state,
                }

                wref.instance = instance
                wref.binding = next((state :: any).effects)
            end
            
            CHECK(wref.binding)

            gc()

            CHECK(not wref.instance)
            CHECK(not wref.binding)
        end
    end

    do CASE "Bind same state to multiple instance properties"
        local state, set = wrap "1"

        local text = create "TextBox" {
            Name = state,
            Text = state,
            PlaceholderText = state
        }

        set "2"

        CHECK(text.Name == "2")
        CHECK(text.Text == "2")
        CHECK(text.PlaceholderText == "2")
    end

    do CASE "Bind children"
        local state, set = wrap({} :: {}?)

        local a, b, c = 
            create "TextLabel" { Name = "A" },
            create "TextLabel" { Name = "B" },
            create "TextLabel" { Name = "C" }

        local frame = create "Frame" {
            [Children] = state
        }
  
        set { a, b }

        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "B")

        -- check that b is removed and c is added while a remains untouched
        
        set { a, c }

        CHECK(frame:FindFirstChild "A")
        CHECK(frame:FindFirstChild "C")
        CHECK(not frame:FindFirstChild "B")

        set(nil)

        CHECK(#frame:GetChildren() == 0)
    end

    do CASE "Parent set to nil by state does not allow gc"
        -- this is technically a bug but we test for this anyways to confirm behavior
        local parent = create "Frame" { Name = "Parent" }
        local state, set = wrap(parent :: Frame?)

        do
            wref.child = create "Frame" { Parent = state, Name = "Child" } :: Frame?
        end

        gc()
        CHECK(wref.child)

        set(nil)

        gc()
        CHECK(wref.child)

        wref.child:Destroy()

        gc()
        CHECK(not wref.child)
    end

    do CASE "GC test"
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

        wref.data = data
        wref.proxy = proxy
        data = nil :: any
        proxy = nil :: any

        gc()

        CHECK(wref.data and wref.proxy)
    end
end)

TEST("map()", function()
    local wrap = vide.wrap
    local unwrap = vide.unwrap
    local map = vide.map

    do CASE "Use integer"
        local n = 5

        local t = map(n, function(i)
            return tostring(i)
        end)

        for i = 1, n do
            CHECK(tostring(i) == t[i])
        end
    end

    do CASE "Use table"
        local t = { 1, 2, 3, 4, 5 }

        local t2 = map(t, function(_, v)
            return tostring(v)
        end)

        for i, v in t do
            CHECK(tostring(v) == t2[i])
        end
    end

    do CASE "Use state"
        local state = wrap { 1, 2, 3 }

        local derived = map(state, function(_, v)
            return tostring(v)    
        end)

        local t = unwrap(derived)

        for i, v in next, unwrap(state) do
            CHECK(tostring(v) == t[i])
        end
    end

    do CASE "Cache result"
        local state, set = wrap { 1, 2, 3 }

        local runcount = table.create(3, 0)

        local derived = map(state, function(i, v)
            runcount[i] += 1
            return tostring(v)    
        end)

        local _ = unwrap(derived) -- trigger evaluation (so the next set is forced to be re-calculated)
        set { 1, 2, 4 }

        local t = unwrap(derived)

        CHECK(t[1] == "1")
        CHECK(t[2] == "2")
        CHECK(t[3] == "4")

        CHECK(runcount[1] == 1)
        CHECK(runcount[2] == 1)
        CHECK(runcount[3] == 2)
    end

    do CASE "Removal reflected"
        local state, set = wrap { 1, 2, 3 }

        local derived = map(state, function(i, v)
            return tostring(v)    
        end)

        local _ = unwrap(derived) -- trigger evaluation (so the next set is forced to be re-calculated)
        set { 1, 2 }

        local t = unwrap(derived)

        CHECK(t[1] == "1")
        CHECK(t[2] == "2")
        CHECK(t[3] == nil)
    end

    local create = vide.create
    local Children = vide.Children

    do CASE "Bind children"
        local state, set = wrap { "A", "B", "C" }

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
        local state, set = wrap { 1, 2, 3 }
        local derived = map(state, function(i, v)
            return { Value = v, Destroyed = false }
        end, function(v)
            v.Destroyed = true
        end)

        local first = unwrap(derived)

        CHECK(first[1].Destroyed == false)

        set { 1, 2, 4 }

        local _ = unwrap(derived)

        CHECK(first[1].Destroyed == false)
        CHECK(first[2].Destroyed == false)
        CHECK(first[3].Destroyed == true)
    end

    do CASE "Garbage collection"
        do -- check that `derived` does not allow gc of `state`
            local state = wrap {}

            local derived = map(state, function(i, v)
                return v
            end)

            wref.state, state = state, nil :: any
            wref.derived = derived

            gc()
            CHECK(wref.state) 
        end

        do -- check that `state` allows gc of `derived`
            local state = wrap {}

            local derived = map(state, function(i, v)
                return i, v
            end) :: State?

            wref.state = state
            wref.derived, derived = derived, nil

            gc()
            CHECK(not wref.derived)
        end
    end
end)

TEST("apply()", function()
    local apply = vide.apply

    -- uses same application method as `create()` internally, further testing unnecessary
    do CASE "Apply properties"
        local part = Instance.new("Part") :: Part

        apply(part) {
            Position = Vector3.new(1, 1, 1),
            Color = Color3.new(1, 0, 0)   
        }

        CHECK(part.Position == Vector3.new(1, 1, 1))
        CHECK(part.Color == Color3.new(1, 0, 0))
    end
end)

TEST("spring()", function()
    local wrap = vide.wrap
    local unwrap = vide.unwrap
    local spring = vide.spring

    do CASE "Update state (on next hearbeat resumption cycle)"
        local number, set = wrap(10)
        local springed = spring(number, 1, 1)

        set(20)
        CHECK(unwrap(springed) == 10)
        vide.step(1/60)
        CHECK(unwrap(springed) ~= 10)
        CHECK(unwrap(springed) > 10)
    end

    do CASE "Garbage collection"
        do -- `spring` should not allow gc of `state`
            local state = wrap(10)
            local _springed = spring(state, 1, 1)   

            wref.state, state = state, nil :: any

            gc()
            CHECK(wref.state)

        end

        do -- `number` should allow gc of `spring`
            local number = wrap(10)
            local springed = spring(number, 1, 1) :: State?
        
            wref.springed, springed = springed, nil
            
            gc()
            CHECK(not wref.springed)

        end
    end

    local create = vide.create

    do CASE "Garbage collection (binded)"
        local number = wrap(10)
        local springed = spring(number, 1, 1) :: State?

        local _label = create "TextLabel" {
            Text = springed
        }

        wref.springed, springed = springed, nil

        gc()
        CHECK(wref.springed) -- `springed` should not gc
    end
end)

TEST("Layout", function()
    local create = vide.create
    local Layout = vide.Layout
    
    do CASE "Apply layout properties"
        local frame = create "Frame" {
            [Layout] = {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0.5, 0.5)
            }
        }

        CHECK(frame.AnchorPoint == Vector2.new(0, 0.5))
        CHECK(frame.Position == UDim2.fromScale(0.5, 0.5))
    end
end)

TEST("Event", function()
    local create = vide.create
    local Event = vide.Event
    local wrap = vide.wrap

    do CASE "Connect event"
        local connected = false

        local event = (Signal.new() :: any) :: RBXScriptSignal & { Fire: any }

        local val = create "IntValue" {
            Changed = event,
            [Event.Changed] = function(newval)
                connected = true
                CHECK(newval == 1)
            end
        } :: IntValue

        CHECK(not connected)
        val.Value = 1; event:Fire(val.Value)
        vide.step(1/60)
        CHECK(connected)
    end

    do CASE "Bind connection to state"
        local countA = 0
        local countB = 0
        local listener, set = wrap(function() countA += 1 end :: () -> ()?)

        local event = (Signal.new() :: any) :: RBXScriptSignal & { Fire: any }

        local int = create "IntValue" {
            Changed = event,
            [Event.Changed] = listener
        } :: IntValue

        int.Value = 1; event:Fire(int.Value)
        int.Value = 2; event:Fire(int.Value)
        CHECK(countA == 2)
        set(function() return function() countB += 1 end end)
        int.Value = 3; event:Fire(int.Value)
        int.Value = 4; event:Fire(int.Value)
        CHECK(countA == 2)
        CHECK(countB == 2)
        set(nil)
        int.Value = 5; event:Fire(int.Value)
        CHECK(countA == 2)
        CHECK(countB == 2)
    end

    do CASE "Always return same object for a given index"
        CHECK(Event.Test == Event.Test)
    end
end)

TEST("Changed", function()
    local create = vide.create
    local Changed = vide.Changed
    local wrap = vide.wrap

    do CASE "Connects event"
        local connected = false
        local label = create "TextLabel" {
            [Changed.Text] = function(text)
                CHECK(text == "hi")
                connected = true
            end
        }
        CHECK(not connected)
        label.Text = "hi"
        CHECK(connected)
    end

    do CASE "Bind connection to state"
        local countA = 0
        local countB = 0
        local listener, set = wrap(function() countA += 1 end :: () -> ()?)


        local label = create "TextLabel" {
            [Changed.Text] = listener
        }

        label.Text = "1"
        label.Text = "2"
        CHECK(countA == 2)
        set(function() return function() countB += 1 end end)
        label.Text = "3"
        label.Text = "4"
        CHECK(countA == 2)
        CHECK(countB == 2)
        set(nil)
        label.Text = "5"
        CHECK(countA == 2)
        CHECK(countB == 2)
    end

    do CASE "Always return same object for a given index"
        CHECK(Changed.Test == Changed.Test)
    end
end)

TEST("Created", function()
    local create = vide.create
    local Created = vide.Created

    do CASE "Run after instance creation"
        local ran = false

        create "Frame" {
            A = true,
            B = true,
            C = true,
            [Created] = function(self)
                ran = true
                CHECK(self.A and self.B and self.C)
            end
        }

        CHECK(ran)
    end
end)

TEST("strict", function()
    vide.strict = true

    local wrap = vide.wrap
    local unwrap = vide.unwrap
    local derive = vide.derive
    local watch = vide.watch

    do CASE "Error on derived callback yield"
        local state = wrap(1)

        local ok = pcall(function()
            local _derived = derive(function(from)
                coroutine.yield()
                return from(state)
            end)
        end)

        CHECK(not ok)
    end

    do CASE "Error on watcher callback yield"
        local state = wrap(1)

        local ok = pcall(function()
            local _derived = watch(function(from)
                coroutine.yield()
                local _ = from(state)
            end)
        end)

        CHECK(not ok)
    end

    do CASE "Run derived callback twice"
        local state, set = wrap(1)
        local runcount = 0

        local derived = derive(function(from)
            runcount += 1
            return from(state)
        end)

        CHECK(runcount == 2)
        set(2)
        local _ = unwrap(derived)
        CHECK(runcount == 4)
    end

    do CASE "Run watcher callback twice"
        local state, set = wrap(1)
        local runcount = 0

        watch(function(from)
            runcount += 1
            local _ = from(state)
        end)

        CHECK(runcount == 2)
        set(2)
        vide.step(1/60)
        CHECK(runcount == 4)
    end

    do CASE "Does not allow non-layout properties"
        local ok = pcall(function()
            vide.create "Frame" {
                [vide.Layout] = {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.new(0, 0, 0)
                }
            }
        end)
        CHECK(not ok)
    end

    do CASE "Does not allow same table set"
        local _, set = wrap()

        local t = {}

        set(t)
        
        local ok = pcall(set, t)

        CHECK(not ok)
    end

    -- todo: add case for strict mode bindings
end)

local ok = FINISH()
if not ok then error("Tests failed", 0) end

return nil
