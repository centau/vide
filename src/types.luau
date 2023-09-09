if not game then
	script = require("test/relative-string")
end

type Prop<T> = T? | () -> T?

-- Creatable instances

export type FolderProps = InstanceProps

export type BillboardGuiProps = LayerCollectorProps & {
	Active: Prop<boolean>,
	Adornee: Prop<Instance>,
	AlwaysOnTop: Prop<boolean>,
	Brightness: Prop<number>,
	ClipsDescendants: Prop<boolean>,
	DistanceLowerLimit: Prop<number>,
	DistanceStep: Prop<number>,
	DistanceUpperLimit: Prop<number>,
	ExtentsOffset: Prop<Vector3>,
	ExtentsOffsetWorldSpace: Prop<Vector3>,
	LightInfluence: Prop<number>,
	MaxDistance: Prop<number>,
	PlayerToHideFrom: Prop<Instance>,
	Size: Prop<UDim2>,
	SizeOffset: Prop<Vector2>,
	StudsOffset: Prop<Vector3>,
	StudsOffsetWorldSpace: Prop<Vector3>,
}

export type CanvasGroupProps = GuiObjectProps & {
	GroupColor3: Prop<Color3>,
	GroupTransparency: Prop<number>,
}

export type FrameProps = GuiObjectProps & {
	Style: Prop<Enum.FrameStyle>,
}

export type ImageButtonProps = GuiButtonProps & ImageProps & {
	HoverImage: Prop<string>,
	PressedImage: Prop<string>,
}

export type ImageLabelProps = GuiObjectProps & ImageProps

export type ScreenGuiProps = LayerCollectorProps & {
	ClipToDeviceSafeArea: Prop<boolean>,
	DisplayOrder: Prop<number>,
	IgnoreGuiInset: Prop<boolean>,
	SafeAreaCompatibilityMode: Prop<Enum.SafeAreaCompatibility>,
	ScreenInsets: Prop<Enum.ScreenInsets>,
}

export type ScrollingFrameProps = GuiObjectProps & {
	AutomaticCanvasSize: Prop<Enum.AutomaticSize>,
	BottomImage: Prop<string>,
	CanvasPosition: Prop<Vector2>,
	CanvasSize: Prop<UDim2>,
	ElasticBehavior: Prop<Enum.ElasticBehavior>,
	HorizontalScrollBarInset: Prop<Enum.ScrollBarInset>,
	MidImage: Prop<string>,
	ScrollBarImageColor3: Prop<Color3>,
	ScrollBarImageTransparency: Prop<number>,
	ScrollBarThickness: Prop<number>,
	ScrollingDirection: Prop<Enum.ScrollingDirection>,
	ScrollingEnabled: Prop<boolean>,
	TopImage: Prop<string>,
	VerticalScrollBarInset: Prop<Enum.ScrollBarInset>,
	VerticalScrollBarPosition: Prop<Enum.VerticalScrollBarPosition>,
}

export type SurfaceGuiProps = LayerCollectorProps & {
	Active: Prop<boolean>,
	Adornee: Prop<Instance>,
	AlwaysOnTop: Prop<boolean>,
	Brightness: Prop<number>,
	CanvasSize: Prop<Vector2>,
	ClipsDescendants: Prop<boolean>,
	Face: Prop<Enum.NormalId>,
	LightInfluence: Prop<number>,
	MaxDistance: Prop<number>,
	PixelsPerStud: Prop<number>,
	SizingMode: Prop<Enum.SurfaceGuiSizingMode>,
	ToolPunchThroughDistance: Prop<number>,
	ZOffset: Prop<number>,
}

export type TextLabelProps = GuiObjectProps & TextProps

export type TextButtonProps = GuiButtonProps & TextProps

export type TextBoxProps = GuiObjectProps & TextProps & {
	ClearTextOnFocus: Prop<boolean>,
	CursorPosition: Prop<number>,
	MultiLine: Prop<boolean>,
	PlaceholderColor3: Prop<Color3>,
	PlaceholderText: Prop<string>,
	SelectionStart: Prop<number>,
	ShowNativeInput: Prop<boolean>,
	TextEditable: Prop<boolean>,

	FocusLost: ((enterPressed: boolean, inputThatCausedFocusLoss: InputObject) -> ())?,
	Focused: (() -> ())?,
	ReturnPressedFromOnScreenKeyboard: (() -> ())?,
}

export type VideoFrameProps = GuiObjectProps & {
	Looped: Prop<boolean>,
	Playing: Prop<boolean>,
	TimePosition: Prop<number>,
	Video: Prop<string>,
	Volume: Prop<number>,

	DidLoop: ((video: string) -> ())?,
	Ended: ((video: string) -> ())?,
	Loaded: ((video: string) -> ())?,
	Paused: ((video: string) -> ())?,
	Played: ((video: string) -> ())?,
}

export type ViewportFrameProps = GuiObjectProps & {
	Ambient: Prop<Color3>,
	CurrentCamera: Prop<Camera>,
	ImageColor3: Prop<Color3>,
	ImageTransparency: Prop<number>,
	LightColor: Prop<Color3>,
	LightDirection: Prop<Vector3>,
}

-- Creatable UI modifiers

export type UIAspectRatioConstraintProps = InstanceProps & {
	AspectRatio: Prop<number>,
	AspectType: Prop<Enum.AspectType>,
	DominantAxis: Prop<Enum.DominantAxis>,
}

export type UICornerProps = InstanceProps & {
	CornerRadius: Prop<UDim>,
}

export type UIGradientProps = InstanceProps & {
	Color: Prop<ColorSequence>,
	Enabled: Prop<boolean>,
	Offset: Prop<number>,
	Rotation: Prop<number>,
	Transparency: Prop<NumberSequence>,
}

export type UIGridLayoutProps = UIGridStyleLayoutProps & {
	CellPadding: Prop<UDim2>,
	CellSize: Prop<UDim2>,
	FillDirectionMaxCells: Prop<number>,
	StartCorner: Prop<Enum.StartCorner>,
}

export type UIListLayoutProps = UIGridStyleLayoutProps & {
	Padding: Prop<UDim>,
}

export type UIPaddingProps = InstanceProps & {
	PaddingBottom: Prop<UDim>,
	PaddingLeft: Prop<UDim>,
	PaddingRight: Prop<UDim>,
	PaddingTop: Prop<UDim>,
}

export type UIPageLayoutProps = UIGridStyleLayoutProps & {
	Animated: Prop<boolean>,
	Circular: Prop<boolean>,
	EasingDirection: Prop<Enum.EasingDirection>,
	EasingStyle: Prop<Enum.EasingStyle>,
	GamepadInputEnabled: Prop<boolean>,
	Padding: Prop<UDim>,
	ScrollWheelInputEnabled: Prop<boolean>,
	TouchInputEnabled: Prop<boolean>,
	TweenTime: Prop<number>,

	PageEnter: ((page: any) -> ())?,
	PageLeave: ((page: any) -> ())?,
	Stopped: ((currentPage: any) -> ())?,
}

export type UIScaleProps = InstanceProps & {
	Scale: Prop<number>,
}

export type UISizeConstraintProps = InstanceProps & {
	MaxSize: Prop<Vector2>,
	MinSize: Prop<Vector2>,
}

export type UIStrokeProps = InstanceProps & {
	ApplyStrokeMode: Prop<Enum.ApplyStrokeMode>,
	Color: Prop<Color3>,
	Enabled: Prop<boolean>,
	LineJoinMode: Prop<Enum.LineJoinMode>,
	Thickness: Prop<number>,
	Transparency: Prop<number>,
}

export type UITableLayoutProps = UIGridStyleLayoutProps & {
	FillEmptySpaceColumns: Prop<boolean>,
	FillEmptySpaceRows: Prop<boolean>,
	MajorAxis: Prop<Enum.TableMajorAxis>,
	Padding: Prop<UDim2>,
}

export type UITextSizeConstraintProps = InstanceProps & {
	MaxTextSize: Prop<number>,
	MinTextSize: Prop<number>,
}

-- Helpers

type ImageProps = {
	Image: Prop<string>,
	ImageColor3: Prop<Color3>,
	ImageRectOffset: Prop<Vector2>,
	ImageRectSize: Prop<Vector2>,
	ImageTransparency: Prop<number>,
	ResampleMode: Prop<Enum.ResamplerMode>,
	ScaleType: Prop<Enum.ScaleType>,
	SliceCenter: Prop<Rect>,
	SliceScale: Prop<number>,
	TileSize: Prop<UDim2>,
}

type TextProps = {
	Font: Prop<Enum.Font>,
	FontFace: Prop<Font>,
	LineHeight: Prop<number>,
	MaxVisibleGraphemes: Prop<number>,
	RichText: Prop<string>,
	Text: Prop<string>,
	TextColor3: Prop<Color3>,
	TextDirection: Prop<Enum.TextDirection>,
	TextScaled: Prop<boolean>,
	TextSize: Prop<number>,
	TextStrokeColor3: Prop<Color3>,
	TextStrokeTransparency: Prop<number>,
	TextTransparency: Prop<number>,
	TextTruncate: Prop<Enum.TextTruncate>,
	TextWrapped: Prop<boolean>,
	TextXAlignment: Prop<Enum.TextXAlignment>,
	TextYAlignment: Prop<Enum.TextYAlignment>,
}

-- Base instance types

type InstanceProps = {
	[any]: any,

	Archivable: Prop<boolean>,
	Name: Prop<string>,
	Parent: Prop<Instance>,

	AncestryChanged: ((child: Instance, parent: Instance?) -> ())?,
	AttributeChanged: ((attribute: string) -> ())?,
	Changed: ((property: string) -> ())?,
	ChildAdded: ((child: Instance) -> ())?,
	ChildRemoved: ((child: Instance) -> ())?,
	DescendantAdded: ((descendant: Instance) -> ())?,
	DescendantRemoving: ((descendant: Instance) -> ())?,
	Destroying: (() -> ())?,
}

type GuiBase2dProps = InstanceProps & {
	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,
}

type UIGridStyleLayoutProps = InstanceProps & {
	FillDirection: Prop<Enum.FillDirection>,
	HorizontalAlignment: Prop<Enum.HorizontalAlignment>,
	SortOrder: Prop<Enum.SortOrder>,
	VerticalAlignment: Prop<Enum.VerticalAlignment>,
}

type GuiObjectProps = GuiBase2dProps & {
	Active: Prop<boolean>,
	AnchorPoint: Prop<Vector2>,
	AutomaticSize: Prop<Enum.AutomaticSize>,
	BackgroundColor3: Prop<Color3>,
	BackgroundTransparency: Prop<number>,
	BorderColor3: Prop<Color3>,
	BorderMode: Prop<Enum.BorderMode>,
	BorderSizePixel: Prop<number>,
	ClipsDescendants: Prop<boolean>,
	Interactable: Prop<boolean>,
	LayoutOrder: Prop<number>,
	NextSelectionDown: Prop<GuiObject>,
	NextSelectionLeft: Prop<GuiObject>,
	NextSelectionRight: Prop<GuiObject>,
	NextSelectionUp: Prop<GuiObject>,
	Position: Prop<UDim2>,
	Rotation: Prop<number>,
	Selectable: Prop<boolean>,
	SelectionImageObject: Prop<GuiObject>,
	SelectionOrder: Prop<number>,
	Size: Prop<UDim2>,
	SizeConstraint: Prop<Enum.SizeConstraint>,
	Visible: Prop<boolean>,
	ZIndex: Prop<number>,

	InputBegan: ((input: InputObject) -> ())?,
	InputChanged: ((input: InputObject) -> ())?,
	InputEnded: ((input: InputObject) -> ())?,
	MouseEnter: ((x: number, y: number) -> ())?,
	MouseLeave: ((x: number, y: number) -> ())?,
	MouseMoved: ((x: number, y: number) -> ())?,
	MouseWheelBackward: ((x: number, y: number) -> ())?,
	MouseWheelForward: ((x: number, y: number) -> ())?,
	SelectionGained: (() -> ())?,
	SelectionLost: (() -> ())?,
	TouchLongPress: ((touchPositions: { Vector2 }, state: Enum.UserInputState) -> ())?,
	TouchPan: ((
		touchPositions: { Vector2 },
		totalTranslation: Vector2,
		velocity: Vector2,
		state: Enum.UserInputState
	) -> ())?,
	TouchPinch: ((touchPositions: { Vector2 }, scale: number, velocity: number, state: Enum.UserInputState) -> ())?,
	TouchRotate: ((touchPositions: { Vector2 }, rotation: number, velocity: number, state: Enum.UserInputState) -> ())?,
	TouchSwipe: ((swipeDirection: Enum.SwipeDirection, numberOfTouches: number) -> ())?,
	TouchTap: ((touchPositions: { Vector2 }) -> ())?,
}

type LayerCollectorProps = GuiBase2dProps & {
	Enabled: Prop<boolean>,
	ResetOnSpawn: Prop<boolean>,
	ZIndexBehavior: Prop<Enum.ZIndexBehavior>,
}

type GuiButtonProps = GuiObjectProps & {
	AutoButtonColor: Prop<boolean>,
	Modal: Prop<boolean>,
	Selected: Prop<boolean>,
	Style: Prop<Enum.ButtonStyle>,

	Activated: ((input: InputObject, clickCount: number) -> ())?,
	MouseButton1Click: (() -> ())?,
	MouseButton1Down: ((x: number, y: number) -> ())?,
	MouseButton1Up: ((x: number, y: number) -> ())?,
	MouseButton2Click: (() -> ())?,
	MouseButton2Down: ((x: number, y: number) -> ())?,
	MouseButton2Up: ((x: number, y: number) -> ())?,
}

return nil
