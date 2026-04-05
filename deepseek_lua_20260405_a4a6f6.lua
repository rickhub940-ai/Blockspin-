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
    Size = UDim2.fromOffset(450, 520),
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
local FOV = 200
local excludedPlayerNames = {}
local AimPart = "Head"

-- ========== ตัวแปร Ballistics (เริ่มต้น) ==========
local GRAVITY = 196.2
local PROJECTILE_SPEED = 2500
local PREDICTION_STRENGTH = 1.0

-- ========== Auto-Learning Variables ==========
local bulletData = {}
local showLearningStatus = true
local lastShotInfo = nil

-- ========== ตัวแปรสำหรับการแสดงผล ==========
local SilentFOVCircle = nil
local tracerLine = nil
local targetDot = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ========== เก็บข้อมูลความเร็วผู้เล่นจริง ==========
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

-- ========== Ballistics Calculations ==========
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
    local gravity = Vector3.new(0, -acceleration * 2, 0)
    local time = getBallisticFlightTime(target - origin, gravity, projectileSpeed)
    return -0.001 * gravity * time^2
end

local function PredictPosition(origin, targetPos, targetVel, player)
    if not origin or not targetPos then return targetPos end
    local direction = targetPos - origin
    local gravityVec = Vector3.new(0, -GRAVITY * 2, 0)
    local pingTime = GetPing()
    local flightTime = getBallisticFlightTime(direction, gravityVec, PROJECTILE_SPEED)
    local totalTime = (flightTime + pingTime) * PREDICTION_STRENGTH
    local realVel = GetRealVelocity(player)
    local useVel = realVel.Magnitude > 0 and realVel or targetVel
    local predictedPos = targetPos + (useVel * totalTime)
    local drop = projectileDrop(origin, predictedPos, PROJECTILE_SPEED, GRAVITY)
    return predictedPos + drop
end

-- ========== Auto-Learning Bullet System (นัดต่อนัด) ==========
local function LearnBulletTime(targetPlayer, startTime, distance, startHealth)
    if not targetPlayer or not targetPlayer.Character then return end
    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local checkCount = 0
    local function CheckBlood()
        checkCount = checkCount + 1
        if checkCount > 80 then  -- ตรวจ 4 วินาทีพอ
            if showLearningStatus then
                WindUI:Notify({
                    Title = "📊 Auto-Learning",
                    Description = "ไม่พบการโดนเป้า (Miss)",
                    Duration = 1
                })
            end
            return 
        end
        
        if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Humanoid") then return end
        local currentHealth = targetPlayer.Character.Humanoid.Health
        
        if currentHealth < startHealth then
            local travelTime = tick() - startTime
            if travelTime > 0 and travelTime < 1.5 then
                table.insert(bulletData, {distance = distance, time = travelTime})
                
                if #bulletData > 30 then 
                    table.remove(bulletData, 1) 
                end
                
                -- คำนวณค่าเฉลี่ยเมื่อมีข้อมูลอย่างน้อย 3 นัด
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
                    
                    -- อัพเดทความเร็วกระสุน
                    if realSpeed > 500 and realSpeed < 10000 then
                        PROJECTILE_SPEED = realSpeed
                    end
                    
                    -- คำนวณแรงโน้มถ่วงจากข้อมูลจริง
                    local totalG = 0
                    for _, data in ipairs(bulletData) do
                        local g = (GRAVITY * data.time^2) / 2
                        totalG = totalG + g
                    end
                    local avgG = totalG / #bulletData
                    if avgG > 50 and avgG < 500 then
                        GRAVITY = avgG
                    end
                    
                    -- ปรับ Prediction Strength ตาม Hit Rate
                    local hitRate = #bulletData / (#bulletData + 5)
                    if hitRate > 0.75 then
                        PREDICTION_STRENGTH = math.min(1.3, PREDICTION_STRENGTH + 0.01)
                    elseif hitRate < 0.5 then
                        PREDICTION_STRENGTH = math.max(0.7, PREDICTION_STRENGTH - 0.01)
                    end
                    
                    if showLearningStatus then
                        WindUI:Notify({
                            Title = "🎯 Auto-Learning",
                            Description = string.format("Speed: %.0f | Gravity: %.1f | Pred: %.2f", 
                                PROJECTILE_SPEED, GRAVITY, PREDICTION_STRENGTH),
                            Duration = 2
                        })
                    end
                end
            end
            return
        end
        task.wait(0.05)
        CheckBlood()
    end
    task.spawn(CheckBlood)
end

-- ========== Get Target Part ==========
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
    tracerLine.Thickness = 1.5
    tracerLine.Transparency = 0.8
    tracerLine.Visible = false
    
    targetDot = Drawing.new("Circle")
    targetDot.Thickness = 2
    targetDot.NumSides = 12
    targetDot.Radius = 5
    targetDot.Filled = true
    targetDot.Transparency = 0.6
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
            if isPlayerExcluded(player.Name) then continue end
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

-- ========== Effects (สวยงามจากไฟล์ต้นฉบับ) ==========
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

-- ========== Remote Hook (Silent Aim + Wallbang + Auto-Learning) ==========
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
                            
                            -- สร้างเอฟเฟกต์
                            CreateBulletEffect(origin.Position, aimPos)
                            
                            -- เริ่มระบบเรียนรู้ (นัดต่อนัด)
                            task.spawn(function()
                                LearnBulletTime(target, startTime, distance, startHealth)
                            end)
                        end
                        
                        CreateHitEffect(target.Character)
                        
                        -- Wallbang (ยิงทะลุกำแพง)
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
                local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                local aimPos = targetPart.Position
                
                if hrp and origin then
                    aimPos = PredictPosition(origin.Position, targetPart.Position, hrp.Velocity, target)
                end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
                
                if onScreen then
                    if tracerLine then
                        tracerLine.Visible = true
                        tracerLine.From = center
                        tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        if AimPart == "Head" then
                            tracerLine.Color = Color3.fromRGB(255, 50, 50)
                        else
                            tracerLine.Color = Color3.fromRGB(50, 255, 50)
                        end
                    end
                    if targetDot then
                        targetDot.Visible = true
                        targetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                        if AimPart == "Head" then
                            targetDot.Color = Color3.fromRGB(255, 50, 50)
                        else
                            targetDot.Color = Color3.fromRGB(50, 255, 50)
                        end
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

-- ========== สร้าง UI Tab ==========
local CombatTab = Window:Tab({Title = "COMBAT", Icon = "crosshair"})

-- Silent Aim Toggle
local SilentToggle = CombatTab:Toggle({
    Title = "Silent Aim | Wallbang",
    Desc = "ล็อคเป้าอัตโนมัติ + ยิงทะลุกำแพง + Auto-Learning วิถีกระสุน",
    Default = false,
    Callback = function(state)
        SilentAimEnabled = state
        if SilentFOVCircle then
            SilentFOVCircle.Visible = ShowFOV and SilentAimEnabled
        end
    end
})
myConfig:Register("SilentAim", SilentToggle)

-- Aim Part Dropdown
local AimPartDropdown = CombatTab:Dropdown({
    Title = "Aim Part",
    Desc = "เลือกส่วนที่จะล็อค",
    Values = {"Head", "Body"},
    Value = "Head",
    Callback = function(option)
        AimPart = option
    end
})
myConfig:Register("AimPart", AimPartDropdown)

-- FOV Slider
local FOVSlider = CombatTab:Slider({
    Title = "FOV Radius",
    Step = 10,
    Value = {Min = 50, Max = 500, Default = FOV},
    Callback = function(value)
        FOV = tonumber(value) or 200
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

-- Show FOV Toggle
local ShowFOVToggle = CombatTab:Toggle({
    Title = "Show FOV Circle",
    Desc = "แสดงวงกลม FOV บนหน้าจอ",
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

-- Auto-Learning Status Toggle
local LearningToggle = CombatTab:Toggle({
    Title = "Show Auto-Learning Status",
    Desc = "แสดงการแจ้งเตือนเมื่อเรียนรู้อัพเดทค่า",
    Default = showLearningStatus,
    Callback = function(state)
        showLearningStatus = state
    end
})
myConfig:Register("ShowLearningStatus", LearningToggle)

-- Reset Learning Data Button
CombatTab:Button({
    Title = "Reset Auto-Learning Data",
    Desc = "ล้างข้อมูลการเรียนรู้ กลับไปใช้ค่าตั้งต้น",
    Callback = function()
        bulletData = {}
        PROJECTILE_SPEED = 2500
        GRAVITY = 196.2
        PREDICTION_STRENGTH = 1.0
        WindUI:Notify({
            Title = "🔄 Reset Complete",
            Description = "ค่า Bullet Data ถูกล้างแล้ว",
            Duration = 2
        })
    end
})

CombatTab:Divider()

-- Safe Friend List
local FriendsInput = CombatTab:Input({
    Title = "Safe Friend List",
    Desc = "ชื่อผู้เล่นที่ไม่โดนล็อค (เว้นวรรค)",
    Value = "",
    InputIcon = "shield-check",
    Type = "Input",
    Placeholder = "Friend1 Friend2",
    Callback = function(input)
        excludedPlayerNames = {}
        for name in string.gmatch(input, "%S+") do
            table.insert(excludedPlayerNames, name)
        end
    end
})
myConfig:Register("FriendsList", FriendsInput)

-- Highlight สำหรับเพื่อน
local excludedPlayersUI = {}
local function UpdateExcludedHighlights()
    for _, player in pairs(Players:GetPlayers()) do
        if isPlayerExcluded(player.Name) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
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

-- ========== อัพเดทความเร็วผู้เล่นแบบเรียลไทม์ ==========
RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        GetRealVelocity(player)
    end
end)

-- ========== Notify สำเร็จ ==========
WindUI:Notify({
    Title = "✅ Silent Aim Complete",
    Description = "โหลด Silent Aim + Ballistics + Auto-Learning + Wallbang เรียบร้อย",
    Duration = 3
})