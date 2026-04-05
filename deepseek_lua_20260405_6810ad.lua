local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "DNN HUB | Test | Demo",
    Icon = "",
    Author = "",
    Folder = "",
    Size = UDim2.fromOffset(450, 480),
    Transparent = true,
    Resizable = true,
})

local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("UltimateSA")

local SilentAimEnabled = false
local ShowFOV = true
local FOV = 200
local excludedPlayers = {}
local AimPart = "Head"

local GRAVITY = 196.2
local PROJECTILE_SPEED = 2500
local PREDICTION_STRENGTH = 1.0

local lastColorWasBlack = false

local function GetBulletColor()
    lastColorWasBlack = not lastColorWasBlack
    return lastColorWasBlack and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
end

local realVelocity = {}

local function GetRealVelocity(player)
    if not player or not player.Character then return Vector3.zero end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.zero end
    local now = tick()
    local currentPos = hrp.Position
    if not realVelocity[player] then
        realVelocity[player] = { lastPos = currentPos, lastTime = now, velocity = Vector3.zero }
        return Vector3.zero
    end
    local data = realVelocity[player]
    local deltaTime = now - data.lastTime
    if deltaTime > 0 and deltaTime < 0.5 then
        local newVelocity = (currentPos - data.lastPos) / deltaTime
        if newVelocity.Magnitude < 200 then data.velocity = newVelocity end
        data.lastPos = currentPos
        data.lastTime = now
        return data.velocity
    end
    return data.velocity
end

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

local function solveQuadratic(A, B, C)
    local discriminant = B^2 - 4*A*C
    if discriminant < 0 then return nil, nil end
    local sqrtDisc = math.sqrt(discriminant)
    local root1 = (-B - sqrtDisc) / (2*A)
    local root2 = (-B + sqrtDisc) / (2*A)
    return root1, root2
end

local function getBallisticFlightTime(direction, gravity, projectileSpeed)
    local a = gravity:Dot(gravity) / 4
    local b = gravity:Dot(direction) - projectileSpeed^2
    local c = direction:Dot(direction)
    local root1, root2 = solveQuadratic(a, b, c)
    if root1 and root2 then
        if root1 > 0 and root1 < root2 then return math.sqrt(root1)
        elseif root2 > 0 and root2 < root1 then return math.sqrt(root2) end
    end
    return direction.Magnitude / projectileSpeed
end

local function projectileDrop(origin, target, projectileSpeed, acceleration)
    local gravity = Vector3.new() + Vector3.yAxis * (acceleration * 2)
    local time = getBallisticFlightTime(target - origin, gravity, projectileSpeed)
    return -0.001 * gravity * time^2
end

local bulletData = {}

local function LearnBulletTime(targetPlayer, startTime, distance, startHealth)
    if not targetPlayer or not targetPlayer.Character then return end
    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local startHealth = startHealth or humanoid.Health
    local checkCount = 0
    local function CheckBlood()
        checkCount = checkCount + 1
        if checkCount > 80 then return end
        if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Humanoid") then return end
        local currentHealth = targetPlayer.Character.Humanoid.Health
        if currentHealth < startHealth then
            local travelTime = tick() - startTime
            table.insert(bulletData, {distance = distance, time = travelTime})
            if #bulletData > 30 then table.remove(bulletData, 1) end
            if #bulletData >= 3 then
                local totalTime = 0
                local totalDist = 0
                for _, data in ipairs(bulletData) do
                    totalTime = totalTime + data.time
                    totalDist = totalDist + data.distance
                end
                local avgTime = totalTime / #bulletData
                local avgDist = totalDist / #bulletData
                local realSpeed = avgDist / avgTime
                if realSpeed > 500 and realSpeed < 10000 then PROJECTILE_SPEED = realSpeed end
                local avgG = 0
                for _, data in ipairs(bulletData) do
                    local g = (15 * 2) / (data.time^2)
                    avgG = avgG + g
                end
                avgG = avgG / #bulletData
                if avgG > 50 and avgG < 500 then GRAVITY = avgG end
                local hitRate = #bulletData / (#bulletData + 1)
                if hitRate > 0.8 then
                    PREDICTION_STRENGTH = math.min(1.2, PREDICTION_STRENGTH + 0.01)
                elseif hitRate < 0.6 then
                    PREDICTION_STRENGTH = math.max(0.8, PREDICTION_STRENGTH - 0.01)
                end
            end
            return
        end
        task.wait(0.05)
        CheckBlood()
    end
    task.spawn(CheckBlood)
end

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

local function GetTargetPart(character)
    if not character then return nil, nil end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil, nil end
    local targetPart = nil
    if AimPart == "Head" then
        targetPart = character:FindFirstChild("Head")
    else
        targetPart = character:FindFirstChild("HumanoidRootPart")
        if not targetPart then targetPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") end
    end
    if not targetPart then targetPart = character:FindFirstChild("Head") end
    return targetPart, humanoid
end

local FOVCircle = nil
local TracerLine = nil
local TargetDot = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function CreateDrawings()
    if not isMobile then
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        FOVCircle.Thickness = 2
        FOVCircle.NumSides = 64
        FOVCircle.Filled = false
        FOVCircle.Transparency = 0.8
        FOVCircle.Radius = FOV
        FOVCircle.Visible = false
        TracerLine = Drawing.new("Line")
        TracerLine.Thickness = 1.5
        TracerLine.Visible = false
        TargetDot = Drawing.new("Circle")
        TargetDot.Thickness = 2
        TargetDot.NumSides = 12
        TargetDot.Radius = 5
        TargetDot.Filled = true
        TargetDot.Transparency = 0.6
        TargetDot.Visible = false
    end
end

local function GetClosestTarget()
    local closest = nil
    local closestPart = nil
    local shortestDistance = FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if excludedPlayers[player.Name] then continue end
            local targetPart, humanoid = GetTargetPart(player.Character)
            if targetPart and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                    local distanceFromCenter = (screenVector - center).Magnitude
                    if distanceFromCenter <= FOV then
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

local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Send")
local oldFire

pcall(function()
    oldFire = hookfunction(Remote.FireServer, function(self, ...)
        if self ~= Remote then return oldFire(self, ...) end
        local args = {...}
        if SilentAimEnabled and args[2] == "shoot_gun" then
            local target, targetPart = GetClosestTarget()
            if target and targetPart then
                local humanoid = target.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                    local aimPos = targetPart.Position
                    if hrp and origin then
                        aimPos = PredictPosition(origin.Position, targetPart.Position, hrp.Velocity, target)
                    end
                    if origin then
                        local startTime = tick()
                        local distance = (aimPos - origin.Position).Magnitude
                        local startHealth = humanoid.Health
                        LearnBulletTime(target, startTime, distance, startHealth)
                        CreateBulletEffect(origin.Position, aimPos)
                    end
                    CreateHitEffect(target.Character)
                    local myPos = origin and origin.Position
                    local dir = aimPos - myPos
                    local blocked = false
                    if dir.Magnitude > 1 then
                        local params = RaycastParams.new()
                        params.FilterDescendantsInstances = {LocalPlayer.Character, target.Character}
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        blocked = workspace:Raycast(myPos, dir, params) ~= nil
                    end
                    if blocked then
                        args[4] = CFrame.new(math.huge, math.huge, math.huge)
                    else
                        args[4] = CFrame.new(myPos, aimPos)
                        args[5] = {{[1] = {Instance = targetPart, Position = aimPos}}}
                    end
                end
            end
        end
        return oldFire(self, unpack(args))
    end)
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        if not FOVCircle then CreateDrawings() end
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        if FOVCircle and not isMobile then
            FOVCircle.Position = center
            FOVCircle.Radius = FOV
            FOVCircle.Visible = SilentAimEnabled and ShowFOV
        end
        if not SilentAimEnabled then
            if TracerLine then TracerLine.Visible = false end
            if TargetDot then TargetDot.Visible = false end
            return
        end
        local target, targetPart = GetClosestTarget()
        if target and targetPart then
            local humanoid = target.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local aimPos = targetPart.Position
                if hrp and origin then
                    aimPos = PredictPosition(origin.Position, targetPart.Position, hrp.Velocity, target)
                end
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
                if onScreen then
                    if TracerLine then
                        TracerLine.Visible = true
                        TracerLine.From = center
                        TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        if AimPart == "Head" then
                            TracerLine.Color = Color3.fromRGB(255, 50, 50)
                        else
                            TracerLine.Color = Color3.fromRGB(50, 255, 50)
                        end
                    end
                    if TargetDot then
                        TargetDot.Visible = true
                        TargetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                        if AimPart == "Head" then
                            TargetDot.Color = Color3.fromRGB(255, 50, 50)
                        else
                            TargetDot.Color = Color3.fromRGB(50, 255, 50)
                        end
                    end
                else
                    if TracerLine then TracerLine.Visible = false end
                    if TargetDot then TargetDot.Visible = false end
                end
            else
                if TracerLine then TracerLine.Visible = false end
                if TargetDot then TargetDot.Visible = false end
            end
        else
            if TracerLine then TracerLine.Visible = false end
            if TargetDot then TargetDot.Visible = false end
        end
    end)
end)

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

local CombatTab = Window:Tab({Title = "SILENT AIM", Icon = "crosshair"})

CombatTab:Toggle({
    Title = "Silent aim | Wallbang",
    Desc = "ล็อคเป้า|ยิงทะลุ",
    Default = false,
    Callback = function(state)
        SilentAimEnabled = state
        if FOVCircle then
            FOVCircle.Visible = SilentAimEnabled and ShowFOV
        end
    end
})
myConfig:Register("SilentAim", CombatTab.Toggle)

CombatTab:Dropdown({
    Title = "Aim Part",
    Desc = "เลือกส่วนที่จะล็อค",
    Values = {"Head", "Body"},
    Value = "Head",
    Callback = function(option)
        AimPart = option
    end
})
myConfig:Register("AimPart", CombatTab.Dropdown)

CombatTab:Slider({
    Title = "FOV Radius",
    Step = 10,
    Value = {Min = 50, Max = 500, Default = 200},
    Callback = function(value)
        FOV = value
        if FOVCircle then
            FOVCircle.Radius = FOV
        end
    end
})
myConfig:Register("FOV", CombatTab.Slider)

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Desc = "แสดงวงกลม FOV",
    Default = true,
    Callback = function(state)
        ShowFOV = state
        if FOVCircle then
            FOVCircle.Visible = SilentAimEnabled and ShowFOV
        end
    end
})
myConfig:Register("ShowFOV", CombatTab.Toggle)

CombatTab:Divider()

local FriendsDropdown = CombatTab:Dropdown({
    Title = "Safe Friend List",
    Desc = "เลือกผู้เล่นที่จะไม่โดนล็อค (เลือกได้หลายคน)",
    Values = UpdateExcludedPlayersList(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selectedPlayers)
        excludedPlayers = {}
        for _, name in ipairs(selectedPlayers) do
            excludedPlayers[name] = true
        end
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

WindUI:Notify({
    Title = "✅ Ultimate Silent Aim",
    Description = "",
    Duration = 3
})
