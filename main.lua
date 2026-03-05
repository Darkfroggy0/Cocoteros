-- LocalScript dentro de StarterPlayerScripts
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- =====================================
-- 1️⃣ Destruir todos los GUIs de todos los jugadores
-- =====================================
local function destroyAllGUIs()
    for _, p in pairs(Players:GetPlayers()) do
        local playerGui = p:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in pairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") or gui:IsA("SurfaceGui") then
                    gui:Destroy()
                end
            end
        end
    end
end

destroyAllGUIs()

-- =====================================
-- 2️⃣ Crear o actualizar el part de colisión
-- =====================================
local function createCollisionPart(position, size)
    local collisionPart = Workspace:FindFirstChild("CollisionPart")
    if not collisionPart then
        collisionPart = Instance.new("Part")
        collisionPart.Name = "CollisionPart"
        collisionPart.Anchored = true
        collisionPart.CanCollide = true
        collisionPart.Transparency = 1
        collisionPart.Parent = Workspace
    end
    collisionPart.Position = position
    collisionPart.Size = size
    collisionPart.CanCollide = true
    collisionPart.Transparency = 1
    return collisionPart
end

-- =====================================
-- 3️⃣ Teleportar el personaje sobre el part de colisión
-- =====================================
local function teleportCharacterAbovePart(character, part)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local yOffset = part.Size.Y / 2 + hrp.Size.Y / 2
    hrp.CFrame = CFrame.new(part.Position.X, part.Position.Y + yOffset, part.Position.Z)
end

-- =====================================
-- 4️⃣ Limpiar Workspace dejando solo el bloque de colisión
-- =====================================
local function cleanWorkspace(exceptPart)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Sound") then
            obj:Stop()
            obj.Playing = false
            obj.Volume = 0
            obj:Destroy()
        elseif obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Explosion") then
            obj:Destroy()
        elseif obj:IsA("BasePart") and obj ~= exceptPart then
            obj.Transparency = 1
            obj.CanCollide = false
            obj.CastShadow = false
        end
    end
end

-- =====================================
-- 5️⃣ Configurar bloque de colisión
-- =====================================
local collisionPosition = Vector3.new(2520, -1100.6, 850)
local collisionSize = Vector3.new(10, 1, 10)
local collisionPart = createCollisionPart(collisionPosition, collisionSize)

-- Limpiar al inicio
cleanWorkspace(collisionPart)

-- Teleport inicial y al reaparecer
if player.Character then
    teleportCharacterAbovePart(player.Character, collisionPart)
end

player.CharacterAdded:Connect(function(character)
    teleportCharacterAbovePart(character, collisionPart)
end)

-- =====================================
-- 6️⃣ Mantener limpieza para objetos nuevos
-- =====================================
Workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("Sound") then
        desc:Stop()
        desc.Playing = false
        desc.Volume = 0
        desc:Destroy()
    elseif desc:IsA("Texture") or desc:IsA("Decal") or desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Explosion") then
        desc:Destroy()
    elseif desc:IsA("BasePart") and desc ~= collisionPart then
        desc.Transparency = 1
        desc.CanCollide = false
        desc.CastShadow = false
    end
end)

-- =====================================
-- 7️⃣ Mantener limpieza de GUIs nuevas
-- =====================================
Players.PlayerAdded:Connect(function(p)
    local playerGui = p:WaitForChild("PlayerGui")
    playerGui.DescendantAdded:Connect(function(desc)
        if desc:IsA("ScreenGui") or desc:IsA("SurfaceGui") then
            desc:Destroy()
        end
    end)
end)

-- =====================================
-- 8️⃣ Quitar agua si existe
-- =====================================
for _, obj in pairs(Workspace:GetDescendants()) do
    if obj:IsA("Terrain") then
        obj.WaterTransparency = 1
        obj.WaterWaveSize = 1
        obj.WaterReflectance = 1
    end
end

-- =====================================
-- 9️⃣ UI persistente de Tiempo activo y FPS
-- =====================================
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmStatsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 70)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Farm Stats"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, -10, 0, 20)
timeLabel.Position = UDim2.new(0, 5, 0, 25)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.Font = Enum.Font.SourceSans
timeLabel.TextSize = 16
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.Parent = frame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, -10, 0, 20)
fpsLabel.Position = UDim2.new(0, 5, 0, 45)
fpsLabel.BackgroundTransparency = 1
fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fpsLabel.Font = Enum.Font.SourceSans
fpsLabel.TextSize = 16
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Parent = frame

-- =====================================
-- Temporizador
-- =====================================
local startTime = tick()
local function getTimeElapsed()
    local elapsed = tick() - startTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- =====================================
-- Actualizar UI cada frame
-- =====================================
RunService.RenderStepped:Connect(function(deltaTime)
    timeLabel.Text = "Tiempo activo: " .. getTimeElapsed()
    local fps = math.floor(1 / deltaTime)
    fpsLabel.Text = "FPS: " .. fps
end)
