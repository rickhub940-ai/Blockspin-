-- DNNHUB | Silent Aim (ดำ-ขาวสลับ)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local SilentAimEnabled = false
local ShowFOV = true
local FOV = 120
local SelectedAimPart = "Head"
local excludedPlayerNames = {}

local SilentFOVCircle = nil
local tracerLine = nil
local targetDot = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local lastColorWasBlack = false

local function isPlayerExcluded(playerName)
    local lowerName = string.lower(playerName)
    for _, excluded in ipairs(excludedPlayerNames) do
        if excluded ~= "" and string.find(lowerName, string.lower(excluded)) then
            return true
        end
    end
    return false
end

local function CreateFOVCircle()
    if not isMobile then
        if SilentFOVCircle then SilentFOVCircle:Remove() end
        SilentFOVCircle = Drawing.new("Circle")
        SilentFOVCircle.Color = Color3.fromRGB(255, 255, 255)
        SilentFOVCircle.Thickness = 2
        SilentFOVCircle.NumSides = 64
        SilentFOVCircle.Filled = false
        SilentFOVCircle.Transparency = 0.8
        SilentFOVCircle.Radius = FOV
        SilentFOVCircle.Visible = SilentAimEnabled and ShowFOV
    else
        if SilentFOVCircle and SilentFOVCircle.Parent then SilentFOVCircle.Parent:Destroy() end
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "MobileFOV"
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        SilentFOVCircle = Instance.new("Frame")
        SilentFOVCircle.Size = UDim2.fromOffset(FOV * 2, FOV * 2)
        SilentFOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        SilentFOVCircle.Position = UDim2.fromScale(0.5, 0.5)
        SilentFOVCircle.BackgroundTransparency = 1
        local circleUI = Instance.new("UICorner")
        circleUI.CornerRadius = UDim.new(1, 0)
        circleUI.Parent = SilentFOVCircle
        local border = Instance.new("UIStroke")
        border.Color = Color3.fromRGB(255, 255, 255)
        border.Thickness = 2
        border.Transparency = 0.2
        border.Parent = SilentFOVCircle
        SilentFOVCircle.Parent = ScreenGui
    end
end

local function CreateDrawingObjects()
    if tracerLine then tracerLine:Remove() end
    if targetDot then targetDot:Remove() end
    tracerLine = Drawing.new("Line")
    tracerLine.Color = Color3.fromRGB(255, 50, 50)
    tracerLine.Thickness = 1
    tracerLine.Transparency = 1
    tracerLine.Visible = false
    targetDot = Drawing.new("Circle")
    targetDot.Color = Color3.fromRGB(255, 50, 50)
    targetDot.Thickness = 2
    targetDot.NumSides = 12
    targetDot.Radius = 4
    targetDot.Filled = true
    targetDot.Transparency = 0.7
    targetDot.Visible = false
end

local function solveQuadratic(A, B, C)
    local discriminant = B^2 - 4*A*C
    if discriminant < 0 then return nil, nil end
    local sqrtDisc = math.sqrt(discriminant)
    return (-B - sqrtDisc) / (2*A), (-B + sqrtDisc) / (2*A)
end

local function getBallisticFlightTime(direction, gravity, projectileSpeed)
    local root1, root2 = solveQuadratic(gravity:Dot(gravity) / 3.5, gravity:Dot(direction) - projectileSpeed^2, direction:Dot(direction))
    if root1 and root2 then
        if root1 > 0 and root1 < root2 then return math.sqrt(root1) end
        if root2 > 0 and root2 < root1 then return math.sqrt(root2) end
    end
    return 0
end

local function projectileDrop(origin, target, projectileSpeed, acceleration)
    local gravity = Vector3.new(0, -acceleration * 2, 0)
    local time = getBallisticFlightTime(target - origin, gravity, projectileSpeed)
    return -0.001 * gravity * time^2
end

local function PredictPosition(origin, targetPos, targetVel, travelTime, gravity)
    local t = travelTime or 0.15
    return targetPos + (targetVel * t) + (targetPos - origin).Unit * t + projectileDrop(origin, targetPos, 1000, gravity or 196.2)
end

local function GetClosestTarget()
    local closest = nil
    local shortestDistance = FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(SelectedAimPart) or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart and humanoid and humanoid.Health > 0 and hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                    local distanceFromCenter = (screenVector - center).Magnitude
                    if distanceFromCenter <= FOV and not isPlayerExcluded(player.Name) then
                        if distanceFromCenter < shortestDistance then
                            shortestDistance = distanceFromCenter
                            closest = player
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- เอฟเฟกต์กระสุนดำ-ขาวสลับ
local function CreateBulletEffect(origin, targetPos)
    pcall(function()
        lastColorWasBlack = not lastColorWasBlack
        local bulletColor = lastColorWasBlack and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        
        local distance = (targetPos - origin).Magnitude
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Size = Vector3.new(0.1, 0.1, distance)
        part.CFrame = CFrame.new(origin, targetPos) * CFrame.new(0, 0, -distance / 2)
        part.Material = Enum.Material.Neon
        part.Color = bulletColor
        part.Transparency = 0.3
        part.Parent = workspace
        Debris:AddItem(part, 0.3)
    end)
end

local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Send")
local oldFire

local function SetupSilentAim()
    oldFire = hookfunction(Remote.FireServer, function(self, ...)
        if self ~= Remote then return oldFire(self, ...) end
        local args = {...}
        if SilentAimEnabled and args[2] == "shoot_gun" then
            local target = GetClosestTarget()
            if target and target.Character then
                local aimPart = target.Character:FindFirstChild(SelectedAimPart) or target.Character:FindFirstChild("Head")
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = target.Character:FindFirstChild("Humanoid")
                if aimPart and humanoid and humanoid.Health > 0 and hrp then
                    local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                    local originPos = origin and origin.Position
                    if originPos then
                        local aimPos = PredictPosition(originPos, aimPart.Position, hrp.Velocity)
                        CreateBulletEffect(originPos, aimPos)
                        args[4] = CFrame.new(1/0, 1/0, 1/0, 0/0, 0/0, 0/0, 0/0, 0/0, 0/0, 0/0, 0/0, 0/0)
                        args[5] = { [1] = { [1] = { ["Instance"] = aimPart, ["Position"] = aimPos } } }
                    end
                end
            end
        end
        return oldFire(self, unpack(args))
    end)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        if SilentFOVCircle then
            if not isMobile then SilentFOVCircle.Position = center SilentFOVCircle.Radius = FOV end
            SilentFOVCircle.Visible = ShowFOV and SilentAimEnabled
        end
        if not SilentAimEnabled then
            if tracerLine then tracerLine.Visible = false end
            if targetDot then targetDot.Visible = false end
            return
        end
        local target = GetClosestTarget()
        if target and target.Character then
            local aimPart = target.Character:FindFirstChild(SelectedAimPart) or target.Character:FindFirstChild("Head")
            if aimPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    if tracerLine then tracerLine.Visible = true tracerLine.From = center tracerLine.To = Vector2.new(screenPos.X, screenPos.Y) end
                    if targetDot then targetDot.Visible = true targetDot.Position = Vector2.new(screenPos.X, screenPos.Y) end
                else
                    if tracerLine then tracerLine.Visible = false end
                    if targetDot then targetDot.Visible = false end
                end
            else
                if tracerLine then tracerLine.Visible = false end
                if targetDot then targetDot.Visible = false end
            end
        else
            if tracerLine then tracerLine.Visible = false end
            if targetDot then targetDot.Visible = false end
        end
    end)
end)

CreateFOVCircle()
CreateDrawingObjects()
pcall(SetupSilentAim)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    CreateFOVCircle()
    CreateDrawingObjects()
end)

-- UI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "DNNHUB | Test Silent Aim",
    Icon = "",
    Author = "",
    Folder = "DNNHUB",
    Size = UDim2.fromOffset(400, 300),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
})

local CombatTab = Window:Tab({Title = "COMBAT", Icon = "crosshair"})

CombatTab:Toggle({
    Title = "Silent Aim | wallbang",
    Desc = "ล็อคหัวกับยิงทะลุ",
    Default = false,
    Callback = function(state) SilentAimEnabled = state end
})

CombatTab:Slider({
    Title = "FOV:",
    Step = 1,
    Value = {Min = 20, Max = 750, Default = FOV},
    Callback = function(value)
        FOV = tonumber(value) or 120
        if SilentFOVCircle then
            if isMobile then SilentFOVCircle.Size = UDim2.fromOffset(FOV * 2, FOV * 2)
            else SilentFOVCircle.Radius = FOV end
        end
    end
})

CombatTab:Toggle({
    Title = "Show FOV",
    Desc = "แสดงวงFOV",
    Default = ShowFOV,
    Callback = function(state)
        ShowFOV = state
        if SilentFOVCircle then SilentFOVCircle.Visible = state and SilentAimEnabled end
    end
})

CombatTab:Divider()

CombatTab:Input({
    Title = "Safe Friend List",
    Desc = "ชื่อเพื่อน (คั่นด้วย space)",
    Placeholder = "Friend1 Friend2",
    Callback = function(input)
        excludedPlayerNames = {}
        for name in string.gmatch(input, "%S+") do table.insert(excludedPlayerNames, name) end
    end
})

