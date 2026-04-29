local typeof = game and typeof or require "../test/mock".typeof :: never
local Instance = game and Instance or require "../test/mock".Instance :: never

local defaults = require "./defaults"
local apply = require "./apply"
local flags = require "./flags"

local function create_constructor_for_class(class: string): ({ [unknown]: unknown }) -> Instance
    local function constructor(properties: { [unknown]: unknown }): Instance
        local ok, instance: Instance = pcall(Instance.new, class :: any)
        if not ok then error(`invalid class name {class}`, 0) end

        if flags.defaults then
            local default: { [string]: unknown }? = defaults[class]
            if default then
                for i, v in default do
                    (instance :: any)[i] = v
                end
            end
        end

        return apply(instance, properties)
    end

    return constructor
end

local constructor_cache = {} :: { [string]: ({ [unknown]: unknown }) -> Instance }

-- todo: remove support for different overloads
local function create(class_or_instance: string|Instance, properties: { [unknown]: unknown }?): unknown
    if type(class_or_instance) ~= "string" and typeof(class_or_instance) ~= "Instance" then
        error("bad argument #1, expected string or instance, got " .. typeof(class_or_instance), 0)
    end

    local constructor: ({ [unknown]: unknown }) -> Instance
    if type(class_or_instance) == "string" then
        constructor = constructor_cache[class_or_instance]
        if not constructor then
            constructor = create_constructor_for_class(class_or_instance)
            constructor_cache[class_or_instance] = constructor
        end
    else
        constructor = function(props)
            local clone = assert(class_or_instance:Clone(), "attempt to clone a non-archivable instance")
            return apply(clone, props)
        end
    end

    return if properties
        then constructor(properties)
        else constructor
end

type Instances = {
    Folder: Folder,
    BillboardGui: BillboardGui,
    CanvasGroup: CanvasGroup,
    Frame: Frame,
    ImageButton: ImageButton,
    ImageLabel: ImageLabel,
    ScreenGui: ScreenGui,
    ScrollingFrame: ScrollingFrame,
    SurfaceGui: SurfaceGui,
    TextBox: TextBox,
    TextButton: TextButton,
    TextLabel: TextLabel,
    UIAspectRatioConstraint: UIAspectRatioConstraint,
    UICorner: UICorner,
    UIGradient: UIGradient,
    UIGridLayout: UIGridLayout,
    UIListLayout: UIListLayout,
    Camera: Camera,
    WorldModel: WorldModel,
}

type function Properties(instance: type?)
    local properties = types.newtable()

    while instance do
        for i, v in instance:properties() do
            local connector = v.read and v.read.tag == "table" and v.read:readproperty(types.singleton("Connect"))
            if connector then
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

type Create = <Name>(Name|keyof<Instances>|"") -> (Properties<index<Instances, Name>>) -> index<Instances, Name>

return create :: Create
