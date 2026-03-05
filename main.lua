-- LocalScript dentro de StarterPlayerScripts
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

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
