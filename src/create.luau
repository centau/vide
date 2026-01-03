local typeof = game and typeof or require "../test/mock".typeof :: never
local Instance = game and Instance or require "../test/mock".Instance :: never

local defaults = require "./defaults"
local apply = require "./apply"
local flags = require "./flags"

local ctor_cache = {} :: { [string]: (AnyProps) -> Instance }
local function lazy_init(_, class: string)
    local function ctor(properties: AnyProps): Instance
        local ok, instance: Instance = pcall(Instance.new, class :: any)
        if not ok then error(`invalid class name { class }`, 0) end

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

    ctor_cache[class] = ctor
    return ctor
end
setmetatable(ctor_cache, { __index = lazy_init })

-- todo: remove support for different overloads
local function create(class_or_instance: string|Instance, properties: AnyProps?): ((AnyProps) -> Instance) | Instance
    if type(class_or_instance) ~= "string" and typeof(class_or_instance) ~= "Instance" then
        error("bad argument #1, expected string or instance, got " .. typeof(class_or_instance), 0)
    end

    local ctor = if type(class_or_instance) == "string"
        then ctor_cache[class_or_instance]
        else function(properties)
            local clone = class_or_instance:Clone()
            if not clone then error "attempt to clone a non-archivable instance" end
            return apply(clone, properties)
        end

    return if properties
        then ctor(properties)
        else ctor
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

type AnyProps = { [any]: any }
type Create = (
    (Instance) -> (AnyProps) -> Instance
) & (
    (string, AnyProps) -> Instance
) & (
    <Name>(Name|keyof<Instances>) -> (Properties<index<Instances, Name>>) -> index<Instances, Name>
)

return (create :: any) :: Create
