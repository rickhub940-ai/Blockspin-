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
    Title = "RICK HUB [ BLOCK SPIN] ",
    Icon = "rbxassetid://108958018844079",
    Author = "Author[ 009.exe ]",
    Folder = "DNN HUB",
    Size = UDim2.fromOffset(730, 410),
    Theme = "XenonReal",
    Transparent = true,
    Resizable = true,

    User = {
        Enabled = true,
        Custom = {
            Name = Anonymous,
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






-- Silent aim



local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local SilentAimEnabled = true
local TracerEnabled = true
local ShowFOV = true
local FOV = 150
local HitPart = "Head"
local SavedFriends = {}

local NORMAL_PREDICTION = 0.10
local HIGH_VELOCITY_PREDICTION = 0.3
local VELOCITY_THRESHOLD = 150

local GunNames = {
    "P226","MP5","M24","Draco","Glock","Sawnoff","Uzi","G3","C9",
    "Hunting Rifle","Anaconda","AK47","Remington","Double Barrel"
}
local GunLookup = {}
for _, v in pairs(GunNames) do
    GunLookup[v] = true
end

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1,1,1)
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Filled = false
fovCircle.Visible = ShowFOV

local tracerLine = Drawing.new("Line")
tracerLine.Color = Color3.fromRGB(255,0,0)
tracerLine.Thickness = 2
tracerLine.Visible = false

local targetDot = Drawing.new("Circle")
targetDot.Color = Color3.fromRGB(255,0,0)
targetDot.Radius = 5
targetDot.Filled = true
targetDot.Visible = false

local function createBulletTracer(fromPos, toPos)
    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(0, 0, 0)
    line.Thickness = 3
    line.Transparency = 1

    local start, on1 = Camera:WorldToViewportPoint(fromPos)
    local finish, on2 = Camera:WorldToViewportPoint(toPos)

    if not on1 or not on2 then
        line:Remove()
        return
    end

    line.From = Vector2.new(start.X, start.Y)
    line.To = Vector2.new(finish.X, finish.Y)
    line.Visible = true

    task.spawn(function()
        for i = 1, 12 do
            line.Transparency = 1 - (i/12)
            task.wait(0.02)
        end
        line:Remove()
    end)
end

local function getGunOrigin()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("RightHand")
        or char:FindFirstChild("Right Arm")
        or char:FindFirstChild("HumanoidRootPart")
end

local function getTargetPart(char)
    if HitPart == "Body" then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("Head")
end

local function getClosestTarget()
    local closest, shortest = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not SavedFriends[plr.Name] and plr.Character then
            local part = getTargetPart(plr.Character)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                    if dist < FOV and dist < shortest then
                        shortest = dist
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

local function getPrediction(hrp)
    if hrp.AssemblyLinearVelocity.Magnitude > VELOCITY_THRESHOLD then
        return HIGH_VELOCITY_PREDICTION
    end
    return NORMAL_PREDICTION
end

local send = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Send")

local oldFire
oldFire = hookfunction(send.FireServer, function(self, ...)
    local args = {...}

    local target = getClosestTarget()
    if SilentAimEnabled and target and target.Character then
        local part = getTargetPart(target.Character)
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        local originPart = getGunOrigin()

        if part and hrp and originPart then
            local predictedPos = part.Position + hrp.AssemblyLinearVelocity * getPrediction(hrp)

            createBulletTracer(originPart.Position, predictedPos)

            args[4] = CFrame.new(originPart.Position, predictedPos)

            args[5] = {
                [1] = {
                    [1] = {
                        Instance = part,
                        Position = predictedPos
                    }
                }
            }
        end
    end

    return oldFire(self, unpack(args))
end)

RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    fovCircle.Visible = ShowFOV and SilentAimEnabled
    fovCircle.Position = center
    fovCircle.Radius = FOV

    tracerLine.Visible = false
    targetDot.Visible = false

    if TracerEnabled then
        local target = getClosestTarget()
        if target and target.Character then
            local part = getTargetPart(target.Character)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)

                    tracerLine.From = center
                    tracerLine.To = screenPos
                    tracerLine.Visible = true

                    targetDot.Position = screenPos
                    targetDot.Visible = true
                end
            end
        end
    end
end)



local CombatTab = Window:Tab({Title = "COMBAT", Icon = "user"})



CombatTab:Toggle({
    Title = "Silent Aim | Wallbang",
    Default = SilentAimEnabled,
    Callback = function(v)
        SilentAimEnabled = v
    end
})

CombatTab:Toggle({
    Title = "Show FOV",
    Default = ShowFOV,
    Callback = function(v)
        ShowFOV = v
    end
})

CombatTab:Toggle({
    Title = "Show Tracer",
    Default = TracerEnabled,
    Callback = function(v)
        TracerEnabled = v
    end
})

CombatTab:Slider({
    Title = "FOV Size",
    Step = 1,
    Value = {Min = 20, Max = 500},
    Default = FOV,
    Callback = function(v)
        FOV = v
    end
})

CombatTab:Dropdown({
    Title = "Hit Part",
    Values = {"Head","Body"},
    Default = HitPart,
    Callback = function(v)
        HitPart = v
    end
})

CombatTab:Dropdown({
    Title = "Save Friend",
    Multi = true,
    Values = (function()
        local t = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(t, p.Name)
            end
        end
        return t
    end)(),
    Callback = function(list)
        SavedFriends = {}
        for _, name in pairs(list) do
            SavedFriends[name] = true
        end
    end
})

