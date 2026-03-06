-- LocalScript | StarterPlayerScripts
-- Version LITE: Teleport + Collision + Prompt Skip (siempre activo) + Timer

local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local CFG = {
    COLLISION_POS  = Vector3.new(2520, -1100.6, 850),
    COLLISION_SIZE = Vector3.new(10, 1, 10),
}

--------------------------------------------------
-- COLLISION PART
--------------------------------------------------

local oldPart = Workspace:FindFirstChild("FarmCollision")
if oldPart then oldPart:Destroy() end

local collisionPart        = Instance.new("Part")
collisionPart.Name         = "FarmCollision"
collisionPart.Anchored     = true
collisionPart.CanCollide   = true
collisionPart.Transparency = 1
collisionPart.CastShadow   = false
collisionPart.Locked       = true
collisionPart.Size         = CFG.COLLISION_SIZE
collisionPart.Position     = CFG.COLLISION_POS
collisionPart.Parent       = Workspace

--------------------------------------------------
-- TELEPORT
--------------------------------------------------

local function teleport(char)
    task.spawn(function()
        pcall(function()
            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            if not hrp then return end
            hrp.Anchored = true
            local offset = CFG.COLLISION_SIZE.Y / 2 + hrp.Size.Y / 2 + 0.1
            hrp.CFrame   = CFrame.new(
                CFG.COLLISION_POS.X,
                CFG.COLLISION_POS.Y + offset,
                CFG.COLLISION_POS.Z
            )
            for _ = 1, 5 do RunService.Heartbeat:Wait() end
            hrp.Anchored = false
        end)
    end)
end

local character = player.Character
if character then teleport(character) end

player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    teleport(char)
end)

--------------------------------------------------
-- PROMPT SKIP (siempre activo)
--------------------------------------------------

local function applyPromptSkip(prompt)
    pcall(function() prompt.HoldDuration = 0 end)
end

-- Aplicar a todos los existentes
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("ProximityPrompt") then applyPromptSkip(obj) end
end

-- Aplicar a los que se agreguen
Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") then applyPromptSkip(obj) end
end)

--------------------------------------------------
-- TIMER
--------------------------------------------------

local startTime = os.clock()

local function fmtTime(e)
    return string.format("%02d:%02d:%02d",
        math.floor(e / 3600),
        math.floor((e % 3600) / 60),
        e % 60)
end

local function timerColor()
    local t = os.clock() * 0.7
    return Color3.new(
        math.sin(t)       * 0.18 + 0.72,
        math.sin(t + 2.1) * 0.09 + 0.25,
        math.sin(t + 4.2) * 0.18 + 0.88
    )
end

--------------------------------------------------
-- UI — PANEL TIMER
--------------------------------------------------

do
    local old = playerGui:FindFirstChild("GothicPanel")
    if old then old:Destroy() end
end

-- Panel compacto: solo título + timer + status
local PW, PH, TH = 274, 160, 48
local panelIsMin  = false

local SG = Instance.new("ScreenGui")
SG.Name         = "GothicPanel"
SG.ResetOnSpawn = false
SG.DisplayOrder = 999
SG.Parent       = playerGui

local panel = Instance.new("Frame")
panel.Name             = "GPanel"
panel.Size             = UDim2.new(0, PW, 0, PH)
panel.Position         = UDim2.new(1, PW + 20, 0.5, -(PH / 2))
panel.BackgroundColor3 = Color3.fromRGB(7, 3, 12)
panel.BorderSizePixel  = 0
panel.ClipsDescendants = false
panel.Parent           = SG
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

do
    local g = Instance.new("UIGradient")
    g.Rotation = 142
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 4, 24)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8,  3, 13)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(18, 5, 28)),
    })
    g.Parent = panel
end

local pStroke = Instance.new("UIStroke")
pStroke.Thickness = 1.5
pStroke.Color     = Color3.fromRGB(105, 33, 140)
pStroke.Parent    = panel

-- Shimmer top
local shimBar = Instance.new("Frame")
shimBar.Size             = UDim2.new(1, 0, 0, 3)
shimBar.BackgroundColor3 = Color3.fromRGB(165, 62, 225)
shimBar.BorderSizePixel  = 0
shimBar.ZIndex           = 6
shimBar.Parent           = panel
do
    local g = Instance.new("UIGradient")
    g.Rotation = 0
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(50, 13, 80)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(210, 92, 255)),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(210, 92, 255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(50, 13, 80)),
    })
    g.Parent = shimBar
end

-- Ornamentos
local function mkOrn(xS, yS, xO, yO)
    local o = Instance.new("TextLabel")
    o.Size             = UDim2.new(0, 16, 0, 16)
    o.Position         = UDim2.new(xS, xO, yS, yO)
    o.BackgroundTransparency = 1
    o.Text             = "✦"
    o.TextColor3       = Color3.fromRGB(78, 24, 108)
    o.Font             = Enum.Font.Antique
    o.TextSize         = 10
    o.ZIndex           = 8
    o.Parent           = panel
    return o
end
local ornTL = mkOrn(0, 0,  5,  5)
local ornTR = mkOrn(1, 0, -21, 5)
local ornBL = mkOrn(0, 1,  5, -21)
local ornBR = mkOrn(1, 1, -21, -21)

-- Título
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, TH)
titleBar.BackgroundColor3 = Color3.fromRGB(17, 5, 28)
titleBar.BorderSizePixel  = 0
titleBar.ZIndex           = 5
titleBar.Parent           = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
do
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 9, 52)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 3, 17)),
    })
    g.Parent = titleBar
end

local tbLine = Instance.new("Frame")
tbLine.Size             = UDim2.new(1, -28, 0, 1)
tbLine.Position         = UDim2.new(0, 14, 1, -1)
tbLine.BackgroundColor3 = Color3.fromRGB(130, 46, 178)
tbLine.BorderSizePixel  = 0
tbLine.ZIndex           = 6
tbLine.Parent           = titleBar
do
    local g = Instance.new("UIGradient")
    g.Rotation = 0
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(32, 8, 52)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(178, 70, 235)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(32, 8, 52)),
    })
    g.Parent = tbLine
end

local gTitle = Instance.new("TextLabel")
gTitle.Size             = UDim2.new(1, -52, 1, 0)
gTitle.Position         = UDim2.new(0, 14, 0, 0)
gTitle.BackgroundTransparency = 1
gTitle.Text             = "✦  GRIMOIRE  ✦"
gTitle.TextColor3       = Color3.fromRGB(205, 130, 255)
gTitle.Font             = Enum.Font.Antique
gTitle.TextSize         = 19
gTitle.TextXAlignment   = Enum.TextXAlignment.Left
gTitle.ZIndex           = 6
gTitle.Parent           = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 26, 0, 26)
minBtn.Position         = UDim2.new(1, -34, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(26, 8, 42)
minBtn.BorderSizePixel  = 0
minBtn.Text             = "−"
minBtn.TextColor3       = Color3.fromRGB(168, 98, 220)
minBtn.Font             = Enum.Font.GothamBold
minBtn.TextSize         = 16
minBtn.ZIndex           = 7
minBtn.Parent           = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)
do
    local s = Instance.new("UIStroke")
    s.Thickness = 1; s.Color = Color3.fromRGB(72, 23, 100); s.Parent = minBtn
end
minBtn.MouseEnter:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.1),
        { BackgroundColor3 = Color3.fromRGB(52, 17, 80) }):Play()
end)
minBtn.MouseLeave:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.1),
        { BackgroundColor3 = Color3.fromRGB(26, 8, 42) }):Play()
end)

-- Body clip
local bodyClip = Instance.new("Frame")
bodyClip.Name             = "BodyClip"
bodyClip.Size             = UDim2.new(1, 0, 0, PH - TH - 24)
bodyClip.Position         = UDim2.new(0, 0, 0, TH)
bodyClip.BackgroundTransparency = 1
bodyClip.BorderSizePixel  = 0
bodyClip.ClipsDescendants = true
bodyClip.Parent           = panel

local body = Instance.new("Frame")
body.Size             = UDim2.new(1, 0, 1, 0)
body.BackgroundTransparency = 1
body.BorderSizePixel  = 0
body.Parent           = bodyClip

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Size             = UDim2.new(1, 0, 0, 24)
statusBar.Position         = UDim2.new(0, 0, 1, -24)
statusBar.BackgroundColor3 = Color3.fromRGB(12, 4, 20)
statusBar.BorderSizePixel  = 0
statusBar.ZIndex           = 5
statusBar.Parent           = bodyClip
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 6)

local sDot = Instance.new("Frame")
sDot.Size             = UDim2.new(0, 6, 0, 6)
sDot.Position         = UDim2.new(0, 10, 0.5, -3)
sDot.BackgroundColor3 = Color3.fromRGB(138, 50, 190)
sDot.BorderSizePixel  = 0
sDot.ZIndex           = 6
sDot.Parent           = statusBar
Instance.new("UICorner", sDot).CornerRadius = UDim.new(1, 0)

local sLabel = Instance.new("TextLabel")
sLabel.Size             = UDim2.new(1, -26, 1, 0)
sLabel.Position         = UDim2.new(0, 22, 0, 0)
sLabel.BackgroundTransparency = 1
sLabel.Text             = "Timer by: 2by"
sLabel.TextColor3       = Color3.fromRGB(118, 62, 158)
sLabel.Font             = Enum.Font.Antique
sLabel.TextSize         = 11
sLabel.TextXAlignment   = Enum.TextXAlignment.Left
sLabel.ZIndex           = 6
sLabel.Parent           = statusBar

--------------------------------------------------
-- TIMER BOX (único contenido del body)
--------------------------------------------------

local timerBox = Instance.new("Frame")
timerBox.Size             = UDim2.new(1, -20, 0, 44)
timerBox.Position         = UDim2.new(0, 10, 0, 6)
timerBox.BackgroundColor3 = Color3.fromRGB(5, 2, 9)
timerBox.BorderSizePixel  = 0
timerBox.Parent           = body
Instance.new("UICorner", timerBox).CornerRadius = UDim.new(0, 5)
do
    local s = Instance.new("UIStroke")
    s.Thickness = 1; s.Color = Color3.fromRGB(65, 20, 92); s.Parent = timerBox
end

local timeLabel = Instance.new("TextLabel")
timeLabel.Size             = UDim2.new(1, 0, 1, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Font             = Enum.Font.Antique
timeLabel.TextSize         = 26
timeLabel.TextXAlignment   = Enum.TextXAlignment.Center
timeLabel.TextYAlignment   = Enum.TextYAlignment.Center
timeLabel.Text             = "00:00:00"
timeLabel.TextColor3       = Color3.fromRGB(195, 105, 250)
timeLabel.Parent           = timerBox

--------------------------------------------------
-- MINIMIZE / MAXIMIZE
--------------------------------------------------

local function setMinimized(val)
    panelIsMin  = val
    minBtn.Text = val and "+" or "−"
    local panelTarget = val and TH or PH
    local bodyTarget  = val and 0 or (PH - TH - 24)
    TweenService:Create(panel,
        TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, PW, 0, panelTarget) }):Play()
    TweenService:Create(bodyClip,
        TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.new(1, 0, 0, bodyTarget) }):Play()
    local t = val and 1 or 0
    TweenService:Create(ornBL, TweenInfo.new(0.15), { TextTransparency = t }):Play()
    TweenService:Create(ornBR, TweenInfo.new(0.15), { TextTransparency = t }):Play()
end

minBtn.MouseButton1Click:Connect(function()
    setMinimized(not panelIsMin)
end)

--------------------------------------------------
-- DRAG
--------------------------------------------------

local dragging, dStart, dOrigin = false, nil, nil
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dStart = i.Position; dOrigin = panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dStart
        panel.Position = UDim2.new(
            dOrigin.X.Scale, dOrigin.X.Offset + d.X,
            dOrigin.Y.Scale, dOrigin.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

--------------------------------------------------
-- ANIMACIONES
--------------------------------------------------

TweenService:Create(panel,
    TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.new(1, -(PW + 14), 0.5, -(PH / 2)) }
):Play()

task.spawn(function()
    while true do
        TweenService:Create(pStroke, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Color = Color3.fromRGB(55, 16, 78) }):Play()
        task.wait(2.4)
        TweenService:Create(pStroke, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Color = Color3.fromRGB(152, 56, 210) }):Play()
        task.wait(2.4)
    end
end)

task.spawn(function()
    local g = shimBar:FindFirstChildOfClass("UIGradient")
    while true do
        TweenService:Create(g, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Offset = Vector2.new(0.42, 0) }):Play()
        task.wait(3.2)
        TweenService:Create(g, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Offset = Vector2.new(-0.42, 0) }):Play()
        task.wait(3.2)
    end
end)

task.spawn(function()
    while true do
        TweenService:Create(gTitle, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { TextColor3 = Color3.fromRGB(148, 78, 210) }):Play()
        task.wait(3)
        TweenService:Create(gTitle, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { TextColor3 = Color3.fromRGB(222, 152, 255) }):Play()
        task.wait(3)
    end
end)

task.spawn(function()
    local orns = { ornTL, ornTR, ornBL, ornBR }
    while true do
        for _, o in ipairs(orns) do
            TweenService:Create(o, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { TextColor3 = Color3.fromRGB(152, 55, 205) }):Play()
        end
        task.wait(2)
        for _, o in ipairs(orns) do
            TweenService:Create(o, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { TextColor3 = Color3.fromRGB(55, 17, 84) }):Play()
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        TweenService:Create(sDot, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { BackgroundColor3 = Color3.fromRGB(192, 78, 248) }):Play()
        task.wait(1.5)
        TweenService:Create(sDot, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { BackgroundColor3 = Color3.fromRGB(85, 26, 118) }):Play()
        task.wait(1.5)
    end
end)

--------------------------------------------------
-- LOOP TIMER
--------------------------------------------------

task.spawn(function()
    while true do
        pcall(function()
            local e = math.max(0, math.floor(os.clock() - startTime))
            timeLabel.Text       = fmtTime(e)
            timeLabel.TextColor3 = timerColor()
        end)
        task.wait(1)
    end
end)
