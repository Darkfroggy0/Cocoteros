-- LocalScript | StarterPlayerScripts
-- Version LITE: Teleport + Collision + Auto Trade + Prompt Skip + Timer

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
-- PROMPT SKIP
--------------------------------------------------

local promptSkipEnabled = false
local promptConn        = nil

local function applyPromptSkip(prompt)
    pcall(function() prompt.HoldDuration = 0 end)
end

local function enablePromptSkip()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then applyPromptSkip(obj) end
    end
    promptConn = Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then applyPromptSkip(obj) end
    end)
end

local function disablePromptSkip()
    if promptConn then
        promptConn:Disconnect()
        promptConn = nil
    end
end

--------------------------------------------------
-- AUTO TRADE
--------------------------------------------------

local autoTradeEnabled = false
local autoTradeItem    = "Sand Tiger Shark"

local function isRedItem(btn)
    for _, d in ipairs(btn:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local c = d.TextColor3
            if c.R > 0.55 and c.G < 0.38 and c.B < 0.38 then return true end
        end
        if d:IsA("ImageLabel") or d:IsA("ImageButton") then
            local c = d.ImageColor3
            if c.R > 0.55 and c.G < 0.38 and c.B < 0.38 then return true end
        end
    end
    return false
end

local function getTradeUI()
    local hud = playerGui:FindFirstChild("hud")
    if not hud then return nil end
    local sz  = hud:FindFirstChild("safezone")
    if not sz  then return nil end
    local tr  = sz:FindFirstChild("Trade")
    if not tr or not tr.Visible then return nil end
    return tr
end

local function runAutoTrade()
    task.spawn(function()
        while autoTradeEnabled do
            pcall(function()
                local tr = getTradeUI()
                if not tr then task.wait(0.5) return end

                local po   = tr:FindFirstChild("PlayerOffer")
                local list = po and po:FindFirstChild("List")
                if not list then task.wait(0.5) return end

                local offerables = list:FindFirstChild("Offerables")
                local sf         = list:FindFirstChild("ScrollingFrame")
                local addBtn     = sf and sf:FindFirstChild("_add")
                if not offerables then task.wait(0.5) return end

                if not offerables.Visible then
                    if addBtn then
                        pcall(function() addBtn:Activate() end)
                        task.wait(0.25)
                    else
                        task.wait(0.5) return
                    end
                end

                local clicked = false
                for _, btn in ipairs(offerables:GetChildren()) do
                    if not autoTradeEnabled then break end
                    if btn.Visible then
                        local hit = (btn.Name == autoTradeItem) or isRedItem(btn)
                        if hit then
                            pcall(function() btn:Activate() end)
                            clicked = true
                            task.wait(0.15)
                        end
                    end
                end
                if not clicked then task.wait(0.4) end
            end)
            task.wait(0.1)
        end
    end)
end

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
-- UI — GOTHIC PANEL
--------------------------------------------------

do
    local old = playerGui:FindFirstChild("GothicPanel")
    if old then old:Destroy() end
end

local PW, PH, TH = 274, 310, 48
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
sLabel.Text             = "Listo"
sLabel.TextColor3       = Color3.fromRGB(118, 62, 158)
sLabel.Font             = Enum.Font.Antique
sLabel.TextSize         = 11
sLabel.TextXAlignment   = Enum.TextXAlignment.Left
sLabel.ZIndex           = 6
sLabel.Parent           = statusBar

local function setStatus(msg)
    TweenService:Create(sLabel, TweenInfo.new(0.08), { TextTransparency = 1 }):Play()
    task.delay(0.09, function()
        sLabel.Text = msg
        TweenService:Create(sLabel, TweenInfo.new(0.14), { TextTransparency = 0 }):Play()
    end)
    TweenService:Create(sDot, TweenInfo.new(0.08),
        { BackgroundColor3 = Color3.fromRGB(225, 145, 255) }):Play()
    task.delay(0.45, function()
        TweenService:Create(sDot, TweenInfo.new(0.3),
            { BackgroundColor3 = Color3.fromRGB(138, 50, 190) }):Play()
    end)
end

--------------------------------------------------
-- HELPERS UI
--------------------------------------------------

local function mkSection(label, y)
    local sf = Instance.new("Frame")
    sf.Size             = UDim2.new(1, -20, 0, 22)
    sf.Position         = UDim2.new(0, 10, 0, y)
    sf.BackgroundColor3 = Color3.fromRGB(18, 6, 30)
    sf.BorderSizePixel  = 0
    sf.Parent           = body
    Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 4)
    do
        local g = Instance.new("UIGradient")
        g.Rotation = 0
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 8, 44)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 3, 18)),
        })
        g.Parent = sf
    end
    local acc = Instance.new("Frame")
    acc.Size             = UDim2.new(0, 3, 0, 13)
    acc.Position         = UDim2.new(0, 0, 0.5, -6.5)
    acc.BackgroundColor3 = Color3.fromRGB(155, 58, 210)
    acc.BorderSizePixel  = 0
    acc.Parent           = sf
    Instance.new("UICorner", acc).CornerRadius = UDim.new(0, 2)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -14, 1, 0)
    lbl.Position         = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextColor3       = Color3.fromRGB(155, 88, 200)
    lbl.Font             = Enum.Font.Antique
    lbl.TextSize         = 12
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = sf
end

local function mkInput(placeholder, y)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -20, 0, 34)
    frame.Position         = UDim2.new(0, 10, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(10, 4, 17)
    frame.BorderSizePixel  = 0
    frame.Parent           = body
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local fStk = Instance.new("UIStroke")
    fStk.Thickness = 1; fStk.Color = Color3.fromRGB(50, 16, 70); fStk.Parent = frame

    local icon = Instance.new("TextLabel")
    icon.Size             = UDim2.new(0, 22, 1, 0)
    icon.Position         = UDim2.new(0, 6, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text             = "✎"
    icon.TextColor3       = Color3.fromRGB(92, 40, 124)
    icon.Font             = Enum.Font.Antique
    icon.TextSize         = 15
    icon.Parent           = frame

    local box = Instance.new("TextBox")
    box.Size             = UDim2.new(1, -36, 1, 0)
    box.Position         = UDim2.new(0, 30, 0, 0)
    box.BackgroundTransparency = 1
    box.PlaceholderText  = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(72, 40, 96)
    box.Text             = ""
    box.TextColor3       = Color3.fromRGB(212, 170, 242)
    box.Font             = Enum.Font.Antique
    box.TextSize         = 13
    box.TextXAlignment   = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent           = frame
    box.Focused:Connect(function()
        TweenService:Create(fStk, TweenInfo.new(0.15),
            { Color = Color3.fromRGB(162, 60, 225) }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(fStk, TweenInfo.new(0.15),
            { Color = Color3.fromRGB(50, 16, 70) }):Play()
    end)
    return box
end

local function mkToggle(label, y, cb)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -20, 0, 36)
    btn.Position         = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(14, 5, 23)
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.Parent           = body
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local bs = Instance.new("UIStroke")
    bs.Thickness = 1; bs.Color = Color3.fromRGB(50, 16, 70); bs.Parent = btn

    local glow = Instance.new("Frame")
    glow.Size             = UDim2.new(1, 8, 1, 8)
    glow.Position         = UDim2.new(0, -4, 0, -4)
    glow.BackgroundColor3 = Color3.fromRGB(128, 40, 180)
    glow.BackgroundTransparency = 1
    glow.BorderSizePixel  = 0
    glow.ZIndex           = btn.ZIndex - 1
    glow.Parent           = btn
    Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -58, 1, 0)
    lbl.Position         = UDim2.new(0, 13, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextColor3       = Color3.fromRGB(168, 122, 208)
    lbl.Font             = Enum.Font.Antique
    lbl.TextSize         = 14
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = btn

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 40, 0, 20)
    track.Position         = UDim2.new(1, -52, 0.5, -10)
    track.BackgroundColor3 = Color3.fromRGB(22, 8, 35)
    track.BorderSizePixel  = 0
    track.Parent           = btn
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    do
        local s = Instance.new("UIStroke")
        s.Thickness = 1; s.Color = Color3.fromRGB(58, 19, 82); s.Parent = track
    end

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 14, 0, 14)
    dot.Position         = UDim2.new(0, 3, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(82, 30, 108)
    dot.BorderSizePixel  = 0
    dot.Parent           = track
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local active = false
    local function setActive(v)
        active = v
        TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quart),
            { BackgroundColor3 = v and Color3.fromRGB(108, 34, 162) or Color3.fromRGB(22, 8, 35) }):Play()
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundColor3 = v and Color3.fromRGB(228, 148, 255) or Color3.fromRGB(82, 30, 108),
            Position         = v and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        }):Play()
        TweenService:Create(bs, TweenInfo.new(0.2),
            { Color = v and Color3.fromRGB(162, 60, 225) or Color3.fromRGB(50, 16, 70) }):Play()
        TweenService:Create(glow, TweenInfo.new(0.25),
            { BackgroundTransparency = v and 0.80 or 1 }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.2),
            { TextColor3 = v and Color3.fromRGB(228, 178, 255) or Color3.fromRGB(168, 122, 208) }):Play()
    end
    btn.MouseButton1Click:Connect(function() setActive(not active); cb(active) end)
    btn.MouseEnter:Connect(function()
        if not active then TweenService:Create(btn, TweenInfo.new(0.1),
            { BackgroundColor3 = Color3.fromRGB(20, 7, 32) }):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if not active then TweenService:Create(btn, TweenInfo.new(0.1),
            { BackgroundColor3 = Color3.fromRGB(14, 5, 23) }):Play() end
    end)
    return btn, setActive
end

--------------------------------------------------
-- SECCIONES
--------------------------------------------------

-- [1] TIMER BOX  y=4..58
mkSection("❧  Farm Timer", 4)

local timerBox = Instance.new("Frame")
timerBox.Size             = UDim2.new(1, -20, 0, 34)
timerBox.Position         = UDim2.new(0, 10, 0, 30)
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
timeLabel.TextSize         = 22
timeLabel.TextXAlignment   = Enum.TextXAlignment.Center
timeLabel.TextYAlignment   = Enum.TextYAlignment.Center
timeLabel.Text             = "00:00:00"
timeLabel.TextColor3       = Color3.fromRGB(195, 105, 250)
timeLabel.Parent           = timerBox

-- [2] PROMPT SKIP  y=74..122
mkSection("❧  Prompts", 74)
mkToggle("Skip Hold Instant", 100, function(v)
    promptSkipEnabled = v
    if v then enablePromptSkip(); setStatus("Prompts: Instant")
    else      disablePromptSkip(); setStatus("Prompts: Normal") end
end)

-- [3] AUTO TRADE  y=148..286
mkSection("❧  Auto Trade", 148)
local tradeInput = mkInput("Nombre del item...", 174)
tradeInput.Text  = autoTradeItem
mkToggle("Auto Click Trade", 214, function(v)
    autoTradeEnabled = v
    if v then
        if tradeInput.Text ~= "" then autoTradeItem = tradeInput.Text end
        runAutoTrade()
        setStatus("Trade activo: " .. autoTradeItem)
    else
        setStatus("Trade detenido")
    end
end)

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
-- LOOP TIMER (liviano, solo actualiza el label)
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
