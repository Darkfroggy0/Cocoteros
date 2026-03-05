-- LocalScript dentro de StarterPlayerScripts
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer


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


local function teleportCharacterAbovePart(character, part)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local yOffset = part.Size.Y / 2 + hrp.Size.Y / 2
    hrp.CFrame = CFrame.new(part.Position.X, part.Position.Y + yOffset, part.Position.Z)
end


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


local collisionPosition = Vector3.new(2520, -1100.6, 850)
local collisionSize = Vector3.new(10, 1, 10)
local collisionPart = createCollisionPart(collisionPosition, collisionSize)


cleanWorkspace(collisionPart)


if player.Character then
    teleportCharacterAbovePart(player.Character, collisionPart)
end

player.CharacterAdded:Connect(function(character)
    teleportCharacterAbovePart(character, collisionPart)
end)


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


Players.PlayerAdded:Connect(function(p)
    local playerGui = p:WaitForChild("PlayerGui")
    playerGui.DescendantAdded:Connect(function(desc)
        if desc:IsA("ScreenGui") or desc:IsA("SurfaceGui") then
            desc:Destroy()
        end
    end)
end)


for _, obj in pairs(Workspace:GetDescendants()) do
    if obj:IsA("Terrain") then
        obj.WaterTransparency = 1
        obj.WaterWaveSize = 1
        obj.WaterReflectance = 1
    end
end


RunService:SetRobloxFPSCap(30)


local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmStatsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 60)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⏱ Farm Activa"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Bodoni
title.TextSize = 18
title.Parent = frame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, -10, 0, 30)
timeLabel.Position = UDim2.new(0, 5, 0, 25)
timeLabel.BackgroundTransparency = 1
timeLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
timeLabel.Font = Enum.Font.Bodoni
timeLabel.TextSize = 18
timeLabel.TextXAlignment = Enum.TextXAlignment.Center
timeLabel.Parent = frame


local startTime = tick()
local function getTimeElapsed()
    local elapsed = tick() - startTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end


local function getRGBColor()
    local t = tick() * 2
    local r = (math.sin(t) * 127 + 128)/255
    local g = (math.sin(t + 2) * 127 + 128)/255
    local b = (math.sin(t + 4) * 127 + 128)/255
    return Color3.new(r, g, b)
end


RunService.RenderStepped:Connect(function()
    timeLabel.Text = getTimeElapsed()
    timeLabel.TextColor3 = getRGBColor()
end)
