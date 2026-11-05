--==================================================
-- DOOR ESP PRO
-- Version 1.2
-- LocalScript
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- CONFIGURACION
--==================================================

local CONFIG = {
    ScanInterval = 2,
    MaxDistance = 1000,
    PromptDistance = 15,
    InstantOpen = false,
    ESPEnabled = true
}

local COLORS = {
    Background = Color3.fromRGB(15, 17, 23),
    Panel = Color3.fromRGB(24, 27, 35),
    Button = Color3.fromRGB(35, 40, 52),
    Accent = Color3.fromRGB(145, 75, 255),
    White = Color3.fromRGB(245, 245, 255),
    Gray = Color3.fromRGB(145, 150, 165),
    Green = Color3.fromRGB(55, 190, 100),
    Red = Color3.fromRGB(210, 65, 75)
}

--==================================================
-- VARIABLES
--==================================================

local espObjects = {}
local originalPrompts = {}
local currentPage = nil
local destroyed = false

local espEnabled = true
local instantEnabled = false

--==================================================
-- FUNCIONES GENERALES
--==================================================

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function corner(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, object)
end

local function stroke(object, color, thickness)
    create("UIStroke", {
        Color = color or COLORS.Accent,
        Thickness = thickness or 1
    }, object)
end

local function createLabel(parent, text, size, position)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Text = text,
        TextColor3 = COLORS.White,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
end

--==================================================
-- DETECCION DE PUERTAS
--==================================================

local function isDoor(object)
    local name = string.lower(object.Name)

    return name == "door"
        or name == "halloweendoor"
end

local function getDoorPart(object)
    if object:IsA("BasePart") then
        return object
    end

    if object:IsA("Model") then
        return object.PrimaryPart
            or object:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function getDistance(part)
    local character = player.Character
    if not character then
        return math.huge
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return math.huge
    end

    return (root.Position - part.Position).Magnitude
end

--==================================================
-- SISTEMA ESP
--==================================================

local function removeESP(object)
    local data = espObjects[object]

    if not data then
        return
    end

    if data.Highlight then
        data.Highlight:Destroy()
    end

    if data.Billboard then
        data.Billboard:Destroy()
    end

    espObjects[object] = nil
end

local function createESP(object)
    if espObjects[object] then
        return
    end

    local part = getDoorPart(object)
    if not part then
        return
    end

    local highlight = create("Highlight", {
        Adornee = object,
        FillColor = COLORS.Accent,
        OutlineColor = COLORS.White,
        FillTransparency = 0.65,
        OutlineTransparency = 0
    }, object)

    local billboard = create("BillboardGui", {
        Name = "DoorESP_Label",
        Adornee = part,
        Size = UDim2.fromOffset(180, 45),
        StudsOffset = Vector3.new(0, 3, 0),
        AlwaysOnTop = true
    }, playerGui)

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = object.Name,
        TextColor3 = COLORS.White,
        TextStrokeTransparency = 0.25,
        TextSize = 14,
        Font = Enum.Font.GothamBold
    }, billboard)

    espObjects[object] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label
    }
end

local function clearAllESP()
    for object in pairs(espObjects) do
        removeESP(object)
    end
end

local function updateESP()
    for object, data in pairs(espObjects) do
        if not object.Parent then
            removeESP(object)
        else
            local part = getDoorPart(object)

            if part then
                local distance = math.floor(getDistance(part))

                data.Label.Text = object.Name
                    .. " | " .. distance .. " studs"

                data.Billboard.Enabled =
                    espEnabled and distance <= CONFIG.MaxDistance
            end
        end
    end
end

local function scan()
    if destroyed or not espEnabled then
        return
    end

    for _, object in ipairs(Workspace:GetDescendants()) do
        if isDoor(object) then
            createESP(object)
        end
    end
end

--==================================================
-- PROXIMITY PROMPT LOCAL
--==================================================

local function updatePrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then
        return
    end

    if not originalPrompts[prompt] then
        originalPrompts[prompt] = {
            HoldDuration = prompt.HoldDuration,
            MaxDistance = prompt.MaxActivationDistance
        }
    end

    if instantEnabled then
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = CONFIG.PromptDistance
    else
        local original = originalPrompts[prompt]

        prompt.HoldDuration = original.HoldDuration
        prompt.MaxActivationDistance = original.MaxDistance
    end
end

local function restorePrompts()
    for prompt, original in pairs(originalPrompts) do
        if prompt and prompt.Parent then
            prompt.HoldDuration = original.HoldDuration
            prompt.MaxActivationDistance = original.MaxDistance
        end
    end
end

--==================================================
-- INTERFAZ PRINCIPAL
--==================================================

local oldGui = playerGui:FindFirstChild("DoorESP_PRO")
if oldGui then
    oldGui:Destroy()
end

local gui = create("ScreenGui", {
    Name = "DoorESP_PRO",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(370, 420),
    Position = UDim2.new(0.5, -185, 0.5, -210),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0
}, gui)

corner(main, 12)
stroke(main, COLORS.Accent, 1.5)

local top = create("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0
}, main)

corner(top, 12)

createLabel(
    top,
    "DOOR ESP PRO",
    UDim2.new(1, -60, 1, 0),
    UDim2.fromOffset(16, 0)
)

local closeButton = create("TextButton", {
    Size = UDim2.fromOffset(35, 35),
    Position = UDim2.new(1, -45, 0, 10),
    BackgroundColor3 = COLORS.Red,
    Text = "X",
    TextColor3 = COLORS.White,
    TextSize = 16,
    Font = Enum.Font.GothamBold
}, top)

corner(closeButton, 8)

--==================================================
-- PESTAÑAS
--==================================================

local tabBar = create("Frame", {
    Position = UDim2.fromOffset(10, 65),
    Size = UDim2.new(1, -20, 0, 42),
    BackgroundTransparency = 1
}, main)

local tabLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, tabBar)

local content = create("Frame", {
    Position = UDim2.fromOffset(10, 115),
    Size = UDim2.new(1, -20, 1, -125),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0
}, main)

corner(content, 8)

local Pages = {}

for _, pageName in ipairs({
    "VISUAL",
    "INTERACTION",
    "COMBATE",
    "SETTINGS"
}) do

    Pages[pageName] = create("ScrollingFrame", {
        Name = pageName,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false
    }, content)

    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, Pages[pageName])

    create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    }, Pages[pageName])
end

--==================================================
-- FUNCIONES DE BOTONES
--==================================================

local function actionButton(page, text, callback)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = COLORS.Button,
        Text = text,
        TextColor3 = COLORS.White,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, page)

    corner(button, 8)

    button.MouseButton1Click:Connect(callback)

    return button
end

local function toggleButton(page, text, initial, callback)
    local enabled = initial

    local button = actionButton(
        page,
        text .. ": " .. (enabled and "ON" or "OFF"),
        function()
            enabled = not enabled

            button.Text = text
                .. ": "
                .. (enabled and "ON" or "OFF")

            callback(enabled)
        end
    )

    return button
end

--==================================================
-- FIN DE LA PARTE 1
-- LA PARTE 2 CONTINUA DESDE AQUI
--==================================================
--==================================================
-- NAVEGACION ENTRE PESTAÑAS
--==================================================

local function selectPage(name)
    currentPage = name

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
    end

    for _, child in ipairs(tabBar:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 =
                child.Name == name
                and COLORS.Accent
                or COLORS.Button
        end
    end
end

for _, name in ipairs({
    "VISUAL",
    "INTERACTION",
    "COMBATE",
    "SETTINGS"
}) do

    local tab = create("TextButton", {
        Name = name,
        Size = UDim2.new(0.25, -5, 1, 0),
        BackgroundColor3 = COLORS.Button,
        Text = name,
        TextColor3 = COLORS.White,
        TextSize = 10,
        Font = Enum.Font.GothamBold
    }, tabBar)

    corner(tab, 7)

    tab.MouseButton1Click:Connect(function()
        selectPage(name)
    end)
end

selectPage("VISUAL")

--==================================================
-- VISUAL
--==================================================

toggleButton(
    Pages.VISUAL,
    "Door ESP",
    true,
    function(value)
        espEnabled = value

        if value then
            scan()
        else
            clearAllESP()
        end
    end
)

actionButton(
    Pages.VISUAL,
    "CLEAR ALL ESP",
    function()
        clearAllESP()
    end
)

actionButton(
    Pages.VISUAL,
    "SCAN DOORS",
    function()
        scan()
    end
)

actionButton(
    Pages.VISUAL,
    "RANGE: 1000 STUDS",
    function()
        CONFIG.MaxDistance = 1000
        updateESP()
    end
)

--==================================================
-- INTERACTION
--==================================================

toggleButton(
    Pages.INTERACTION,
    "INSTANT OPEN LOCAL",
    false,
    function(value)
        instantEnabled = value

        for _, object in ipairs(Workspace:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                updatePrompt(object)
            end
        end

        if not value then
            restorePrompts()
        end
    end
)

actionButton(
    Pages.INTERACTION,
    "RESTORE PROMPTS",
    function()
        instantEnabled = false
        restorePrompts()
    end
)

--==================================================
-- COMBATE
-- RESERVADO PARA FUTURAS FUNCIONES
--==================================================

createLabel(
    Pages.COMBATE,
    "COMBATE",
    UDim2.new(1, 0, 0, 35),
    UDim2.new()
)

local combatInfo = createLabel(
    Pages.COMBATE,
    "Próximamente...",
    UDim2.new(1, 0, 0, 35),
    UDim2.new()
)

combatInfo.TextColor3 = COLORS.Gray

--==================================================
-- SETTINGS
--==================================================

actionButton(
    Pages.SETTINGS,
    "CLEAR ALL ESP",
    function()
        clearAllESP()
    end
)

actionButton(
    Pages.SETTINGS,
    "RESTORE ESP",
    function()
        espEnabled = true
        scan()
    end
)

actionButton(
    Pages.SETTINGS,
    "RESTORE PROMPTS",
    function()
        instantEnabled = false
        restorePrompts()
    end
)

--==================================================
-- ACTUALIZAR TAMAÑO DE LAS PAGINAS
--==================================================

local function updateCanvas()
    for _, page in pairs(Pages) do
        local layout = page:FindFirstChildOfClass("UIListLayout")

        if layout then
            page.CanvasSize = UDim2.new(
                0,
                0,
                0,
                layout.AbsoluteContentSize.Y + 25
            )
        end
    end
end

for _, page in pairs(Pages) do
    local layout = page:FindFirstChildOfClass("UIListLayout")

    if layout then
        layout:GetPropertyChangedSignal(
            "AbsoluteContentSize"
        ):Connect(updateCanvas)
    end
end

task.defer(updateCanvas)

--==================================================
-- BOTON FLOTANTE
--==================================================

local orb = create("TextButton", {
    Name = "DoorESP_Orb",
    Size = UDim2.fromOffset(55, 55),
    Position = UDim2.new(0, 20, 0.5, 0),
    BackgroundColor3 = COLORS.Accent,
    Text = "D",
    TextColor3 = COLORS.White,
    TextSize = 24,
    Font = Enum.Font.GothamBlack,
    Visible = false
}, gui)

corner(orb, 100)
stroke(orb, COLORS.White, 1.5)

orb.MouseButton1Click:Connect(function()
    main.Visible = true
    orb.Visible = false
    scan()
end)

closeButton.MouseButton1Click:Connect(function()
    clearAllESP()
    main.Visible = false
    orb.Visible = true
end)

--==================================================
-- MOVIMIENTO DEL PANEL
--==================================================

local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

--==================================================
-- ESCANEO AUTOMATICO
--==================================================

local scanConnection

scanConnection = task.spawn(function()
    while not destroyed do
        if espEnabled then
            scan()
            updateESP()
        end

        task.wait(CONFIG.ScanInterval)
    end
end)

--==================================================
-- DETECTAR PUERTAS NUEVAS Y PROMPTS NUEVOS
--==================================================

local addedConnection = Workspace.DescendantAdded:Connect(
    function(object)

        if isDoor(object) and espEnabled then
            task.wait(0.1)
            createESP(object)
        end

        if object:IsA("ProximityPrompt") and instantEnabled then
            updatePrompt(object)
        end
    end
)

--==================================================
-- DESTRUIR TODO
--==================================================

local function destroyScript()
    if destroyed then
        return
    end

    destroyed = true

    clearAllESP()
    restorePrompts()

    if addedConnection then
        addedConnection:Disconnect()
    end

    if gui then
        gui:Destroy()
    end

    _G.DoorESP_Destroy = nil
end

_G.DoorESP_Destroy = destroyScript

actionButton(
    Pages.SETTINGS,
    "DESTROY SCRIPT",
    function()
        destroyScript()
    end
)

--==================================================
-- INICIAR
--==================================================

scan()
updateESP()

print("DOOR ESP PRO iniciado correctamente")
