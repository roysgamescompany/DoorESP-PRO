
--============================================================
-- DOOR ESP PRO v1.2
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
-- CONFIGURATION
--============================================================

local Config = {
    ESP = true,
    ShowName = true,
    ShowDistance = true,
    InstantPrompt = true,
    MaxDistance = 5000,
}

local Colors = {
    door = Color3.fromRGB(255, 200, 80),
    halloweendoor = Color3.fromRGB(255, 120, 40),
}

local ORANGE = Color3.fromRGB(255, 145, 45)
local DARK = Color3.fromRGB(18, 18, 23)
local PANEL = Color3.fromRGB(28, 27, 35)
local ROW = Color3.fromRGB(39, 38, 48)
local WHITE = Color3.fromRGB(240, 235, 240)
local GRAY = Color3.fromRGB(145, 140, 155)

local tracked = {}
local promptOriginals = {}
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
Gui.DisplayOrder = 9999
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
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

--============================================================
-- FLOATING ORB
--============================================================

local Orb = Instance.new("TextButton")
Orb.Name = "DoorESP_Orb"
Orb.Size = UDim2.fromOffset(52, 52)
Orb.Position = UDim2.new(0, 20, 0.5, -26)
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
Main.Size = UDim2.fromOffset(340, 440)
Main.Position = UDim2.new(0.5, -170, 0.5, -220)
Main.BackgroundColor3 = DARK
Main.BorderSizePixel = 0
Main.Visible = false
Main.Active = true
Main.Parent = Gui

corner(Main, 14)
stroke(Main, ORANGE, 1.5)

--============================================================
-- DRAG SYSTEM
--============================================================

local function makeDraggable(object, handle)
    local dragging = false
    local dragInput
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

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
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

-- Orb movement without blocking its click
makeDraggable(Orb, Orb)

--============================================================
-- HEADER
--============================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = PANEL
Header.BorderSizePixel = 0
Header.Parent = Main

corner(Header, 12)

local Title = makeLabel(
    Header,
    "DOOR ESP PRO",
    UDim2.new(1, -55, 1, 0),
    UDim2.fromOffset(15, 0),
    ORANGE
)

Title.TextSize = 15

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(28, 28)
Close.Position = UDim2.new(1, -37, 0, 10)
Close.BackgroundColor3 = Color3.fromRGB(65, 35, 38)
Close.Text = "X"
Close.TextColor3 = WHITE
Close.Font = Enum.Font.GothamBold
Close.Parent = Header

corner(Close, 8)

Close.Activated:Connect(function()
    Main.Visible = false
end)

makeDraggable(Main, Header)

Orb.Activated:Connect(function()
    Main.Visible = not Main.Visible
end)

--============================================================
-- TABS
--============================================================

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 43)
TabBar.Position = UDim2.fromOffset(8, 57)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabBar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -110)
Content.Position = UDim2.fromOffset(8, 104)
Content.BackgroundColor3 = PANEL
Content.BorderSizePixel = 0
Content.Parent = Main

corner(Content, 10)

local Tabs = {"VISUAL", "INTERACTION", "COMBATE", "SETTINGS"}

local Pages = {}
local TabButtons = {}

for _, name in ipairs(Tabs) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.25, -3, 1, 0)
    button.BackgroundColor3 = PANEL
    button.Text = name
    button.TextColor3 = GRAY
    button.TextSize = 9
    button.Font = Enum.Font.GothamBold
    button.Parent = TabBar
    corner(button, 7)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.fromOffset(8, 8)
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
    layout.Parent = page

    Pages[name] = page
    TabButtons[name] = button

    button.Activated:Connect(function()
        for tab, p in pairs(Pages) do
            p.Visible = tab == name
            TabButtons[tab].TextColor3 =
                tab == name and ORANGE or GRAY
            TabButtons[tab].BackgroundColor3 =
                tab == name
                and Color3.fromRGB(55, 40, 30)
                or PANEL
        end
    end)
end

local function selectTab(name)
    for tab, page in pairs(Pages) do
        page.Visible = tab == name
        TabButtons[tab].TextColor3 =
            tab == name and ORANGE or GRAY
        TabButtons[tab].BackgroundColor3 =
            tab == name
            and Color3.fromRGB(55, 40, 30)
            or PANEL
    end
end

selectTab("VISUAL")

--============================================================
-- UI BUILDERS
--============================================================

local function section(parent, text)
    local l = makeLabel(
        parent,
        text,
        UDim2.new(1, 0, 0, 24),
        UDim2.new(),
        ORANGE
    )
    l.TextSize = 11
    return l
end

local function toggle(parent, name, initial, callback)
    local state = initial

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 39)
    button.BackgroundColor3 = ROW
    button.Text = ""
    button.Parent = parent
    corner(button, 8)

    makeLabel(
        button,
        name,
        UDim2.new(1, -65, 1, 0),
        UDim2.fromOffset(12, 0),
        WHITE
    )

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(38, 20)
    indicator.Position = UDim2.new(1, -48, 0.5, -10)
    indicator.BackgroundColor3 = Color3.fromRGB(58, 52, 60)
    indicator.Parent = button
    corner(indicator, 20)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(16, 16)
    dot.Position = UDim2.fromOffset(2, 2)
    dot.BackgroundColor3 = WHITE
    dot.Parent = indicator
    corner(dot, 20)

    local function refresh()
        indicator.BackgroundColor3 = state
            and ORANGE
            or Color3.fromRGB(58, 52, 60)

        dot.Position = state
            and UDim2.new(1, -18, 0, 2)
            or UDim2.fromOffset(2, 2)
    end

    local function setState(value)
        state = value
        refresh()
        callback(state)
    end

    button.Activated:Connect(function()
        setState(not state)
    end)

    refresh()

    return {
        Get = function()
            return state
        end,
        Set = setState
    }
end

local function actionButton(parent, name, color, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 40)
    button.BackgroundColor3 = color
    button.Text = name
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = parent
    corner(button, 8)

    button.Activated:Connect(callback)

    return button
end

--============================================================
-- PROMPT SYSTEM - LOCAL
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
end

local function applyPrompts()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if Config.InstantPrompt then
                checkPrompt(obj)
            end
        end
    end

    if not Config.InstantPrompt then
        restorePrompts()
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("ProximityPrompt") then
        checkPrompt(obj)
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") then
        task.defer(function()
            checkPrompt(obj)
        end)
    end
end)

PromptService.PromptShown:Connect(function(prompt)
    checkPrompt(prompt)
end)

--============================================================
-- ESP SYSTEM
--============================================================

local function removeESP(obj)
    local data = tracked[obj]
    if not data then return end

    pcall(function()
        data.Highlight:Destroy()
    end)

    pcall(function()
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

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextStrokeTransparency = 0.3
        label.Text = ""
        label.Parent = billboard

        return {
            Highlight = highlight,
            Billboard = billboard,
            Label = label,
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
-- VISUAL TAB
--============================================================

section(Pages.VISUAL, "ESP SETTINGS")

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

local colorInfo = makeLabel(
    Pages.VISUAL,
    "YELLOW  - Normal Door\nORANGE  - Halloween Door",
    UDim2.new(1, 0, 0, 45),
    UDim2.new(),
    WHITE
)
colorInfo.TextSize = 12

section(Pages.VISUAL, "MAX DISTANCE")

local rangeLabel = makeLabel(
    Pages.VISUAL,
    "Range: " .. Config.MaxDistance .. " studs",
    UDim2.new(1, 0, 0, 25),
    UDim2.new(),
    WHITE
)

local rangeFrame = Instance.new("Frame")
rangeFrame.Size = UDim2.new(1, -4, 0, 36)
rangeFrame.BackgroundTransparency = 1
rangeFrame.Parent = Pages.VISUAL

local rangeLayout = Instance.new("UIListLayout")
rangeLayout.FillDirection = Enum.FillDirection.Horizontal
rangeLayout.Padding = UDim.new(0, 8)
rangeLayout.Parent = rangeFrame

local function makeRangeButton(text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -4, 1, 0)
    b.BackgroundColor3 = Color3.fromRGB(55, 40, 30)
    b.Text = text
    b.TextColor3 = ORANGE
    b.Font = Enum.Font.GothamBold
    b.Parent = rangeFrame
    corner(b, 7)
    b.Activated:Connect(callback)
end

local function updateRange()
    rangeLabel.Text = "Range: " .. Config.MaxDistance .. " studs"

    for _, data in pairs(tracked) do
        data.Billboard.MaxDistance = Config.MaxDistance
    end
end

makeRangeButton("- 500", function()
    Config.MaxDistance = math.max(100, Config.MaxDistance - 500)
    updateRange()
end)

makeRangeButton("+ 500", function()
    Config.MaxDistance = math.min(10000, Config.MaxDistance + 500)
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

makeLabel(
    Pages.INTERACTION,
    "Modifies the local ProximityPrompt settings.",
    UDim2.new(1, 0, 0, 40),
    UDim2.new(),
    GRAY
).TextSize = 11

--============================================================
-- COMBAT TAB
--============================================================

section(Pages.COMBATE, "COMBAT OPTIONS")

local combatText = makeLabel(
    Pages.COMBATE,
    "COMBATE\n\nPróximamente...",
    UDim2.new(1, 0, 0, 140),
    UDim2.new(),
    ORANGE
)

combatText.TextSize = 21
combatText.TextXAlignment = Enum.TextXAlignment.Center
combatText.TextYAlignment = Enum.TextYAlignment.Center

--============================================================
-- SETTINGS TAB
--============================================================

section(Pages.SETTINGS, "GENERAL")

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
    Color3.fromRGB(55, 100, 65),
    function()
        espSuspended = false
        espToggle.Set(true)
        scan()
    end
)

actionButton(
    Pages.SETTINGS,
    "DESTROY SCRIPT",
    Color3.fromRGB(95, 35, 40),
    function()
        if _G.DoorESP_Destroy then
            _G.DoorESP_Destroy()
        end
    end
)

makeLabel(
    Pages.SETTINGS,
    "DOOR ESP PRO v1.2",
    UDim2.new(1, 0, 0, 25),
    UDim2.new(),
    GRAY
)

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
end)

local removingConnection = Workspace.DescendantRemoving:Connect(function(obj)
    if tracked[obj] then
        removeESP(obj)
    end
end)

--============================================================
-- UPDATE LOOP
--============================================================

local updateElapsed = 0

local renderConnection = RunService.RenderStepped:Connect(function(dt)
    updateElapsed += dt

    if updateElapsed < 0.1 then return end
    updateElapsed = 0

    local camera = Workspace.CurrentCamera
    if not camera then return end

    local camPos = camera.CFrame.Position

    for obj, data in pairs(tracked) do
        if not obj.Parent then
            removeESP(obj)
        else
            local root = data.Root

            if not root or not root.Parent then
                root = getRoot(obj)
                data.Root = root
            end

            if not Config.ESP or espSuspended or not root then
                data.Highlight.Enabled = false
                data.Billboard.Enabled = false
            else
                local distance = (camPos - root.Position).Magnitude
                local visible = distance <= Config.MaxDistance

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

task.spawn(function()
    while not destroyed and Gui.Parent do
        task.wait(3)
        scan()
    end
end)

--============================================================
-- DESTROY HOOK
--============================================================

_G.DoorESP_Destroy = function()
    if destroyed then return end

    destroyed = true

    addedConnection:Disconnect()
    removingConnection:Disconnect()
    renderConnection:Disconnect()

    for obj in pairs(tracked) do
        removeESP(obj)
    end

    restorePrompts()

    Gui:Destroy()

    _G.DoorESP_Destroy = nil

    print("[Door ESP PRO] Destroyed successfully")
end

print("[Door ESP PRO v1.2] Loaded successfully!")
