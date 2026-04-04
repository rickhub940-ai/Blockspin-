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
    Title = "ERROR HUB | Silent Aim",
    Icon = "",
    Author = "",
    Folder = "ERROR HUB",
    Size = UDim2.fromOffset(450, 400),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
})

-- ========== Config Manager ==========
local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("SilentAimConfig")

-- ========== ตัวแปร Silent Aim ==========
local SilentAimEnabled = false
local ShowFOV = true
local FOV = 120
local excludedPlayerNames = {}
local AimPart = "Head"

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

-- ========== ระบบตรวจจับการเคลื่อนไหวผิดปกติ ==========
local MovementData = {}

local function DetectAbnormalMovement(player, currentPos, currentVel)
    local now = tick()
    local data = MovementData[player]
    
    if not data then
        MovementData[player] = {
            positions = {},
            times = {},
            velocities = {},
            lastUpdate = now,
            lastPos = currentPos,
            lastVel = currentVel,
            abnormalCount = 0,
            predictionReduction = 0
        }
        return 0
    end
    
    table.insert(data.positions, currentPos)
    table.insert(data.times, now)
    table.insert(data.velocities, currentVel)
    
    while #data.times > 0 and now - data.times[1] > 4 do
        table.remove(data.positions, 1)
        table.remove(data.times, 1)
        table.remove(data.velocities, 1)
    end
    
    local abnormalScore = 0
    
    if #data.velocities >= 3 then
        local dirChanges = 0
        for i = #data.velocities - 2, #data.velocities - 1 do
            if i >= 1 and data.velocities[i] and data.velocities[i+1] then
                local v1 = data.velocities[i]
                local v2 = data.velocities[i+1]
                if v1.Magnitude > 5 and v2.Magnitude > 5 then
                    local dot = v1.Unit:Dot(v2.Unit)
                    if dot < 0.3 then
                        dirChanges = dirChanges + 1
                    end
                end
            end
        end
        abnormalScore = abnormalScore + (dirChanges * 25)
    end
    
    if data.lastVel and currentVel then
        local speedChange = (currentVel.Magnitude - data.lastVel.Magnitude)
        if math.abs(speedChange) > 30 then
            abnormalScore = abnormalScore + 30
        end
    end
    
    if data.lastPos and currentPos then
        local distanceJump = (currentPos - data.lastPos).Magnitude
        local timeDiff = now - data.lastUpdate
        local expectedSpeed = data.lastVel and data.lastVel.Magnitude or 0
        local maxPossibleJump = expectedSpeed * timeDiff + 20
        
        if distanceJump > maxPossibleJump + 15 then
            abnormalScore = abnormalScore + 40
        end
    end
    
    if data.lastVel and currentVel and data.lastVel.Magnitude > 10 and currentVel.Magnitude > 10 then
        local angleChange = math.acos(math.clamp(data.lastVel.Unit:Dot(currentVel.Unit), -1, 1)) * (180 / math.pi)
        if angleChange > 90 then
            abnormalScore = abnormalScore + 35
        end
    end
    
    local stayedInPlace = false
    if #data.positions >= 5 then
        local avgPos = Vector3.zero
        for i = #data.positions - 4, #data.positions do
            avgPos = avgPos + data.positions[i]
        end
        avgPos = avgPos / 5
        
        local maxDistanceFromAvg = 0
        for i = #data.positions - 4, #data.positions do
            local dist = (data.positions[i] - avgPos).Magnitude
            if dist > maxDistanceFromAvg then
                maxDistanceFromAvg = dist
            end
        end
        
        if maxDistanceFromAvg < 8 then
            stayedInPlace = true
        end
    end
    
    local predictionReduction = 0
    
    if stayedInPlace and abnormalScore > 30 then
        predictionReduction = 0.85
        data.abnormalCount = math.min(data.abnormalCount + 1, 3)
    elseif abnormalScore > 50 then
        predictionReduction = 0.7
        data.abnormalCount = math.min(data.abnormalCount + 1, 3)
    elseif abnormalScore > 25 then
        predictionReduction = 0.5
        data.abnormalCount = math.min(data.abnormalCount + 0.5, 2)
    else
        data.abnormalCount = math.max(data.abnormalCount - 0.2, 0)
        predictionReduction = 0
    end
    
    if data.abnormalCount >= 2 then
        predictionReduction = math.max(predictionReduction, 0.9)
    end
    
    data.lastPos = currentPos
    data.lastVel = currentVel
    data.lastUpdate = now
    data.predictionReduction = predictionReduction
    
    return predictionReduction
end

-- ========== ฟังก์ชัน Ballistic ==========
local function solveQuadratic(A, B, C)
    local discriminant = B^2 - 4*A*C
    if discriminant < 0 then
        return nil, nil
    end
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
    );
    if root1 and root2 then
        if root1 > 0 and root1 < root2 then
            return math.sqrt(root1);
        elseif root2 > 0 and root2 < root1 then
            return math.sqrt(root2);
        end;
    end;
    return 0;
end;

local function projectileDrop(origin, target, projectileSpeed, acceleration)
    local gravity = Vector3.new() + Vector3.yAxis * (acceleration * 2);
    local time = getBallisticFlightTime(target - origin, gravity, projectileSpeed)
    return -0.001 * gravity * time^2;
end

local function PredictPosition(origin, targetPos, targetVel, player)
    local pingTime = GetPing()
    local distance = (targetPos - origin).Magnitude
    local baseTravelTime = distance / 2500
    local totalTravelTime = baseTravelTime + pingTime
    
    local predictionReduction = 0
    if player then
        predictionReduction = DetectAbnormalMovement(player, targetPos, targetVel)
    end
    
    local adjustedTravelTime = totalTravelTime * (1 - predictionReduction)
    
    local predictedPos = targetPos + (targetVel * adjustedTravelTime)
    
    if predictionReduction > 0.5 then
        predictedPos = (targetPos * 0.6) + (predictedPos * 0.4)
    elseif predictionReduction > 0.2 then
        predictedPos = (targetPos * 0.3) + (predictedPos * 0.7)
    end
    
    local dropMultiplier = 1 - (predictionReduction * 0.5)
    local drop = projectileDrop(origin, predictedPos, 1000, 196.2) * dropMultiplier
    predictedPos = predictedPos + drop
    
    return predictedPos
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
    local lowerPlayerName = string.lower(playerName)
    for _, excludedName in ipairs(excludedPlayerNames) do
        if excludedName ~= "" and string.find(lowerPlayerName, string.lower(excludedName)) then
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

-- ========== เอฟเฟคกระสุนแบบใหม่ (Beam กลม อยู่นาน 1 วินาที) ==========
local function CreateBulletEffect(origin, targetPos)
    pcall(function()
        local bulletColor = GetBulletColor()
        local distance = (targetPos - origin).Magnitude
        local direction = (targetPos - origin).Unit
        
        -- ส่วนเริ่มต้นและปลายทางสำหรับ Beam
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
        
        -- Beam กระสุนกลม
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
        
        -- ไฟส่องสว่าง
        local spotlight = Instance.new("SpotLight")
        spotlight.Brightness = 4
        spotlight.Range = 12
        spotlight.Angle = 45
        spotlight.Enabled = true
        spotlight.Parent = beam
        
        -- อนุภาคตามแนว
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
        
        -- ปากกระบอก
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
        
        -- แสงแฟลช
        local light = Instance.new("PointLight")
        light.Color = bulletColor
        light.Brightness = 5
        light.Range = 15
        light.Parent = muzzleFlash
        Debris:AddItem(light, 1.0)
        
        -- ระเบิดที่เป้า
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
        
        -- วงแหวนระเบิด
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
        
        -- ลบ Beam และ Parts
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
                            -- ====== ทำนายตำแหน่ง ======
                            local pingTime = GetPing()
                            local distance = (targetPart.Position - origin).Magnitude
                            local baseTravelTime = distance / 2500
                            local totalTravelTime = baseTravelTime + pingTime
                            
                            local predictionReduction = DetectAbnormalMovement(target, targetPart.Position, hrp.Velocity)
                            local adjustedTravelTime = totalTravelTime * (1 - predictionReduction)
                            
                            local predictedPos = targetPart.Position + (hrp.Velocity * adjustedTravelTime)
                            
                            if predictionReduction > 0.5 then
                                predictedPos = (targetPart.Position * 0.6) + (predictedPos * 0.4)
                            elseif predictionReduction > 0.2 then
                                predictedPos = (targetPart.Position * 0.3) + (predictedPos * 0.7)
                            end
                            
                            aimPos = predictedPos
                        end

                        -- สร้างเอฟเฟคกระสุน
                        if origin then
                            CreateBulletEffect(origin, aimPos)
                        end

                        CreateHitEffect(target.Character)

                        -- Wallbang
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
