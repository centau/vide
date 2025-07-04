local typeof = game and typeof or require "../test/mock".typeof :: never
local Instance = game and Instance or require "../test/mock".Instance :: never

local defaults = require "./defaults"
local apply = require "./apply"
local flags = require "./flags"

local ctor_cache = {} :: { [string]: () -> Instance }

setmetatable(ctor_cache :: any, {
    __index = function(self, class)
        local function ctor(properties: Props): Instance
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

        self[class] = ctor
        return ctor
    end
})

local function create_instance(class: string)
    return ctor_cache[class]
end

local function clone_instance(instance: Instance)
    return function(properties: Props): Instance
        local clone = instance:Clone()
        if not clone then error "attempt to clone a non-archivable instance" end
        return apply(clone, properties)
    end
end

local function create(class_or_instance: string | Instance, props: Props?): ((Props) -> Instance) | Instance
	local result: (Props) -> Instance
	if type(class_or_instance) == "string" then
		result = create_instance(class_or_instance)
	elseif typeof(class_or_instance) == "Instance" then
		result = clone_instance(class_or_instance)
	else
		error("bad argument #1, expected string or instance, got " .. typeof(class_or_instance), 0)
		return nil :: never
	end
	if props then
		return result(props)
	end
	return result
end

type Props = { [any]: any }

type Create<Name, Instance> = ((Name, Props) -> Instance) & ((Name) -> (Props) -> Instance)

return (create :: any) ::
	& ( <T>(T & Instance) -> (Props) -> T )
	& ( <T>(T & Instance, Props) -> T )
	& Create<"Folder", Folder>
	& Create<"BillboardGui", BillboardGui>
	& Create<"CanvasGroup", CanvasGroup>
	& Create<"Frame", Frame>
	& Create<"ImageButton", ImageButton>
	& Create<"ImageLabel", ImageLabel>
	& Create<"ScreenGui", ScreenGui>
	& Create<"ScrollingFrame", ScrollingFrame>
	& Create<"SurfaceGui", SurfaceGui>
	& Create<"TextBox", TextBox>
	& Create<"TextButton", TextButton>
	& Create<"TextLabel", TextLabel>
	& Create<"UIAspectRatioConstraint", UIAspectRatioConstraint>
	& Create<"UICorner", UICorner>
	& Create<"UIGradient", UIGradient>
	& Create<"UIGridLayout", UIGridLayout>
	& Create<"UIListLayout", UIListLayout>
	& Create<"UIPadding", UIPadding>
	& Create<"UIPageLayout", UIPageLayout>
	& Create<"UIScale", UIScale>
	& Create<"UISizeConstraint", UISizeConstraint>
	& Create<"UIStroke", UIStroke>
	& Create<"UITableLayout", UITableLayout>
	& Create<"UITextSizeConstraint", UITextSizeConstraint>
	& Create<"VideoFrame", VideoFrame>
	& Create<"ViewportFrame", ViewportFrame>
	& Create<string, Instance>
