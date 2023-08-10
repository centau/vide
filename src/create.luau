local Instance = Instance
local typeof = typeof

if not game then
    script = require "test/relative-string"
    Instance = require("test/mock").Instance
    typeof = require("test/mock").typeof
end

local throw = require(script.Parent.throw)
local defaults = require(script.Parent.defaults)
local apply = require(script.Parent.apply)
local memoize = require(script.Parent.memoize)

local function create_instance(className: string)
    local success, instance: Instance = pcall(Instance.new, className :: any)
    if success == false then throw(`invalid class name, could not create instance of class { className }`) end

    local default: { [string]: unknown }? = defaults[className]
    if default then
        for i, v in next, default do
            (instance :: any)[i] = v
        end
    end

    return function(properties: { [any]: unknown }): Instance
        return apply(instance:Clone(), properties)    
    end  
end; create_instance = memoize(create_instance)

local function clone_instance(instance: Instance)
    return function(properties: { [any]: unknown }): Instance
        local clone = instance:Clone()
        if not clone then error("Attempt to clone a non-archivable instance", 3) end
        return apply(clone, properties)
    end
end

local function create(classNameOrInstance: string|Instance)
    if type(classNameOrInstance) == "string" then
        return create_instance(classNameOrInstance)
    elseif typeof(classNameOrInstance) == "Instance" then
        return clone_instance(classNameOrInstance)
    else
        error("Bad argument #1, expected string or instance, got "..typeof(classNameOrInstance), 2)
    end
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
