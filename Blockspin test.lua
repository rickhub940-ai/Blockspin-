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
local AimPart = "Head"  -- "Head" หรือ "Body"

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

-- ========== ฟังก์ชัน Ballistic (สำหรับระยะไกล) ==========
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
    )
    if root1 and root2 then
        if root1 > 0 and root1 < root2 then
            return math.sqrt(root1)
        elseif root2 > 0 and root2 < root1 then
            return math.sqrt(root2)
        end
    end
    return (direction.Magnitude / projectileSpeed)
end

local function projectileDrop(origin, target, projectileSpeed, acceleration)
    local gravity = Vector3.new(0, -acceleration, 0)
    local time = getBallisticFlightTime(target - origin, gravity, projectileSpeed)
    return 0.5 * gravity * (time^2)
end

-- ========== ระบบตรวจจับ Anti-Look ของเป้า ==========
local AntiLookUsers = {}

local function IsUsingAntiLook(character)
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local vel = hrp.Velocity
    if vel.Magnitude > 100 and math.abs(vel.Y) > 200 then
        return true
    end
    return false
end

local function GetStablePosition(player, currentPos)
    if not IsUsingAntiLook(player.Character) then
        return currentPos
    end
    
    local now = tick()
    local data = AntiLookUsers[player]
    
    if not data then
        AntiLookUsers[player] = {
            positions = {},
            times = {},
            stablePos = currentPos,
            lastUpdate = now
        }
        return currentPos
    end
    
    table.insert(data.positions, currentPos)
    table.insert(data.times, now)
    
    while #data.times > 0 and now - data.times[1] > 0.3 do
        table.remove(data.positions, 1)
        table.remove(data.times, 1)
    end
    
    if #data.positions >= 3 then
        local freq = {}
        for _, pos in ipairs(data.positions) do
            local key = string.format("%.1f,%.1f,%.1f", pos.X, pos.Y, pos.Z)
            freq[key] = (freq[key] or 0) + 1
        end
        
        local maxCount = 0
        local bestKey = nil
        for key, count in pairs(freq) do
            if count > maxCount then
                maxCount = count
                bestKey = key
            end
        end
        
        if bestKey then
            local x, y, z = string.match(bestKey, "(.-),(.-),(.-)")
            data.stablePos = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
        end
    end
    
    return data.stablePos
end

-- ========== ระบบตรวจจับการเคลื่อนไหวผิดปกติ ==========
local MovementData = {}

local function DetectAbnormalMovement(player, currentPos, currentVel)
    if IsUsingAntiLook(player.Character) then
        return 0.9
    end
    
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

-- ========== PredictPosition ฉบับสมบูรณ์ (ระยะใกล้ + ระยะไกล) ==========
local function PredictPosition(origin, targetPos, targetVel, player)
    -- Anti-Look: ล็อคตำแหน่งปัจจุบัน
    if IsUsingAntiLook(player.Character) then
        return targetPos
    end
    
    local distance = (targetPos - origin).Magnitude
    local projectileSpeed = 2500
    local gravity = 196.2
    
    -- ระยะไกล (มากกว่า 100 สตั๊ด) ใช้ Ballistic
    if distance > 100 then
        local travelTime = distance / projectileSpeed
        local pingComp = GetPing()
        local predictedPos = targetPos + (targetVel * (travelTime + pingComp))
        local drop = projectileDrop(origin, predictedPos, projectileSpeed, gravity)
        return predictedPos + drop
    end
    
    -- ระยะใกล้ (น้อยกว่า 100 สตั๊ด) ใช้แบบง่าย
    local pingTime = GetPing()
    local baseTravelTime = distance / projectileSpeed
    local totalTravelTime = baseTravelTime + pingTime
    
    local predictionReduction = DetectAbnormalMovement(player, targetPos, targetVel)
    local adjustedTravelTime = totalTravelTime * (1 - predictionReduction)
    
    local predictedPos = targetPos + (targetVel * adjustedTravelTime)
    
    if predictionReduction > 0.5 then
        predictedPos = (targetPos * 0.6) + (predictedPos * 0.4)
    elseif predictionReduction > 0.2 then
        predictedPos = (targetPos * 0.3) + (predictedPos * 0.7)
    end
    
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
    elseif AimPart == "Body" then
        targetPart = character:FindFirstChild("HumanoidRootPart")
        if not targetPart then
            targetPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        end
    end
    
    if not targetPart then
        targetPart = character:FindFirstChild("HumanoidRootPart")
    end
    
    return targetPart, humanoid
end

-- ========== FOV Circle ==========
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
local function isPlayerExcluded(playerName)
    for _, excludedName in ipairs(excludedPlayerNames) do
        if excludedName == playerName then
            return true
        end
    end
    return false
end

local function GetClosestTarget()
    local closest = nil
    local closestPart = nil
    local shortestDistance = FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart, humanoid = GetTargetPart(player.Character)
            
            if targetPart and humanoid and humanoid.Health > 0 and not isPlayerExcluded(player.Name) then
                local truePos = GetStablePosition(player, targetPart.Position)
                local screenPos, onScreen = Camera:WorldToViewportPoint(truePos)
                
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
                loc
