local typeof = game and typeof or require "../test/mock".typeof :: never
local Instance = game and Instance or require "../test/mock".Instance :: never

local defaults = require "./defaults"
local apply = require "./apply"
local r = require "./roblox_types"

local ctor_cache = {} :: { [string]: () -> Instance }
type Props = { [any]: any }

setmetatable(ctor_cache :: any, {
    __index = function(self, class)
        local ok, instance: Instance = pcall(Instance.new, class :: any)
        if not ok then error(`invalid class name, could not create instance of class { class }`, 0) end

        local default: { [string]: unknown }? = defaults[class]
        if default then
            for i, v in next, default do
                (instance :: any)[i] = v
            end
        end

        local function ctor(properties: Props): Instance
            return apply(instance:Clone(), properties)
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

local function create(class_or_instance: string | Instance, props: Props?): ((any) -> Instance) | Instance
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

return (create :: any) ::
	( (class: "CanvasGroup") -> (r.vCanvasGroup) -> CanvasGroup )
&	( (class: "Frame") -> (r.vFrame) -> Frame )
&	( (class: "ImageButton") -> (r.vImageButton) -> ImageButton )
&	( (class: "TextButton") -> (r.vTextButton) -> TextButton )
&	( (class: "ImageLabel") -> (r.vImageLabel) -> ImageLabel )
&	( (class: "TextLabel") -> (r.vTextLabel) -> TextLabel )
&	( (class: "ScrollingFrame") -> (r.vScrollingFrame) -> ScrollingFrame )
&	( (class: "TextBox") -> (r.vTextBox) -> TextBox )
&	( (class: "VideoFrame") -> (r.vVideoFrame) -> VideoFrame )
&	( (class: "ViewportFrame") -> (r.vViewportFrame) -> ViewportFrame )
&	( (class: "BillboardGui") -> (r.vBillboardGui) -> BillboardGui )
&	( (class: "ScreenGui") -> (r.vScreenGui) -> ScreenGui )
&	( (class: "AdGui") -> (r.vAdGui) -> AdGui )
&	( (class: "SurfaceGui") -> (r.vSurfaceGui) -> SurfaceGui )
&	( (class: "SelectionBox") -> (r.vSelectionBox) -> SelectionBox )
&	( (class: "BoxHandleAdornment") -> (r.vBoxHandleAdornment) -> BoxHandleAdornment )
&	( (class: "ConeHandleAdornment") -> (r.vConeHandleAdornment) -> ConeHandleAdornment )
&	( (class: "CylinderHandleAdornment") -> (r.vCylinderHandleAdornment) -> CylinderHandleAdornment )
&	( (class: "ImageHandleAdornment") -> (r.vImageHandleAdornment) -> ImageHandleAdornment )
&	( (class: "LineHandleAdornment") -> (r.vLineHandleAdornment) -> LineHandleAdornment )
&	( (class: "SphereHandleAdornment") -> (r.vSphereHandleAdornment) -> SphereHandleAdornment )
&	( (class: "WireframeHandleAdornment") -> (r.vWireframeHandleAdornment) -> WireframeHandleAdornment )
&	( (class: "ParabolaAdornment") -> (r.vParabolaAdornment) -> ParabolaAdornment )
&	( (class: "SelectionSphere") -> (r.vSelectionSphere) -> SelectionSphere )
&	( (class: "ArcHandles") -> (r.vArcHandles) -> ArcHandles )
&	( (class: "Handles") -> (r.vHandles) -> Handles )
&	( (class: "SurfaceSelection") -> (r.vSurfaceSelection) -> SurfaceSelection )
&	( (class: "Path2D") -> (r.vPath2D) -> Path2D )
&	( (class: "UIAspectRatioConstraint") -> (r.vUIAspectRatioConstraint) -> UIAspectRatioConstraint )
&	( (class: "UISizeConstraint") -> (r.vUISizeConstraint) -> UISizeConstraint )
&	( (class: "UITextSizeConstraint") -> (r.vUITextSizeConstraint) -> UITextSizeConstraint )
&	( (class: "UICorner") -> (r.vUICorner) -> UICorner )
&	( (class: "UIDragDetector") -> (r.vUIDragDetector) -> UIDragDetector )
&	( (class: "UIFlexItem") -> (r.vUIFlexItem) -> UIFlexItem )
&	( (class: "UIGradient") -> (r.vUIGradient) -> UIGradient )
&	( (class: "UIListLayout") -> (r.vUIListLayout) -> UIListLayout )
&	( (class: "UIGridLayout") -> (r.vUIGridLayout) -> UIGridLayout )
&	( (class: "UIPageLayout") -> (r.vUIPageLayout) -> UIPageLayout )
&	( (class: "UITableLayout") -> (r.vUITableLayout) -> UITableLayout )
&	( (class: "UIPadding") -> (r.vUIPadding) -> UIPadding )
&	( (class: "UIScale") -> (r.vUIScale) -> UIScale )
&	( (class: "UIStroke") -> (r.vUIStroke) -> UIStroke )
&	( (class: "WorldModel") -> (r.vWorldModel) -> WorldModel )
&	( (class: "Camera") -> (r.vCamera) -> Camera )
&	( (class: "Part") -> (r.vPart) -> Part )
&	( (class: "Model") -> (r.vModel) -> Model )
&	( (class: "MeshPart") -> (r.vMeshPart) -> MeshPart )
&	( (class: "Highlight") -> (r.vHighlight) -> Highlight )
&	( (class: "Folder") -> (r.vFolder) -> Folder )
&	( (class: "Attachment") -> (r.vAttachment) -> Attachment )
&	( (class: "ParticleEmitter") -> (r.vParticleEmitter) -> ParticleEmitter )
