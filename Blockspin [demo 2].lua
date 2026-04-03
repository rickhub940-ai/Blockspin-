local WindUI = loadstring(game:HttpGet(
"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local player = game.Players.LocalPlayer


--// COLORS (เทาใส)
local DARK1 = Color3.fromHex("#1E1E1E")
local DARK2 = Color3.fromHex("#2A2A2A")
local DARK3 = Color3.fromHex("#242424")
local WHITE = Color3.fromHex("#FFFFFF")

--// GRADIENT (เรียบมาก)
local BG = WindUI:Gradient({
    ["0"] = {Color = DARK1, Transparency = 0.25},
    ["100"] = {Color = DARK2, Transparency = 0.25},
},{Rotation = 90})

local TAB = WindUI:Gradient({
    ["0"] = {Color = DARK2, Transparency = 0.1},
    ["100"] = {Color = DARK3, Transparency = 0.1},
},{Rotation = 90})

--// THEME
WindUI:AddTheme({
    Name = "XenonReal",

    Accent = WHITE, -- ไม่มีสีจัด
    Hover = WHITE,

    Background = BG,
    BackgroundTransparency = 0.35,

    Outline = Color3.fromRGB(255,255,255),
    OutlineTransparency = 0.92, -- จางมาก

    Text = WHITE,
    Icon = WHITE,

    WindowBackground = BG,
    WindowShadow = Color3.fromRGB(0,0,0),

    TabBackground = TAB,
    TabTitle = WHITE,
    TabIcon = WHITE,

    ElementBackground = TAB,
    ElementTitle = WHITE,

    Button = TAB,
    Toggle = TAB,
    Slider = TAB,
})

WindUI:SetTheme("XenonReal")

local avatar = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="
..player.UserId.."&size=420x420&format=Png"

local Window = WindUI:CreateWindow({
    Title = "????? HUB [ Block spin ] ",
    Icon = "rbxassetid://108958018844079",
    Author = "Author[ 009.exe ]",
    Folder = "RICK HUB",
    Size = UDim2.fromOffset(730, 410),
    Theme = "XenonReal",
    Transparent = true,
    Resizable = true,

    User = {
        Enabled = true,
        Custom = {
            Name = player.Name,
            Bio = "RickHUB USER",
            Image = avatar
        }
    }
})
Window:Tag({
    Title = "v0.0.1",
    Icon = "github",
    Color = Color3.fromHex("#00bfff"),
    Radius = 5,
})

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")


Window:EditOpenButton({ Enabled = false })

local ScreenGui = Instance.new("ScreenGui")
local ToggleBtn = Instance.new("ImageButton")

ScreenGui.Name = "WindUI_Toggle"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Image = "rbxassetid://108958018844079"
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local opened = true

local function toggle()
    opened = not opened
    if Window.UI then
        Window.UI.Enabled = opened
    else
        Window:Toggle()
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    ToggleBtn:TweenSize(
        UDim2.new(0, 56, 0, 56),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.12,
        true,
        function()
            ToggleBtn:TweenSize(
                UDim2.new(0, 50, 0, 50),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.12,
                true
            )
        end
    )
    toggle()
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        toggle()
    end
end)










-- [[ 1. ฟิสิกส์และการคำนวณขั้นสูง (Physics & Math Core) ]]
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ค่าคงที่สำหรับคำนวณ (ปรับแต่งได้ตามความแรงปืน)
local PROJECTILE_SPEED = 1000 -- ความเร็วกระสุน (เมตร/วินาที)
local PROJECTILE_GRAVITY = Vector3.new(0, -196.2, 0) -- แรงโน้มถ่วงใน Roblox
local PREDICT_SENSITIVITY = 1.05 -- ค่าชดเชยแรงเหวี่ยง

-- ตัวแปรควบคุม
local SilentAimEnabled = false
local ShowFOV = false
local ShowTargetLine = false
local FOVRadius = 200
local SelectedAimPart = "Head"
local ExcludedPlayers = {}
local CurrentTarget = nil

-- [[ 2. ระบบ Visuals (Drawing) ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 100
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Color = Color3.fromRGB(255, 255, 255)

local TargetLine = Drawing.new("Line")
TargetLine.Thickness = 1.5
TargetLine.Color = Color3.fromRGB(255, 0, 0)

-- [[ 3. ฟังก์ชันการคำนวณความคม (Advanced Logic) ]]

-- ฟังก์ชันคำนวณจุดดักหน้าโดยใช้ฟิสิกส์ (Physics Prediction)
local function getPredictedPosition(targetPart)
    local character = targetPart.Parent
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return targetPart.Position end

    local targetVelocity = rootPart.Velocity
    local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
    local timeToHit = distance / PROJECTILE_SPEED
    
    -- สูตร: ตำแหน่งปัจจุบัน + (ความเร็ว * เวลาที่กระสุนเดินทาง) + การชดเชยแรงโน้มถ่วง
    local prediction = targetPart.Position + (targetVelocity * timeToHit * PREDICT_SENSITIVITY)
    
    -- ถ้าเป้าหมายอยู่ไกลมาก ให้คำนวณวิถีโค้งจากแรงโน้มถ่วงเพิ่ม (Bullet Drop)
    if distance > 100 then
        prediction = prediction - (0.5 * PROJECTILE_GRAVITY * timeToHit^2)
    end
    
    return prediction
end

-- ฟังก์ชันหาเป้าหมายที่ดีที่สุดใน FOV
local function getClosestTarget()
    local closest = nil
    local shortestDist = FOVRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not ExcludedPlayers[player.Name] then
            local targetPart = player.Character:FindFirstChild(SelectedAimPart)
            local hum = player.Character:FindFirstChild("Humanoid")
            
            if targetPart and hum and hum.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist <= FOVRadius and dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- ลูปอัปเดต Visuals
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = FOVRadius
    FOVCircle.Visible = ShowFOV

    CurrentTarget = getClosestTarget()

    if SilentAimEnabled and ShowTargetLine and CurrentTarget and CurrentTarget.Character then
        local targetPart = CurrentTarget.Character:FindFirstChild(SelectedAimPart)
        if targetPart then
            local screenPos, _ = Camera:WorldToViewportPoint(targetPart.Position)
            TargetLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            TargetLine.To = Vector2.new(screenPos.X, screenPos.Y)
            TargetLine.Visible = true
        end
    else
        TargetLine.Visible = false
    end
end)

-- [[ 4. ระบบ Silent Aim Hook (แก้ไขให้นับดาเมจทะลุ) ]]
local _SA_Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Send")
local _oldFire
_oldFire = hookfunction(_SA_Remote.FireServer, function(self, ...)
    local args = {...}
    
    -- args[2] คือชื่อ Event การยิง, args[4] คือ CFrame ทิศทาง, args[5] คือข้อมูลการกระทบ (Hit)
    if SilentAimEnabled and args[2] == "shoot_gun" and CurrentTarget then
        local targetPart = CurrentTarget.Character:FindFirstChild(SelectedAimPart)
        if targetPart then
            local predictedPos = getPredictedPosition(targetPart)
            
            -- ปรับทิศทาง CFrame ให้แม่นยำตามฟิสิกส์
            args[4] = CFrame.new(Camera.CFrame.Position, predictedPos)
            
            -- แก้ไขข้อมูล Hit เพื่อให้เซิร์ฟเวอร์นับดาเมจ (แม้จะ Wallbang)
            -- ส่งตำแหน่งที่คำนวณว่าโดนจริงไปให้เซิร์ฟเวอร์
            args[5] = {
                {
                    [1] = {
                        ["Instance"] = targetPart,
                        ["Normal"] = Vector3.new(0, 1, 0), -- ปรับให้ดูเป็นมุมฉากกับพื้นโลกเพื่อความเนียน
                        ["Position"] = predictedPos
                    }
                }
            }
        end
    end
    return _oldFire(self, unpack(args))
end)

-- [[ 5. ส่วนของปุ่มกด UI (อยู่ล่างสุดตามสั่ง) ]]
-- ใช้ชื่อตัวแปร MainTab ตามโครงสร้างไฟล์ Block spin ของคุณ




local MainTab = Window:Tab({Title = "MAIN", Icon = "user"})
MainTab:Toggle({
    Title = "Ultra Ultimate Pro Max Silent Aim 👉💀👈",
    Default = false,
    Callback = function(state) SilentAimEnabled = state end
})

MainTab:Dropdown({
    Title = " Aim Part",
    Options = {"Head", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(v) SelectedAimPart = v end
})
MainTab:Slider({
    Title = "FOV Size",
    Desc = "ปรับวง",
    Value = {Min = 10, Max = 800, Default = 200},
    Callback = function(v) FOVRadius = v end
})

MainTab:Dropdown({
    Title = " Exclude Player",
    Desc = "เลือกรายชื่อคนที่จะไม่ล็อกเป้า",
    Options = (function() 
        local n = {} 
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(n, p.Name) end end 
        return n 
    end)(),
    Default = nil,
    Callback = function(v) ExcludedPlayers[v] = not ExcludedPlayers[v] end
})

MainTab:Toggle({
    Title = " Show FOV Circle",
    Default = false,
    Callback = function(state) ShowFOV = state end
})

MainTab:Toggle({
    Title = "Show Target Line",
    Default = false,
    Callback = function(state) ShowTargetLine = state end
})

