-- Silent Aim PigHub 100% + FOV BlockSpin + เอฟเฟกต์กระสุนแบบใหม่
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===============================
-- ตั้งค่า
-- ===============================
local SilentAimEnabled = false
local ShowFOV = true
local FOV = 120
local SelectedAimPart = "Head"
local excludedPlayerNames = {}

-- ===============================
-- เอฟเฟกต์กระสุน (แบบที่คุณให้มา)
-- ===============================
local lastColorWasBlack = false

local function GetBulletColor()
    lastColorWasBlack = not lastColorWasBlack
    return lastColorWasBlack and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
end

local function CreateBulletEffect(origin, targetPos)
    pcall(function()
        local bulletColor = GetBulletColor()
        local distance = (targetPos - origin).Magnitude
        local direction = (targetPos - origin).Unit
        
        local startPart = Instance.new("Part")
        startPart.Size = Vector3.new(0.1, 0.1, 0.1)
        startPart.Position = origin
        startPart.Anchored = true
        startPart.CanCollide = false
        startPart.Transparency = 1
        startPart.Parent = workspace
        
        local endPart = Instance.new("Part")
        endPart.Size = Vector3.new(0.1, 0.1, 0.1)
        endPart.Position = targetPos
        endPart.Anchored = true
        endPart.CanCollide = false
        endPart.Transparency = 1
        endPart.Parent = workspace
        
        local startAttachment = Instance.new("Attachment")
        startAttachment.Parent = startPart
        
        local endAttachment = Instance.new("Attachment")
        endAttachment.Parent = endPart
        
        local beam = Instance.new("Beam")
        beam.Attachment0 = startAttachment
        beam.Attachment1 = endAttachment
        beam.Color = ColorSequence.new(bulletColor)
        beam.Width0 = 0.3
        beam.Width1 = 0.3
        beam.LightInfluence = 0
        beam.FaceCamera = true
        beam.Transparency = NumberSequence.new(0.2)
        beam.Parent = workspace
        
        for i = 1, 6 do
            local t = i / 6
            local particlePos = origin + direction * (distance * t)
            local particle = Instance.new("Part")
            particle.Size = Vector3.new(0.12, 0.12, 0.12)
            particle.Position = particlePos
            particle.Anchored = true
            particle.CanCollide = false
            particle.Material = Enum.Material.Neon
            particle.Color = bulletColor
            particle.Transparency = 0.3
            particle.Parent = workspace
            Debris:AddItem(particle, 0.8)
        end
        
        local muzzleFlash = Instance.new("Part")
        muzzleFlash.Shape = Enum.PartType.Ball
        muzzleFlash.Size = Vector3.new(0.5, 0.5, 0.5)
        muzzleFlash.Position = origin
        muzzleFlash.Anchored = true
        muzzleFlash.CanCollide = false
        muzzleFlash.Material = Enum.Material.Neon
        muzzleFlash.Color = bulletColor
        muzzleFlash.Transparency = 0.1
        muzzleFlash.Parent = workspace
        Debris:AddItem(muzzleFlash, 0.5)
        
        local light = Instance.new("PointLight")
        light.Color = bulletColor
        light.Brightness = 4
        light.Range = 12
        light.Parent = muzzleFlash
        Debris:AddItem(light, 0.5)
        
        for i = 1, 25 do
            local particle = Instance.new("Part")
            particle.Shape = Enum.PartType.Ball
            particle.Size = Vector3.new(math.random(15, 35) / 100, math.random(15, 35) / 100, math.random(15, 35) / 100)
            particle.Position = targetPos + Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
            particle.Anchored = true
            particle.CanCollide = false
            particle.Material = Enum.Material.Neon
            particle.Color = bulletColor
            particle.Transparency = 0.4
            particle.Parent = workspace
            Debris:AddItem(particle, 0.8)
        end
        
        local ring = Instance.new("Part")
        ring.Shape = Enum.PartType.Ball
        ring.Size = Vector3.new(1.8, 1.8, 1.8)
        ring.Position = targetPos
        ring.Anchored = true
        ring.CanCollide = false
        ring.Material = Enum.Material.Neon
        ring.Color = bulletColor
        ring.Transparency = 0.5
        ring.Parent = workspace
        
        task.spawn(function()
            for i = 1, 15 do
                task.wait(0.05)
                ring.Size = ring.Size + Vector3.new(0.25, 0.25, 0.25)
                ring.Transparency = ring.Transparency + 0.05
            end
            ring:Destroy()
        end)
        
        Debris:AddItem(beam, 0.8)
        Debris:AddItem(startPart, 0.8)
        Debris:AddItem(endPart, 0.8)
    end)
end

local function CreateHitEffect(character)
    task.spawn(function()
        task.wait(0.05)
        if character and character.Parent then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local hitColor = lastColorWasBlack and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
                
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local box = Instance.new("Part")
                        box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
                        box.CFrame = part.CFrame
                        box.Anchored = true
                        box.CanCollide = false
                        box.Material = Enum.Material.Neon
                        box.Color = hitColor
                        box.Transparency = 0.5
                        box.Parent = workspace
                        
                        local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Linear)
                        TweenService:Create(box, tweenInfo, {Transparency = 1}):Play()
                        Debris:AddItem(box, 0.8)
                    end
                end
            end
        end
    end)
end

-- ===============================
-- BlockSpin: FOV Circle (Visual)
-- ===============================
local SilentFOVCircle = nil
local tracerLine = nil
local targetDot = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

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

-- ===============================
-- BlockSpin: Tracer + Dot (Visual)
-- ===============================
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

-- ===============================
-- PigHub: Ballistic Prediction (100% PigHub)
-- ===============================
local function solveQuadratic(A, B, C)
    local discriminant = B^2 - 4*A*C
    if discriminant < 0 then return nil, nil end
    local sqrtDisc = math.sqrt(discriminant)
    return (-B - sqrtDisc) / (2*A), (-B + sqrtDisc) / (2*A)
end

local function getBallisticFlightTime(direction, gravity, projectileSpeed)
    local root1, root2 = solveQuadratic(
        gravity:Dot(gravity) / 3.5,
        gravity:Dot(direction) - projectileSpeed^2,
        direction:Dot(direction)
    )
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

-- ===============================
-- PigHub: Raycast Check
-- ===============================
local function IsWallBetween(origin, target)
    local direction = target - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result ~= nil
end

-- ===============================
-- PigHub: Check excluded player
-- ===============================
local function isPlayerExcluded(playerName)
    local lowerName = string.lower(playerName)
    for _, excluded in ipairs(excludedPlayerNames) do
        if excluded ~= "" and string.find(lowerName, string.lower(excluded)) then
            return true
        end
    end
    return false
end

-- ===============================
-- PigHub: Get Closest Target
-- ===============================
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

-- ===============================
-- PigHub: Hook Remote (100% PigHub)
-- ===============================
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
                        local isBlocked = IsWallBetween(originPos, aimPos)
                        
                        -- เอฟเฟกต์กระสุนแบบใหม่
                        CreateBulletEffect(originPos, aimPos)
                        CreateHitEffect(target.Character)
                        
                        if isBlocked then
                            args[4] = CFrame.new(math.huge, math.huge, math.huge)
                        else
                            args[4] = CFrame.new(originPos, aimPos)
                            args[5] = {
                                [1] = {
                                    [1] = {
                                        ["Instance"] = aimPart,
                                        ["Position"] = aimPos
                                    }
                                }
                            }
                        end
                    end
                end
            end
        end
        return oldFire(self, unpack(args))
    end)
end

-- ===============================
-- BlockSpin: Render Loop (Visual)
-- ===============================
RunService.RenderStepped:Connect(function()
    pcall(function()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        if SilentFOVCircle then
            if not isMobile then
                SilentFOVCircle.Position = center
                SilentFOVCircle.Radius = FOV
            end
            SilentFOVCircle.Visible = ShowFOV and SilentAimEnabled
        end
        
        if SilentAimEnabled then
            local target = GetClosestTarget()
            if target and target.Character then
                local aimPart = target.Character:FindFirstChild(SelectedAimPart) or target.Character:FindFirstChild("Head")
                if aimPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                    if onScreen then
                        if tracerLine then
                            tracerLine.Visible = true
                            tracerLine.From = center
                            tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        end
                        if targetDot then
                            targetDot.Visible = true
                            targetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                        end
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
        else
            if tracerLine then tracerLine.Visible = false end
            if targetDot then targetDot.Visible = false end
        end
    end)
end)

-- ===============================
-- UI
-- ===============================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "DnnHUB | Silent Aim",
    Icon = "",
    Author = "",
    Folder = "",
    Size = UDim2.fromOffset(400, 320),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
})

local CombatTab = Window:Tab({Title = "COMBAT", Icon = "crosshair"})

CombatTab:Toggle({
    Title = "Silent Aim | wallbang",
    Default = false,
    Callback = function(state)
        SilentAimEnabled = state
        if SilentFOVCircle then
            SilentFOVCircle.Visible = state and ShowFOV
        end
    end
})

CombatTab:Slider({
    Title = "FOV Radius",
    Step = 5,
    Value = {Min = 50, Max = 500, Default = FOV},
    Callback = function(value)
        FOV = tonumber(value) or 120
        if SilentFOVCircle then
            if isMobile then
                SilentFOVCircle.Size = UDim2.fromOffset(FOV * 2, FOV * 2)
            else
                SilentFOVCircle.Radius = FOV
            end
        end
    end
})

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Desc = "แสดงวง FOV",
    Default = ShowFOV,
    Callback = function(state)
        ShowFOV = state
        if SilentFOVCircle then
            SilentFOVCircle.Visible = state and SilentAimEnabled
        end
    end
})

CombatTab:Dropdown({
    Title = "Aim Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso"},
    Default = 1,
    Callback = function(value)
        SelectedAimPart = value
    end
})

CombatTab:Input({
    Title = "Excluded Friends",
    Desc = "ชื่อเพื่อนที่ไม่เล็ง (คั่นด้วย space)",
    Placeholder = "Friend1 Friend2",
    Callback = function(input)
        excludedPlayerNames = {}
        for name in string.gmatch(input, "%S+") do
            table.insert(excludedPlayerNames, name)
        end
    end
})

-- ===============================
-- เริ่มต้น
-- ===============================
CreateFOVCircle()
CreateDrawingObjects()
pcall(SetupSilentAim)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    CreateFOVCircle()
    CreateDrawingObjects()
end)

print("✅ Silent Aim โหลดสำเร็จ! (PigHub 100% + เอฟเฟกต์กระสุนสวยๆ)")
