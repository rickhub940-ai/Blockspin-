-- ============================================================
-- SILENT AIM AI ULTIMATE
-- คำนวณอัตโนมัติ: ฟิสิกส์การเคลื่อนที่, ความเร็ว, ปิง, แรงโน้มถ่วง
-- พร้อมระบบต่อต้าน Anti-Aim (การดีด/กระตุก/ความเร็วลวง)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
-- ตัวแปรหลัก
-- ============================================================
local SilentAimEnabled = false
local ShowFOV = true
local FOV = 120
local SilentFOVCircle = nil
local tracerLine = nil
local targetDot = nil
local excludedPlayerNames = {}

-- ============================================================
-- ตัวแปร Ping
-- ============================================================
local Ping = 0
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local pingStats = Stats:FindFirstChild("Network") and Stats.Network:FindFirstChild("Ping")
            if pingStats then
                Ping = math.clamp(pingStats.Value / 1000, 0, 0.5)
            end
        end)
    end
end)

-- ============================================================
-- ค่าคงที่ฟิสิกส์
-- ============================================================
local PHYSICS = {
    GRAVITY = 196.2,
    AIR_RESISTANCE = 0.995,
    MAX_PREDICTION_TIME = 0.4,
    MIN_PREDICTION_TIME = 0.05,
    BULLET_SPEED_BASE = 850,
}

-- ============================================================
-- ระบบ Anti-Aim Detection + Filter
-- ============================================================
local MovementBuffer = {}
local BUFFER_SIZE = 8
local ANTI_AIM_THRESHOLD = 3.5

local function UpdateMovementBuffer(player, position)
    if not MovementBuffer[player] then
        MovementBuffer[player] = {}
    end
    local buffer = MovementBuffer[player]
    table.insert(buffer, position)
    while #buffer > BUFFER_SIZE do
        table.remove(buffer, 1)
    end
end

local function GetMedianPosition(player)
    local buffer = MovementBuffer[player]
    if not buffer or #buffer < 3 then return nil end
    
    local xs, ys, zs = {}, {}, {}
    for _, pos in ipairs(buffer) do
        table.insert(xs, pos.X)
        table.insert(ys, pos.Y)
        table.insert(zs, pos.Z)
    end
    
    local function sortAndGetMid(t)
        table.sort(t)
        return t[math.floor(#t/2) + 1]
    end
    
    return Vector3.new(sortAndGetMid(xs), sortAndGetMid(ys), sortAndGetMid(zs))
end

local function GetSmoothedVelocity(player)
    local buffer = MovementBuffer[player]
    if not buffer or #buffer < 3 then return Vector3.new(0,0,0) end
    
    local velocities = {}
    for i = 2, #buffer do
        local vel = (buffer[i] - buffer[i-1]) / (1/60)
        table.insert(velocities, vel)
    end
    
    if #velocities == 0 then return Vector3.new(0,0,0) end
    
    local sum = Vector3.new(0,0,0)
    for _, v in ipairs(velocities) do
        sum = sum + v
    end
    return sum / #velocities
end

local function IsAntiAiming(player)
    local char = player.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local currentPos = hrp.Position
    local filtered = GetMedianPosition(player)
    
    if not filtered then return false end
    
    local jitter = (currentPos - filtered).Magnitude
    local buffer = MovementBuffer[player]
    
    if not buffer or #buffer < 5 then return false end
    
    local velocityJitter = 0
    for i = 2, #buffer do
        velocityJitter = velocityJitter + (buffer[i] - buffer[i-1]).Magnitude
    end
    velocityJitter = velocityJitter / (#buffer - 1)
    
    return jitter > ANTI_AIM_THRESHOLD or velocityJitter > 8
end

-- ============================================================
-- ฟังก์ชันพื้นฐาน
-- ============================================================
local function isPlayerExcluded(playerName)
    local lowerName = string.lower(playerName)
    for _, excluded in ipairs(excludedPlayerNames) do
        if excluded ~= "" and string.find(lowerName, string.lower(excluded)) then
            return true
        end
    end
    return false
end

-- ============================================================
-- วง FOV
-- ============================================================
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

-- ============================================================
-- วัตถุวาดเส้น
-- ============================================================
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

-- ============================================================
-- หาเป้าหมาย
-- ============================================================
local function GetClosestTarget()
    local closest = nil
    local shortestDistance = FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not isPlayerExcluded(player.Name) then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
                local targetPos = GetMedianPosition(player) or head.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================================
-- AI: คำนวณเวลากระสุน (ปรับตามระยะ + ปิง)
-- ============================================================
local function CalculateFlightTime(distance)
    local bulletSpeed = PHYSICS.BULLET_SPEED_BASE
    
    if distance < 50 then
        bulletSpeed = 700
    elseif distance < 150 then
        bulletSpeed = 850
    elseif distance < 300 then
        bulletSpeed = 1000
    else
        bulletSpeed = 1200
    end
    
    local flightTime = distance / bulletSpeed
    flightTime = math.clamp(flightTime, PHYSICS.MIN_PREDICTION_TIME, PHYSICS.MAX_PREDICTION_TIME)
    flightTime = flightTime + (Ping * 0.6)
    
    return flightTime, bulletSpeed
end

-- ============================================================
-- AI: ทำนายตำแหน่งหลัก (รวมทุกปัจจัย + ต้าน Anti-Aim)
-- ============================================================
local function PredictPosition(target, origin)
    if not target or not target.Character then return nil, false end
    
    local char = target.Character
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    
    if not head or not hrp or not humanoid or humanoid.Health <= 0 then
        return nil, false
    end
    
    -- อัปเดต buffer
    UpdateMovementBuffer(target, hrp.Position)
    
    -- ตรวจจับ Anti-Aim
    local isAnti = IsAntiAiming(target)
    
    -- เลือกตำแหน่งที่จะใช้
    local usePos
    local useVel
    
    if isAnti then
        -- Anti-Aim: ใช้ Median position + smoothed velocity
        usePos = GetMedianPosition(target) or head.Position
        useVel = GetSmoothedVelocity(target)
        
        -- จำกัดความเร็วสูงสุด
        if useVel.Magnitude > 40 then
            useVel = useVel.Unit * 35
        end
        
        -- Anti-Aim: เล็งที่ตัว (HumanoidRootPart) แทนหัว
        usePos = hrp.Position + Vector3.new(0, 2, 0)
    else
        -- ปกติ: ใช้หัว + velocity ปัจจุบัน
        usePos = head.Position
        useVel = hrp.Velocity or Vector3.new(0,0,0)
    end
    
    -- ระยะทาง
    local distance = (usePos - origin).Magnitude
    
    -- เวลากระสุนถึง
    local flightTime, bulletSpeed = CalculateFlightTime(distance)
    
    -- แยกความเร็ว
    local horizontalVel = Vector3.new(useVel.X, 0, useVel.Z)
    local verticalVel = useVel.Y
    
    -- แรงต้านอากาศ
    horizontalVel = horizontalVel * PHYSICS.AIR_RESISTANCE
    
    -- ทำนายแนวราบ
    local predictedHorizontal = usePos + (horizontalVel * flightTime)
    
    -- แนวดิ่ง (แรงโน้มถ่วงกระสุน + เป้าหมาย)
    local bulletDrop = -0.5 * PHYSICS.GRAVITY * flightTime^2
    local targetVerticalMove = verticalVel * flightTime - 0.5 * PHYSICS.GRAVITY * flightTime^2
    
    -- รวมตำแหน่ง
    local predictedPos = Vector3.new(
        predictedHorizontal.X,
        usePos.Y + targetVerticalMove + bulletDrop,
        predictedHorizontal.Z
    )
    
    -- ชดเชยปิง
    if Ping > 0.05 then
        local pingOffset = horizontalVel * (Ping * 0.4)
        predictedPos = predictedPos + pingOffset
    end
    
    -- Anti-Aim: เพิ่ม randomness เพื่อต้าน Anti-Aim
    if isAnti then
        local noise = Vector3.new(
            (math.random() - 0.5) * 1.5,
            (math.random() - 0.5) * 1,
            (math.random() - 0.5) * 1.5
        )
        predictedPos = predictedPos + noise
    end
    
    -- จำกัดการทำนายสูงสุด
    local maxOffset = 18
    local offset = (predictedPos - usePos).Magnitude
    if offset > maxOffset then
        local ratio = maxOffset / offset
        predictedPos = usePos + (predictedPos - usePos) * ratio
    end
    
    return predictedPos, isAnti
end

-- ============================================================
-- เอฟเฟค
-- ============================================================
local function CreateShootEffects(origin, targetPos, hitCharacter, isAnti)
    -- เส้นกระสุน (สีตามสถานะ Anti-Aim)
    local lineColor = isAnti and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(255, 0, 255)
    
    pcall(function()
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Size = Vector3.new(0.15, 0.15, (targetPos - origin).Magnitude)
        part.CFrame = CFrame.new(origin, targetPos) * CFrame.new(0, 0, -part.Size.Z / 2)
        part.Material = Enum.Material.Neon
        part.Transparency = 0.25
        part.Color = lineColor
        part.Parent = Workspace
        Debris:AddItem(part, 0.4)
    end)
    
    -- เอฟเฟคโดนตัว
    if hitCharacter then
        task.spawn(function()
            for _, part in ipairs(hitCharacter:GetDescendants()) do
                if part:IsA("BasePart") then
                    local box = Instance.new("Part")
                    box.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
                    box.CFrame = part.CFrame
                    box.Anchored = true
                    box.CanCollide = false
                    box.Material = Enum.Material.Neon
                    box.Color = Color3.fromRGB(255, 0, 0)
                    box.Transparency = 0.5
                    box.Parent = Workspace
                    TweenService:Create(box, TweenInfo.new(0.5), {Transparency = 1}):Play()
                    Debris:AddItem(box, 0.5)
                end
            end
        end)
    end
end

-- ============================================================
-- Remote Hook
-- ============================================================
local Remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Send")
local oldFire = nil

if Remote and Remote.FireServer then
    pcall(function()
        oldFire = hookfunction(Remote.FireServer, function(self, ...)
            if self ~= Remote then return oldFire(self, ...) end
            local args = {...}

            if SilentAimEnabled and args[2] == "shoot_gun" then
                local target = GetClosestTarget()
                if target and target.Character then
                    local originPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                    
                    if originPart then
                        local origin = originPart.Position
                        local aimPos, isAnti = PredictPosition(target, origin)
                        
                        if aimPos then
                            local head = target.Character:FindFirstChild("Head")
                            
                            CreateShootEffects(origin, aimPos, target.Character, isAnti)
                            
                            args[4] = CFrame.new(99999, 99999, 99999, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                            args[5] = {
                                [1] = {
                                    [1] = {
                                        ["Instance"] = head,
                                        ["Position"] = aimPos
                                    }
                                }
                            }
                        end
                    end
                end
            end
            return oldFire(self, unpack(args))
        end)
    end)
end

-- ============================================================
-- Render Loop
-- ============================================================
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
        
        if not SilentAimEnabled then
            if tracerLine then tracerLine.Visible = false end
            if targetDot then targetDot.Visible = false end
            return
        end
        
        local target = GetClosestTarget()
        if target and target.Character then
            local originPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            local humanoid = target.Character:FindFirstChild("Humanoid")
            
            if originPart and humanoid and humanoid.Health > 0 then
                local aimPos = PredictPosition(target, originPart.Position)
                
                if aimPos then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(aimPos)
                    
                    if onScreen then
                        local screenVec = Vector2.new(screenPos.X, screenPos.Y)
                        
                        if tracerLine then
                            tracerLine.Visible = true
                            tracerLine.From = center
                            tracerLine.To = screenVec
                        end
                        if targetDot then
                            targetDot.Visible = true
                            targetDot.Position = screenVec
                        end
                    else
                        if tracerLine then tracerLine.Visible = false end
                        if targetDot then targetDot.Visible = false end
                    end
                end
            end
        else
            if tracerLine then tracerLine.Visible = false end
            if targetDot then targetDot.Visible = false end
        end
    end)
end)

-- ============================================================
-- ตั้งค่าเริ่มต้น
-- ============================================================
CreateFOVCircle()
CreateDrawingObjects()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    CreateFOVCircle()
    CreateDrawingObjects()
end)


local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "????? HUB | Silent Aim [ test V 0.1 ]",
    Icon = "",
    Author = "009.exe",
    Size = UDim2.fromOffset(420, 320),
    Theme = "Dark",
    Transparent = true,
    Resizable = true,
})

local Tab = Window:Tab({Title = "AIMBOT AI", Icon = "crosshair"})

Tab:Toggle({
    Title = "Silent Aim AI Ultimate",
    Desc = "",
    Default = false,
    Callback = function(state)
        SilentAimEnabled = state
    end
})

Tab:Slider({
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

Tab:Toggle({
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
