if not game then script = require "test/relative-string" end
local typeof = game and typeof or require "test/mock".typeof:: never
local Instance = game and Instance or require "test/mock".Instance :: never

local throw = require(script.Parent.throw)
local defaults = require(script.Parent.defaults)
local apply = require(script.Parent.apply)
local memoize = require(script.Parent.memoize)

local function create_instance(class: string)
    local ok, instance: Instance = pcall(Instance.new, class :: any)
    if not ok then throw(`invalid class name, could not create instance of class { class }`) end

    local default: { [string]: unknown }? = defaults[class]
    if default then
        for i, v in next, default do
            (instance :: any)[i] = v
        end
    end

    return function(properties: { [any]: unknown }): Instance
        return apply(instance:Clone(), properties)    
    end  
end; create_instance = memoize(create_instance) -- always return same constructor for given class

local function clone_instance(instance: Instance)
    return function(properties: { [any]: unknown }): Instance
        local clone = instance:Clone()
        if not clone then error("Attempt to clone a non-archivable instance", 3) end
        return apply(clone, properties)
    end
end

local function create(class_or_instance: string|Instance)
    if type(class_or_instance) == "string" then
        return create_instance(class_or_instance)
    elseif typeof(class_or_instance) == "Instance" then
        return clone_instance(class_or_instance)
    else
        throw("bad argument #1, expected string or instance, got "..typeof(class_or_instance))
    end
    return nil :: never
end

type Props = { [any]: any }
return (create :: any) :: 
( <T>(T & Instance) -> (Props) -> T ) &
( ("Folder") -> (Props) -> Folder ) &
( ("BillboardGui") -> (Props) -> BillboardGui ) &
( ("CanvasGroup") -> (Props) -> CanvasGroup ) &
( ("Frame") -> (Props) -> Frame ) &
( ("ImageButton") -> (Props) -> ImageButton ) &
( ("ImageLabel") -> (Props) -> ImageLabel ) &
( ("ScreenGui") -> (Props) -> ScreenGui ) &
( ("ScrollingFrame") -> (Props) -> ScrollingFrame ) &
( ("SurfaceGui") -> (Props) -> SurfaceGui ) &
( ("TextBox") -> (Props) -> TextBox ) &
( ("TextButton") -> (Props) -> TextButton ) &
( ("TextLabel") -> (Props) -> TextLabel ) &
( ("UIAspectRatioConstraint") -> (Props) -> UIAspectRatioConstraint ) &
( ("UICorner") -> (Props) -> UICorner ) &
( ("UIGradient") -> (Props) -> UIGradient ) &
( ("UIGridLayout") -> (Props) -> UIGridLayout ) &
( ("UIListLayout") -> (Props) -> UIListLayout ) &
( ("UIPadding") -> (Props) -> UIPadding ) &
( ("UIPageLayout") -> (Props) -> UIPageLayout ) &
( ("UIScale") -> (Props) -> UIScale ) &
( ("UISizeConstraint") -> (Props) -> UISizeConstraint ) &
( ("UIStroke") -> (Props) -> UIStroke ) &
( ("UITableLayout") -> (Props) -> UITableLayout ) &
( ("UITextSizeConstraint") -> (Props) -> UITextSizeConstraint ) &
( ("VideoFrame") -> (Props) -> VideoFrame ) &
( ("ViewportFrame") -> (Props) -> ViewportFrame ) &
( (string) -> (Props) -> Instance )
