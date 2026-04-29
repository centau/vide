local vide = require "../src/"

local count = vide.source(0)

vide.create("TextButton") {
    BackgroundTransparency = 1,
    AnchorPoint = "bad value", -- should error
    InvalidProperty = true, -- should error

    Text = function()
        return "count: " .. count()
    end,

    Size = function() -- should error
        return "bad value"
    end,

    MouseEnter = function(x, y)

    end,

    Activated = "bad value", -- should error

    vide.create "TextLabel" {},
    
    function() end,
}
