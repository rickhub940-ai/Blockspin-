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




-- Esp


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalHRP = LocalCharacter:WaitForChild("HumanoidRootPart")

local ESPSettings = {
    Box = false,
    Name = false,
    Distance = false,
    Health = false
}

local ESP = {}
ESP.__index = ESP

function ESP.new()
    return setmetatable({cache = {}}, ESP)
end

function ESP:createDrawing(type, props)
    local d = Drawing.new(type)
    for i,v in pairs(props) do
        d[i] = v
    end
    return d
end

function ESP:createComponents()
    return {
        Box = self:createDrawing("Square", {
            Thickness = 1,
            Color = Color3.fromRGB(255,255,255),
            Filled = false,
            Visible = false
        }),
        Name = self:createDrawing("Text", {
            Size = 16,
            Center = true,
            Outline = true,
            Visible = false
        }),
        Distance = self:createDrawing("Text", {
            Size = 14,
            Center = true,
            Outline = true,
            Visible = false
        }),
        HealthOutline = self:createDrawing("Square", {
            Thickness = 1,
            Color = Color3.new(0,0,0),
            Filled = false,
            Visible = false
        }),
        Health = self:createDrawing("Square", {
            Thickness = 1,
            Filled = true,
            Visible = false
        })
    }
end

function ESP:update(comp, char, plr)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        self:hide(comp)
        return
    end

    local dist = (LocalHRP.Position - hrp.Position).Magnitude

    local scale = 1 / (pos.Z * math.tan(math.rad(Camera.FieldOfView/2)) * 2) * 100
    local w = math.floor(Camera.ViewportSize.Y / 25 * scale)
    local h = math.floor(Camera.ViewportSize.X / 27 * scale)

    local boxPos = Vector2.new(pos.X - w/2, pos.Y - h/2)

    comp.Box.Visible = ESPSettings.Box
    if ESPSettings.Box then
        comp.Box.Size = Vector2.new(w,h)
        comp.Box.Position = boxPos
    end

    comp.Name.Visible = ESPSettings.Name
    if ESPSettings.Name then
        comp.Name.Text = plr.Name
        comp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - 14)
        if plr.Team and plr.TeamColor then
            comp.Name.Color = plr.TeamColor.Color
        else
            comp.Name.Color = Color3.fromRGB(255,255,255)
        end
    end

    comp.Distance.Visible = ESPSettings.Distance
    if ESPSettings.Distance then
        comp.Distance.Text = "["..math.floor(dist).."]"
        comp.Distance.Position = Vector2.new(pos.X, pos.Y + h/2 + 2)
    end

    comp.Health.Visible = ESPSettings.Health
    comp.HealthOutline.Visible = ESPSettings.Health

    if ESPSettings.Health then
        local hp = hum.Health / hum.MaxHealth
        comp.HealthOutline.Size = Vector2.new(4,h)
        comp.HealthOutline.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
        comp.Health.Size = Vector2.new(2, h * hp)
        comp.Health.Position = Vector2.new(boxPos.X - 5, boxPos.Y + h*(1-hp))
        comp.Health.Color = Color3.fromRGB(255*(1-hp),255*hp,0)
    end
end

function ESP:hide(comp)
    for _,v in pairs(comp) do
        if typeof(v) == "table" then
            for _,x in pairs(v) do x.Visible = false end
        else
            v.Visible = false
        end
    end
end

function ESP:remove(plr)
    local comp = self.cache[plr]
    if comp then
        for _,v in pairs(comp) do
            if typeof(v) == "table" then
                for _,x in pairs(v) do x:Remove() end
            else
                v:Remove()
            end
        end
        self.cache[plr] = nil
    end
end

local esp = ESP.new()

RunService.RenderStepped:Connect(function()
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                if not esp.cache[plr] then
                    esp.cache[plr] = esp:createComponents()
                end
                esp:update(esp.cache[plr], char, plr)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    esp:remove(plr)
end)



-- Esp items 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false
local BillboardCache = {}
local WeaponDB = {}
local ESPConnection = nil

local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(200, 200, 200),
    ["Uncommon"] = Color3.fromRGB(86, 176, 62),
    ["Rare"] = Color3.fromRGB(0, 162, 255),
    ["Epic"] = Color3.fromRGB(170, 85, 255),
    ["Legendary"] = Color3.fromRGB(255, 170, 0),
    ["Omega"] = Color3.fromRGB(255, 75, 75)
}

local function registerItems(folder)
    for _, tool in ipairs(folder:GetChildren()) do
        local handle = tool:FindFirstChild("Handle")
        local key
        if handle then
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                key = mesh.MeshId .. (mesh.TextureId or "")
            elseif handle:IsA("MeshPart") then
                key = handle.MeshId .. (handle.TextureID or "")
            end
        end
        if key then
            WeaponDB[key] = {
                Name = tool:GetAttribute("DisplayName") or tool.Name,
                Rarity = tool:GetAttribute("RarityName") or "Common",
                ImageId = tool:GetAttribute("ImageId") or "rbxassetid://7072725737"
            }
        else
            WeaponDB[tool.Name] = {
                Name = tool:GetAttribute("DisplayName") or tool.Name,
                Rarity = tool:GetAttribute("RarityName") or "Common",
                ImageId = tool:GetAttribute("ImageId") or "rbxassetid://7072725737"
            }
        end
    end
end

local function getMeshId(tool)
    local handle = tool:FindFirstChild("Handle")
    if not handle then return nil end
    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    if mesh then
        return mesh.MeshId .. (mesh.TextureId or "")
    end
    if handle:IsA("MeshPart") then
        return handle.MeshId .. (handle.TextureID or "")
    end
    return nil
end

local function getWeaponInfo(tool)
    local meshId = getMeshId(tool)
    if meshId and WeaponDB[meshId] then
        return WeaponDB[meshId]
    elseif WeaponDB[tool.Name] then
        return WeaponDB[tool.Name]
    else
        return nil
    end
end

local function createBillboardForPlayer(player)
    if not ESPEnabled or player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if BillboardCache[player] then
        BillboardCache[player]:Destroy()
        BillboardCache[player] = nil
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(0, 90, 0, 20)
    billboard.StudsOffset = Vector3.new(0, -5.0, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char
    billboard:ClearAllChildren()
    
    local layout = Instance.new("UIListLayout", billboard)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local tools = {}
    for _, container in ipairs({"Backpack", "StarterGear", "StarterPack"}) do
        local obj = player:FindFirstChild(container)
        if obj then
            for _, tool in ipairs(obj:GetChildren()) do
                if tool:IsA("Tool") and tool.Name ~= "Fists" then
                    table.insert(tools, tool)
                end
            end
        end
    end
    
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.Name ~= "Fists" then
                table.insert(tools, tool)
            end
        end
    end
    
    for _, tool in ipairs(tools) do
        local info = getWeaponInfo(tool)
        if info then
            local img = Instance.new("ImageLabel", billboard)
            img.Size = UDim2.new(0, 20, 0, 20)
            img.BackgroundTransparency = 0.1
            img.Image = info.ImageId
            img.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
            Instance.new("UICorner", img).CornerRadius = UDim.new(0, 10)
            local border = Instance.new("UIStroke", img)
            border.Color = RARITY_COLORS[info.Rarity] or Color3.new(1, 1, 1)
            border.Thickness = 2
        end
    end
    
    BillboardCache[player] = billboard
end

for _, category in ipairs({"gun", "melee", "throwable", "consumable", "farming", "misc", "rod", "fish"}) do
    local folder = ReplicatedStorage:FindFirstChild("Items")
    if folder then
        local cat = folder:FindFirstChild(category)
        if cat then
            registerItems(cat)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPEnabled then
            task.wait(0.2)
            createBillboardForPlayer(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if BillboardCache[player] then
        BillboardCache[player]:Destroy()
        BillboardCache[player] = nil
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




local EspTab = Window:Tab({Title = "ESP", Icon = "eye"})

EspTab:Toggle({
    Title = "ESP Box",
    Default = false,
    Callback = function(v)
        ESPSettings.Box = v
    end
})

EspTab:Toggle({
    Title = "ESP Name",
    Default = false,
    Callback = function(v)
        ESPSettings.Name = v
    end
})

EspTab:Toggle({
    Title = "ESP Distance",
    Default = false,
    Callback = function(v)
        ESPSettings.Distance = v
    end
})

EspTab:Toggle({
    Title = "ESP Health",
    Default = false,
    Callback = function(v)
        ESPSettings.Health = v
    end
})

local ItemsESPToggle = EspTab:Toggle({
    Title = "Items Invectorry ESP",
    Default = false,
    Callback = function(state)
        ESPEnabled = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    createBillboardForPlayer(p)
                end
            end
            ESPConnection = RunService.Heartbeat:Connect(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        createBillboardForPlayer(p)
                    end
                end
            end)
        else
            if ESPConnection then
                ESPConnection:Disconnect()
                ESPConnection = nil
            end
            for _, billboard in pairs(BillboardCache) do
                billboard:Destroy()
            end
            BillboardCache = {}
        end
    end
})
