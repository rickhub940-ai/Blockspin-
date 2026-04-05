local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ========== โหลด WindUI ==========
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ========== ตั้งค่า Window ==========
local Window = WindUI:CreateWindow({
    Title = "DNN HUB | Test | Demo |",
    Icon = "",
    Author = "",
    Folder = "Dnn HUB",
    Size = UDim2.fromOffset(500, 500),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
})


local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("SilentAimUltraConfig")


local SilentAimEnabled = false
local ShowFOV = false
local FOV = 120
local excludedPlayers = {}
local AimPart = "Head"

-- ========== ค่าที่ปรับอัตโนมัติ ==========
local GRAVITY = 196.2
local PROJECTILE_SPEED = 2500
local PREDICTION_STRENGTH = 1.0

-- ========== ระบบความเร็วจริง (ไม่โดน Velocity ปลอมหลอก) ==========
local realVelocity = {}

local function GetRealVelocity(player)
    if not player or not player.Character then return Vector3.zero end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.zero end
    
    local now = tick()
    local currentPos = hrp.Position
    
    if not realVelocity[player] then
        realVelocity[player] = {
            lastPos = currentPos,
            lastTime = now,
            velocity = Vector3.zero
        }
        return Vector3.zero
    end
    
    local data = realVelocity[player]
    local deltaTime = now - data.lastTime
    
    if deltaTime > 0 and deltaTime < 0.5 then
        local newVelocity = (currentPos - data.lastPos) / deltaTime
        if newVelocity.Magnitude < 200 then
            data.velocity = newVelocity
        end
        data.lastPos = currentPos
        data.lastTime = now
        return data.velocity
    end
    
    return data.velocity
end

-- ========== ระบบเรียนรู้ค่าที่ดีที่สุด (Auto-Calibration) ==========
local hitData = {}

local function AutoCalibrate(distance, travelTime)
    table.insert(hitData, {distance = distance, time = travelTime})
    if #hitData > 30 then table.remove(hitData, 1) end
    
    if #hitData >= 5 then
        local totalTime = 0
        local totalDistance = 0
        for _, data in ipairs(hitData) do
            totalTime = totalTime + data.time
            totalDistance = totalDistance + data.distance
        end
        local avgTime = totalTime / #hitData
        local avgDistance = totalDistance / #hitData
        
        local realSpeed = avgDistance / avgTime
        if realSpeed > 500 and realSpeed < 10000 then
            PROJECTILE_SPEED = realSpeed
        end
        
        local totalG = 0
        for _, data in ipairs(hitData) do
            local g = (15 * 2) / (data.time^2)
            totalG = totalG + g
        end
        local avgG = totalG / #hitData
        if avgG > 50 and avgG < 500 then
            GRAVITY = avgG
        end
    end
end

-- ========== ระบบกระสุนสลับดำ/ขาว ==========
local lastColorWasBlack = false

local function GetBulletColor()
    lastColorWasBlack = not lastColorWasBlack
    return lastColorWasBlack and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
end

-- ========== วัด Ping ==========
local function GetPing()
    local stats = game:GetService("Stats")
    local networkStats = stats:FindFirstChild("Network")
    if networkStats then
        local pingStats = networkStats:FindFirstChild("Ping")
        if pingStats then
            local pingValue = tonumber(string.match(pingStats:GetValueString(), "(%d+)"))
            return (pingValue or 0) / 1000
        end
    end
    return 0.05
end

-- ========== QUADRATIC BALLISTIC ==========
local function solveQuadratic(A, B, C)
    local discriminant = B^2 - 4*A*C
    if discriminant < 0 then return nil, nil end
    local sqrtDisc = math.sqrt(discriminant)
    local root1 = (-B - sqrtDisc) / (2*A)
    local root2 = (-B + sqrtDisc) / (2*A)
    return root1, root2
end

local function getBallisticFlightTime(direction, gravity, projectileSpeed)
    local root1, root2 = solveQuadratic(
        gravity:Dot(gravity) / 3.5,
        gravity:Dot(direction) - projectileSpeed^2,
        direction:Dot(direction)
    )
    
    if root1 and root2 then
        if root1 > 0 and root1 < root2 then
            return math.sqrt(root1)
        elseif root2 > 0 and root2 < root1 then
            return math.sqrt(root2)
        end
    end
    
    return direction.Magnitude / projectileSpeed
end

local function projectileDrop(origin, target, projectileSpeed, acceleration)
    local gravity = Vector3.new() + Vector3.yAxis * (acceleration * 2)
    local time = getBallisticFlightTime(target - origin, gravity, projectileSpeed)
    return -0.001 * gravity * time^2
end

-- ========== ทำนายตำแหน่ง (ใช้ความเร็วจริง + Quadratic) ==========
local function PredictPosition(origin, targetPos, targetVel, player)
    if not origin or not targetPos then return targetPos end
    
    local direction = targetPos - origin
    local gravityVec = Vector3.new() + Vector3.yAxis * (GRAVITY * 2)
    local pingTime = GetPing()
    
    local flightTime = getBallisticFlightTime(direction, gravityVec, PROJECTILE_SPEED)
    local totalTime = (flightTime + pingTime) * PREDICTION_STRENGTH
    
    local realVel = GetRealVelocity(player)
    local useVel = realVel.Magnitude > 0 and realVel or targetVel
    
    local predictedPos = targetPos + (useVel * totalTime)
    local drop = projectileDrop(origin, predictedPos, PROJECTILE_SPEED, GRAVITY)
    
    return predictedPos + drop
end

-- ========== Blood Check (วัดเวลาจริง) ==========
local function MeasureLastShot(targetPlayer, startTime, distance, startHealth)
    if not targetPlayer or not targetPlayer.Character then return end
    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local startHealth = startHealth or humanoid.Health
    local checkCount = 0
    
    local function CheckBlood()
        checkCount = checkCount + 1
        if checkCount > 80 then return end
        
        if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Humanoid") then
            return
        end
        
        local currentHealth = targetPlayer.Character.Humanoid.Health
        if currentHealth < startHealth then
            local travelTime = tick() - startTime
            AutoCalibrate(distance, travelTime)
            return
        end
        
        task.wait(0.05)
        CheckBlood()
    end
    
    task.spawn(CheckBlood)
end

-- ========== หา Hitbox ==========
local function GetTargetPart(character)
    if not character then return nil, nil end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil, nil end
    
    local targetPart = nil
    if AimPart == "Head" then
        targetPart = character:FindFirstChild("Head")
    else
        targetPart = character:FindFirstChild("HumanoidRootPart")
        if not targetPart then
            targetPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        end
    end
    return targetPart, humanoid
end

local SilentFOVCircle = nil
local tracerLine = nil
local targetDot = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ========== Utility ==========
local function isPlayerExcluded(playerName)
    for _, excludedName in ipairs(excludedPlayers) do
        if excludedName == playerName then
            return true
        end
    end
    return false
end

-- ========== FOV Circle ==========
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

-- ========== Drawing Objects ==========
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

-- ========== Target Selection ==========
local function GetClosestTarget()
    local closest = nil
    local closestPart = nil
    local shortestDistance = FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart, humanoid = GetTargetPart(player.Character)
            
            if targetPart and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                    local distanceFromCenter = (screenVector - center).Magnitude
                    
                    if distanceFromCenter <= FOV and not isPlayerExcluded(player.Name) then
                        if distanceFromCenter < shortestDistance then
                            shortestDistance = distanceFromCenter
                            closest = player
                            closestPart = targetPart
                        end
                    end
                end
            end
        end
    end
    return closest, closestPart
end

-- ========== เอฟเฟคกระสุน ==========
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
        startPart.Parent = Workspace
        
        local endPart = Instance.new("Part")
        endPart.Size = Vector3.new(0.1, 0.1, 0.1)
        endPart.Position = targetPos
        endPart.Anchored = true
        endPart.CanCollide = false
        endPart.Transparency = 1
        endPart.Parent = Workspace
        
        local startAttachment = Instance.new("Attachment")
        startAttachment.Parent = startPart
        
        local endAttachment = Instance.new("Attachment")
        endAttachment.Parent = endPart
        
        local beam = Instance.new("Beam")
        beam.Attachment0 = startAttachment
        beam.Attachment1 = endAttachment
        beam.Color = ColorSequence.new(bulletColor)
        beam.Width0 = 0.35
        beam.Width1 = 0.35
        beam.LightInfluence = 0
        beam.FaceCamera = true
        beam.Transparency = NumberSequence.new(0.1)
        beam.Parent = Workspace
        
        local spotlight = Instance.new("SpotLight")
        spotlight.Brightness = 4
        spotlight.Range = 12
        spotlight.Angle = 45
        spotlight.Enabled = true
        spotlight.Parent = beam
        
        for i = 1, 8 do
            local t = i / 8
            local particlePos = origin + direction * (distance * t)
            local particle = Instance.new("Part")
            particle.Size = Vector3.new(0.15, 0.15, 0.15)
            particle.Position = particlePos
            particle.Anchored = true
            particle.CanCollide = false
            particle.Material = Enum.Material.Neon
            particle.Color = bulletColor
            particle.Transparency = 0.2
            particle.Parent = Workspace
            Debris:AddItem(particle, 1.0)
        end
        
        local muzzleFlash = Instance.new("Part")
        muzzleFlash.Shape = Enum.PartType.Ball
        muzzleFlash.Size = Vector3.new(0.55, 0.55, 0.55)
        muzzleFlash.Position = origin
        muzzleFlash.Anchored = true
        muzzleFlash.CanCollide = false
        muzzleFlash.Material = Enum.Material.Neon
        muzzleFlash.Color = bulletColor
        muzzleFlash.Transparency = 0.05
        muzzleFlash.Parent = Workspace
        Debris:AddItem(muzzleFlash, 1.0)
        
        local light = Instance.new("PointLight")
        light.Color = bulletColor
        light.Brightness = 5
        light.Range = 15
        light.Parent = muzzleFlash
        Debris:AddItem(light, 1.0)
        
        for i = 1, 35 do
            local particle = Instance.new("Part")
            particle.Shape = Enum.PartType.Ball
            particle.Size = Vector3.new(math.random(20, 45) / 100, math.random(20, 45) / 100, math.random(20, 45) / 100)
            particle.Position = targetPos + Vector3.new(math.random(-4, 4), math.random(-4, 4), math.random(-4, 4))
            particle.Anchored = true
            particle.CanCollide = false
            particle.Material = Enum.Material.Neon
            particle.Color = bulletColor
            particle.Transparency = 0.3
            particle.Parent = Workspace
            
            local velocity = Vector3.new(math.random(-25, 25), math.random(-15, 35), math.random(-25, 25))
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = velocity
            bodyVel.MaxForce = Vector3.new(500, 500, 500)
            bodyVel.Parent = particle
            
            Debris:AddItem(particle, 1.0)
        end
        
        local ring = Instance.new("Part")
        ring.Shape = Enum.PartType.Ball
        ring.Size = Vector3.new(2.2, 2.2, 2.2)
        ring.Position = targetPos
        ring.Anchored = true
        ring.CanCollide = false
        ring.Material = Enum.Material.Neon
        ring.Color = bulletColor
        ring.Transparency = 0.4
        ring.Parent = Workspace
        
        task.spawn(function()
            for i = 1, 20 do
                task.wait(0.05)
                ring.Size = ring.Size + Vector3.new(0.3, 0.3, 0.3)
                ring.Transparency = ring.Transparency + 0.05
            end
            ring:Destroy()
        end)
        
        Debris:AddItem(beam, 1.0)
        Debris:AddItem(startPart, 1.0)
        Debris:AddItem(endPart, 1.0)
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
                        box.Transparency = 0.4
                        box.Parent = Workspace
                        
                        local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear)
                        TweenService:Create(box, tweenInfo, {Transparency = 1}):Play()
                        Debris:AddItem(box, 1)
                    end
                end
            end
        end
    end)
end

-- ========== Remote Hook ==========
local Remote
pcall(function()
    Remote = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("Send", 5)
end)

local oldFire
if Remote and Remote.FireServer then
    pcall(function()
        oldFire = hookfunction(Remote.FireServer, function(self, ...)
            if self ~= Remote then return oldFire(self, ...) end
            local args = {...}

            if SilentAimEnabled and args[2] == "shoot_gun" then
                local target, targetPart = GetClosestTarget()
                if target and targetPart then
                    local humanoid = target.Character:FindFirstChild("Humanoid")
                    
                    if humanoid and humanoid.Health > 0 then
                        local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position
                        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                        
                        local aimPos = targetPart.Position
                        if hrp and origin then
                            aimPos = PredictPosition(origin, targetPart.Position, hrp.Velocity, target)
                        end

                        if origin then
                            CreateBulletEffect(origin, aimPos)
                            
                            local startTime = tick()
                            local distance = (aimPos - origin).Magnitude
                            local startHealth = humanoid.Health
                            MeasureLastShot(target, startTime, distance, startHealth)
                        end

                        CreateHitEffect(target.Character)

                        args[4] = CFrame.new(
                            1/0, 1/0, 1/0,
                            0/0, 0/0, 0/0,
                            0/0, 0/0, 0/0,
                            0/0, 0/0, 0/0
                        )
                        args[5] = {
                            [1] = {
                                [1] = {
                                    ["Instance"] = targetPart,
                                    ["Position"] = aimPos
                                }
                            }
                        }
                    end
                end
            end
            return oldFire(self, unpack(args))
        end)
    end)
end

-- ========== Main Render Loop ==========
RunService.RenderStepped:Connect(function()
    pcall(function()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        if SilentFOVCircle and not isMobile then
            SilentFOVCircle.Position = center
            SilentFOVCircle.Radius = FOV
        end
        if SilentFOVCircle then
            SilentFOVCircle.Visible = ShowFOV and SilentAimEnabled
        end
        
        if not SilentAimEnabled then
            if tracerLine then tracerLine.Visible = false end
            if targetDot then targetDot.Visible = false end
            return
        end
        
        local target, targetPart = GetClosestTarget()
        if target and targetPart then
            local humanoid = target.Character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                
                local aimPos = targetPart.Position
                if hrp and origin then
                    aimPos = PredictPosition(origin, targetPart.Position, hrp.Velocity, target)
                end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
                
                if onScreen then
                    if tracerLine then
                        tracerLine.Visible = true
                        tracerLine.From = center
                        tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        tracerLine.Color = AimPart == "Head" and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
                    end
                    if targetDot then
                        targetDot.Visible = true
                        targetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                        targetDot.Color = AimPart == "Head" and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
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

-- ========== Initial Setup ==========
CreateFOVCircle()
CreateDrawingObjects()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    CreateFOVCircle()
    CreateDrawingObjects()
end)

-- ========== UI Tab ==========
local CombatTab = Window:Tab({Title = "COMBAT", Icon = "crosshair"})

local SilentToggle = CombatTab:Toggle({
    Title = "Silent Aim | Wallbang",
    Desc = "",
    Default = false,
    Callback = function(state)
        SilentAimEnabled = state
        if SilentFOVCircle then
            SilentFOVCircle.Visible = ShowFOV and SilentAimEnabled
        end
    end
})
myConfig:Register("SilentAim", SilentToggle)

local AimPartDropdown = CombatTab:Dropdown({
    Title = "Aim Part",
    Desc = "เลือกส่วนที่จะล็อค",
    Values = {"Head", "Body"},
    Value = "Head",
    Multi = false,
    Callback = function(option)
        AimPart = option
    end
})
myConfig:Register("AimPart", AimPartDropdown)

local FOVSlider = CombatTab:Slider({
    Title = "FOV Radius",
    Step = 1,
    Value = {Min = 20, Max = 750, Default = FOV},
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
myConfig:Register("FOVRadius", FOVSlider)

local ShowFOVToggle = CombatTab:Toggle({
    Title = "Show FOV Circle",
    Desc = "แสดงวง",
    Default = ShowFOV,
    Callback = function(state)
        ShowFOV = state
        if SilentFOVCircle then
            SilentFOVCircle.Visible = ShowFOV and SilentAimEnabled
        end
    end
})
myConfig:Register("ShowFOV", ShowFOVToggle)

CombatTab:Divider()

-- ========== Safe Friend List ==========
local function UpdateExcludedPlayersList()
    local playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerNames, player.Name)
        end
    end
    table.sort(playerNames)
    return playerNames
end

local function RefreshFriendDropdown(dropdown)
    if dropdown then
        local newValues = UpdateExcludedPlayersList()
        dropdown:SetValues(newValues)
    end
end

local FriendsDropdown = CombatTab:Dropdown({
    Title = "Safe Friend List",
    Desc = "เลือกผู้เล่นที่จะไม่โดนล็อค",
    Values = UpdateExcludedPlayersList(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selectedPlayers)
        excludedPlayers = {}
        for _, name in ipairs(selectedPlayers) do
            table.insert(excludedPlayers, name)
        end
        UpdateExcludedHighlights()
    end
})
myConfig:Register("FriendsList", FriendsDropdown)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    RefreshFriendDropdown(FriendsDropdown)
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    RefreshFriendDropdown(FriendsDropdown)
end)

local excludedPlayersUI = {}
local function UpdateExcludedHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isPlayerExcluded(player.Name) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not excludedPlayersUI[player] then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                highlight.FillTransparency = 0.3
                highlight.OutlineTransparency = 0
                highlight.Parent = player.Character
                excludedPlayersUI[player] = highlight
            end
        else
            if excludedPlayersUI[player] then
                excludedPlayersUI[player]:Destroy()
                excludedPlayersUI[player] = nil
            end
        end
    end
end

Players.PlayerAdded:Connect(UpdateExcludedHighlights)
Players.PlayerRemoving:Connect(function(player)
    if excludedPlayersUI[player] then
        excludedPlayersUI[player]:Destroy()
        excludedPlayersUI[player] = nil
    end
end)

task.spawn(function()
    while task.wait(2) do
        UpdateExcludedHighlights()
    end
end)

WindUI:Notify({
    Title = "✅ Dnn HUB Ultra Ready",
    Description = "FUCK",
    Duration = 3
})
