
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
    COLLISION_POS  = Vector3.new(-2669.1, -318.3, -2447.3),
    COLLISION_SIZE = Vector3.new(10, 1, 10),
}

--------------------------------------------------
-- COLLISION PART
--------------------------------------------------

local oldPart = Workspace:FindFirstChild("FarmCollision")
if oldPart then oldPart:Destroy() end

local collisionPart      = Instance.new("Part")
collisionPart.Name       = "FarmCollision"
collisionPart.Anchored   = true
collisionPart.CanCollide = true
collisionPart.Transparency = 1
collisionPart.CastShadow = false
collisionPart.Locked     = true
collisionPart.Size       = CFG.COLLISION_SIZE
collisionPart.Position   = CFG.COLLISION_POS
collisionPart.Parent     = Workspace

--------------------------------------------------
-- TELEPORT
--------------------------------------------------

local function teleport(char)
    task.spawn(function()
        pcall(function()

            local hrp = char:WaitForChild("HumanoidRootPart", 10)
            local humanoid = char:FindFirstChildOfClass("Humanoid")

            if not hrp or not humanoid then return end

            -- asegurar posición correcta del part
            collisionPart.Position = CFG.COLLISION_POS

            hrp.Anchored = true

            local partHeight = collisionPart.Size.Y / 2
            local rootHeight = hrp.Size.Y / 2
            local hipHeight = humanoid.HipHeight

            local finalY = CFG.COLLISION_POS.Y + partHeight + rootHeight + hipHeight

            hrp.CFrame = CFrame.new(
                CFG.COLLISION_POS.X,
                finalY,
                CFG.COLLISION_POS.Z
            )

            for _ = 1,5 do
                RunService.Heartbeat:Wait()
            end

            hrp.Anchored = false

        end)
    end)
end
--------------------------------------------------
-- PROMPT SKIP (siempre activo)
--------------------------------------------------

local function applyPromptSkip(prompt)
    pcall(function() prompt.HoldDuration = 0 end)
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("ProximityPrompt") then applyPromptSkip(obj) end
end

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

--------------------------------------------------
-- COLORES TEMA
--------------------------------------------------

local C = {
    bg0       = Color3.fromRGB(6,  2,  11),
    bg1       = Color3.fromRGB(11, 4,  20),
    bg2       = Color3.fromRGB(18, 6,  32),
    accent    = Color3.fromRGB(148, 52, 210),
    accentLo  = Color3.fromRGB(55,  16, 82),
    accentHi  = Color3.fromRGB(210, 130, 255),
    text      = Color3.fromRGB(210, 170, 245),
    textDim   = Color3.fromRGB(120, 72, 165),
    textLo    = Color3.fromRGB(72,  38, 105),
    white     = Color3.fromRGB(255, 255, 255),
    green     = Color3.fromRGB(90,  220, 140),
    greenLo   = Color3.fromRGB(30,  80,  55),
}

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, thickness, color)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Color     = color or C.accentLo
    s.Parent    = parent
    return s
end

local function gradient(parent, rotation, seq)
    local g = Instance.new("UIGradient")
    g.Rotation = rotation
    g.Color    = seq
    g.Parent   = parent
    return g
end

local function mkLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font     = props.Font or Enum.Font.GothamBold
    l.TextSize = props.TextSize or 13
    l.Text     = props.Text or ""
    l.TextColor3 = props.Color or C.text
    l.TextXAlignment = props.AlignX or Enum.TextXAlignment.Center
    l.TextYAlignment = props.AlignY or Enum.TextYAlignment.Center
    l.Size     = props.Size or UDim2.new(1, 0, 1, 0)
    l.Position = props.Pos or UDim2.new(0, 0, 0, 0)
    l.ZIndex   = props.Z or 2
    if props.RichText then l.RichText = true end
    l.Parent   = props.Parent
    return l
end

local function pulse(obj, propName, v1, v2, duration)
    duration = duration or 2
    task.spawn(function()
        while obj and obj.Parent do
            TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { [propName] = v2 }):Play()
            task.wait(duration)
            TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { [propName] = v1 }):Play()
            task.wait(duration)
        end
    end)
end

--------------------------------------------------
-- SCREEN GUI
--------------------------------------------------

do
    local old = playerGui:FindFirstChild("GothicPanel")
    if old then old:Destroy() end
end

local SG = Instance.new("ScreenGui")
SG.Name         = "GothicPanel"
SG.ResetOnSpawn = false
SG.DisplayOrder = 999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent       = playerGui

--------------------------------------------------
-- PANEL PRINCIPAL
--------------------------------------------------

local PW   = 280
local PH   = 310
local TH   = 52
local panelMin = false

local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.new(0, PW, 0, PH)
panel.Position         = UDim2.new(1, PW + 30, 0.5, -(PH / 2))
panel.BackgroundColor3 = C.bg0
panel.BorderSizePixel  = 0
panel.ClipsDescendants = false
panel.Parent           = SG
corner(panel, 14)

gradient(panel, 145, ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 4,  26)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(7,  2,  13)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(16, 5,  28)),
}))

local pStroke = stroke(panel, 1.5, C.accentLo)

-- Glow externo
local glow = Instance.new("ImageLabel")
glow.Name              = "Glow"
glow.Size              = UDim2.new(1, 60, 1, 60)
glow.Position          = UDim2.new(0, -30, 0, -30)
glow.BackgroundTransparency = 1
glow.Image             = "rbxassetid://7912134082"   -- soft radial blur
glow.ImageColor3       = C.accent
glow.ImageTransparency = 0.82
glow.ZIndex            = 0
glow.Parent            = panel

pulse(glow, "ImageTransparency", 0.82, 0.72, 2.8)
pulse(pStroke, "Color", C.accentLo, C.accent, 2.4)

--------------------------------------------------
-- SHIMMER TOP
--------------------------------------------------

local shimFrame = Instance.new("Frame")
shimFrame.Size             = UDim2.new(1, 0, 0, 3)
shimFrame.BackgroundColor3 = C.accent
shimFrame.BorderSizePixel  = 0
shimFrame.ZIndex           = 8
shimFrame.Parent           = panel
corner(shimFrame, 3)

local shimG = gradient(shimFrame, 0, ColorSequence.new({
    ColorSequenceKeypoint.new(0,    C.accentLo),
    ColorSequenceKeypoint.new(0.35, C.accentHi),
    ColorSequenceKeypoint.new(0.65, C.accentHi),
    ColorSequenceKeypoint.new(1,    C.accentLo),
}))

task.spawn(function()
    while true do
        TweenService:Create(shimG, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Offset = Vector2.new(0.45, 0) }):Play()
        task.wait(2.8)
        TweenService:Create(shimG, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Offset = Vector2.new(-0.45, 0) }):Play()
        task.wait(2.8)
    end
end)

--------------------------------------------------
-- TITULO BAR
--------------------------------------------------

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, TH)
titleBar.BackgroundColor3 = C.bg1
titleBar.BorderSizePixel  = 0
titleBar.ZIndex           = 5
titleBar.Parent           = panel
corner(titleBar, 14)

gradient(titleBar, 90, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 8, 48)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(9,  3, 16)),
}))

-- Línea inferior del título
local titleLine = Instance.new("Frame")
titleLine.Size             = UDim2.new(1, -32, 0, 1)
titleLine.Position         = UDim2.new(0, 16, 1, -1)
titleLine.BackgroundColor3 = C.accent
titleLine.BorderSizePixel  = 0
titleLine.ZIndex           = 6
titleLine.Parent           = titleBar
gradient(titleLine, 0, ColorSequence.new({
    ColorSequenceKeypoint.new(0,   C.accentLo),
    ColorSequenceKeypoint.new(0.5, C.accentHi),
    ColorSequenceKeypoint.new(1,   C.accentLo),
}))

-- Icono ✦
local titleIcon = mkLabel({
    Text = "✦", Font = Enum.Font.Antique,
    TextSize = 16, Color = C.accent,
    Size = UDim2.new(0, 28, 1, 0),
    Pos  = UDim2.new(0, 14, 0, 0),
    Z = 6, Parent = titleBar,
    AlignX = Enum.TextXAlignment.Left,
})
pulse(titleIcon, "TextColor3", C.accentLo, C.accentHi, 2.2)

-- Texto título
local gTitle = mkLabel({
    Text = "GRIMOIRE", Font = Enum.Font.GothamBold,
    TextSize = 17, Color = C.accentHi,
    Size = UDim2.new(1, -90, 1, 0),
    Pos  = UDim2.new(0, 40, 0, 0),
    Z = 6, Parent = titleBar,
    AlignX = Enum.TextXAlignment.Left,
})
pulse(gTitle, "TextColor3", C.textDim, C.accentHi, 3)

-- Subtítulo / versión
mkLabel({
    Text = "FARM SUITE", Font = Enum.Font.Gotham,
    TextSize = 9, Color = C.textLo,
    Size = UDim2.new(0, 80, 0, 12),
    Pos  = UDim2.new(0, 40, 1, -14),
    Z = 6, Parent = titleBar,
    AlignX = Enum.TextXAlignment.Left,
})

-- Botón minimizar
local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 28, 0, 28)
minBtn.Position         = UDim2.new(1, -38, 0.5, -14)
minBtn.BackgroundColor3 = C.bg2
minBtn.BorderSizePixel  = 0
minBtn.Text             = "−"
minBtn.TextColor3       = C.accent
minBtn.Font             = Enum.Font.GothamBold
minBtn.TextSize         = 18
minBtn.ZIndex           = 9
minBtn.Parent           = titleBar
corner(minBtn, 7)
stroke(minBtn, 1, C.accentLo)

minBtn.MouseEnter:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.12), { BackgroundColor3 = C.accentLo }):Play()
end)
minBtn.MouseLeave:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.12), { BackgroundColor3 = C.bg2 }):Play()
end)

--------------------------------------------------
-- BODY CLIP
--------------------------------------------------

local bodyClip = Instance.new("Frame")
bodyClip.Name             = "BodyClip"
bodyClip.Size             = UDim2.new(1, 0, 0, PH - TH - 28)
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

--------------------------------------------------
-- TIMER CARD
--------------------------------------------------

local timerCard = Instance.new("Frame")
timerCard.Size             = UDim2.new(1, -24, 0, 88)
timerCard.Position         = UDim2.new(0, 12, 0, 12)
timerCard.BackgroundColor3 = C.bg1
timerCard.BorderSizePixel  = 0
timerCard.Parent           = body
corner(timerCard, 12)
gradient(timerCard, 135, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 6, 36)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,  3, 15)),
}))
local timerStk = stroke(timerCard, 1, C.accentLo)
pulse(timerStk, "Color", C.accentLo, Color3.fromRGB(130, 45, 190), 2)

-- Label "FARM TIMER"
mkLabel({
    Text = "FARM TIMER", Font = Enum.Font.GothamBold,
    TextSize = 9, Color = C.textLo,
    Size = UDim2.new(1, -24, 0, 16),
    Pos  = UDim2.new(0, 14, 0, 10),
    Z = 3, Parent = timerCard,
    AlignX = Enum.TextXAlignment.Left,
})

-- Tiempo
local timeLabel = mkLabel({
    Text = "00:00:00", Font = Enum.Font.GothamBold,
    TextSize = 34, Color = C.accentHi,
    Size = UDim2.new(1, 0, 0, 44),
    Pos  = UDim2.new(0, 0, 0, 22),
    Z = 3, Parent = timerCard,
})

-- Label "by: 2by"
mkLabel({
    Text = "by: 2by", Font = Enum.Font.Gotham,
    TextSize = 9, Color = C.textLo,
    Size = UDim2.new(1, -14, 0, 12),
    Pos  = UDim2.new(0, 0, 1, -14),
    Z = 3, Parent = timerCard,
    AlignX = Enum.TextXAlignment.Right,
})

-- Destello interior del timer
local timerGlow = Instance.new("Frame")
timerGlow.Size             = UDim2.new(0.6, 0, 0, 2)
timerGlow.Position         = UDim2.new(0.2, 0, 1, -2)
timerGlow.BackgroundColor3 = C.accent
timerGlow.BorderSizePixel  = 0
timerGlow.ZIndex           = 2
timerGlow.Parent           = timerCard
corner(timerGlow, 2)
gradient(timerGlow, 0, ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accentLo),
    ColorSequenceKeypoint.new(0.5, C.accentHi),
    ColorSequenceKeypoint.new(1, C.accentLo),
}))
pulse(timerGlow, "BackgroundTransparency", 0, 0.5, 1.4)

--------------------------------------------------
-- SEPARADOR
--------------------------------------------------

local sep = Instance.new("Frame")
sep.Size             = UDim2.new(1, -32, 0, 1)
sep.Position         = UDim2.new(0, 16, 0, 113)
sep.BackgroundColor3 = C.accentLo
sep.BorderSizePixel  = 0
sep.ZIndex           = 2
sep.Parent           = body
gradient(sep, 0, ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.5, C.accent),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 0, 0)),
}))

-- Label sección "UTILIDADES"
mkLabel({
    Text = "UTILIDADES", Font = Enum.Font.GothamBold,
    TextSize = 9, Color = C.textLo,
    Size = UDim2.new(1, -32, 0, 14),
    Pos  = UDim2.new(0, 16, 0, 121),
    Z = 2, Parent = body,
    AlignX = Enum.TextXAlignment.Left,
})

--------------------------------------------------
-- BOTON TELEPORT
--------------------------------------------------

local tpBtn = Instance.new("TextButton")
tpBtn.Size             = UDim2.new(1, -24, 0, 50)
tpBtn.Position         = UDim2.new(0, 12, 0, 140)
tpBtn.BackgroundColor3 = Color3.fromRGB(18, 6, 32)
tpBtn.BorderSizePixel  = 0
tpBtn.Text             = ""
tpBtn.ZIndex           = 3
tpBtn.Parent           = body
corner(tpBtn, 10)
gradient(tpBtn, 135, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 12, 64)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 4, 24)),
}))
local tpStk = stroke(tpBtn, 1, C.accentLo)

-- Ícono del botón
local tpIcon = mkLabel({
    Text = "⟶", Font = Enum.Font.GothamBold,
    TextSize = 20, Color = C.accent,
    Size = UDim2.new(0, 40, 1, 0),
    Pos  = UDim2.new(0, 12, 0, 0),
    Z = 4, Parent = tpBtn,
    AlignX = Enum.TextXAlignment.Left,
})

-- Texto principal del botón
local tpMain = mkLabel({
    Text = "Teleport a Zona Farm", Font = Enum.Font.GothamBold,
    TextSize = 13, Color = C.text,
    Size = UDim2.new(1, -56, 0, 24),
    Pos  = UDim2.new(0, 48, 0, 6),
    Z = 4, Parent = tpBtn,
    AlignX = Enum.TextXAlignment.Left,
})

local tpSub = mkLabel({
    Text = "Clic para teletransportar", Font = Enum.Font.Gotham,
    TextSize = 9, Color = C.textLo,
    Size = UDim2.new(1, -56, 0, 14),
    Pos  = UDim2.new(0, 48, 0, 30),
    Z = 4, Parent = tpBtn,
    AlignX = Enum.TextXAlignment.Left,
})

-- Glow del boton
local tpGlow = Instance.new("Frame")
tpGlow.Size             = UDim2.new(1, 14, 1, 14)
tpGlow.Position         = UDim2.new(0, -7, 0, -7)
tpGlow.BackgroundColor3 = C.accent
tpGlow.BackgroundTransparency = 1
tpGlow.BorderSizePixel  = 0
tpGlow.ZIndex           = tpBtn.ZIndex - 1
tpGlow.Parent           = tpBtn
corner(tpGlow, 13)

-- Hover
tpBtn.MouseEnter:Connect(function()
    TweenService:Create(tpBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(30, 10, 52) }):Play()
    TweenService:Create(tpStk, TweenInfo.new(0.15), { Color = C.accent }):Play()
    TweenService:Create(tpGlow, TweenInfo.new(0.2), { BackgroundTransparency = 0.82 }):Play()
    TweenService:Create(tpIcon, TweenInfo.new(0.15), { TextColor3 = C.accentHi }):Play()
    TweenService:Create(tpMain, TweenInfo.new(0.15), { TextColor3 = C.accentHi }):Play()
end)
tpBtn.MouseLeave:Connect(function()
    TweenService:Create(tpBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(18, 6, 32) }):Play()
    TweenService:Create(tpStk, TweenInfo.new(0.15), { Color = C.accentLo }):Play()
    TweenService:Create(tpGlow, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(tpIcon, TweenInfo.new(0.15), { TextColor3 = C.accent }):Play()
    TweenService:Create(tpMain, TweenInfo.new(0.15), { TextColor3 = C.text }):Play()
end)

-- Click: rebote + teleport
tpBtn.MouseButton1Click:Connect(function()
    -- Rebote visual
    TweenService:Create(tpBtn, TweenInfo.new(0.07, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        { Size = UDim2.new(1, -30, 0, 46) }):Play()
    task.delay(0.07, function()
        TweenService:Create(tpBtn, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.new(1, -24, 0, 50) }):Play()
    end)
    -- Flash stroke
    TweenService:Create(tpStk, TweenInfo.new(0.05), { Color = C.accentHi }):Play()
    task.delay(0.3, function()
        TweenService:Create(tpStk, TweenInfo.new(0.2), { Color = C.accentLo }):Play()
    end)
    -- Texto feedback
    tpSub.Text = "Teletransportando..."
    tpSub.TextColor3 = C.accentHi
    task.delay(1.2, function()
        tpSub.Text = "Clic para teletransportar"
        tpSub.TextColor3 = C.textLo
    end)
    -- Ejecutar teleport
    local char = player.Character
    if char then teleport(char) end
end)

--------------------------------------------------
-- STATUS BAR
--------------------------------------------------

local statusBar = Instance.new("Frame")
statusBar.Size             = UDim2.new(1, 0, 0, 28)
statusBar.Position         = UDim2.new(0, 0, 1, -28)
statusBar.BackgroundColor3 = Color3.fromRGB(9, 3, 16)
statusBar.BorderSizePixel  = 0
statusBar.ZIndex           = 5
statusBar.Parent           = bodyClip
corner(statusBar, 8)

-- Línea superior status
local stLine = Instance.new("Frame")
stLine.Size             = UDim2.new(1, -24, 0, 1)
stLine.Position         = UDim2.new(0, 12, 0, 0)
stLine.BackgroundColor3 = C.accentLo
stLine.BorderSizePixel  = 0
stLine.ZIndex           = 6
stLine.Parent           = statusBar
gradient(stLine, 0, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, C.accentLo),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
}))

local sDot = Instance.new("Frame")
sDot.Size             = UDim2.new(0, 6, 0, 6)
sDot.Position         = UDim2.new(0, 12, 0.5, -3)
sDot.BackgroundColor3 = C.green
sDot.BorderSizePixel  = 0
sDot.ZIndex           = 6
sDot.Parent           = statusBar
corner(sDot, 99)
pulse(sDot, "BackgroundColor3", C.green, C.greenLo, 1.2)

mkLabel({
    Text = "Timer by: 2by  •  Prompt Skip: ON",
    Font = Enum.Font.Gotham, TextSize = 10,
    Color = C.textLo,
    Size = UDim2.new(1, -32, 1, 0),
    Pos  = UDim2.new(0, 24, 0, 0),
    Z = 6, Parent = statusBar,
    AlignX = Enum.TextXAlignment.Left,
})

--------------------------------------------------
-- MINIMIZE / MAXIMIZE
--------------------------------------------------

local function setMinimized(val)
    panelMin  = val
    minBtn.Text = val and "+" or "−"
    local pTarget = val and TH or PH
    local bTarget = val and 0  or (PH - TH - 28)
    TweenService:Create(panel,
        TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, PW, 0, pTarget) }):Play()
    TweenService:Create(bodyClip,
        TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.new(1, 0, 0, bTarget) }):Play()
end

minBtn.MouseButton1Click:Connect(function()
    setMinimized(not panelMin)
end)

--------------------------------------------------
-- DRAG
--------------------------------------------------

local dragging, dStart, dOrigin = false, nil, nil
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dStart   = i.Position
        dOrigin  = panel.Position
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
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

--------------------------------------------------
-- ENTRADA CON BOUNCE
--------------------------------------------------

TweenService:Create(panel,
    TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.new(1, -(PW + 16), 0.5, -(PH / 2)) }
):Play()

--------------------------------------------------
-- LOOP TIMER
--------------------------------------------------

task.spawn(function()
    while true do
        pcall(function()
            local e = math.max(0, math.floor(os.clock() - startTime))
            timeLabel.Text = fmtTime(e)
            -- Color oscilante
            local t = os.clock() * 0.6
            timeLabel.TextColor3 = Color3.new(
                math.sin(t)         * 0.14 + 0.76,
                math.sin(t + 2.1)   * 0.07 + 0.22,
                math.sin(t + 4.2)   * 0.14 + 0.90
            )
        end)
        task.wait(1)
    end
end)
