local vide = require "src/init"
local wrap = vide.wrap
local derive = vide.derive
local map = vide.map
local create = vide.create
local unwrap = vide.unwrap
local Event = vide.Event
local Layout = vide.Layout

do
    local count = wrap(0)
    local count2 = derive(function(from)
        local c = from(count) * unwrap(count)
        return c ^ 2
    end)
    local x = count2.value

    local count2b = count + 1
    local xb = unwrap(count2b)
end

local count = wrap(0)
local v = count.value

do
    local t = map(1, function(i)
        return ""
    end)

    local t = map({ true }, function(i, v)
        return 1
    end)

    local data = wrap { "" }

    local t = map(data, function(i, v)
        return 1
    end)
end



create("Frame") {

}

local Value, Computed, peek, OnEvent = nil :: any, nil :: any, nil :: any, nil :: any
local New = nil :: any

local function Counter(props)
    local count, set = wrap(0)

    return create("TextLabel") {
        Text = "Count: " .. count,

        [Layout] = props[Layout],

        [Event.Activated] = function()
            set(count + 1)
        end
    }
end

local function Frame(props)
    return create("Frame") {
        Position = props.Position
    }
end

Frame { Position = UDim2.fromScale(0.5, 0.5) }

Frame { Position = positionState }
