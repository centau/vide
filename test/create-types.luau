type Pseudo = {
    Test: number
}

type Instances = {
    TextLabel: TextLabel,
    TextButton: TextButton,
    ImageLabel: ImageLabel,
    Pseudo: Pseudo
}

type function Properties(instance: type?)
    local properties = types.newtable()

    while instance do
        for i, v in instance:properties() do
            local connector = v.read and v.read.tag == "table" and v.read:readproperty(types.singleton("Connect"))
            if connector then
                if not connector then continue end
                local params = connector:parameters().head
                if not params then continue end
                local listener = params[2]
                if not listener then continue end
                properties:setproperty(i, types.optional(listener))
            elseif v.write then
                properties:setproperty(i, types.optional(types.unionof(
                    v.write,
                    types.newfunction({}, { head = { v.write } })
                )))
            end
        end

        instance = instance:readparent()
    end

    properties:setindexer(types.number, types.any)

    return properties
end

local function create<Name>(name: Name | keyof<Instances>): (Properties<index<Instances, Name>>) -> index<Instances, Name>
    return function()
        return "" :: any
    end
end

local vide = require "../src/"
local count = vide.source(0)
create("TextButton") { -- todo: why is `:: "TextButton"` not necessary?
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

    create "TextLabel" {},
    function() end,
}
