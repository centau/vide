type Prop<T> = T? | () -> T?

-- Creatable instances

export type FolderProps = {
	[any]: any,

	-- Instance

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

export type BillboardGuiProps = {
	[any]: any,

	-- BillboardGui

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

	-- LayerCollector

	Enabled: Prop<boolean>,
	ResetOnSpawn: Prop<boolean>,
	ZIndexBehavior: Prop<Enum.ZIndexBehavior>,

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type CanvasGroupProps = {
	[any]: any,

	-- CanvasGroup

	GroupColor3: Prop<Color3>,
	GroupTransparency: Prop<number>,

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type FrameProps = {
	[any]: any,

	-- Frame

	Style: Prop<Enum.FrameStyle>,

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type ImageButtonProps = {
	[any]: any,

	-- ImageButton

	HoverImage: Prop<string>,
	PressedImage: Prop<string>,

	-- ImageLabel

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

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type ImageLabelProps = {
	[any]: any,

	-- ImageLabel

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

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type ScreenGuiProps = {
	[any]: any,

	-- ScreenGui

	ClipToDeviceSafeArea: Prop<boolean>,
	DisplayOrder: Prop<number>,
	IgnoreGuiInset: Prop<boolean>,
	SafeAreaCompatibilityMode: Prop<Enum.SafeAreaCompatibility>,
	ScreenInsets: Prop<Enum.ScreenInsets>,

	-- LayerCollector

	Enabled: Prop<boolean>,
	ResetOnSpawn: Prop<boolean>,
	ZIndexBehavior: Prop<Enum.ZIndexBehavior>,

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type ScrollingFrameProps = {
	[any]: any,

	-- ScrollingFrame

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

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type SurfaceGuiProps = {
	[any]: any,

	-- SurfaceGui

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

	-- LayerCollector

	Enabled: Prop<boolean>,
	ResetOnSpawn: Prop<boolean>,
	ZIndexBehavior: Prop<Enum.ZIndexBehavior>,

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type TextLabelProps = {
	[any]: any,

	-- TextLabel

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

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type TextButtonProps = {
	[any]: any,

	-- TextButton

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

	-- GuiButton

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

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type TextBoxProps = {
	[any]: any,

	-- TextBox

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

	-- TextLabel

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

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type VideoFrameProps = {
	[any]: any,

	-- VideoFrame

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

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

export type ViewportFrameProps = {
	[any]: any,

	-- ViewportFrame

	Ambient: Prop<Color3>,
	CurrentCamera: Prop<Camera>,
	ImageColor3: Prop<Color3>,
	ImageTransparency: Prop<number>,
	LightColor: Prop<Color3>,
	LightDirection: Prop<Vector3>,

	-- GuiObject

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

	-- GuiBase2d

	AutoLocalize: Prop<boolean>,
	Localize: Prop<boolean>,
	RootLocalizationTable: Prop<LocalizationTable>,
	SelectionBehaviorDown: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorLeft: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorRight: Prop<Enum.SelectionBehavior>,
	SelectionBehaviorUp: Prop<Enum.SelectionBehavior>,
	SelectionGroup: Prop<boolean>,

	SelectionChanged: ((amISelected: boolean, previousSelection: GuiObject, newSelection: GuiObject) -> ())?,

	-- Instance

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

-- Creatable UI modifiers

export type UIAspectRatioConstraintProps = {
	[any]: any,

	-- UIAspectRatioConstraint

	AspectRatio: Prop<number>,
	AspectType: Prop<Enum.AspectType>,
	DominantAxis: Prop<Enum.DominantAxis>,

	-- Instance

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

export type UICornerProps = {
	[any]: any,

	-- UICorner

	CornerRadius: Prop<UDim>,

	-- Instance

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

export type UIGradientProps = {
	[any]: any,

	-- UIGradient

	Color: Prop<ColorSequence>,
	Enabled: Prop<boolean>,
	Offset: Prop<number>,
	Rotation: Prop<number>,
	Transparency: Prop<NumberSequence>,

	-- Instance

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

export type UIGridLayoutProps = {
	[any]: any,

	-- UIGridLayout

	CellPadding: Prop<UDim2>,
	CellSize: Prop<UDim2>,
	FillDirectionMaxCells: Prop<number>,
	StartCorner: Prop<Enum.StartCorner>,

	-- UIGridStyleLayout

	FillDirection: Prop<Enum.FillDirection>,
	HorizontalAlignment: Prop<Enum.HorizontalAlignment>,
	SortOrder: Prop<Enum.SortOrder>,
	VerticalAlignment: Prop<Enum.VerticalAlignment>,

	-- Instance

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

export type UIListLayoutProps = {
	[any]: any,

	-- UIListLayout

	Padding: Prop<UDim>,

	-- UIGridStyleLayout

	FillDirection: Prop<Enum.FillDirection>,
	HorizontalAlignment: Prop<Enum.HorizontalAlignment>,
	SortOrder: Prop<Enum.SortOrder>,
	VerticalAlignment: Prop<Enum.VerticalAlignment>,

	-- Instance

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

export type UIPaddingProps = {
	[any]: any,

	-- UIPadding

	PaddingBottom: Prop<UDim>,
	PaddingLeft: Prop<UDim>,
	PaddingRight: Prop<UDim>,
	PaddingTop: Prop<UDim>,

	-- Instance

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

export type UIPageLayoutProps = {
	[any]: any,

	-- UIPageLayout

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

	-- UIGridStyleLayout

	FillDirection: Prop<Enum.FillDirection>,
	HorizontalAlignment: Prop<Enum.HorizontalAlignment>,
	SortOrder: Prop<Enum.SortOrder>,
	VerticalAlignment: Prop<Enum.VerticalAlignment>,

	-- Instance

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

export type UIScaleProps = {
	[any]: any,

	-- UIScale

	Scale: Prop<number>,

	-- Instance

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

export type UISizeConstraintProps = {
	[any]: any,

	-- UISizeConstraint

	MaxSize: Prop<Vector2>,
	MinSize: Prop<Vector2>,

	-- Instance

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

export type UIStrokeProps = {
	[any]: any,

	-- UIStroke

	ApplyStrokeMode: Prop<Enum.ApplyStrokeMode>,
	Color: Prop<Color3>,
	Enabled: Prop<boolean>,
	LineJoinMode: Prop<Enum.LineJoinMode>,
	Thickness: Prop<number>,
	Transparency: Prop<number>,

	-- Instance

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

export type UITableLayoutProps = {
	[any]: any,

	-- UITableLayout

	FillEmptySpaceColumns: Prop<boolean>,
	FillEmptySpaceRows: Prop<boolean>,
	MajorAxis: Prop<Enum.TableMajorAxis>,
	Padding: Prop<UDim2>,

	-- UIGridStyleLayout

	FillDirection: Prop<Enum.FillDirection>,
	HorizontalAlignment: Prop<Enum.HorizontalAlignment>,
	SortOrder: Prop<Enum.SortOrder>,
	VerticalAlignment: Prop<Enum.VerticalAlignment>,

	-- Instance

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

export type UITextSizeConstraintProps = {
	[any]: any,

	-- UITextSizeConstraint

	MaxTextSize: Prop<number>,
	MinTextSize: Prop<number>,

	-- Instance

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

return {}
