-- LocalScript | StarterPlayerScripts
-- Farm optimizado + Panel Gotico

local Players               = game:GetService("Players")
local Workspace             = game:GetService("Workspace")
local RunService            = game:GetService("RunService")
local UserInputService      = game:GetService("UserInputService")
local Lighting              = game:GetService("Lighting")
local TeleportService       = game:GetService("TeleportService")
local SoundService          = game:GetService("SoundService")
local StarterGui            = game:GetService("StarterGui")
local ProximityPromptService= game:GetService("ProximityPromptService")
local TweenService          = game:GetService("TweenService")

local player   = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local CFG = {
    FPS_NORMAL     = 30,
    FPS_MINIMIZED  = 5,
    TICK_NORMAL    = 1,
    TICK_MINIMIZED = 10,
    BACKPACK_DELAY = 3,
    AUTO_REJOIN    = true,
    REJOIN_DELAY   = 5,
    COLLISION_POS  = Vector3.new(2520, -1100.6, 850),
    COLLISION_SIZE = Vector3.new(10, 1, 10),
}

--------------------------------------------------
-- ESTADO GLOBAL
--------------------------------------------------

local running        = true
local minimized      = false
local character      = player.Character
local itemsDeleted   = 0
local startTime      = os.clock()
local hoursElapsed   = 0
local connections    = {}
local ownedInstances = {}
local backpackReady  = false

-- Estado del panel gotico
local promptSkipEnabled = false
local followEnabled     = false
local autoTradeEnabled  = false
local followTarget      = nil
local autoTradeItem     = "Sand Tiger Shark"
local FOLLOW_OFFSET     = CFrame.new(0, 0.5, 3.2)

--------------------------------------------------
-- FPS
--------------------------------------------------

local function setFPS(fps)
    pcall(function() RunService:SetRobloxFPSCap(fps) end)
    pcall(function() settings().Rendering.FrameRateManager = 0 end)
    pcall(function() settings().Rendering.MaxFrameRate = fps end)
end

setFPS(CFG.FPS_NORMAL)

--------------------------------------------------
-- OCULTAR BACKPACK UI
--------------------------------------------------

local function hideBackpackUI()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

hideBackpackUI()

--------------------------------------------------
-- LIGHTING Y AGUA
--------------------------------------------------

pcall(function()
    Lighting.GlobalShadows            = false
    Lighting.FogEnd                   = 9e9
    Lighting.Brightness               = 0
    Lighting.EnvironmentDiffuseScale  = 0
    Lighting.EnvironmentSpecularScale = 0
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Atmosphere")
        or v:IsA("BloomEffect") or v:IsA("BlurEffect")
        or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect")
        or v:IsA("DepthOfFieldEffect") then
            v:Destroy()
        end
    end
end)

pcall(function()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterTransparency = 1
        terrain.WaterReflectance  = 0
        terrain.WaterWaveSize     = 0
        terrain.WaterWaveSpeed    = 0
        terrain.WaterColor        = Color3.new(0, 0, 0)
        terrain.Decoration        = false
    end
end)

--------------------------------------------------
-- SONIDOS
--------------------------------------------------

local function killSounds(parent)
    pcall(function()
        for _, obj in ipairs(parent:GetDescendants()) do
            pcall(function()
                if obj:IsA("Sound") then
                    obj.Volume = 0
                    obj:Stop()
                    obj:Destroy()
                end
            end)
        end
    end)
end

pcall(function()
    SoundService.AmbientReverb  = Enum.ReverbType.NoReverb
    SoundService.DistanceFactor = 0
    SoundService.DopplerScale   = 0
    SoundService.RolloffScale   = 0
end)

killSounds(Workspace)
killSounds(SoundService)

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
            local hrp      = char:WaitForChild("HumanoidRootPart", 10)
            local humanoid = char:WaitForChild("Humanoid", 10)
            if not hrp or not humanoid then return end

            collisionPart.CanCollide = true
            collisionPart.Anchored   = true
            collisionPart.Parent     = Workspace

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

if character then teleport(character) end

--------------------------------------------------
-- VFX CLEANER
--------------------------------------------------

local VFX_CLASSES = {
    Sound = true, Texture = true, Decal = true,
    ParticleEmitter = true, Trail = true, Explosion = true,
    Smoke = true, Fire = true, Sparkles = true,
    SelectionBox = true, BillboardGui = true, SurfaceGui = true,
    PointLight = true, SpotLight = true, SurfaceLight = true,
}

local function isProtected(obj)
    if obj == collisionPart then return true end
    if character and obj:IsDescendantOf(character) then return true end
    return false
end

local function processObj(obj)
    pcall(function()
        if not obj or not obj.Parent then return end
        if isProtected(obj) then return end
        local cn = obj.ClassName
        if VFX_CLASSES[cn] then
            if cn == "Sound" then obj.Volume = 0; obj:Stop() end
            obj:Destroy()
            return
        end
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CanCollide   = false
            obj.CastShadow   = false
        end
    end)
end

local function cleanWorkspace()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        processObj(obj)
    end
end

cleanWorkspace()

connections.wsAdded = Workspace.DescendantAdded:Connect(function(obj)
    pcall(function()
        if obj == collisionPart then
            collisionPart.CanCollide   = true
            collisionPart.Transparency = 1
            return
        end
        if obj:IsA("Sound") then
            obj.Volume = 0; obj:Stop(); obj:Destroy()
            return
        end
        processObj(obj)
    end)
end)

connections.svcAdded = SoundService.DescendantAdded:Connect(function(obj)
    pcall(function()
        if obj:IsA("Sound") then
            obj.Volume = 0; obj:Stop(); obj:Destroy()
        end
    end)
end)

connections.lightAdded = Lighting.DescendantAdded:Connect(function(obj)
    pcall(function()
        if obj:IsA("Sky") or obj:IsA("Atmosphere")
        or obj:IsA("BloomEffect") or obj:IsA("BlurEffect")
        or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect")
        or obj:IsA("DepthOfFieldEffect") then
            obj:Destroy()
        end
    end)
end)

--------------------------------------------------
-- BACKPACK CLEANER
--------------------------------------------------

local function buildOwnedList()
    ownedInstances = {}
    for _, item in ipairs(backpack:GetChildren()) do
        ownedInstances[item] = true
    end
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                ownedInstances[item] = true
            end
        end
    end
    backpackReady = true
end

local function handleCharacterTool(item)
    pcall(function()
        if not item or not item.Parent then return end
        if not item:IsA("Tool") then return end
        if ownedInstances[item] then return end
        item:Destroy()
        itemsDeleted += 1
    end)
end

task.delay(CFG.BACKPACK_DELAY, function()
    if not running then return end
    buildOwnedList()
    hideBackpackUI()

    connections.backpackAdded = backpack.ChildAdded:Connect(function(item)
        pcall(function()
            if not item or not item.Parent then return end
            if ownedInstances[item] then return end
            item:Destroy()
            itemsDeleted += 1
        end)
    end)

    if character then
        connections.charToolAdded = character.ChildAdded:Connect(handleCharacterTool)
    end
end)

--------------------------------------------------
-- CHARACTER ADDED
--------------------------------------------------

connections.charAdded = player.CharacterAdded:Connect(function(char)
    character = char
    hideBackpackUI()
    task.wait(0.5)
    teleport(char)
    cleanWorkspace()
    killSounds(Workspace)

    if connections.charToolAdded then
        connections.charToolAdded:Disconnect()
    end
    if backpackReady then
        connections.charToolAdded = char.ChildAdded:Connect(handleCharacterTool)
    end

    task.delay(CFG.BACKPACK_DELAY, function()
        buildOwnedList()
        hideBackpackUI()
        if not connections.charToolAdded then
            connections.charToolAdded = char.ChildAdded:Connect(handleCharacterTool)
        end
    end)
end)

--------------------------------------------------
-- FOCUS / MINIMIZE
--------------------------------------------------

connections.focusLost = UserInputService.WindowFocusReleased:Connect(function()
    minimized = true
    setFPS(CFG.FPS_MINIMIZED)
end)

connections.focusGained = UserInputService.WindowFocused:Connect(function()
    minimized = false
    setFPS(CFG.FPS_NORMAL)
end)

--------------------------------------------------
-- DISCONNECT / KICK
--------------------------------------------------

connections.ancestry = player.AncestryChanged:Connect(function()
    if player.Parent then return end
    running = false
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    if CFG.AUTO_REJOIN then
        task.wait(CFG.REJOIN_DELAY)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
    end
end)

--------------------------------------------------
-- PANEL GOTICO - FUNCIONES
--------------------------------------------------

-- PROMPT SKIP
local function applyPromptSkip(prompt)
    pcall(function() prompt.HoldDuration = 0 end)
end

local function enablePromptSkip()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then applyPromptSkip(obj) end
    end
    connections.promptAdded = Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then applyPromptSkip(obj) end
    end)
end

local function disablePromptSkip()
    if connections.promptAdded then
        connections.promptAdded:Disconnect()
        connections.promptAdded = nil
    end
end

-- FOLLOW PLAYER
local function startFollow(targetName)
    if connections.followLoop then
        connections.followLoop:Disconnect()
        connections.followLoop = nil
    end
    local targetPlayer = Players:FindFirstChild(targetName)
    if not targetPlayer then return false end

    followTarget = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()

    connections.targetRespawn = targetPlayer.CharacterAdded:Connect(function(newChar)
        followTarget = newChar
    end)

    connections.followLoop = RunService.Heartbeat:Connect(function()
        pcall(function()
            local myChar = player.Character
            if not myChar or not followTarget then return end
            local myHRP     = myChar:FindFirstChild("HumanoidRootPart")
            local targetHRP = followTarget:FindFirstChild("HumanoidRootPart")
            if not myHRP or not targetHRP then return end
            myHRP.Anchored = true
            myHRP.CFrame   = targetHRP.CFrame * FOLLOW_OFFSET
        end)
    end)
    return true
end

local function stopFollow()
    if connections.followLoop then
        connections.followLoop:Disconnect()
        connections.followLoop = nil
    end
    if connections.targetRespawn then
        connections.targetRespawn:Disconnect()
        connections.targetRespawn = nil
    end
    followTarget = nil
    pcall(function()
        local myChar = player.Character
        if myChar then
            local hrp = myChar:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end
    end)
end

-- AUTO TRADE
-- Estructura del trade UI segun el codigo del juego:
--   hud.safezone.Trade
--     PlayerOffer.List.ScrollingFrame        <- items ya ofrecidos
--     PlayerOffer.List.ScrollingFrame._add   <- boton para abrir offerables
--     PlayerOffer.List.Offerables            <- items disponibles para ofrecer
-- Los items en Offerables tienen Name = nombre del pez (ej: "Sand Tiger Shark")
-- Hay que activar la vista de offerables primero, luego clickear

local function getTradeUI()
    local hud = playerGui:FindFirstChild("hud")
    if not hud then return nil end
    local safezone = hud:FindFirstChild("safezone")
    if not safezone then return nil end
    local trade = safezone:FindFirstChild("Trade")
    if not trade or not trade.Visible then return nil end
    return trade
end

local function getTradeOfferables(trade)
    local po = trade:FindFirstChild("PlayerOffer")
    if not po then return nil, nil end
    local list = po:FindFirstChild("List")
    if not list then return nil, nil end
    local offerables = list:FindFirstChild("Offerables")
    local addBtn     = list:FindFirstChild("ScrollingFrame")
        and list.ScrollingFrame:FindFirstChild("_add")
    return offerables, addBtn
end


--------------------------------------------------
-- AUTO TRADE
-- Clickea items que sean "Sand Tiger Shark" o
-- que contengan texto/imagen con tono rojo
--------------------------------------------------

local playerGui = player:WaitForChild("PlayerGui")

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

                -- Abrir vista de offerables si está oculta
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
-- HELPERS
--------------------------------------------------

local function getElapsed()
    return math.max(0, math.floor(os.clock() - startTime))
end

local function fmtTime(e)
    return string.format("%02d:%02d:%02d",
        math.floor(e / 3600),
        math.floor((e % 3600) / 60),
        e % 60)
end

-- Oscila en paleta morado/violeta acorde al tema
local function timerColor()
    local t = os.clock() * 0.7
    return Color3.new(
        math.sin(t)         * 0.18 + 0.72,
        math.sin(t + 2.1)   * 0.09 + 0.25,
        math.sin(t + 4.2)   * 0.18 + 0.88
    )
end

--------------------------------------------------
-- UI — FARM WIDGET (arriba izquierda)
--------------------------------------------------

do
    local old = playerGui:FindFirstChild("FarmUI")
    if old then old:Destroy() end
end

local farmSG = Instance.new("ScreenGui")
farmSG.Name           = "FarmUI"
farmSG.ResetOnSpawn   = false
farmSG.DisplayOrder   = 1
farmSG.Parent         = playerGui

local fFrame = Instance.new("Frame")
fFrame.Size              = UDim2.new(0, 248, 0, 88)
fFrame.Position          = UDim2.new(0, -260, 0, 14)   -- empieza fuera, animado
fFrame.BackgroundColor3  = Color3.fromRGB(7, 3, 12)
fFrame.BorderSizePixel   = 0
fFrame.ClipsDescendants  = true
fFrame.Parent            = farmSG
Instance.new("UICorner", fFrame).CornerRadius = UDim.new(0, 8)

-- Degradado de fondo
do
    local g = Instance.new("UIGradient")
    g.Rotation = 135
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 5, 24)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(7,  2, 12)),
    })
    g.Parent = fFrame
end

-- Borde pulsante
local fStroke = Instance.new("UIStroke")
fStroke.Thickness = 1.5
fStroke.Color     = Color3.fromRGB(95, 30, 128)
fStroke.Parent    = fFrame

-- Barra shimmer superior
local fShim = Instance.new("Frame")
fShim.Size             = UDim2.new(1, 0, 0, 3)
fShim.BackgroundColor3 = Color3.fromRGB(160, 60, 220)
fShim.BorderSizePixel  = 0
fShim.ZIndex           = 3
fShim.Parent           = fFrame
do
    local g = Instance.new("UIGradient")
    g.Rotation = 0
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(45, 10, 72)),
        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(200, 90, 255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(45, 10, 72)),
    })
    g.Parent = fShim
end

-- Título
local fTitle = Instance.new("TextLabel")
fTitle.Size             = UDim2.new(1, -10, 0, 20)
fTitle.Position         = UDim2.new(0, 10, 0, 7)
fTitle.BackgroundTransparency = 1
fTitle.Text             = "✦  Farm Activo"
fTitle.TextColor3       = Color3.fromRGB(140, 75, 185)
fTitle.Font             = Enum.Font.Antique
fTitle.TextSize         = 12
fTitle.TextXAlignment   = Enum.TextXAlignment.Left
fTitle.Parent           = fFrame

-- Caja del timer
local fTimerBox = Instance.new("Frame")
fTimerBox.Size             = UDim2.new(1, -18, 0, 33)
fTimerBox.Position         = UDim2.new(0, 9, 0, 29)
fTimerBox.BackgroundColor3 = Color3.fromRGB(5, 2, 9)
fTimerBox.BorderSizePixel  = 0
fTimerBox.Parent           = fFrame
Instance.new("UICorner", fTimerBox).CornerRadius = UDim.new(0, 5)
do
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color     = Color3.fromRGB(65, 20, 92)
    s.Parent    = fTimerBox
end

local timeLabel = Instance.new("TextLabel")
timeLabel.Size             = UDim2.new(1, 0, 1, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Font             = Enum.Font.Antique
timeLabel.TextSize         = 23
timeLabel.TextXAlignment   = Enum.TextXAlignment.Center
timeLabel.TextYAlignment   = Enum.TextYAlignment.Center
timeLabel.Text             = "00:00:00"
timeLabel.TextColor3       = Color3.fromRGB(195, 105, 250)
timeLabel.Parent           = fTimerBox

-- Contador items
local itemsLabel = Instance.new("TextLabel")
itemsLabel.Size             = UDim2.new(1, -18, 0, 14)
itemsLabel.Position         = UDim2.new(0, 9, 0, 68)
itemsLabel.BackgroundTransparency = 1
itemsLabel.Font             = Enum.Font.Antique
itemsLabel.TextSize         = 11
itemsLabel.TextXAlignment   = Enum.TextXAlignment.Left
itemsLabel.TextColor3       = Color3.fromRGB(95, 48, 130)
itemsLabel.Text             = "Items eliminados: 0"
itemsLabel.Parent           = fFrame

-- Entrada con rebote
TweenService:Create(fFrame,
    TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.new(0, 14, 0, 14) }
):Play()

-- Pulso borde farm
task.spawn(function()
    while true do
        TweenService:Create(fStroke, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Color = Color3.fromRGB(50, 14, 72) }):Play()
        task.wait(2.4)
        TweenService:Create(fStroke, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Color = Color3.fromRGB(148, 52, 205) }):Play()
        task.wait(2.4)
    end
end)

--------------------------------------------------
-- UI — GOTHIC PANEL
-- Arquitectura: ScreenGui > wrapper (solo titulo
-- cuando minimizado) > titleBar + bodyClip
-- bodyClip hace ClipsDescendants para que los
-- elementos del body no sobresalgan al colapsar
--------------------------------------------------

do
    local old = playerGui:FindFirstChild("GothicPanel")
    if old then old:Destroy() end
end

local SG = Instance.new("ScreenGui")
SG.Name          = "GothicPanel"
SG.ResetOnSpawn  = false
SG.DisplayOrder  = 999
SG.Parent        = playerGui

local PW, PH, TH = 274, 400, 48
local panelIsMin  = false

-- Panel raíz: NO tiene ClipsDescendants
-- Así el título se ve siempre bien
local panel = Instance.new("Frame")
panel.Name             = "GPanel"
panel.Size             = UDim2.new(0, PW, 0, PH)
panel.Position         = UDim2.new(1, PW + 20, 0.5, -(PH / 2))  -- off-screen
panel.BackgroundColor3 = Color3.fromRGB(7, 3, 12)
panel.BorderSizePixel  = 0
panel.ClipsDescendants = false   -- IMPORTANTE: false para no cortar ornamentos
panel.Parent           = SG
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

do
    local g = Instance.new("UIGradient")
    g.Rotation = 142
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(14,  4, 24)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8,   3, 13)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(18,  5, 28)),
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

-- Ornamentos esquina (siempre visibles, fuera del clip)
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
local ornBR = mkOrn(1, 1, -21,-21)

--------------------------------------------------
-- TITULO (siempre sobre el clip)
--------------------------------------------------

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

-- Línea decorativa bajo título
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

-- Botón minimizar
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
    s.Thickness = 1
    s.Color     = Color3.fromRGB(72, 23, 100)
    s.Parent    = minBtn
end
minBtn.MouseEnter:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.1),
        { BackgroundColor3 = Color3.fromRGB(52, 17, 80) }):Play()
end)
minBtn.MouseLeave:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.1),
        { BackgroundColor3 = Color3.fromRGB(26, 8, 42) }):Play()
end)

--------------------------------------------------
-- BODY CLIP
-- Frame con ClipsDescendants que se anima
-- junto con el panel para ocultar el cuerpo
--------------------------------------------------

local bodyClip = Instance.new("Frame")
bodyClip.Name             = "BodyClip"
bodyClip.Size             = UDim2.new(1, 0, 1, -TH - 26)
bodyClip.Position         = UDim2.new(0, 0, 0, TH)
bodyClip.BackgroundTransparency = 1
bodyClip.BorderSizePixel  = 0
bodyClip.ClipsDescendants = true   -- clip solo aquí
bodyClip.Parent           = panel

-- Status bar (dentro del bodyClip, pegada al fondo)
local statusBar = Instance.new("Frame")
statusBar.Size             = UDim2.new(1, 0, 0, 26)
statusBar.Position         = UDim2.new(0, 0, 1, -26)
statusBar.BackgroundColor3 = Color3.fromRGB(12, 4, 20)
statusBar.BorderSizePixel  = 0
statusBar.ZIndex           = 5
statusBar.Parent           = bodyClip
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 6)
do
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(1, -24, 0, 1)
    d.Position         = UDim2.new(0, 12, 0, 0)
    d.BackgroundColor3 = Color3.fromRGB(52, 17, 74)
    d.BorderSizePixel  = 0
    d.ZIndex           = 6
    d.Parent           = statusBar
end

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
    TweenService:Create(sLabel, TweenInfo.new(0.08),
        { TextTransparency = 1 }):Play()
    task.delay(0.09, function()
        sLabel.Text = msg
        TweenService:Create(sLabel, TweenInfo.new(0.14),
            { TextTransparency = 0 }):Play()
    end)
    TweenService:Create(sDot, TweenInfo.new(0.08),
        { BackgroundColor3 = Color3.fromRGB(225, 145, 255) }):Play()
    task.delay(0.45, function()
        TweenService:Create(sDot, TweenInfo.new(0.3),
            { BackgroundColor3 = Color3.fromRGB(138, 50, 190) }):Play()
    end)
end

-- Body (contenido de secciones, dentro del bodyClip)
local body = Instance.new("Frame")
body.Size             = UDim2.new(1, 0, 1, -26)  -- deja espacio para status
body.BackgroundTransparency = 1
body.BorderSizePixel  = 0
body.Parent           = bodyClip

--------------------------------------------------
-- MINIMIZE / MAXIMIZE
-- Anima panel + bodyClip juntos
--------------------------------------------------

local function setMinimized(val)
    panelIsMin  = val
    minBtn.Text = val and "+" or "−"
    local panelTarget = val and TH or PH
    local bodyTarget  = val and 0 or (PH - TH - 26)
    -- Panel se encoge
    TweenService:Create(panel,
        TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, PW, 0, panelTarget) }
    ):Play()
    -- bodyClip se encoge en paralelo para que el clip funcione bien
    TweenService:Create(bodyClip,
        TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        { Size = UDim2.new(1, 0, 0, bodyTarget) }
    ):Play()
    -- Ornamentos de abajo se ocultan cuando minimizado
    local ornTrans = val and 1 or 0
    TweenService:Create(ornBL, TweenInfo.new(0.15),
        { TextTransparency = ornTrans }):Play()
    TweenService:Create(ornBR, TweenInfo.new(0.15),
        { TextTransparency = ornTrans }):Play()
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
-- HELPERS UI (crean elementos en body)
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
        TweenService:Create(icon, TweenInfo.new(0.15),
            { TextColor3 = Color3.fromRGB(188, 108, 240) }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(fStk, TweenInfo.new(0.15),
            { Color = Color3.fromRGB(50, 16, 70) }):Play()
        TweenService:Create(icon, TweenInfo.new(0.15),
            { TextColor3 = Color3.fromRGB(92, 40, 124) }):Play()
    end)
    return box
end

local function mkActionBtn(label, y, cb)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -20, 0, 32)
    btn.Position         = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(42, 13, 65)
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.Parent           = body
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    do
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(62, 20, 96)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 10, 52)),
        })
        g.Parent = btn
    end
    local bStk = Instance.new("UIStroke")
    bStk.Thickness = 1; bStk.Color = Color3.fromRGB(118, 42, 168); bStk.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextColor3       = Color3.fromRGB(215, 165, 255)
    lbl.Font             = Enum.Font.Antique
    lbl.TextSize         = 13
    lbl.Parent           = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1),
            { BackgroundColor3 = Color3.fromRGB(64, 20, 96) }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.1),
            { TextColor3 = Color3.fromRGB(238, 192, 255) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1),
            { BackgroundColor3 = Color3.fromRGB(42, 13, 65) }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.1),
            { TextColor3 = Color3.fromRGB(215, 165, 255) }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.06),
            { BackgroundColor3 = Color3.fromRGB(96, 30, 142) }):Play()
        task.delay(0.07, function()
            TweenService:Create(btn, TweenInfo.new(0.18),
                { BackgroundColor3 = Color3.fromRGB(42, 13, 65) }):Play()
        end)
        cb()
    end)
    return btn
end

--------------------------------------------------
-- SECCIONES
--------------------------------------------------

mkSection("❧  Prompts",       4)
mkToggle("Skip Hold Instant",  30, function(v)
    promptSkipEnabled = v
    if v then enablePromptSkip(); setStatus("Prompts: Instant")
    else disablePromptSkip(); setStatus("Prompts: Normal") end
end)

mkSection("❧  Follow Player", 82)
local followInput = mkInput("Nombre del jugador...", 108)
mkActionBtn("⚔  Seguir / Detener", 148, function()
    local name = followInput.Text
    if name == "" then setStatus("Escribe un nombre") return end
    if not followEnabled then
        local ok = startFollow(name)
        if ok then followEnabled = true; setStatus("Siguiendo: " .. name)
        else setStatus("No encontrado") end
    else
        stopFollow(); followEnabled = false; setStatus("Follow detenido")
    end
end)

mkSection("❧  Auto Trade",    196)
local tradeInput = mkInput("Nombre del item...", 222)
tradeInput.Text  = autoTradeItem
mkToggle("Auto Click Trade",  262, function(v)
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
-- ANIMACIONES CONTINUAS
--------------------------------------------------

-- Entrada con rebote
TweenService:Create(panel,
    TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.new(1, -(PW + 14), 0.5, -(PH / 2)) }
):Play()

-- Pulso borde exterior
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

-- Shimmer
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

-- Titulo breathing
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

-- Ornamentos
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

-- Dot de status
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
-- LOOP MAESTRO
--------------------------------------------------

task.spawn(function()
    while running do
        local dt = minimized and CFG.TICK_MINIMIZED or CFG.TICK_NORMAL
        pcall(function()
            local e = getElapsed()
            timeLabel.Text       = fmtTime(e)
            timeLabel.TextColor3 = timerColor()
            itemsLabel.Text      = "Items eliminados: " .. itemsDeleted

            local h = math.floor(e / 3600)
            if h > hoursElapsed then
                hoursElapsed   = h
                fTitle.Text    = string.format("✦  Farm  |  %dh activo", h)
            end
        end)
        task.wait(dt)
    end
end)
