
--============================================================
-- DOOR ESP PRO v3.0
-- PART 1/4
-- CORE + GUI + UI BUILDERS
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local PromptService = game:GetService("ProximityPromptService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--============================================================
-- CONFIG
--============================================================

local Config = {
    ESP = false,
    ShowName = false,
    ShowDistance = false,
    MaxDistance = 5000,

    EnemyESP = false,
    EnemyNames = false,
    EnemyColor = Color3.fromRGB(0, 200, 170),

    InstantPrompt = false,

    AimEnabled = false,
    TeamAim = false,
    NPCAim = false,
    AimPart = "Head",
    AimSmoothness = 0.18,
    AimMaxDistance = 1000,
}

local Colors = {
    door = Color3.fromRGB(255, 200, 80),
    halloweendoor = Color3.fromRGB(255, 120, 40),
}

local ORANGE = Color3.fromRGB(255, 145, 45)
local DARK = Color3.fromRGB(15, 15, 19)
local PANEL = Color3.fromRGB(27, 27, 32)
local ROW = Color3.fromRGB(43, 43, 49)
local WHITE = Color3.fromRGB(245, 245, 245)
local GRAY = Color3.fromRGB(155, 155, 165)
local GREEN = Color3.fromRGB(0, 180, 145)

local trackedDoors = {}
local trackedEnemies = {}
local promptOriginals = {}
local rowRegistry = {}

local SelectedPlayer = nil
local CurrentTargetModel = nil

local destroyed = false
local espSuspended = false

local Connections = {}

--============================================================
-- HELPERS
--============================================================

local function trackConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function getColor(name)
    return Colors[string.lower(name)]
end

local function getRoot(inst)
    if not inst then return nil end

    if inst:IsA("BasePart") then
        return inst
    end

    if inst:IsA("Model") then
        return inst.PrimaryPart
            or inst:FindFirstChild("HumanoidRootPart")
            or inst:FindFirstChild("Head")
            or inst:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function getHeight(inst)
    if inst:IsA("Model") then
        local success, _, size = pcall(function()
            return inst:GetBoundingBox()
        end)

        if success and size then
            return size.Y + 2
        end
    elseif inst:IsA("BasePart") then
        return inst.Size.Y + 2
    end

    return 3
end

local function isAlive(model)
    if not model or not model:IsA("Model") then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")

    return humanoid ~= nil and humanoid.Health > 0
end

local function isEnemy(model)
    return model
        and model:IsA("Model")
        and Players:GetPlayerFromCharacter(model) == nil
        and isAlive(model)
        and getRoot(model) ~= nil
end

--============================================================
-- GUI ROOT
--============================================================

local oldGui = PlayerGui:FindFirstChild("DoorESP_PRO")

if oldGui then
    oldGui:Destroy()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "DoorESP_PRO"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Parent = obj
    return s
end

local function makeLabel(parent, text, size, position, color)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or WHITE
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

--============================================================
-- FLOATING BUTTON
--============================================================

local Orb = Instance.new("TextButton")
Orb.Name = "DoorESP_Orb"
Orb.Size = UDim2.fromOffset(48, 48)
Orb.Position = UDim2.new(0, 15, 0.5, -24)
Orb.BackgroundColor3 = DARK
Orb.BackgroundTransparency = 0.08
Orb.Text = "D"
Orb.TextColor3 = ORANGE
Orb.TextSize = 23
Orb.Font = Enum.Font.GothamBlack
Orb.Parent = Gui

corner(Orb, 100)
stroke(Orb, ORANGE, 2)

--============================================================
-- MAIN WINDOW
--============================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Size = UDim2.new(0.92, 0, 0.72, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.BackgroundColor3 = DARK
Main.BackgroundTransparency = 0.15
Main.BorderSizePixel = 0
Main.Visible = false
Main.Active = true
Main.Parent = Gui

corner(Main, 12)
stroke(Main, Color3.fromRGB(75, 75, 85), 1)

local SizeLimit = Instance.new("UISizeConstraint")
SizeLimit.MinSize = Vector2.new(290, 260)
SizeLimit.MaxSize = Vector2.new(650, 480)
SizeLimit.Parent = Main

--============================================================
-- DRAG SYSTEM
--============================================================

local function makeDraggable(object, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    trackConnection(UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

            local delta = input.Position - dragStart

            object.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))
end

--============================================================
-- HEADER
--============================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = PANEL
Header.BackgroundTransparency = 0.12
Header.BorderSizePixel = 0
Header.Parent = Main

corner(Header, 10)

local Title = makeLabel(
    Header,
    "DOOR ESP PRO | v3.0",
    UDim2.new(1, -60, 1, 0),
    UDim2.fromOffset(13, 0),
    WHITE
)

Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 28)
Close.Position = UDim2.new(1, -37, 0, 7)
Close.BackgroundColor3 = Color3.fromRGB(105, 43, 43)
Close.Text = "X"
Close.TextColor3 = WHITE
Close.Font = Enum.Font.GothamBold
Close.TextSize = 12
Close.Parent = Header

corner(Close, 6)

Close.Activated:Connect(function()
    Main.Visible = false
end)

makeDraggable(Main, Header)
makeDraggable(Orb, Orb)

Orb.Activated:Connect(function()
    Main.Visible = not Main.Visible
end)

--============================================================
-- SIDEBAR
--============================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0.27, -10, 1, -52)
Sidebar.Position = UDim2.fromOffset(7, 47)
Sidebar.BackgroundColor3 = PANEL
Sidebar.BackgroundTransparency = 0.16
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

corner(Sidebar, 8)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 8)
SidePadding.PaddingLeft = UDim.new(0, 6)
SidePadding.PaddingRight = UDim.new(0, 6)
SidePadding.Parent = Sidebar

--============================================================
-- CONTENT
--============================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(0.73, -3, 1, -52)
Content.Position = UDim2.new(0.27, 3, 0, 47)
Content.BackgroundColor3 = PANEL
Content.BackgroundTransparency = 0.16
Content.BorderSizePixel = 0
Content.Parent = Main

corner(Content, 8)

local Search = Instance.new("TextBox")
Search.Size = UDim2.new(1, -18, 0, 33)
Search.Position = UDim2.fromOffset(9, 8)
Search.BackgroundColor3 = ROW
Search.BackgroundTransparency = 0.12
Search.Text = ""
Search.PlaceholderText = "Buscar opciones..."
Search.PlaceholderColor3 = GRAY
Search.TextColor3 = WHITE
Search.Font = Enum.Font.Gotham
Search.TextSize = 12
Search.ClearTextOnFocus = false
Search.Parent = Content

corner(Search, 7)

--============================================================
-- TABS
--============================================================

local Tabs = {
    "EVENT",
    "VISUAL",
    "INTERACTION",
    "COMBATE",
    "SETTINGS"
}

local Pages = {}
local TabButtons = {}
local rowRegistry = {}

for index, name in ipairs(Tabs) do

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 38)
    button.BackgroundColor3 = ROW
    button.BackgroundTransparency = 0.08
    button.Text = name
    button.TextColor3 = GRAY
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.TextWrapped = true
    button.LayoutOrder = index
    button.Parent = Sidebar

    corner(button, 6)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 1, -8)
    indicator.Position = UDim2.new(0, 0, 0, 4)
    indicator.BackgroundColor3 = ORANGE
    indicator.Visible = false
    indicator.Parent = button

    corner(indicator, 4)

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1, -14, 1, -51)
    page.Position = UDim2.fromOffset(7, 46)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = ORANGE
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Pages[name] = page

    TabButtons[name] = {
        Button = button,
        Indicator = indicator
    }

    button.Activated:Connect(function()
        for tab, p in pairs(Pages) do
            local selected = tab == name

            p.Visible = selected
            TabButtons[tab].Button.TextColor3 =
                selected and ORANGE or GRAY

            TabButtons[tab].Button.BackgroundColor3 =
                selected and Color3.fromRGB(57, 45, 35) or ROW

            TabButtons[tab].Indicator.Visible = selected
        end

        Search.Text = ""
    end)
end

local function selectTab(name)
    for tab, page in pairs(Pages) do
        local selected = tab == name
        page.Visible = selected

        TabButtons[tab].Button.TextColor3 =
            selected and ORANGE or GRAY

        TabButtons[tab].Indicator.Visible = selected
    end
end

selectTab("EVENT")

--============================================================
-- SEARCH
--============================================================

local function registerSearch(object, name)
    table.insert(rowRegistry, {
        Object = object,
        Name = string.lower(name)
    })
end

local function refreshSearch()
    local query = string.lower(Search.Text)

    for _, item in ipairs(rowRegistry) do
        if item.Object.Parent then
            item.Object.Visible =
                query == ""
                or string.find(item.Name, query, 1, true) ~= nil
        end
    end
end

Search:GetPropertyChangedSignal("Text"):Connect(refreshSearch)

--============================================================
-- UI BUILDERS
--============================================================

local function section(parent, text)
    local label = makeLabel(
        parent,
        text,
        UDim2.new(1, 0, 0, 23),
        UDim2.new(),
        ORANGE
    )

    label.Font = Enum.Font.GothamBold
    label.TextSize = 11

    registerSearch(label, text)
    return label
end

local function infoText(parent, text, height)
    local label = makeLabel(
        parent,
        text,
        UDim2.new(1, -4, 0, height or 38),
        UDim2.new(),
        GRAY
    )

    label.TextSize = 10
    label.TextWrapped = true

    registerSearch(label, text)
    return label
end

local function toggle(parent, name, initial, callback)
    local state = initial

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 39)
    button.BackgroundColor3 = ROW
    button.BackgroundTransparency = 0.08
    button.Text = ""
    button.Parent = parent

    corner(button, 7)

    local label = makeLabel(
        button,
        name,
        UDim2.new(1, -72, 1, 0),
        UDim2.fromOffset(10, 0),
        WHITE
    )

    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(39, 21)
    indicator.Position = UDim2.new(1, -48, 0.5, -10)
    indicator.BackgroundColor3 = ROW
    indicator.Parent = button

    corner(indicator, 20)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(15, 15)
    dot.Position = UDim2.fromOffset(3, 3)
    dot.BackgroundColor3 = WHITE
    dot.Parent = indicator

    corner(dot, 20)

    local function refresh()
        indicator.BackgroundColor3 = state
            and GREEN
            or Color3.fromRGB(65, 65, 70)

        dot.Position = state
            and UDim2.new(1, -18, 0, 3)
            or UDim2.fromOffset(3, 3)
    end

    local function setState(value)
        state = value
        refresh()

        if callback then
            callback(state)
        end
    end

    button.Activated:Connect(function()
        setState(not state)
    end)

    refresh()
    registerSearch(button, name)

    return {
        Get = function()
            return state
        end,
        Set = setState
    }
end

local function actionButton(parent, name, color, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 37)
    button.BackgroundColor3 = color
    button.BackgroundTransparency = 0.05
    button.Text = name
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.TextWrapped = true
    button.Parent = parent

    corner(button, 7)

    button.Activated:Connect(callback)
    registerSearch(button, name)

    return button
end

--============================================================
-- COLOR INPUT
--============================================================

local function colorInput(parent, title, initialColor, callback)
    section(parent, title)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 83)
    frame.BackgroundColor3 = ROW
    frame.Parent = parent

    corner(frame, 7)

    local function makeBox(x, value)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 48, 0, 27)
        box.Position = UDim2.fromOffset(x, 9)
        box.BackgroundColor3 = DARK
        box.Text = tostring(value)
        box.TextColor3 = WHITE
        box.Font = Enum.Font.GothamBold
        box.TextSize = 11
        box.ClearTextOnFocus = false
        box.Parent = frame
        corner(box, 5)
        return box
    end

    local r = makeBox(9, math.floor(initialColor.R * 255))
    local g = makeBox(63, math.floor(initialColor.G * 255))
    local b = makeBox(117, math.floor(initialColor.B * 255))

    local preview = Instance.new("Frame")
    preview.Size = UDim2.fromOffset(30, 27)
    preview.Position = UDim2.fromOffset(171, 9)
    preview.BackgroundColor3 = initialColor
    preview.Parent = frame

    corner(preview, 5)

    local apply = Instance.new("TextButton")
    apply.Size = UDim2.new(1, -18, 0, 28)
    apply.Position = UDim2.fromOffset(9, 47)
    apply.BackgroundColor3 = GREEN
    apply.Text = "APPLY COLOR"
    apply.TextColor3 = WHITE
    apply.Font = Enum.Font.GothamBold
    apply.TextSize = 10
    apply.Parent = frame

    corner(apply, 5)

    apply.Activated:Connect(function()
        local red = tonumber(r.Text)
        local green = tonumber(g.Text)
        local blue = tonumber(b.Text)

        if not red or not green or not blue then
            return
        end

        local color = Color3.fromRGB(
            math.clamp(math.floor(red), 0, 255),
            math.clamp(math.floor(green), 0, 255),
            math.clamp(math.floor(blue), 0, 255)
        )

        preview.BackgroundColor3 = color
        callback(color)
    end)

    registerSearch(frame, title)
    return frame
end

--============================================================
-- PART 1/4 END
-- PART 2 MUST BE PASTED BELOW
--============================================================

--============================================================
-- DOOR ESP PRO v3.0
-- PART 2/4
-- DOOR TRACKER + EVENT + INTERACTION
--============================================================

--============================================================
-- PROMPT SYSTEM
--============================================================

local function isDoorPrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end

    local model = prompt:FindFirstAncestorOfClass("Model")
    local targetName = model and model.Name or prompt.Parent.Name

    return getColor(targetName) ~= nil
end

local function checkPrompt(prompt)
    if not Config.InstantPrompt then return end
    if not isDoorPrompt(prompt) then return end

    if not promptOriginals[prompt] then
        promptOriginals[prompt] = {
            HoldDuration = prompt.HoldDuration,
            MaxDistance = prompt.MaxActivationDistance
        }
    end

    pcall(function()
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 15
    end)
end

local function restorePrompts()
    for prompt, original in pairs(promptOriginals) do
        if prompt and prompt.Parent then
            pcall(function()
                prompt.HoldDuration = original.HoldDuration
                prompt.MaxActivationDistance = original.MaxDistance
            end)
        end
    end

    table.clear(promptOriginals)
end

local function applyPrompts()
    if Config.InstantPrompt then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                checkPrompt(obj)
            end
        end
    else
        restorePrompts()
    end
end

--============================================================
-- DOOR ESP
--============================================================

local function removeDoorESP(obj)
    local data = trackedDoors[obj]
    if not data then return end

    pcall(function()
        data.Highlight:Destroy()
        data.Billboard:Destroy()
    end)

    trackedDoors[obj] = nil
end

local function addDoorESP(obj)
    if destroyed or not Config.ESP or espSuspended then
        return
    end

    if trackedDoors[obj] then return end

    local color = getColor(obj.Name)
    if not color then return end

    if not obj:IsA("Model") and not obj:IsA("BasePart") then
        return
    end

    local root = getRoot(obj)
    if not root then return end

    local success, data = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "DoorESP_Highlight"
        highlight.Adornee = obj
        highlight.FillColor = color
        highlight.FillTransparency = 0.65
        highlight.OutlineColor = color
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = Gui

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DoorESP_Label"
        billboard.Size = UDim2.fromOffset(180, 25)
        billboard.StudsOffsetWorldSpace =
            Vector3.new(0, getHeight(obj) + 1, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = Config.MaxDistance
        billboard.Adornee = root
        billboard.Parent = Gui

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.TextColor3 = color
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.TextStrokeTransparency = 0.2
        text.Parent = billboard

        return {
            Highlight = highlight,
            Billboard = billboard,
            Label = text,
            Root = root
        }
    end)

    if success and data then
        trackedDoors[obj] = data
    end
end

local function scanDoors()
    if not Config.ESP or espSuspended then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if getColor(obj.Name) then
            addDoorESP(obj)
        end
    end
end

local function clearDoors()
    for obj in pairs(trackedDoors) do
        removeDoorESP(obj)
    end
end

--============================================================
-- EVENT PAGE
--============================================================

section(Pages.EVENT, "DOOR ESP")

toggle(
    Pages.EVENT,
    "Door ESP",
    false,
    function(v)
        Config.ESP = v

        if v then
            espSuspended = false
            scanDoors()
        else
            clearDoors()
        end
    end
)

toggle(
    Pages.EVENT,
    "Show Door Name",
    false,
    function(v)
        Config.ShowName = v
    end
)

toggle(
    Pages.EVENT,
    "Show Distance",
    false,
    function(v)
        Config.ShowDistance = v
    end
)

section(Pages.EVENT, "DOOR COLORS")

infoText(
    Pages.EVENT,
    "YELLOW = Normal Door\nORANGE = Halloween Door",
    35
)

section(Pages.EVENT, "MAX DISTANCE")

local rangeLabel = makeLabel(
    Pages.EVENT,
    "Range: " .. Config.MaxDistance .. " studs",
    UDim2.new(1, 0, 0, 22),
    UDim2.new(),
    WHITE
)

local rangeFrame = Instance.new("Frame")
rangeFrame.Size = UDim2.new(1, -4, 0, 34)
rangeFrame.BackgroundTransparency = 1
rangeFrame.Parent = Pages.EVENT

local rangeLayout = Instance.new("UIListLayout")
rangeLayout.FillDirection = Enum.FillDirection.Horizontal
rangeLayout.Padding = UDim.new(0, 6)
rangeLayout.Parent = rangeFrame

local function updateRange()
    rangeLabel.Text =
        "Range: " .. Config.MaxDistance .. " studs"

    for _, data in pairs(trackedDoors) do
        data.Billboard.MaxDistance = Config.MaxDistance
    end

    for _, data in pairs(trackedEnemies) do
        data.Billboard.MaxDistance = Config.MaxDistance
    end
end

local function makeRangeButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -3, 1, 0)
    button.BackgroundColor3 = ROW
    button.Text = text
    button.TextColor3 = ORANGE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = rangeFrame

    corner(button, 6)
    button.Activated:Connect(callback)

    return button
end

makeRangeButton("- 500", function()
    Config.MaxDistance = math.max(
        100,
        Config.MaxDistance - 500
    )

    updateRange()
end)

makeRangeButton("+ 500", function()
    Config.MaxDistance = math.min(
        10000,
        Config.MaxDistance + 500
    )

    updateRange()
end)

--============================================================
-- INTERACTION PAGE
--============================================================

section(Pages.INTERACTION, "DOOR INTERACTION")

toggle(
    Pages.INTERACTION,
    "Instant Open",
    false,
    function(v)
        Config.InstantPrompt = v
        applyPrompts()
    end
)

infoText(
    Pages.INTERACTION,
    "Adjusts local ProximityPrompt properties. The server may enforce its own interaction rules.",
    55
)

--============================================================
-- WORLD DOOR CONNECTIONS
--============================================================

trackConnection(
    Workspace.DescendantAdded:Connect(function(obj)
        if getColor(obj.Name) then
            task.defer(function()
                if obj.Parent then
                    addDoorESP(obj)
                end
            end)
        end

        if obj:IsA("ProximityPrompt") then
            task.defer(function()
                checkPrompt(obj)
            end)
        end
    end)
)

trackConnection(
    Workspace.DescendantRemoving:Connect(function(obj)
        if trackedDoors[obj] then
            removeDoorESP(obj)
        end
    end)
)

trackConnection(
    PromptService.PromptShown:Connect(function(prompt)
        checkPrompt(prompt)
    end)
)

--============================================================
-- PART 2/4 END
--============================================================

--============================================================
-- DOOR ESP PRO v3.0
-- PART 3/4
-- VISUAL + ENEMY HOLOGRAM
--============================================================

--============================================================
-- ENEMY ESP
--============================================================

local function removeEnemyESP(model)
    local data = trackedEnemies[model]
    if not data then return end

    pcall(function()
        data.Highlight:Destroy()
        data.Billboard:Destroy()
    end)

    trackedEnemies[model] = nil
end

local function addEnemyESP(model)
    if destroyed then return end
    if not isEnemy(model) then return end

    if not Config.EnemyESP and not Config.EnemyNames then
        return
    end

    if trackedEnemies[model] then return end

    local root = getRoot(model)
    if not root then return end

    local success, data = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "Enemy_Hologram"
        highlight.Adornee = model
        highlight.FillColor = Config.EnemyColor
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = Config.EnemyColor
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = Config.EnemyESP
        highlight.Parent = Gui

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "Enemy_Name"
        billboard.Size = UDim2.fromOffset(180, 25)
        billboard.StudsOffsetWorldSpace =
            Vector3.new(0, getHeight(model) + 1, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = Config.MaxDistance
        billboard.Adornee = root
        billboard.Enabled = Config.EnemyNames
        billboard.Parent = Gui

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Text = model.Name
        text.TextColor3 = Config.EnemyColor
        text.TextStrokeTransparency = 0.2
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.Parent = billboard

        return {
            Highlight = highlight,
            Billboard = billboard,
            Label = text,
            Root = root
        }
    end)

    if success and data then
        trackedEnemies[model] = data
    end
end

local function scanEnemies()
    if not Config.EnemyESP and not Config.EnemyNames then
        return
    end

    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and isEnemy(model) then
            addEnemyESP(model)
        end
    end
end

local function clearEnemies()
    for model in pairs(trackedEnemies) do
        removeEnemyESP(model)
    end
end

local function updateEnemyColor()
    for _, data in pairs(trackedEnemies) do
        data.Highlight.FillColor = Config.EnemyColor
        data.Highlight.OutlineColor = Config.EnemyColor
        data.Label.TextColor3 = Config.EnemyColor
    end
end

--============================================================
-- VISUAL PAGE
--============================================================

section(Pages.VISUAL, "ENEMY HOLOGRAM")

toggle(
    Pages.VISUAL,
    "Enemy Hologram",
    false,
    function(v)
        Config.EnemyESP = v

        if v then
            scanEnemies()
        end

        for _, data in pairs(trackedEnemies) do
            data.Highlight.Enabled = v
        end
    end
)

toggle(
    Pages.VISUAL,
    "Show Enemy Names",
    false,
    function(v)
        Config.EnemyNames = v

        if v then
            scanEnemies()
        end

        for _, data in pairs(trackedEnemies) do
            data.Billboard.Enabled = v
        end
    end
)

infoText(
    Pages.VISUAL,
    "Detects NPC models with a living Humanoid. Players are excluded.",
    40
)

--============================================================
-- HOLOGRAM COLOR
--============================================================

colorInput(
    Pages.VISUAL,
    "HOLOGRAM COLOR (RGB)",
    Config.EnemyColor,
    function(color)
        Config.EnemyColor = color
        updateEnemyColor()
    end
)

--============================================================
-- ENEMY WORLD CONNECTION
--============================================================

trackConnection(
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            task.defer(function()
                if obj.Parent and isEnemy(obj) then
                    addEnemyESP(obj)
                end
            end)
        end
    end)
)

trackConnection(
    Workspace.DescendantRemoving:Connect(function(obj)
        if trackedEnemies[obj] then
            removeEnemyESP(obj)
        end
    end)
)

--============================================================
-- PART 3/4 END
--==========================
--============================================================
-- DOOR ESP PRO v3.0
-- PART 4/4
-- COMBAT + SETTINGS + UPDATE + DESTROY
--============================================================

--============================================================
-- COMBAT PAGE
--============================================================

section(Pages.COMBATE, "AIM ASSIST")

toggle(
    Pages.COMBATE,
    "Aim Lock",
    false,
    function(v)
        Config.AimEnabled = v
        CurrentTargetModel = nil
    end
)

toggle(
    Pages.COMBATE,
    "Team Filter",
    false,
    function(v)
        Config.TeamAim = v
    end
)

toggle(
    Pages.COMBATE,
    "NPC Targeting",
    false,
    function(v)
        Config.NPCAim = v
    end
)

section(Pages.COMBATE, "TARGET SETTINGS")

local PartButton = actionButton(
    Pages.COMBATE,
    "TARGET PART: HEAD",
    ROW,
    function()
        if Config.AimPart == "Head" then
            Config.AimPart = "Torso"
        elseif Config.AimPart == "Torso" then
            Config.AimPart = "HumanoidRootPart"
        else
            Config.AimPart = "Head"
        end

        PartButton.Text = "TARGET PART: "
            .. string.upper(Config.AimPart)
    end
)

actionButton(
    Pages.COMBATE,
    "CLEAR SELECTED PLAYER",
    ROW,
    function()
        SelectedPlayer = nil
        CurrentTargetModel = nil
    end
)

infoText(
    Pages.COMBATE,
    "Target selection and camera assistance settings.",
    30
)

--============================================================
-- PLAYER LIST
--============================================================

section(Pages.COMBATE, "PLAYER SELECTION")

local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(1, -4, 0, 125)
PlayerScroll.BackgroundColor3 = ROW
PlayerScroll.BorderSizePixel = 0
PlayerScroll.ScrollBarThickness = 3
PlayerScroll.ScrollBarImageColor3 = ORANGE
PlayerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScroll.Parent = Pages.COMBATE

corner(PlayerScroll, 7)

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.Padding = UDim.new(0, 5)
PlayerLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerLayout.Parent = PlayerScroll

local function refreshPlayerList()
    for _, child in ipairs(PlayerScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -8, 0, 30)
            button.BackgroundColor3 = DARK
            button.TextColor3 = WHITE
            button.Font = Enum.Font.GothamBold
            button.TextSize = 11
            button.Text = plr.Name
            button.Parent = PlayerScroll

            corner(button, 5)

            if SelectedPlayer == plr then
                button.Text = "SELECTED: " .. plr.Name
                button.TextColor3 = ORANGE
            end

            button.Activated:Connect(function()
                SelectedPlayer = plr
                refreshPlayerList()
            end)
        end
    end
end

refreshPlayerList()

trackConnection(
    Players.PlayerAdded:Connect(function()
        task.defer(refreshPlayerList)
    end)
)

trackConnection(
    Players.PlayerRemoving:Connect(function(plr)
        if SelectedPlayer == plr then
            SelectedPlayer = nil
        end

        task.defer(refreshPlayerList)
    end)
)

--============================================================
-- AIM HELPERS
--============================================================

local function getAimPart(model)
    if not model then return nil end

    local names = {Config.AimPart}

    if Config.AimPart == "Torso" then
        names = {
            "Torso",
            "UpperTorso",
            "LowerTorso",
            "HumanoidRootPart"
        }
    end

    for _, name in ipairs(names) do
        local part = model:FindFirstChild(name)

        if part and part:IsA("BasePart") then
            return part
        end
    end

    return getRoot(model)
end

--============================================================
-- CLOSEST PLAYER
--============================================================

local function closestPlayer()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local best = nil
    local bestDistance = Config.AimMaxDistance

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player
        and plr.Character
        and isAlive(plr.Character) then

            local allowed = not Config.TeamAim
                or plr.Team ~= Player.Team

            if allowed then
                local root = getRoot(plr.Character)

                if root then
                    local distance =
                        (root.Position - camera.CFrame.Position).Magnitude

                    if distance < bestDistance then
                        best = plr.Character
                        bestDistance = distance
                    end
                end
            end
        end
    end

    return best
end

--============================================================
-- CLOSEST NPC
--============================================================

local function closestNPC()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local best = nil
    local bestDistance = Config.AimMaxDistance

    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model")
        and Players:GetPlayerFromCharacter(model) == nil
        and isAlive(model) then

            local root = getRoot(model)

            if root then
                local distance =
                    (root.Position - camera.CFrame.Position).Magnitude

                if distance < bestDistance then
                    best = model
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

--============================================================
-- TARGET RESOLVER
--============================================================

local function resolveAimTarget()
    if SelectedPlayer then
        if SelectedPlayer.Parent
        and SelectedPlayer.Character
        and isAlive(SelectedPlayer.Character) then
            return SelectedPlayer.Character
        end

        SelectedPlayer = nil
        refreshPlayerList()
    end

    if Config.NPCAim then
        local npc = closestNPC()

        if npc then
            return npc
        end
    end

    return closestPlayer()
end

--============================================================
-- AIM UPDATE
--============================================================

trackConnection(
    RunService.RenderStepped:Connect(function(dt)
        if destroyed or not Config.AimEnabled then
            return
        end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        local target = resolveAimTarget()

        if not target or not isAlive(target) then
            CurrentTargetModel = nil
            return
        end

        local part = getAimPart(target)
        if not part then return end

        local cameraPosition = camera.CFrame.Position

        local desired = CFrame.lookAt(
            cameraPosition,
            part.Position
        )

        local alpha = math.clamp(
            1 - math.exp(
                -(1 - Config.AimSmoothness) * 60 * dt
            ),
            0,
            1
        )

        camera.CFrame = camera.CFrame:Lerp(desired, alpha)

        CurrentTargetModel = target
    end)
)

--============================================================
-- SETTINGS PAGE
--============================================================

section(Pages.SETTINGS, "GENERAL SETTINGS")

toggle(
    Pages.SETTINGS,
    "Show Floating Button",
    true,
    function(v)
        Orb.Visible = v
    end
)

section(Pages.SETTINGS, "DOOR MANAGEMENT")

actionButton(
    Pages.SETTINGS,
    "CLEAR DOOR ESP",
    Color3.fromRGB(145, 40, 45),
    function()
        Config.ESP = false
        espSuspended = true
        clearDoors()
    end
)

actionButton(
    Pages.SETTINGS,
    "RESTORE DOOR ESP",
    Color3.fromRGB(45, 105, 75),
    function()
        espSuspended = false
        Config.ESP = true
        scanDoors()
    end
)

section(Pages.SETTINGS, "ENEMY MANAGEMENT")

actionButton(
    Pages.SETTINGS,
    "CLEAR ENEMY ESP",
    Color3.fromRGB(145, 40, 45),
    function()
        Config.EnemyESP = false
        Config.EnemyNames = false
        clearEnemies()
    end
)

actionButton(
    Pages.SETTINGS,
    "RESTORE ENEMY ESP",
    Color3.fromRGB(45, 105, 75),
    function()
        Config.EnemyESP = true
        scanEnemies()
    end
)

section(Pages.SETTINGS, "SYSTEM")

infoText(
    Pages.SETTINGS,
    "DOOR ESP PRO v3.0\nAndroid / PC",
    35
)

actionButton(
    Pages.SETTINGS,
    "DESTROY SCRIPT",
    Color3.fromRGB(100, 40, 45),
    function()
        if _G.DoorESP_Destroy then
            _G.DoorESP_Destroy()
        end
    end
)

--============================================================
-- INITIAL SCAN
--============================================================

scanDoors()
scanEnemies()
applyPrompts()

--============================================================
-- WORLD UPDATE
--============================================================

local updateElapsed = 0

trackConnection(
    RunService.RenderStepped:Connect(function(dt)
        if destroyed then return end

        updateElapsed += dt

        if updateElapsed < 0.1 then
            return
        end

        updateElapsed = 0

        local camera = Workspace.CurrentCamera
        if not camera then return end

        local cameraPosition = camera.CFrame.Position

        -- DOOR UPDATE

        for obj, data in pairs(trackedDoors) do
            if not obj.Parent then
                removeDoorESP(obj)
            else
                local root = data.Root

                if not root or not root.Parent then
                    root = getRoot(obj)
                    data.Root = root

                    if root then
                        data.Billboard.Adornee = root
                        data.Billboard.StudsOffsetWorldSpace =
                            Vector3.new(0, getHeight(obj) + 1, 0)
                    end
                end

                if not Config.ESP or espSuspended or not root then
                    data.Highlight.Enabled = false
                    data.Billboard.Enabled = false
                else
                    local distance =
                        (cameraPosition - root.Position).Magnitude

                    local visible = distance <= Config.MaxDistance

                    data.Highlight.Enabled = visible
                    data.Billboard.Enabled = visible

                    if visible then
                        local parts = {}

                        if Config.ShowName then
                            table.insert(parts, "Door")
                        end

                        if Config.ShowDistance then
                            table.insert(
                                parts,
                                math.floor(distance) .. " studs"
                            )
                        end

                        data.Label.Text = table.concat(parts, " | ")
                    end
                end
            end
        end

        -- ENEMY UPDATE

        for model, data in pairs(trackedEnemies) do
            if not model.Parent or not isEnemy(model) then
                removeEnemyESP(model)
            else
                local root = data.Root

                if not root or not root.Parent then
                    root = getRoot(model)
                    data.Root = root

                    if root then
                        data.Billboard.Adornee = root
                        data.Billboard.StudsOffsetWorldSpace =
                            Vector3.new(0, getHeight(model) + 1, 0)
                    end
                end

                if not root then
                    data.Highlight.Enabled = false
                    data.Billboard.Enabled = false
                else
                    local distance =
                        (cameraPosition - root.Position).Magnitude

                    local visible = distance <= Config.MaxDistance

                    data.Highlight.Enabled =
                        Config.EnemyESP and visible

                    data.Billboard.Enabled =
                        Config.EnemyNames and visible

                    data.Label.Text = model.Name
                end
            end
        end
    end)
)

--============================================================
-- PERIODIC SCAN
--============================================================

task.spawn(function()
    while not destroyed and Gui.Parent do
        task.wait(3)

        if not destroyed then
            scanDoors()
            scanEnemies()
        end
    end
end)

--============================================================
-- DESTROY SYSTEM
--============================================================

_G.DoorESP_Destroy = function()
    if destroyed then return end

    destroyed = true

    -- Disconnect all tracked connections

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Connections)

    -- Remove ESP

    clearDoors()
    clearEnemies()

    -- Restore prompts

    restorePrompts()

    -- Reset target

    SelectedPlayer = nil
    CurrentTargetModel = nil

    -- Remove GUI

    Gui:Destroy()

    _G.DoorESP_Destroy = nil

    print("[DOOR ESP PRO v3.0] Destroyed successfully!")
end

--============================================================
-- LOADED
--============================================================

print("======================================")
print("       DOOR ESP PRO v3.0")
print("       Android / PC")
print("       Loaded successfully!")
print("======================================")
==================================
