--------------------------------------------------------------------------------
-- vide.luau
--------------------------------------------------------------------------------

local version = { major = 0, minor = 3, patch = 1 }

if not game then script = require "test/relative-string" end

local root = require(script.root)
local mount = require(script.mount)
local create = require(script.create)
local apply = require(script.apply)
local source = require(script.source)
local effect = require(script.effect)
local derive = require(script.derive)
local cleanup = require(script.cleanup)
local untrack = require(script.untrack)
local read = require(script.read)
local batch = require(script.batch)
local context = require(script.context)
local switch = require(script.switch)
local show = require(script.show)
local indexes, values = require(script.maps)()
local spring, update_springs = require(script.spring)()
local action = require(script.action)()
local changed = require(script.changed)
local throw = require(script.throw)
local flags = require(script.flags)
local roblox_types = require(script.roblox_types)

export type Source<T> = source.Source<T>
export type source<T> = Source<T>
export type Context<T> = context.Context<T>
export type context<T> = Context<T>

local function step(dt: number)
    if game then
        debug.profilebegin("VIDE STEP")
        debug.profilebegin("VIDE SPRING")
    end

    update_springs(dt)

    if game then
        debug.profileend()
        debug.profileend()
    end
end

local stepped = game and game:GetService("RunService").Heartbeat:Connect(function(dt: number)
    task.defer(step, dt)
end)

local vide = {
    version = version,

    -- core
    root = root,
    mount = mount,
    create = create,
    source = source,
    effect = effect,
    derive = derive,
    switch = switch,
    show = show,
    indexes = indexes,
    values = values,

    -- util
    cleanup = cleanup,
    untrack = untrack,
    read = read,
    batch = batch,
    context = context,

    -- animations
    spring = spring,

    -- actions
    action = action,
    changed = changed,

    -- flags
    strict = (nil :: any) :: boolean,

    -- temporary
    apply = function(instance: Instance)
        return function(props: { [any]: any })
            apply(instance, props)
            return instance
        end
    end,

    -- runtime
    step = function(dt: number)
        if stepped then
            stepped:Disconnect()
            stepped = nil
        end
        step(dt)
    end
}

setmetatable(vide :: any, {
    __index = function(_, index: unknown): ()
        if index == "strict" then
            return flags.strict
        else
            throw(`{tostring(index)} is not a valid member of vide`)
        end
    end,

    __newindex = function(_, index: unknown, value: unknown)
        if index == "strict" then
            flags.strict = value :: boolean
        else
            throw(`{tostring(index)} is not a valid member of vide`)
        end
    end
})

-- TYPES HERE
export type vCanvasGroup = roblox_types.vCanvasGroup
export type vFrame = roblox_types.vFrame
export type vImageButton = roblox_types.vImageButton
export type vTextButton = roblox_types.vTextButton
export type vImageLabel = roblox_types.vImageLabel
export type vTextLabel = roblox_types.vTextLabel
export type vScrollingFrame = roblox_types.vScrollingFrame
export type vTextBox = roblox_types.vTextBox
export type vVideoFrame = roblox_types.vVideoFrame
export type vViewportFrame = roblox_types.vViewportFrame
export type vBillboardGui = roblox_types.vBillboardGui
export type vScreenGui = roblox_types.vScreenGui
export type vAdGui = roblox_types.vAdGui
export type vSurfaceGui = roblox_types.vSurfaceGui
export type vSelectionBox = roblox_types.vSelectionBox
export type vBoxHandleAdornment = roblox_types.vBoxHandleAdornment
export type vConeHandleAdornment = roblox_types.vConeHandleAdornment
export type vCylinderHandleAdornment = roblox_types.vCylinderHandleAdornment
export type vImageHandleAdornment = roblox_types.vImageHandleAdornment
export type vLineHandleAdornment = roblox_types.vLineHandleAdornment
export type vSphereHandleAdornment = roblox_types.vSphereHandleAdornment
export type vWireframeHandleAdornment = roblox_types.vWireframeHandleAdornment
export type vParabolaAdornment = roblox_types.vParabolaAdornment
export type vSelectionSphere = roblox_types.vSelectionSphere
export type vArcHandles = roblox_types.vArcHandles
export type vHandles = roblox_types.vHandles
export type vSurfaceSelection = roblox_types.vSurfaceSelection
export type vPath2D = roblox_types.vPath2D
export type vUIAspectRatioConstraint = roblox_types.vUIAspectRatioConstraint
export type vUISizeConstraint = roblox_types.vUISizeConstraint
export type vUITextSizeConstraint = roblox_types.vUITextSizeConstraint
export type vUICorner = roblox_types.vUICorner
export type vUIDragDetector = roblox_types.vUIDragDetector
export type vUIFlexItem = roblox_types.vUIFlexItem
export type vUIGradient = roblox_types.vUIGradient
export type vUIListLayout = roblox_types.vUIListLayout
export type vUIGridLayout = roblox_types.vUIGridLayout
export type vUIPageLayout = roblox_types.vUIPageLayout
export type vUITableLayout = roblox_types.vUITableLayout
export type vUIPadding = roblox_types.vUIPadding
export type vUIScale = roblox_types.vUIScale
export type vUIStroke = roblox_types.vUIStroke
export type vWorldModel = roblox_types.vWorldModel
export type vCamera = roblox_types.vCamera
export type vPart = roblox_types.vPart
export type vModel = roblox_types.vModel
export type vMeshPart = roblox_types.vMeshPart
export type vHighlight = roblox_types.vHighlight
export type vFrame = roblox_types.vFrame
export type vImageButton = roblox_types.vImageButton
export type vTextButton = roblox_types.vTextButton
export type vImageLabel = roblox_types.vImageLabel
export type vTextLabel = roblox_types.vTextLabel
export type vScrollingFrame = roblox_types.vScrollingFrame
export type vTextBox = roblox_types.vTextBox
export type vVideoFrame = roblox_types.vVideoFrame
export type vViewportFrame = roblox_types.vViewportFrame
export type vBillboardGui = roblox_types.vBillboardGui
export type vScreenGui = roblox_types.vScreenGui
export type vAdGui = roblox_types.vAdGui
export type vSurfaceGui = roblox_types.vSurfaceGui
export type vSelectionBox = roblox_types.vSelectionBox
export type vBoxHandleAdornment = roblox_types.vBoxHandleAdornment
export type vConeHandleAdornment = roblox_types.vConeHandleAdornment
export type vCylinderHandleAdornment = roblox_types.vCylinderHandleAdornment
export type vImageHandleAdornment = roblox_types.vImageHandleAdornment
export type vLineHandleAdornment = roblox_types.vLineHandleAdornment
export type vSphereHandleAdornment = roblox_types.vSphereHandleAdornment
export type vWireframeHandleAdornment = roblox_types.vWireframeHandleAdornment
export type vParabolaAdornment = roblox_types.vParabolaAdornment
export type vSelectionSphere = roblox_types.vSelectionSphere
export type vArcHandles = roblox_types.vArcHandles
export type vHandles = roblox_types.vHandles
export type vSurfaceSelection = roblox_types.vSurfaceSelection
export type vPath2D = roblox_types.vPath2D
export type vUIAspectRatioConstraint = roblox_types.vUIAspectRatioConstraint
export type vUISizeConstraint = roblox_types.vUISizeConstraint
export type vUITextSizeConstraint = roblox_types.vUITextSizeConstraint
export type vUICorner = roblox_types.vUICorner
export type vUIDragDetector = roblox_types.vUIDragDetector
export type vUIFlexItem = roblox_types.vUIFlexItem
export type vUIGradient = roblox_types.vUIGradient
export type vUIListLayout = roblox_types.vUIListLayout
export type vUIGridLayout = roblox_types.vUIGridLayout
export type vUIPageLayout = roblox_types.vUIPageLayout
export type vUITableLayout = roblox_types.vUITableLayout
export type vUIPadding = roblox_types.vUIPadding
export type vUIScale = roblox_types.vUIScale
export type vUIStroke = roblox_types.vUIStroke
export type vWorldModel = roblox_types.vWorldModel
export type vCamera = roblox_types.vCamera
export type vPart = roblox_types.vPart
export type vModel = roblox_types.vModel
export type vMeshPart = roblox_types.vMeshPart
export type vHighlight = roblox_types.vHighlight

return vide