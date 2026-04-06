
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Dnn HUB | Test Silent Aim",
    Icon = "",
    Author = "",
    Folder = "",
    Size = UDim2.fromOffset(420, 350),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local Camera = workspace.CurrentCamera





local LocalPlayer = Players.LocalPlayer

local Settings = {
    Enabled = true,
    FOV = 150,
    ShowFOV = true,
    AimPart = "Head",
    Gravity = 196.2,
    MaxPredictionTime = 0.35,
    MinPredictionTime = 0.05,
    ShowTracer = true,
    LearningEnabled = true,
}

local BulletData = {
    Samples = {},
    CurrentVelocity = 800,
    AverageVelocity = 800,
    SamplesToKeep = 15,
}

local excludedPlayerNames = {}
local SilentFOVCircle = nil
local tracerLine = nil
local targetDot = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local PendingShots = {}
local shotCounter = 0
local lastColorWasBlack = false

local AimPartsList = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}

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
        
        local light = Instance.new("PointLight")
        light.Color = bulletColor
        light.Brightness = 4
        light.Range = 12
        light.Parent = muzzleFlash
        Debris:AddItem(muzzleFlash, 0.5)
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

local function GetPing()
    local ping = Stats:FindFirstChild("DataStats"):FindFirstChild("Network"):FindFirstChild("Ping")
    if ping then return ping:GetValue() / 1000 end
    return 0.08
end

local PingHistory = {}
local function GetSmoothedPing()
    local currentPing = GetPing()
    table.insert(PingHistory, currentPing)
    if #PingHistory > 5 then table.remove(PingHistory, 1) end
    local sum = 0
    for _, v in ipairs(PingHistory) do sum = sum + v end
    return sum / #PingHistory
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function CalculateVelocity(distance, time)
    if time <= 0.01 then return nil end
    return distance / time
end

local function AddVelocitySample(velocity)
    if not velocity or velocity <= 0 or velocity > 5000 then return end
    table.insert(BulletData.Samples, velocity)
    if #BulletData.Samples > BulletData.SamplesToKeep then
        table.remove(BulletData.Samples, 1)
    end
    local sum = 0
    for _, v in ipairs(BulletData.Samples) do sum = sum + v end
    BulletData.AverageVelocity = sum / #BulletData.Samples
    BulletData.CurrentVelocity = BulletData.AverageVelocity
end

local function GenerateShotId()
    shotCounter = shotCounter + 1
    return shotCounter
end

local function isPlayerExcluded(playerName)
    local lowerPlayerName = string.lower(playerName)
    for _, excludedName in ipairs(excludedPlayerNames) do
        if excludedName ~= "" and string.find(lowerPlayerName, string.lower(excludedName)) then
            return true
        end
    end
    return false
end

local function SolveQuadratic(A, B, C)
    local disc = B^2 - 4*A*C
    if disc < 0 then return nil, nil end
    local sqrtDisc = math.sqrt(disc)
    return (-B - sqrtDisc) / (2*A), (-B + sqrtDisc) / (2*A)
end

local function CalculateFlightTime(origin, targetPos, targetVel, bulletSpeed, gravity)
    local relativePos = targetPos - origin
    local relativeVel = targetVel
    local a = bulletSpeed^2 - relativeVel:Dot(relativeVel)
    local b = -2 * relativePos:Dot(relativeVel)
    local c = -relativePos:Dot(relativePos)
    local t1, t2 = SolveQuadratic(a, b, c)
    if t1 and t1 > 0 then
        return math.min(t1, t2 or t1)
    elseif t2 and t2 > 0 then
        return t2
    end
    return relativePos.Magnitude / bulletSpeed
end

local function PredictPosition(origin, targetPos, targetVel, bulletSpeed, gravity, ping)
    local baseTime = (targetPos - origin).Magnitude / bulletSpeed
    local maxTime = math.min(baseTime * 1.5, Settings.MaxPredictionTime)
    local minTime = Settings.MinPredictionTime
    local bestTime = baseTime
    for _ = 1, 8 do
        local testTime = (minTime + maxTime) / 2
        local predictedPos = targetPos + targetVel * testTime
        local flightTime = (predictedPos - origin).Magnitude / bulletSpeed
        if math.abs(flightTime - testTime) < 0.01 then
            bestTime = testTime
            break
        elseif flightTime > testTime then
            maxTime = testTime
        else
            minTime = testTime
        end
    end
    local pingComp = ping or GetSmoothedPing()
    local totalTime = bestTime + pingComp
    totalTime = math.min(totalTime, Settings.MaxPredictionTime)
    return targetPos + targetVel * totalTime, totalTime
end

local function GetTargetAimPart(player)
    if not player.Character then return nil end
    local aimPart = player.Character:FindFirstChild(Settings.AimPart)
    if not aimPart then
        for _, partName in ipairs(AimPartsList) do
            aimPart = player.Character:FindFirstChild(partName)
            if aimPart then break end
        end
    end
    return aimPart
end

local function GetClosestTarget()
    local closest = nil
    local shortestDistance = Settings.FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local aimPart = GetTargetAimPart(player)
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if aimPart and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                    local distanceFromCenter = (screenVector - center).Magnitude
                    if distanceFromCenter <= Settings.FOV and not isPlayerExcluded(player.Name) then
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

local function CreateFOVCircle()
    if not isMobile then
        if SilentFOVCircle then SilentFOVCircle:Remove() end
        SilentFOVCircle = Drawing.new("Circle")
        SilentFOVCircle.Color = Color3.fromRGB(255, 255, 255)
        SilentFOVCircle.Thickness = 2
        SilentFOVCircle.NumSides = 64
        SilentFOVCircle.Filled = false
        SilentFOVCircle.Transparency = 0.8
        SilentFOVCircle.Radius = Settings.FOV
        SilentFOVCircle.Visible = Settings.Enabled and Settings.ShowFOV
    else
        if SilentFOVCircle and SilentFOVCircle.Parent then SilentFOVCircle.Parent:Destroy() end
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "MobileFOV"
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        SilentFOVCircle = Instance.new("Frame")
        SilentFOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
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

            if Settings.Enabled and args[2] == "shoot_gun" then
                local target = GetClosestTarget()
                if target and target.Character then
                    local aimPart = GetTargetAimPart(target)
                    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                    local humanoid = target.Character:FindFirstChild("Humanoid")

                    if aimPart and humanoid and humanoid.Health > 0 and hrp then
                        local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position
                        local bulletSpeed = BulletData.CurrentVelocity
                        local ping = GetSmoothedPing()
                        local aimPos, flightTime = PredictPosition(origin or aimPart.Position, aimPart.Position, hrp.Velocity, bulletSpeed, Settings.Gravity, ping)
                        
                        local shotId = GenerateShotId()
                        PendingShots[shotId] = {
                            fireTime = tick(),
                            origin = origin,
                            targetPlayer = target,
                            targetPart = aimPart,
                            predictedPos = aimPos,
                            flightTime = flightTime,
                            isHit = false,
                        }
                        
                        task.delay(2, function()
                            if PendingShots[shotId] and not PendingShots[shotId].isHit then
                                PendingShots[shotId] = nil
                            end
                        end)

                        if origin then
                            CreateBulletEffect(origin, aimPos)
                        end

                        args[4] = CFrame.new(
                            1/0, 1/0, 1/0,
                            0/0, 0/0, 0/0,
                            0/0, 0/0, 0/0,
                            0/0, 0/0, 0/0
                        )
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
            return oldFire(self, unpack(args))
        end)
    end)
end

local function OnHealthChanged(player, humanoid, oldHealth, newHealth)
    if newHealth >= oldHealth then return end
    if player == LocalPlayer then return end
    
    local now = tick()
    local bestMatch = nil
    local bestTimeDiff = 0.5
    
    for shotId, data in pairs(PendingShots) do
        if data.targetPlayer == player and not data.isHit then
            local timeDiff = now - data.fireTime
            if timeDiff < bestTimeDiff then
                bestTimeDiff = timeDiff
                bestMatch = {shotId = shotId, data = data, flightTime = timeDiff}
            end
        end
    end
    
    if bestMatch and Settings.LearningEnabled then
        local data = bestMatch.data
        local flightTime = bestMatch.flightTime
        local shotId = bestMatch.shotId
        
        PendingShots[shotId].isHit = true
        
        local currentTargetPos = player.Character and player.Character:FindFirstChild(data.targetPart and data.targetPart.Name or Settings.AimPart)
        if currentTargetPos then
            currentTargetPos = currentTargetPos.Position
        else
            currentTargetPos = data.predictedPos
        end
        
        if data.origin and currentTargetPos then
            local distance = GetDistance(data.origin, currentTargetPos)
            local calculatedVelocity = CalculateVelocity(distance, flightTime)
            
            if calculatedVelocity and calculatedVelocity > 100 and calculatedVelocity < 3000 then
                AddVelocitySample(calculatedVelocity)
            end
        end
        
        PendingShots[shotId] = nil
    end
    
    CreateHitEffect(player.Character)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        humanoid.HealthChanged:Connect(function(oldHealth, newHealth)
            OnHealthChanged(player, humanoid, oldHealth, newHealth)
        end)
    end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.HealthChanged:Connect(function(oldHealth, newHealth)
                OnHealthChanged(player, humanoid, oldHealth, newHealth)
            end)
        end
    end)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        if SilentFOVCircle then
            if not isMobile then
                SilentFOVCircle.Position = center
                SilentFOVCircle.Radius = Settings.FOV
            end
            SilentFOVCircle.Visible = Settings.ShowFOV and Settings.Enabled
        end
        
        if not Settings.Enabled then
            if tracerLine then tracerLine.Visible = false end
            if targetDot then targetDot.Visible = false end
            return
        end
        
        local target = GetClosestTarget()
        if target and target.Character then
            local aimPart = GetTargetAimPart(target)
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = target.Character:FindFirstChild("Humanoid")
            
            if aimPart and humanoid and humanoid.Health > 0 and hrp then
                local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position
                local bulletSpeed = BulletData.CurrentVelocity
                local aimPos = PredictPosition(origin or aimPart.Position, aimPart.Position, hrp.Velocity, bulletSpeed, Settings.Gravity, GetSmoothedPing())
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
                
                if onScreen then
                    if Settings.ShowTracer and tracerLine then
                        tracerLine.Visible = true
                        tracerLine.From = center
                        tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        tracerLine.Color = Color3.fromRGB(255, 50, 50)
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
    end)
end)

CreateFOVCircle()
CreateDrawingObjects()

LocalPlayer.CharacterAdded:Connect(function()
    wait(0.1)
    CreateFOVCircle()
    CreateDrawingObjects()
end)



local CombatTab = Window:Tab({Title = "Silent Aim", Icon = "crosshair"})

CombatTab:Toggle({
    Title = "Silent Aim",
    Desc = "ล็อคอัตโนมัติ + Wallbang",
    Default = Settings.Enabled,
    Callback = function(state)
        Settings.Enabled = state
        if SilentFOVCircle then
            SilentFOVCircle.Visible = Settings.ShowFOV and Settings.Enabled
        end
    end
})

CombatTab:Slider({
    Title = "FOV Radius",
    Step = 1,
    Value = {Min = 20, Max = 500, Default = Settings.FOV},
    Callback = function(value)
        Settings.FOV = tonumber(value) or 150
        if SilentFOVCircle then
            if isMobile then
                SilentFOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)
            else
                SilentFOVCircle.Radius = Settings.FOV
            end
        end
    end
})

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Desc = "แสดงวง FOV",
    Default = Settings.ShowFOV,
    Callback = function(state)
        Settings.ShowFOV = state
        if SilentFOVCircle then
            SilentFOVCircle.Visible = Settings.ShowFOV and Settings.Enabled
        end
    end
})

CombatTab:Divider()

CombatTab:Dropdown({
    Title = "Aim Part",
    Desc = "เลือกส่วนที่ต้องการล็อค",
    Values = AimPartsList,
    Default = Settings.AimPart,
    Callback = function(value)
        Settings.AimPart = value
    end
})

CombatTab:Divider()

CombatTab:Toggle({
    Title = "Tracer Line",
    Desc = "เส้นจากกลางจอไปเป้าหมาย",
    Default = Settings.ShowTracer,
    Callback = function(state)
        Settings.ShowTracer = state
        if not state and tracerLine then
            tracerLine.Visible = false
        end
    end
})

CombatTab:Divider()

CombatTab:Input({
    Title = "Friend List (ไม่ล็อค)",
    Desc = "ใส่ชื่อเพื่อน คั่นด้วยช่องว่าง",
    Value = "",
    Type = "Input",
    Placeholder = "Friend1 Friend2 Friend3",
    Callback = function(input)
        excludedPlayerNames = {}
        for name in string.gmatch(input, "%S+") do
            table.insert(excludedPlayerNames, name)
        end
    end
})

local InfoTab = Window:Tab({Title = "Info", Icon = "info"})

InfoTab:Label({Title = "Bullet Speed: " .. math.floor(BulletData.CurrentVelocity) .. " studs/s"})
InfoTab:Label({Title = "Bullet Effect: AUTO (ขาว/ดำ สลับ)"})
InfoTab:Label({Title = "Hit Effect: AUTO (ขาว/ดำ สลับ)"})

task.spawn(function()
    while true do
        task.wait(1)
        if InfoTab and InfoTab._ui then
            for _, child in ipairs(InfoTab._ui:GetChildren()) do
                if child:IsA("Frame") and child:FindFirstChild("TextLabel") then
                    local label = child.TextLabel
                    if label and label.Text:find("Bullet Speed:") then
                        label.Text = "Bullet Speed: " .. math.floor(BulletData.CurrentVelocity) .. " studs/s"
                        break
                    end
                end
            end
        end
    end
end)

print("Silent Aim Loaded | Current Velocity: " .. math.floor(BulletData.CurrentVelocity) .. " studs/s | Aim Part: " .. Settings.AimPart)
