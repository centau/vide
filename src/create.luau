if not game then script = require "test/relative-string" end
local typeof = game and typeof or require "test/mock".typeof:: never
local Instance = game and Instance or require "test/mock".Instance :: never

local types = require(script.Parent.types)
local throw = require(script.Parent.throw)
local defaults = require(script.Parent.defaults)
local apply = require(script.Parent.apply)
local memoize = require(script.Parent.memoize)

local function create_instance(class_name: string)
    local ok, instance: Instance = pcall(Instance.new, class_name :: any)
    if not ok then throw(`invalid class name, could not create instance of class { class_name }`) end

    local default: { [string]: unknown }? = defaults[class_name]
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
( ("Folder") -> (types.FolderProps) -> Folder ) &
( ("BillboardGui") -> (types.BillboardGuiProps) -> BillboardGui ) &
( ("CanvasGroup") -> (types.CanvasGroupProps) -> CanvasGroup ) &
( ("Frame") -> (types.FrameProps) -> Frame ) &
( ("ImageButton") -> (types.ImageButtonProps) -> ImageButton ) &
( ("ImageLabel") -> (types.ImageLabelProps) -> ImageLabel ) &
( ("ScreenGui") -> (types.ScreenGuiProps) -> ScreenGui ) &
( ("ScrollingFrame") -> (types.ScrollingFrameProps) -> ScrollingFrame ) &
( ("SurfaceGui") -> (types.SurfaceGuiProps) -> SurfaceGui ) &
( ("TextBox") -> (types.TextBoxProps) -> TextBox ) &
( ("TextButton") -> (types.TextButtonProps) -> TextButton ) &
( ("TextLabel") -> (types.TextLabelProps) -> TextLabel ) &
( ("UIAspectRatioConstraint") -> (types.UIAspectRatioConstraintProps) -> UIAspectRatioConstraint ) &
( ("UICorner") -> (types.UICornerProps) -> UICorner ) &
( ("UIGradient") -> (types.UIGradientProps) -> UIGradient ) &
( ("UIGridLayout") -> (types.UIGridLayoutProps) -> UIGridLayout ) &
( ("UIListLayout") -> (types.UIListLayoutProps) -> UIListLayout ) &
( ("UIPadding") -> (types.UIPaddingProps) -> UIPadding ) &
( ("UIPageLayout") -> (types.UIPageLayoutProps) -> UIPageLayout ) &
( ("UIScale") -> (types.UIScaleProps) -> UIScale ) &
( ("UISizeConstraint") -> (types.UISizeConstraintProps) -> UISizeConstraint ) &
( ("UIStroke") -> (types.UIStrokeProps) -> UIStroke ) &
( ("UITableLayout") -> (types.UITableLayoutProps) -> UITableLayout ) &
( ("UITextSizeConstraint") -> (types.UITextSizeConstraintProps) -> UITextSizeConstraint ) &
( ("VideoFrame") -> (types.VideoFrameProps) -> VideoFrame ) &
( ("ViewportFrame") -> (types.ViewportFrameProps) -> ViewportFrame ) &
( (string) -> (Props) -> Instance )
