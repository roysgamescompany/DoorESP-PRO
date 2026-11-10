
--============================================================
-- DOOR ESP PRO v2.2
-- PART 1/3
-- GUI + CONFIG + UI BUILDERS
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
-- CONFIGURATION
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

local destroyed = false
local espSuspended = false

--============================================================
-- HELPERS
--============================================================

local function getColor(name)
    return Colors[string.lower(name)]
end

local function getRoot(inst)
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
        local _, size = inst:GetBoundingBox()
        return size.Y + 2
    elseif inst:IsA("BasePart") then
        return inst.Size.Y + 2
    end

    return 3
end

local function isEnemy(model)
    return model
        and model:IsA("Model")
        and CollectionService:HasTag(model, "Enemy")
        and model:FindFirstChildOfClass("Humanoid") ~= nil
        and not Players:GetPlayerFromCharacter(model)
end

--============================================================
-- GUI ROOT
--============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "DoorESP_PRO"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
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
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or WHITE
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

--============================================================
-- FLOATING BUTTON
--============================================================

local Orb = Instance.new("TextButton")
Orb.Name = "DoorESP_Orb"
Orb.Size = UDim2.fromOffset(52, 52)
Orb.Position = UDim2.new(0, 18, 0.5, -26)
Orb.BackgroundColor3 = DARK
Orb.Text = "D"
Orb.TextColor3 = ORANGE
Orb.TextSize = 25
Orb.Font = Enum.Font.GothamBlack
Orb.Parent = Gui

corner(Orb, 100)
stroke(Orb, ORANGE, 2)

--============================================================
-- MAIN WINDOW
--============================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(650, 440)
Main.Position = UDim2.new(0.5, -325, 0.5, -220)
Main.BackgroundColor3 = DARK
Main.BorderSizePixel = 0
Main.Visible = false
Main.Active = true
Main.Parent = Gui

corner(Main, 13)
stroke(Main, Color3.fromRGB(65, 65, 72), 1)

--============================================================
-- DRAG
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

    UIS.InputChanged:Connect(function(input)
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
    end)
end

--============================================================
-- HEADER
--============================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = PANEL
Header.BorderSizePixel = 0
Header.Parent = Main

corner(Header, 10)

local Title = makeLabel(
    Header,
    "DOOR ESP PRO  |  v2.2",
    UDim2.new(1, -65, 1, 0),
    UDim2.fromOffset(18, 0),
    WHITE
)

Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(35, 30)
Close.Position = UDim2.new(1, -43, 0, 9)
Close.BackgroundColor3 = Color3.fromRGB(105, 43, 43)
Close.Text = "X"
Close.TextColor3 = WHITE
Close.Font = Enum.Font.GothamBold
Close.Parent = Header

corner(Close, 7)

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
Sidebar.Size = UDim2.new(0, 165, 1, -58)
Sidebar.Position = UDim2.fromOffset(8, 53)
Sidebar.BackgroundColor3 = PANEL
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

corner(Sidebar, 9)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 7)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 10)
SidePadding.PaddingLeft = UDim.new(0, 7)
SidePadding.PaddingRight = UDim.new(0, 7)
SidePadding.Parent = Sidebar

--============================================================
-- CONTENT
--============================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -185, 1, -58)
Content.Position = UDim2.fromOffset(178, 53)
Content.BackgroundColor3 = PANEL
Content.BorderSizePixel = 0
Content.Parent = Main

corner(Content, 9)

local Search = Instance.new("TextBox")
Search.Size = UDim2.new(1, -24, 0, 37)
Search.Position = UDim2.fromOffset(12, 10)
Search.BackgroundColor3 = ROW
Search.Text = ""
Search.PlaceholderText = "Buscar opciones..."
Search.PlaceholderColor3 = GRAY
Search.TextColor3 = WHITE
Search.Font = Enum.Font.Gotham
Search.TextSize = 13
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
local activeTab = "EVENT"

for index, name in ipairs(Tabs) do

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 42)
    button.BackgroundColor3 = ROW
    button.Text = name
    button.TextColor3 = GRAY
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.LayoutOrder = index
    button.Parent = Sidebar

    corner(button, 7)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 4, 1, -8)
    indicator.Position = UDim2.new(0, 0, 0, 4)
    indicator.BackgroundColor3 = ORANGE
    indicator.Visible = false
    indicator.Parent = button

    corner(indicator, 5)

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1, -20, 1, -60)
    page.Position = UDim2.fromOffset(10, 55)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = ORANGE
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Pages[name] = page

    TabButtons[name] = {
        Button = button,
        Indicator = indicator
    }

    button.Activated:Connect(function()
        activeTab = name

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
    activeTab = name

    for tab, page in pairs(Pages) do
        local selected = tab == name
        page.Visible = selected

        TabButtons[tab].Button.TextColor3 =
            selected and ORANGE or GRAY

        TabButtons[tab].Button.BackgroundColor3 =
            selected and Color3.fromRGB(57, 45, 35) or ROW

        TabButtons[tab].Indicator.Visible = selected
    end
end

selectTab("EVENT")

--============================================================
-- SEARCH SYSTEM
--============================================================

local function registerSearch(object, name, tab)
    table.insert(rowRegistry, {
        Object = object,
        Name = string.lower(name),
        Tab = tab
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

local function getTabFromPage(parent)
    return parent.Name:gsub("_Page", "")
end

local function section(parent, text)
    local l = makeLabel(
        parent,
        text,
        UDim2.new(1, 0, 0, 27),
        UDim2.new(),
        ORANGE
    )

    l.Font = Enum.Font.GothamBold
    l.TextSize = 12

    registerSearch(l, text, getTabFromPage(parent))

    return l
end

local function infoText(parent, text, height)
    local l = makeLabel(
        parent,
        text,
        UDim2.new(1, -4, 0, height or 40),
        UDim2.new(),
        GRAY
    )

    l.TextSize = 11
    l.TextWrapped = true

    registerSearch(l, text, getTabFromPage(parent))

    return l
end

local function toggle(parent, name, initial, callback)
    local state = initial

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 46)
    button.BackgroundColor3 = ROW
    button.Text = ""
    button.Parent = parent

    corner(button, 8)

    local textLabel = makeLabel(
        button,
        name,
        UDim2.new(1, -85, 1, 0),
        UDim2.fromOffset(14, 0),
        WHITE
    )

    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 13

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(48, 25)
    indicator.Position = UDim2.new(1, -60, 0.5, -12)
    indicator.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
    indicator.Parent = button

    corner(indicator, 20)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(19, 19)
    dot.Position = UDim2.fromOffset(3, 3)
    dot.BackgroundColor3 = WHITE
    dot.Parent = indicator

    corner(dot, 20)

    local function refresh()
        indicator.BackgroundColor3 = state
            and GREEN
            or Color3.fromRGB(65, 65, 70)

        dot.Position = state
            and UDim2.new(1, -22, 0, 3)
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

    registerSearch(button, name, getTabFromPage(parent))

    return {
        Get = function()
            return state
        end,
        Set = setState
    }
end

local function actionButton(parent, name, color, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 43)
    button.BackgroundColor3 = color
    button.Text = name
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = parent

    corner(button, 8)

    button.Activated:Connect(callback)

    registerSearch(button, name, getTabFromPage(parent))

    return button
end

--============================================================
-- COLOR INPUT BUILDER
--============================================================

local function colorInput(parent, title, initialColor, callback)

    section(parent, title)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 92)
    frame.BackgroundColor3 = ROW
    frame.Parent = parent

    corner(frame, 8)

    local function makeBox(x, placeholder, value)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 65, 0, 32)
        box.Position = UDim2.fromOffset(x, 12)
        box.BackgroundColor3 = DARK
        box.Text = tostring(value)
        box.PlaceholderText = placeholder
        box.TextColor3 = WHITE
        box.Font = Enum.Font.GothamBold
        box.TextSize = 12
        box.ClearTextOnFocus = false
        box.Parent = frame
        corner(box, 6)
        return box
    end

    local r = makeBox(12, "R", math.floor(initialColor.R * 255))
    local g = makeBox(87, "G", math.floor(initialColor.G * 255))
    local b = makeBox(162, "B", math.floor(initialColor.B * 255))

    local preview = Instance.new("Frame")
    preview.Size = UDim2.fromOffset(45, 32)
    preview.Position = UDim2.fromOffset(237, 12)
    preview.BackgroundColor3 = initialColor
    preview.Parent = frame

    corner(preview, 6)

    local apply = Instance.new("TextButton")
    apply.Size = UDim2.new(1, -24, 0, 30)
    apply.Position = UDim2.fromOffset(12, 53)
    apply.BackgroundColor3 = GREEN
    apply.Text = "APPLY COLOR"
    apply.TextColor3 = WHITE
    apply.Font = Enum.Font.GothamBold
    apply.TextSize = 11
    apply.Parent = frame

    corner(apply, 6)

    apply.Activated:Connect(function()
        local red = tonumber(r.Text)
        local green = tonumber(g.Text)
        local blue = tonumber(b.Text)

        if not red or not green or not blue then
            return
        end

        red = math.clamp(math.floor(red), 0, 255)
        green = math.clamp(math.floor(green), 0, 255)
        blue = math.clamp(math.floor(blue), 0, 255)

        local newColor = Color3.fromRGB(red, green, blue)

        preview.BackgroundColor3 = newColor
        callback(newColor)
    end)

    registerSearch(
        frame,
        title,
        getTabFromPage(parent)
    )

    return frame
end

--============================================================
-- PART 2/3 CONTINUES
--============================================================

--============================================================
-- DOOR ESP PRO v2.2
-- PART 2/3
-- EVENT + DOOR TRACKER + INTERACTION
--============================================================

--============================================================
-- DOOR PROMPTS
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

    if not Config.InstantPrompt then
        return
    end

    if not isDoorPrompt(prompt) then
        return
    end

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

    if not data then
        return
    end

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

    if trackedDoors[obj] then
        return
    end

    local color = getColor(obj.Name)

    if not color then
        return
    end

    if not (obj:IsA("Model") or obj:IsA("BasePart")) then
        return
    end

    local root = getRoot(obj)

    if not root then
        return
    end

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
        billboard.Size = UDim2.fromOffset(240, 32)

        -- LABEL ABOVE THE DOOR
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
        text.TextSize = 14
        text.TextStrokeTransparency = 0.2
        text.Text = ""
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

    if not Config.ESP or espSuspended then
        return
    end

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
    42
)

section(Pages.EVENT, "MAX DISTANCE")

local rangeLabel = makeLabel(
    Pages.EVENT,
    "Range: " .. Config.MaxDistance .. " studs",
    UDim2.new(1, 0, 0, 25),
    UDim2.new(),
    WHITE
)

local rangeFrame = Instance.new("Frame")
rangeFrame.Size = UDim2.new(1, -4, 0, 40)
rangeFrame.BackgroundTransparency = 1
rangeFrame.Parent = Pages.EVENT

local rangeLayout = Instance.new("UIListLayout")
rangeLayout.FillDirection = Enum.FillDirection.Horizontal
rangeLayout.Padding = UDim.new(0, 8)
rangeLayout.Parent = rangeFrame

local function updateRange()

    rangeLabel.Text =
        "Range: " .. Config.MaxDistance .. " studs"

    for _, data in pairs(trackedDoors) do
        data.Billboard.MaxDistance = Config.MaxDistance
    end
end

local function makeRangeButton(text, callback)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -4, 1, 0)
    button.BackgroundColor3 = ROW
    button.Text = text
    button.TextColor3 = ORANGE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = rangeFrame

    corner(button, 7)

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
    "Modifies local ProximityPrompt properties. The game server may still enforce its own interaction rules.",
    65
)

--============================================================
-- COMBAT PAGE
--============================================================

section(Pages.COMBATE, "COMBAT OPTIONS")

local combatInfo = makeLabel(
    Pages.COMBATE,
    "COMBATE\n\nPróximamente...",
    UDim2.new(1, 0, 0, 150),
    UDim2.new(),
    ORANGE
)

combatInfo.Font = Enum.Font.GothamBold
combatInfo.TextSize = 22
combatInfo.TextXAlignment = Enum.TextXAlignment.Center
combatInfo.TextYAlignment = Enum.TextYAlignment.Center

--============================================================
-- WORLD TRACKER CONNECTIONS
--============================================================

local addedConnection = Workspace.DescendantAdded:Connect(function(obj)

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

local removingConnection =
    Workspace.DescendantRemoving:Connect(function(obj)

        if trackedDoors[obj] then
            removeDoorESP(obj)
        end
    end)

local promptConnection =
    PromptService.PromptShown:Connect(function(prompt)

        checkPrompt(prompt)
    end)

--============================================================
-- PART 3/3 CONTINUES
--============================================================

--============================================================
-- DOOR ESP PRO v2.2
-- PART 3/3
-- VISUAL + ENEMY ESP + SETTINGS + DESTROY
--============================================================

--============================================================
-- ENEMY ESP SYSTEM
--============================================================

local function removeEnemyESP(model)

    local data = trackedEnemies[model]

    if not data then
        return
    end

    pcall(function()
        data.Highlight:Destroy()
        data.Billboard:Destroy()
    end)

    trackedEnemies[model] = nil
end

local function addEnemyESP(model)

    if destroyed then
        return
    end

    if not isEnemy(model) then
        return
    end

    if not Config.EnemyESP and not Config.EnemyNames then
        return
    end

    if trackedEnemies[model] then
        return
    end

    local root = getRoot(model)

    if not root then
        return
    end

    local success, data = pcall(function()

        -- ENEMY HOLOGRAM
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

        -- ENEMY NAME
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "Enemy_Name"
        billboard.Size = UDim2.fromOffset(220, 30)
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
        text.TextSize = 14
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

    for _, model in ipairs(CollectionService:GetTagged("Enemy")) do
        addEnemyESP(model)
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
        else
            for _, data in pairs(trackedEnemies) do
                data.Highlight.Enabled = false
            end
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
        else
            for _, data in pairs(trackedEnemies) do
                data.Billboard.Enabled = false
            end
        end
    end
)

infoText(
    Pages.VISUAL,
    "Enemy ESP detects NPC models tagged as Enemy in Roblox Studio.",
    45
)

--============================================================
-- CUSTOM HOLOGRAM COLOR
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
    "DOOR ESP PRO v2.2\nAndroid / PC",
    40
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
-- ENEMY TRACKING EVENTS
--============================================================

local enemyAddedConnection =
    CollectionService:GetInstanceAddedSignal("Enemy"):Connect(function(model)

        task.defer(function()

            if model.Parent then
                addEnemyESP(model)
            end
        end)
    end)

local enemyRemovedConnection =
    CollectionService:GetInstanceRemovedSignal("Enemy"):Connect(function(model)

        removeEnemyESP(model)
    end)

--============================================================
-- INITIAL SCAN
--============================================================

scanDoors()
scanEnemies()
applyPrompts()

--============================================================
-- UPDATE LOOP
--============================================================

local updateElapsed = 0

local renderConnection = RunService.RenderStepped:Connect(function(dt)

    updateElapsed += dt

    if updateElapsed < 0.1 then
        return
    end

    updateElapsed = 0

    local camera = Workspace.CurrentCamera

    if not camera then
        return
    end

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

                    -- ONE NAME ONLY
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

                if visible then
                    data.Label.Text = model.Name
                end
            end
        end
    end
end)

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

    if destroyed then
        return
    end

    destroyed = true

    -- Disconnect events
    addedConnection:Disconnect()
    removingConnection:Disconnect()
    promptConnection:Disconnect()
    enemyAddedConnection:Disconnect()
    enemyRemovedConnection:Disconnect()
    renderConnection:Disconnect()

    -- Remove ESP
    clearDoors()
    clearEnemies()

    -- Restore prompt settings
    restorePrompts()

    -- Remove GUI
    Gui:Destroy()

    _G.DoorESP_Destroy = nil

    print("[DOOR ESP PRO v2.2] Destroyed successfully!")
end

--============================================================
-- LOADED
--============================================================

print("======================================")
print("       DOOR ESP PRO v2.2")
print("       Loaded successfully!")
print("======================================")
