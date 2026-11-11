
--============================================================
-- DOOR ESP PRO v3.0
-- PARTE 1/4 - CONFIG + GUI + BUILDERS
-- Roblox Studio - LocalScript
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- LIMPIAR VERSION ANTERIOR
local old = PlayerGui:FindFirstChild("DoorESP_PRO")
if old then old:Destroy() end

--============================================================
-- CONFIG
--============================================================

local Config = {
    DoorESP = false,
    DoorNames = true,

    PlayerESP = false,
    PlayerNames = true,

    EnemyESP = false,
    EnemyNames = true,

    MaxDistance = 3000,
    EnemyColor = Color3.fromRGB(0, 200, 170),
    PlayerColor = Color3.fromRGB(0, 180, 255),

    Transparency = 0.20,
    UITransparency = 0.18
}

local ORANGE = Color3.fromRGB(255, 145, 45)
local DARK = Color3.fromRGB(15, 15, 19)
local PANEL = Color3.fromRGB(27, 27, 32)
local ROW = Color3.fromRGB(43, 43, 49)
local WHITE = Color3.fromRGB(245, 245, 245)
local GRAY = Color3.fromRGB(155, 155, 165)
local GREEN = Color3.fromRGB(0, 190, 150)

local tracked = {}
local destroyed = false

local function getRoot(model)
    if not model then return nil end

    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
        or model:FindFirstChildWhichIsA("BasePart", true)
end

local function isAlive(model)
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getHeight(model)
    local _, size = model:GetBoundingBox()
    return size.Y + 1.5
end

--============================================================
-- GUI
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
end

local function outline(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = 0.25
    s.Parent = obj
end

local function label(parent, text, size, position, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = size
    l.Position = position
    l.Text = text
    l.TextColor3 = color or WHITE
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

--============================================================
-- MAIN PANEL
--============================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(500, 340)
Main.Position = UDim2.new(0.5, -250, 0.5, -170)
Main.BackgroundColor3 = DARK
Main.BackgroundTransparency = Config.UITransparency
Main.BorderSizePixel = 0
Main.Visible = false
Main.Active = true
Main.Parent = Gui

corner(Main, 12)
outline(Main, Color3.fromRGB(100, 100, 110), 1)

-- HEADER

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = PANEL
Header.BackgroundTransparency = 0.12
Header.BorderSizePixel = 0
Header.Parent = Main
corner(Header, 10)

local Title = label(
    Header,
    "DOOR ESP PRO  |  v3.0",
    UDim2.new(1, -60, 1, 0),
    UDim2.fromOffset(14, 0),
    WHITE
)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(30, 28)
Close.Position = UDim2.new(1, -37, 0, 7)
Close.BackgroundColor3 = Color3.fromRGB(115, 45, 45)
Close.Text = "X"
Close.TextColor3 = WHITE
Close.Font = Enum.Font.GothamBold
Close.TextSize = 12
Close.Parent = Header
corner(Close, 6)

-- FLOATING BUTTON

local Orb = Instance.new("TextButton")
Orb.Name = "DoorESP_Orb"
Orb.Size = UDim2.fromOffset(44, 44)
Orb.Position = UDim2.new(0, 14, 0.5, -22)
Orb.BackgroundColor3 = DARK
Orb.BackgroundTransparency = 0.12
Orb.Text = "D"
Orb.TextColor3 = ORANGE
Orb.TextSize = 22
Orb.Font = Enum.Font.GothamBlack
Orb.Parent = Gui
corner(Orb, 50)
outline(Orb, ORANGE, 2)

Orb.Activated:Connect(function()
    Main.Visible = not Main.Visible
end)

Close.Activated:Connect(function()
    Main.Visible = false
end)

--============================================================
-- DRAG SYSTEM
--============================================================

local function draggable(object, handle)
    local dragging = false
    local startPosition
    local startInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input.Position
            startPosition = object.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - startInput
            object.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

draggable(Main, Header)
draggable(Orb, Orb)

--============================================================
-- SIDEBAR + CONTENT
--============================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 125, 1, -52)
Sidebar.Position = UDim2.fromOffset(7, 47)
Sidebar.BackgroundColor3 = PANEL
Sidebar.BackgroundTransparency = 0.12
Sidebar.Parent = Main
corner(Sidebar, 8)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -145, 1, -52)
Content.Position = UDim2.fromOffset(138, 47)
Content.BackgroundColor3 = PANEL
Content.BackgroundTransparency = 0.12
Content.Parent = Main
corner(Content, 8)

local Pages = {}
local TabButtons = {}

local Tabs = {
    "EVENT",
    "VISUAL",
    "PLAYERS",
    "SETTINGS"
}

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 7)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = Sidebar

local sidePadding = Instance.new("UIPadding")
sidePadding.PaddingTop = UDim.new(0, 9)
sidePadding.PaddingLeft = UDim.new(0, 6)
sidePadding.PaddingRight = UDim.new(0, 6)
sidePadding.Parent = Sidebar

for i, name in ipairs(Tabs) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 39)
    button.BackgroundColor3 = ROW
    button.Text = name
    button.TextColor3 = GRAY
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.LayoutOrder = i
    button.Parent = Sidebar
    corner(button, 6)

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1, -14, 1, -14)
    page.Position = UDim2.fromOffset(7, 7)
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
            local selected = tab == name
            p.Visible = selected
            TabButtons[tab].TextColor3 = selected and ORANGE or GRAY
            TabButtons[tab].BackgroundColor3 =
                selected and Color3.fromRGB(65, 48, 34) or ROW
        end
    end)
end

TabButtons.EVENT:Activate()

--============================================================
-- DOOR ESP PRO v3.0
-- PARTE 2/4 - ESP ENGINE
--============================================================

local function removeESP(model)
    local data = tracked[model]
    if not data then return end

    if data.Highlight then
        data.Highlight:Destroy()
    end

    if data.Billboard then
        data.Billboard:Destroy()
    end

    tracked[model] = nil
end

local function createESP(model, kind)
    if destroyed or not model or not model.Parent then
        return
    end

    if tracked[model] then return end

    local root = getRoot(model)
    if not root then return end

    local color = kind == "PLAYER"
        and Config.PlayerColor
        or Config.EnemyColor

    local success, data = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "DoorESP_Highlight"
        highlight.Adornee = model
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = Config.Transparency
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = Gui

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DoorESP_Name"
        billboard.Size = UDim2.fromOffset(180, 25)
        billboard.StudsOffsetWorldSpace =
            Vector3.new(0, getHeight(model), 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = Config.MaxDistance
        billboard.Adornee = root
        billboard.Parent = Gui

        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.TextColor3 = color
        text.TextStrokeTransparency = 0.2
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.Parent = billboard

        return {
            Highlight = highlight,
            Billboard = billboard,
            Label = text,
            Root = root,
            Kind = kind,
            Model = model
        }
    end)

    if success and data then
        tracked[model] = data
    end
end

--============================================================
-- PLAYER TRACKER
--============================================================

local function scanPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and isAlive(plr.Character) then
            createESP(plr.Character, "PLAYER")
        end
    end
end

--============================================================
-- NPC TRACKER
-- NPCs tagged as Enemy
--============================================================

local function scanEnemies()
    for _, model in ipairs(CollectionService:GetTagged("Enemy")) do
        if model:IsA("Model")
        and not Players:GetPlayerFromCharacter(model)
        and isAlive(model) then
            createESP(model, "NPC")
        end
    end
end

--============================================================
-- DOOR TRACKER
--============================================================

local DoorColors = {
    door = Color3.fromRGB(255, 200, 80),
    halloweendoor = Color3.fromRGB(255, 120, 40)
}

local function getDoorColor(model)
    return DoorColors[string.lower(model.Name)]
end

local function scanDoors()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart"))
        and getDoorColor(obj) then

            if not tracked[obj] then
                local root = getRoot(obj)
                if root then
                    local color = getDoorColor(obj)

                    local highlight = Instance.new("Highlight")
                    highlight.Name = "DoorESP_Door"
                    highlight.Adornee = obj
                    highlight.FillColor = color
                    highlight.OutlineColor = color
                    highlight.FillTransparency = 0.65
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode =
                        Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = Gui

                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "DoorESP_DoorName"
                    billboard.Size = UDim2.fromOffset(160, 25)
                    billboard.StudsOffsetWorldSpace =
                        Vector3.new(0, 4, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = root
                    billboard.MaxDistance = Config.MaxDistance
                    billboard.Parent = Gui

                    local text = Instance.new("TextLabel")
                    text.Size = UDim2.fromScale(1, 1)
                    text.BackgroundTransparency = 1
                    text.TextColor3 = color
                    text.TextStrokeTransparency = 0.2
                    text.Font = Enum.Font.GothamBold
                    text.TextSize = 12
                    text.Text = "DOOR"
                    text.Parent = billboard

                    tracked[obj] = {
                        Highlight = highlight,
                        Billboard = billboard,
                        Label = text,
                        Root = root,
                        Kind = "DOOR",
                        Model = obj
                    }
                end
            end
        end
    end
end

--============================================================
-- CLEAR SYSTEM
--============================================================

local function clearKind(kind)
    for model, data in pairs(tracked) do
        if data.Kind == kind then
            removeESP(model)
        end
    end
end

local function refreshAll()
    for model, data in pairs(tracked) do
        local enabled = false

        if data.Kind == "PLAYER" then
            enabled = Config.PlayerESP
        elseif data.Kind == "NPC" then
            enabled = Config.EnemyESP
        elseif data.Kind == "DOOR" then
            enabled = Config.DoorESP
        end

        if data.Highlight then
            data.Highlight.Enabled = enabled
        end

        if data.Billboard then
            data.Billboard.Enabled = enabled
        end
    end
end

--============================================================
-- COLOR UPDATE
--============================================================

local function updateColors()
    for _, data in pairs(tracked) do
        local color

        if data.Kind == "PLAYER" then
            color = Config.PlayerColor
        elseif data.Kind == "NPC" then
            color = Config.EnemyColor
        elseif data.Kind == "DOOR" then
            color = getDoorColor(data.Model)
        end

        if color then
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
            data.Label.TextColor3 = color
        end
    end
end

--============================================================
-- DOOR ESP PRO v3.0
-- PARTE 3/4 - CONTROLS + RGB
--============================================================

local function section(parent, title)
    local l = label(
        parent,
        title,
        UDim2.new(1, -5, 0, 25),
        UDim2.new(),
        ORANGE
    )
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    return l
end

local function info(parent, message, height)
    local l = label(
        parent,
        message,
        UDim2.new(1, -5, 0, height or 38),
        UDim2.new(),
        GRAY
    )
    l.TextWrapped = true
    l.TextSize = 10
    return l
end

local function toggle(parent, title, initial, callback)
    local state = initial

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -5, 0, 40)
    button.BackgroundColor3 = ROW
    button.Text = ""
    button.Parent = parent
    corner(button, 7)

    local txt = label(
        button,
        title,
        UDim2.new(1, -75, 1, 0),
        UDim2.fromOffset(12, 0),
        WHITE
    )
    txt.TextSize = 11

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.fromOffset(40, 21)
    indicator.Position = UDim2.new(1, -50, 0.5, -10)
    indicator.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
    indicator.Parent = button
    corner(indicator, 20)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(15, 15)
    dot.Position = UDim2.fromOffset(3, 3)
    dot.BackgroundColor3 = WHITE
    dot.Parent = indicator
    corner(dot, 20)

    local function update()
        indicator.BackgroundColor3 = state
            and GREEN
            or Color3.fromRGB(65, 65, 70)

        dot.Position = state
            and UDim2.new(1, -18, 0, 3)
            or UDim2.fromOffset(3, 3)
    end

    button.Activated:Connect(function()
        state = not state
        update()
        callback(state)
    end)

    update()
    return button
end

local function action(parent, title, color, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -5, 0, 37)
    button.BackgroundColor3 = color
    button.Text = title
    button.TextColor3 = WHITE
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.Parent = parent
    corner(button, 7)

    button.Activated:Connect(callback)
    return button
end

--============================================================
-- EVENT PAGE
--============================================================

section(Pages.EVENT, "DOOR ESP")

toggle(Pages.EVENT, "Door ESP", false, function(value)
    Config.DoorESP = value

    if value then
        scanDoors()
    else
        clearKind("DOOR")
    end

    refreshAll()
end)

toggle(Pages.EVENT, "Show Door Names", true, function(value)
    Config.DoorNames = value
end)

info(
    Pages.EVENT,
    "Detecta puertas llamadas Door y HalloweenDoor. Puedes ampliar los nombres en DoorColors.",
    42
)

section(Pages.EVENT, "DISTANCE")

local distanceLabel = label(
    Pages.EVENT,
    "Maximum distance: " .. Config.MaxDistance,
    UDim2.new(1, -5, 0, 25),
    UDim2.new(),
    WHITE
)

local distanceRow = Instance.new("Frame")
distanceRow.Size = UDim2.new(1, -5, 0, 35)
distanceRow.BackgroundTransparency = 1
distanceRow.Parent = Pages.EVENT

local function distanceButton(title, x, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -4, 1, 0)
    b.Position = UDim2.new(x, 0, 0, 0)
    b.BackgroundColor3 = ROW
    b.Text = title
    b.TextColor3 = ORANGE
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = distanceRow
    corner(b, 6)
    b.Activated:Connect(callback)
end

distanceButton("- 500", 0, function()
    Config.MaxDistance = math.max(100, Config.MaxDistance - 500)
    distanceLabel.Text = "Maximum distance: " .. Config.MaxDistance
end)

distanceButton("+ 500", 0.5, function()
    Config.MaxDistance = math.min(10000, Config.MaxDistance + 500)
    distanceLabel.Text = "Maximum distance: " .. Config.MaxDistance
end)

--============================================================
-- VISUAL PAGE - NPC
--============================================================

section(Pages.VISUAL, "NPC HOLOGRAM")

toggle(Pages.VISUAL, "Enemy Hologram", false, function(value)
    Config.EnemyESP = value

    if value then
        scanEnemies()
    else
        clearKind("NPC")
    end

    refreshAll()
end)

toggle(Pages.VISUAL, "Show NPC Names", true, function(value)
    Config.EnemyNames = value
end)

info(
    Pages.VISUAL,
    "Detecta NPC etiquetados Enemy mediante CollectionService.",
    36
)

--============================================================
-- PLAYERS PAGE
--============================================================

section(Pages.PLAYERS, "PLAYER ESP")

toggle(Pages.PLAYERS, "Player Hologram", false, function(value)
    Config.PlayerESP = value

    if value then
        scanPlayers()
    else
        clearKind("PLAYER")
    end

    refreshAll()
end)

toggle(Pages.PLAYERS, "Show Player Names", true, function(value)
    Config.PlayerNames = value
end)

info(
    Pages.PLAYERS,
    "Detecta personajes de jugadores conectados, sin necesitar la etiqueta Enemy.",
    40
)

--============================================================
-- RGB COLOR BUILDER
--============================================================

local function colorInput(parent, title, initialColor, callback)
    section(parent, title)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 75)
    frame.BackgroundColor3 = ROW
    frame.Parent = parent
    corner(frame, 7)

    local boxes = {}

    local values = {
        math.floor(initialColor.R * 255),
        math.floor(initialColor.G * 255),
        math.floor(initialColor.B * 255)
    }

    for i, value in ipairs(values) do
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 53, 0, 27)
        box.Position = UDim2.fromOffset(10 + (i - 1) * 60, 8)
        box.BackgroundColor3 = DARK
        box.TextColor3 = WHITE
        box.Text = tostring(value)
        box.PlaceholderText = ({"R", "G", "B"})[i]
        box.Font = Enum.Font.GothamBold
        box.TextSize = 11
        box.ClearTextOnFocus = false
        box.Parent = frame
        corner(box, 5)
        boxes[i] = box
    end

    local preview = Instance.new("Frame")
    preview.Size = UDim2.fromOffset(35, 27)
    preview.Position = UDim2.fromOffset(195, 8)
    preview.BackgroundColor3 = initialColor
    preview.Parent = frame
    corner(preview, 5)

    local apply = Instance.new("TextButton")
    apply.Size = UDim2.new(1, -20, 0, 27)
    apply.Position = UDim2.fromOffset(10, 42)
    apply.BackgroundColor3 = GREEN
    apply.Text = "APPLY COLOR"
    apply.TextColor3 = WHITE
    apply.Font = Enum.Font.GothamBold
    apply.TextSize = 10
    apply.Parent = frame
    corner(apply, 5)

    apply.Activated:Connect(function()
        local r = tonumber(boxes[1].Text)
        local g = tonumber(boxes[2].Text)
        local b = tonumber(boxes[3].Text)

        if not r or not g or not b then
            return
        end

        r = math.clamp(math.floor(r), 0, 255)
        g = math.clamp(math.floor(g), 0, 255)
        b = math.clamp(math.floor(b), 0, 255)

        local newColor = Color3.fromRGB(r, g, b)
        preview.BackgroundColor3 = newColor
        callback(newColor)
        updateColors()
    end)
end

colorInput(
    Pages.VISUAL,
    "NPC HOLOGRAM COLOR (RGB)",
    Config.EnemyColor,
    function(color)
        Config.EnemyColor = color
    end
)

colorInput(
    Pages.PLAYERS,
    "PLAYER COLOR (RGB)",
    Config.PlayerColor,
    function(color)
        Config.PlayerColor = color
    end
)

--============================================================
-- SETTINGS PAGE
--============================================================

section(Pages.SETTINGS, "INTERFACE")

toggle(Pages.SETTINGS, "Floating Button", true, function(value)
    Orb.Visible = value
end)

toggle(Pages.SETTINGS, "Transparent Panel", true, function(value)
    Config.UITransparency = value and 0.18 or 0
    Main.BackgroundTransparency = Config.UITransparency
end)

section(Pages.SETTINGS, "MANAGEMENT")

action(
    Pages.SETTINGS,
    "CLEAR ALL ESP",
    Color3.fromRGB(135, 45, 45),
    function()
        Config.DoorESP = false
        Config.PlayerESP = false
        Config.EnemyESP = false
        clearKind("DOOR")
        clearKind("PLAYER")
        clearKind("NPC")
        refreshAll()
    end
)

action(
    Pages.SETTINGS,
    "RESTORE ENABLED ESP",
    Color3.fromRGB(40, 105, 75),
    function()
        if Config.DoorESP then scanDoors() end
        if Config.PlayerESP then scanPlayers() end
        if Config.EnemyESP then scanEnemies() end
        refreshAll()
    end
)

info(Pages.SETTINGS, "DOOR ESP PRO v3.0 | Android / PC", 30)

--============================================================
-- DOOR ESP PRO v3.0
-- PARTE 4/4 - TRACKING + UPDATE + DESTROY
--============================================================

local connections = {}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

--============================================================
-- PLAYER EVENTS
--============================================================

local function watchPlayer(plr)
    if plr == Player then return end

    connect(plr.CharacterAdded, function(character)
        task.wait(0.5)

        if destroyed then return end

        if Config.PlayerESP and character.Parent then
            createESP(character, "PLAYER")
        end
    end)

    connect(plr.CharacterRemoving, function(character)
        removeESP(character)
    end)

    if plr.Character and Config.PlayerESP then
        createESP(plr.Character, "PLAYER")
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    watchPlayer(plr)
end

connect(Players.PlayerAdded, watchPlayer)

connect(Players.PlayerRemoving, function(plr)
    if plr.Character then
        removeESP(plr.Character)
    end
end)

--============================================================
-- NPC EVENTS
--============================================================

connect(
    CollectionService:GetInstanceAddedSignal("Enemy"),
    function(model)
        task.defer(function()
            if destroyed then return end

            if Config.EnemyESP and model:IsA("Model") then
                createESP(model, "NPC")
            end
        end)
    end
)

connect(
    CollectionService:GetInstanceRemovedSignal("Enemy"),
    function(model)
        if tracked[model] and tracked[model].Kind == "NPC" then
            removeESP(model)
        end
    end
)

--============================================================
-- DOOR EVENTS
--============================================================

connect(Workspace.DescendantAdded, function(obj)
    if destroyed or not Config.DoorESP then return end

    if (obj:IsA("Model") or obj:IsA("BasePart"))
    and getDoorColor(obj) then

        task.defer(function()
            if not destroyed and obj.Parent then
                scanDoors()
            end
        end)
    end
end)

connect(Workspace.DescendantRemoving, function(obj)
    if tracked[obj] then
        removeESP(obj)
    end
end)

--============================================================
-- UPDATE LOOP
--============================================================

local elapsed = 0

connect(RunService.Heartbeat, function(dt)
    if destroyed then return end

    elapsed += dt
    if elapsed < 0.10 then return end
    elapsed = 0

    local camera = Workspace.CurrentCamera
    if not camera then return end

    local cameraPosition = camera.CFrame.Position

    for model, data in pairs(tracked) do
        if not model.Parent then
            removeESP(model)
            continue
        end

        local kind = data.Kind
        local enabled = false
        local showName = false

        if kind == "PLAYER" then
            enabled = Config.PlayerESP
            showName = Config.PlayerNames

        elseif kind == "NPC" then
            enabled = Config.EnemyESP
            showName = Config.EnemyNames

        elseif kind == "DOOR" then
            enabled = Config.DoorESP
            showName = Config.DoorNames
        end

        if kind ~= "DOOR" and not isAlive(model) then
            removeESP(model)
            continue
        end

        local root = data.Root

        if not root or not root.Parent then
            root = getRoot(model)
            data.Root = root

            if root then
                data.Billboard.Adornee = root
            end
        end

        if not root then
            data.Highlight.Enabled = false
            data.Billboard.Enabled = false
            continue
        end

        local distance =
            (cameraPosition - root.Position).Magnitude

        local visible =
            enabled and distance <= Config.MaxDistance

        data.Highlight.Enabled = visible
        data.Billboard.Enabled = visible and showName

        if visible and showName then
            if kind == "PLAYER" then
                local targetPlayer =
                    Players:GetPlayerFromCharacter(model)

                data.Label.Text = targetPlayer
                    and targetPlayer.DisplayName
                    or model.Name

            elseif kind == "NPC" then
                data.Label.Text = model.Name

            elseif kind == "DOOR" then
                data.Label.Text = model.Name
            end
        end

        if kind == "DOOR" then
            data.Billboard.MaxDistance = Config.MaxDistance
        else
            data.Billboard.MaxDistance = Config.MaxDistance
        end
    end
end)

--============================================================
-- PERIODIC SCAN
--============================================================

task.spawn(function()
    while not destroyed and Gui.Parent do
        task.wait(3)

        if destroyed then break end

        if Config.PlayerESP then
            scanPlayers()
        end

        if Config.EnemyESP then
            scanEnemies()
        end

        if Config.DoorESP then
            scanDoors()
        end
    end
end)

--============================================================
-- DESTROY
--============================================================

_G.DoorESP_Destroy = function()
    if destroyed then return end

    destroyed = true

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for model in pairs(tracked) do
        removeESP(model)
    end

    table.clear(tracked)

    if Gui then
        Gui:Destroy()
    end

    _G.DoorESP_Destroy = nil

    print("[DOOR ESP PRO v3.0] Destroyed successfully")
end

--============================================================
-- INITIALIZATION
--============================================================

TabButtons.EVENT:Activate()

print("======================================")
print("       DOOR ESP PRO v3.0")
print("       GUI: LOADED")
print("       PLAYER ESP: READY")
print("       NPC ESP: READY")
print("       DOOR ESP: READY")
print("======================================")
