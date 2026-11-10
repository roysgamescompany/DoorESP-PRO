
--============================================================
-- DOOR ESP PRO v2.0
-- PART 1/2
-- SINGLE LOCALSCRIPT
-- StarterPlayer > StarterPlayerScripts
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local PromptService = game:GetService("ProximityPromptService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--============================================================
-- CONFIG
--============================================================

local Config = {
    ESP = true,
    ShowName = true,
    ShowDistance = true,
    InstantPrompt = false,
    MaxDistance = 5000,
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

local tracked = {}
local promptOriginals = {}
local rowRegistry = {}

local espSuspended = false
local destroyed = false

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
        return size.Y + 1.5
    elseif inst:IsA("BasePart") then
        return inst.Size.Y + 1.5
    end

    return 3
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

local function label(parent, text, size, position, color)
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
Main.ClipsDescendants = true
Main.Parent = Gui

corner(Main, 13)
stroke(Main, Color3.fromRGB(65, 65, 72), 1)

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

makeDraggable(Main, Main)
makeDraggable(Orb, Orb)

--============================================================
-- HEADER
--============================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = PANEL
Header.BorderSizePixel = 0
Header.Parent = Main

local Title = label(
    Header,
    "DOOR ESP PRO  |  v2.0",
    UDim2.new(1, -100, 1, 0),
    UDim2.fromOffset(18, 0),
    WHITE
)

Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 30)
Minimize.Position = UDim2.new(1, -85, 0, 9)
Minimize.BackgroundColor3 = ROW
Minimize.Text = "—"
Minimize.TextColor3 = WHITE
Minimize.TextSize = 17
Minimize.Parent = Header
corner(Minimize, 7)

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

Minimize.Activated:Connect(function()
    Main.Visible = false
end)

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
-- CONTENT AREA
--============================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -185, 1, -58)
Content.Position = UDim2.fromOffset(178, 53)
Content.BackgroundColor3 = PANEL
Content.BorderSizePixel = 0
Content.Parent = Main

corner(Content, 9)

-- SEARCH
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
-- PAGES
--============================================================

local Tabs = {
    "VISUAL",
    "INTERACTION",
    "COMBATE",
    "SETTINGS"
}

local Pages = {}
local TabButtons = {}
local activeTab = "VISUAL"

for index, name in ipairs(Tabs) do

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 42)
    button.BackgroundColor3 = ROW
    button.Text = name
    button.TextColor3 = GRAY
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
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

selectTab("VISUAL")

--============================================================
-- SEARCH REGISTRY
--============================================================

local function registerSearch(object, name, tab)
    table.insert(rowRegistry, {
        Object = object,
        Name = string.lower(name),
        Tab = tab
    })
end

Search:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(Search.Text)

    for _, item in ipairs(rowRegistry) do
        local matches =
            query == ""
            or string.find(item.Name, query, 1, true) ~= nil

        item.Object.Visible =
            Pages[item.Tab].Visible and matches
    end
end)

--============================================================
-- UI BUILDERS
--============================================================

local function section(parent, text)
    local l = label(
        parent,
        text,
        UDim2.new(1, 0, 0, 27),
        UDim2.new(),
        ORANGE
    )

    l.Font = Enum.Font.GothamBold
    l.TextSize = 12

    registerSearch(l, text, parent.Name:gsub("_Page", ""))

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

    local textLabel = label(
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
        indicator.BackgroundColor3 = state and GREEN
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

    registerSearch(button, name, parent.Name:gsub("_Page", ""))

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

    registerSearch(button, name, parent.Name:gsub("_Page", ""))

    return button
end

local function infoText(parent, text, height)
    local l = label(
        parent,
        text,
        UDim2.new(1, -4, 0, height or 40),
        UDim2.new(),
        GRAY
    )

    l.TextSize = 11
    l.TextWrapped = true

    registerSearch(l, text, parent.Name:gsub("_Page", ""))

    return l
end

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
-- ESP SYSTEM
--============================================================

local function removeESP(obj)
    local data = tracked[obj]
    if not data then return end

    pcall(function()
        data.Highlight:Destroy()
        data.Billboard:Destroy()
    end)

    tracked[obj] = nil
end

local function addESP(obj)
    if destroyed or espSuspended or not Config.ESP then return end
    if tracked[obj] then return end

    local color = getColor(obj.Name)
    if not color then return end

    if not (obj:IsA("Model") or obj:IsA("BasePart")) then
        return
    end

    local root = getRoot(obj)
    if not root then return end

    local success, data = pcall(function()

        local highlight = Instance.new("Highlight")
        highlight.Name = "DoorESP_Highlight"
        highlight.Adornee = obj
        highlight.FillColor = color
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = color
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = Gui

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DoorESP_Label"
        billboard.Size = UDim2.fromOffset(240, 30)
        billboard.StudsOffsetWorldSpace =
            Vector3.new(0, getHeight(obj), 0)
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
        text.TextStrokeTransparency = 0.3
        text.Parent = billboard

        return {
            Highlight = highlight,
            Billboard = billboard,
            Label = text,
            Root = root
        }
    end)

    if success and data then
        tracked[obj] = data
    end
end

local function scan()
    if not Config.ESP or espSuspended then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if getColor(obj.Name) then
            addESP(obj)
        end
    end
end

local function clearAll()
    espSuspended = true
    Config.ESP = false

    for obj in pairs(tracked) do
        removeESP(obj)
    end

    print("[Door ESP PRO] CLEAR ALL")
end

--============================================================
-- PART 2 CONTINUES BELOW
--============================================================

--============================================================
-- DOOR ESP PRO v2.0
-- PART 2/2
--============================================================

--============================================================
-- VISUAL TAB
--============================================================

section(Pages.VISUAL, "VISUAL ESP")

local espToggle = toggle(
    Pages.VISUAL,
    "ESP Enabled",
    Config.ESP,
    function(v)
        Config.ESP = v

        if v then
            espSuspended = false
            scan()
        else
            for _, data in pairs(tracked) do
                data.Highlight.Enabled = false
                data.Billboard.Enabled = false
            end
        end
    end
)

toggle(
    Pages.VISUAL,
    "Show Names",
    Config.ShowName,
    function(v)
        Config.ShowName = v
    end
)

toggle(
    Pages.VISUAL,
    "Show Distance",
    Config.ShowDistance,
    function(v)
        Config.ShowDistance = v
    end
)

section(Pages.VISUAL, "DOOR COLORS")

infoText(
    Pages.VISUAL,
    "YELLOW = Normal Door\nORANGE = Halloween Door",
    45
)

section(Pages.VISUAL, "MAX DISTANCE")

local rangeLabel = label(
    Pages.VISUAL,
    "Range: " .. Config.MaxDistance .. " studs",
    UDim2.new(1, 0, 0, 27),
    UDim2.new(),
    WHITE
)

local rangeFrame = Instance.new("Frame")
rangeFrame.Size = UDim2.new(1, -4, 0, 42)
rangeFrame.BackgroundTransparency = 1
rangeFrame.Parent = Pages.VISUAL

local rangeLayout = Instance.new("UIListLayout")
rangeLayout.FillDirection = Enum.FillDirection.Horizontal
rangeLayout.Padding = UDim.new(0, 8)
rangeLayout.Parent = rangeFrame

local function updateRange()
    rangeLabel.Text = "Range: " .. Config.MaxDistance .. " studs"

    for _, data in pairs(tracked) do
        data.Billboard.MaxDistance = Config.MaxDistance
    end
end

local function rangeButton(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -4, 1, 0)
    b.BackgroundColor3 = ROW
    b.Text = text
    b.TextColor3 = ORANGE
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = rangeFrame

    corner(b, 7)
    b.Activated:Connect(callback)

    return b
end

rangeButton("- 500", function()
    Config.MaxDistance = math.max(
        100,
        Config.MaxDistance - 500
    )
    updateRange()
end)

rangeButton("+ 500", function()
    Config.MaxDistance = math.min(
        10000,
        Config.MaxDistance + 500
    )
    updateRange()
end)

--============================================================
-- INTERACTION TAB
--============================================================

section(Pages.INTERACTION, "DOOR INTERACTION")

toggle(
    Pages.INTERACTION,
    "Instant Open",
    Config.InstantPrompt,
    function(v)
        Config.InstantPrompt = v
        applyPrompts()
    end
)

infoText(
    Pages.INTERACTION,
    "Local ProximityPrompt settings. Changes may not be accepted by the game server.",
    55
)

--============================================================
-- COMBAT TAB
--============================================================

section(Pages.COMBATE, "COMBAT OPTIONS")

local combatInfo = label(
    Pages.COMBATE,
    "COMBAT\n\nPróximamente...",
    UDim2.new(1, 0, 0, 150),
    UDim2.new(),
    ORANGE
)

combatInfo.Font = Enum.Font.GothamBold
combatInfo.TextSize = 22
combatInfo.TextXAlignment = Enum.TextXAlignment.Center
combatInfo.TextYAlignment = Enum.TextYAlignment.Center

--============================================================
-- SETTINGS TAB
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

section(Pages.SETTINGS, "ESP MANAGEMENT")

actionButton(
    Pages.SETTINGS,
    "CLEAR ALL",
    Color3.fromRGB(145, 40, 45),
    function()
        clearAll()
        espToggle.Set(false)
    end
)

actionButton(
    Pages.SETTINGS,
    "RESTORE ESP",
    Color3.fromRGB(45, 105, 75),
    function()
        espSuspended = false
        espToggle.Set(true)
        scan()
    end
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

infoText(
    Pages.SETTINGS,
    "DOOR ESP PRO v2.0\nCreated for Android and PC",
    45
)

--============================================================
-- SEARCH REFRESH
--============================================================

local function refreshSearch()
    local query = string.lower(Search.Text)

    for _, item in ipairs(rowRegistry) do
        local matches =
            query == ""
            or string.find(item.Name, query, 1, true) ~= nil

        item.Object.Visible =
            Pages[item.Tab].Visible and matches
    end
end

Search:GetPropertyChangedSignal("Text"):Connect(refreshSearch)

for name, data in pairs(TabButtons) do
    data.Button.Activated:Connect(function()
        task.defer(refreshSearch)
    end)
end

--============================================================
-- WORLD TRACKER
--============================================================

local addedConnection = Workspace.DescendantAdded:Connect(function(obj)

    if getColor(obj.Name) then
        task.defer(function()
            if obj.Parent then
                addESP(obj)
            end
        end)
    end

    if obj:IsA("ProximityPrompt") then
        task.defer(function()
            checkPrompt(obj)
        end)
    end
end)

local removingConnection = Workspace.DescendantRemoving:Connect(function(obj)
    if tracked[obj] then
        removeESP(obj)
    end
end)

--============================================================
-- PROMPT EVENTS
--============================================================

local promptConnection = PromptService.PromptShown:Connect(function(prompt)
    checkPrompt(prompt)
end)

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

    local camPos = camera.CFrame.Position

    for obj, data in pairs(tracked) do

        if not obj.Parent then
            removeESP(obj)

        else
            local root = data.Root

            if not root or not root.Parent then
                root = getRoot(obj)
                data.Root = root

                if root then
                    data.Billboard.Adornee = root
                    data.Billboard.StudsOffsetWorldSpace =
                        Vector3.new(0, getHeight(obj), 0)
                end
            end

            if not Config.ESP or espSuspended or not root then

                data.Highlight.Enabled = false
                data.Billboard.Enabled = false

            else
                local distance =
                    (camPos - root.Position).Magnitude

                local visible =
                    distance <= Config.MaxDistance

                data.Highlight.Enabled = visible
                data.Billboard.Enabled = visible

                if visible then

                    local parts = {}

                    if Config.ShowName then
                        table.insert(parts, obj.Name)
                    end

                    if Config.ShowDistance then
                        table.insert(
                            parts,
                            math.floor(distance) .. " studs"
                        )
                    end

                    data.Label.Text = table.concat(parts, "  ")
                end
            end
        end
    end
end)

--============================================================
-- INITIAL SCAN
--============================================================

scan()
applyPrompts()

task.spawn(function()

    while not destroyed and Gui.Parent do

        task.wait(3)

        if not destroyed then
            scan()
        end
    end
end)

--============================================================
-- DESTROY HOOK
--============================================================

_G.DoorESP_Destroy = function()

    if destroyed then
        return
    end

    destroyed = true

    addedConnection:Disconnect()
    removingConnection:Disconnect()
    renderConnection:Disconnect()
    promptConnection:Disconnect()

    for obj in pairs(tracked) do
        removeESP(obj)
    end

    restorePrompts()

    Gui:Destroy()

    _G.DoorESP_Destroy = nil

    print("[Door ESP PRO v2.0] Destroyed successfully!")
end

--============================================================
-- LOADED
--============================================================

print("====================================")
print("       DOOR ESP PRO v2.0")
print("       Loaded successfully!")
print("====================================")
