-- LocalScript dentro de StarterPlayerScripts

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local NORMAL_FPS = 30
local MINIMIZED_FPS = 10

local minimized = false

-- FPS CONTROL
local function setFPS(fps)
	pcall(function()
		RunService:SetRobloxFPSCap(fps)
	end)
end

setFPS(NORMAL_FPS)

UserInputService.WindowFocusReleased:Connect(function()
	minimized = true
	setFPS(MINIMIZED_FPS)
end)

UserInputService.WindowFocused:Connect(function()
	minimized = false
	setFPS(NORMAL_FPS)
end)

--------------------------------------------------
-- ULTRA VISUAL OPTIMIZATION
--------------------------------------------------

Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 0

for _,v in pairs(Lighting:GetChildren()) do
	if v:IsA("Sky") then
		v:Destroy()
	end
end

-- AGUA INVISIBLE
local terrain = Workspace:FindFirstChildOfClass("Terrain")
if terrain then
	terrain.WaterTransparency = 1
	terrain.WaterReflectance = 0
	terrain.WaterWaveSize = 0
	terrain.WaterWaveSpeed = 0
	terrain.WaterColor = Color3.new(0,0,0)
end

--------------------------------------------------
-- COLLISION PART
--------------------------------------------------

local function createCollisionPart(position,size)
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
	return collisionPart
end

--------------------------------------------------
-- TELEPORT
--------------------------------------------------

local function teleportCharacterAbovePart(character,part)
	local hrp = character:WaitForChild("HumanoidRootPart")
	local yOffset = part.Size.Y/2 + hrp.Size.Y/2
	hrp.CFrame = CFrame.new(
		part.Position.X,
		part.Position.Y + yOffset,
		part.Position.Z
	)
end

--------------------------------------------------
-- CLEAN WORKSPACE
--------------------------------------------------

local function cleanWorkspace(exceptPart)
	for _,obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Sound") then
			obj:Destroy()
		elseif obj:IsA("Texture")
		or obj:IsA("Decal")
		or obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Explosion") then
			obj:Destroy()
		elseif obj:IsA("BasePart") and obj ~= exceptPart then
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CastShadow = false
		end
	end
end

--------------------------------------------------
-- COLLISION SETUP
--------------------------------------------------

local collisionPosition = Vector3.new(2520,-1100.6,850)
local collisionSize = Vector3.new(10,1,10)
local collisionPart = createCollisionPart(collisionPosition,collisionSize)
cleanWorkspace(collisionPart)

--------------------------------------------------
-- TELEPORT PLAYER
--------------------------------------------------

if player.Character then
	teleportCharacterAbovePart(player.Character,collisionPart)
end

player.CharacterAdded:Connect(function(character)
	teleportCharacterAbovePart(character,collisionPart)
end)

--------------------------------------------------
-- AUTO CLEAN NEW OBJECTS
--------------------------------------------------

Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Sound") then
		desc:Destroy()
	elseif desc:IsA("Texture")
	or desc:IsA("Decal")
	or desc:IsA("ParticleEmitter")
	or desc:IsA("Trail")
	or desc:IsA("Explosion") then
		desc:Destroy()
	elseif desc:IsA("BasePart") and desc ~= collisionPart then
		desc.Transparency = 1
		desc.CanCollide = false
		desc.CastShadow = false
	end
end)

--------------------------------------------------
-- REMOVE UI FROM OTHER PLAYERS
--------------------------------------------------

Players.PlayerAdded:Connect(function(p)
	local playerGui = p:WaitForChild("PlayerGui")
	playerGui.DescendantAdded:Connect(function(desc)
		if desc:IsA("ScreenGui") or desc:IsA("SurfaceGui") then
			desc:Destroy()
		end
	end)
end)

--------------------------------------------------
-- UI MEJORADA
--------------------------------------------------

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmStatsUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 70)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.AnchorPoint = Vector2.new(0,0)
frame.ClipsDescendants = true

local shadow = Instance.new("UIStroke")
shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
shadow.Thickness = 2
shadow.Color = Color3.fromRGB(50,50,50)
shadow.Transparency = 0.5
shadow.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 25)
title.Position = UDim2.new(0,5,0,5)
title.BackgroundTransparency = 1
title.Text = "⏱ Farm Activa"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1,-20,0,35)
timeLabel.Position = UDim2.new(0,10,0,30)
timeLabel.BackgroundTransparency = 0
timeLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
timeLabel.BorderSizePixel = 0
timeLabel.TextColor3 = Color3.fromRGB(255,0,0)
timeLabel.Font = Enum.Font.GothamBold
timeLabel.TextSize = 20
timeLabel.TextXAlignment = Enum.TextXAlignment.Center
timeLabel.TextYAlignment = Enum.TextYAlignment.Center
timeLabel.Parent = frame

local uiGradient = Instance.new("UIGradient")
uiGradient.Rotation = 45
uiGradient.Color = ColorSequence.new(Color3.fromRGB(255,0,0), Color3.fromRGB(255,255,0))
uiGradient.Parent = timeLabel

--------------------------------------------------
-- TIME SYSTEM
--------------------------------------------------

local startTime = tick()

local function getTimeElapsed()
	local elapsed = tick() - startTime
	local hours = math.floor(elapsed/3600)
	local minutes = math.floor((elapsed%3600)/60)
	local seconds = math.floor(elapsed%60)
	return string.format("%02d:%02d:%02d",hours,minutes,seconds)
end

--------------------------------------------------
-- RGB COLOR
--------------------------------------------------

local function getRGBColor()
	local t = tick()*2
	local r = (math.sin(t)*127+128)/255
	local g = (math.sin(t+2)*127+128)/255
	local b = (math.sin(t+4)*127+128)/255
	return Color3.new(r,g,b)
end

--------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------

task.spawn(function()
	while true do
		timeLabel.Text = getTimeElapsed()
		if minimized then
			task.wait(3)
		else
			task.wait(1)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	timeLabel.TextColor3 = getRGBColor()
end)
