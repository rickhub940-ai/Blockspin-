


local WindUI = loadstring(game:HttpGet(
"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local player = game.Players.LocalPlayer




local avatar = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="
..player.UserId.."&size=420x420&format=Png"

local Window = WindUI:CreateWindow({
    Title = "Dipper HUB [ BLOCK SPIN] ",
    Icon = "rbxassetid://124339558110081",
    Author = "Author[ 009.exe ]",
    Folder = "DNN HUB",
    Size = UDim2.fromOffset(730, 410),
    Theme = "Light",
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
ToggleBtn.Image = "rbxassetid://124339558110081"
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui


local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ToggleBtn

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255,255,255)
UIStroke.Parent = ToggleBtn

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
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Network = require(ReplicatedStorage.Modules.Core.Net)

local TargetHistory = {}

local SilentAimEnabled = false
local ShowFOV = false
local ShowTracer = false
local FOV = 200
local HIGH_VEL_THRESHOLD = 250
local HitPart = "Head"
local SavedFriends = {}

local fovCircle = Drawing.new("Circle")
fovCircle.Radius = FOV
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255,255,255)
fovCircle.Visible = false

local tracer = Drawing.new("Line")
tracer.Thickness = 2
tracer.Color = Color3.fromRGB(255,0,0)
tracer.Visible = false

local TargetDot = Drawing.new("Circle")
TargetDot.Color = Color3.fromRGB(255,0,0)
TargetDot.Radius = 4
TargetDot.Filled = true
TargetDot.Visible = false

local shotToggle = false

local function CreateTracer(fromPos, toPos)
    if not SilentAimEnabled then return end
    shotToggle = not shotToggle
    local distance = (toPos - fromPos).Magnitude

    local part = Instance.new("Part")  
    part.Size = Vector3.new(0.25, 0.25, distance)  
    part.CFrame = CFrame.new(fromPos, toPos) * CFrame.new(0, 0, -distance/2)  
    part.Anchored = true  
    part.CanCollide = false  
    part.Material = Enum.Material.Neon  
    part.Color = shotToggle and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,255,255)  
    part.Parent = workspace  

    Debris:AddItem(part, 3)
end

local function GetDistanceStart(a, b)
    return (a - b).Magnitude
end

local function WorldToViewPoint(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return vp, onScreen
end

local function IsAlive(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    return hum and root and hum.Health > 0
end

local function IsBehindWall(startPos, endPos, ignore)
    local ray = Ray.new(startPos, endPos - startPos)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, ignore or {})
    return hit ~= nil
end

local function getPart(char)
    if HitPart == "Head" then
        return char:FindFirstChild("Head")
    else
        return char:FindFirstChild("HumanoidRootPart")
    end
end

local function GetClosestTarget()
    local closest = nil
    local dist = math.huge

    for _, v in pairs(Players:GetPlayers()) do  
        if v ~= LocalPlayer and not SavedFriends[v.Name] and v.Character and IsAlive(v.Character) then  
            local targetPart = getPart(v.Character)  
            if targetPart then  
                local pos, onScreen = WorldToViewPoint(targetPart.Position)  
                if onScreen then  
                    local d = GetDistanceStart(  
                        Vector2.new(pos.X, pos.Y),  
                        Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)  
                    )  
                    if d < FOV and d < dist then  
                        closest = v.Character  
                        dist = d  
                    end  
                end  
            end  
        end  
    end  

    return closest
end

RunService.RenderStepped:Connect(function()
    if not SilentAimEnabled then
        fovCircle.Visible = false
        tracer.Visible = false
        TargetDot.Visible = false
        return
    end

    -- อัปเดตรัศมี FOV ให้ตรงกับค่าปัจจุบัน
    if fovCircle.Radius ~= FOV then
        fovCircle.Radius = FOV
    end

    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)  
    fovCircle.Visible = ShowFOV  

    if ShowTracer then  
        local target = GetClosestTarget()  
        if target then  
            local targetPart = getPart(target)  
            if targetPart then  
                local pos, onScreen = WorldToViewPoint(targetPart.Position)  
                if onScreen then  
                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)  
                    local screenPos = Vector2.new(pos.X, pos.Y)  
                      
                    tracer.From = center  
                    tracer.To = screenPos  
                    tracer.Visible = true  
                      
                    TargetDot.Position = screenPos  
                    TargetDot.Visible = true  
                else  
                    tracer.Visible = false  
                    TargetDot.Visible = false  
                end  
            else  
                tracer.Visible = false  
                TargetDot.Visible = false  
            end  
        else  
            tracer.Visible = false  
            TargetDot.Visible = false  
        end  
    else  
        tracer.Visible = false  
        TargetDot.Visible = false  
    end
end)

local function solveQuadratic(A, B, C)
    local D = B^2 - 4*A*C
    if D < 0 then return nil, nil end
    local s = math.sqrt(D)
    return (-B - s)/(2*A), (-B + s)/(2*A)
end

local function getBallisticFlightTime(direction, gravity, speed)
    local r1, r2 = solveQuadratic(
        gravity:Dot(gravity)/3.8,
        gravity:Dot(direction) - speed^2,
        direction:Dot(direction)
    )

    if r1 and r2 then  
        if r1 > 0 then return math.sqrt(r1) end  
        if r2 > 0 then return math.sqrt(r2) end  
    end  

    return 0
end

local function PredictPosition(pos, vel, t, gravity)
    return pos + vel * t + (0.001 * gravity * (t^2))
end

local function GetVelocity(target, pos)
    local t = tick()

    TargetHistory[target] = TargetHistory[target] or {}  
    local hist = TargetHistory[target]  

    if #hist >= 3 then table.remove(hist, 1) end  
    table.insert(hist, {pos = pos, time = t})  

    if #hist < 2 then return Vector3.zero end  

    local p1 = hist[#hist - 1]  
    local p2 = hist[#hist]  

    local dt = math.max(p2.time - p1.time, 1e-6)  
    return (p2.pos - p1.pos) / dt
end

local OldSend
OldSend = hookfunction(Network.send, function(...)
    local args = {...}

    if args[1] == "shoot_gun" and SilentAimEnabled then  
        local target = GetClosestTarget()  

        if target then  
            local part = getPart(target)  
            if part then  
                local char = LocalPlayer.Character  
                if not char then return OldSend(...) end  

                local root = char:FindFirstChild("HumanoidRootPart")  
                if not root then return OldSend(...) end  

                local myPos = root.Position  
                local targetPos = part.Position  

                local vel = GetVelocity(target, targetPos)  
                local velMagnitude = vel.Magnitude  

                local predictedPos  

                if velMagnitude >= HIGH_VEL_THRESHOLD then  
                    predictedPos = targetPos  
                else  
                    local dir = targetPos - myPos  
                    local gravity = Vector3.new(0, -workspace.Gravity, 0)  
                    local speed = 1000  

                    local t = getBallisticFlightTime(dir, gravity, speed)  
                    predictedPos = PredictPosition(targetPos, vel, t, gravity)  
                end  

                local ignore = {LocalPlayer.Character, target}  
                local behind = IsBehindWall(myPos, predictedPos, ignore)  

                if behind then  
                    args[3] = CFrame.new(math.huge, math.huge, math.huge)  
                else  
                    args[3] = CFrame.new(myPos, predictedPos)  
                end  

                for _, v in pairs(args[4] or {}) do  
                    for _, x in pairs(v) do  
                        x.Position = predictedPos  
                        x.Instance = part  
                    end  
                end  

                CreateTracer(myPos, predictedPos)  
            end  
        end  
    end  

    return OldSend(table.unpack(args))
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

local function updateESP()
    if not ESPSettings.Box and not ESPSettings.Name and not ESPSettings.Distance and not ESPSettings.Health then
        return
    end
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
end
espConnection = RunService.RenderStepped:Connect(updateESP)

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


-- Walkspeed







-- Farm ถูพื้นกากๆ




    






-- farm 7-11 + Auto Deposit

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local ATMModule = require(ReplicatedStorage.Modules.Game.ATM.ATM)
local Net = require(ReplicatedStorage.Modules.Core.Net)

local Client = Players.LocalPlayer
_G.StopWalking = false
_G.AutoATM = false
_G.AutoSevenEleven = false


if not _G.Bypass then
    local func = getupvalue(Net.get, 2)
    if func then
        setconstant(func, 3, "KUYIENGOKUYIENGO")
        setconstant(func, 4, "KUYIENGOKUYIENGO")
    end
    _G.Bypass = true
end


local DepositAmount = 200

local function GetMoney()
    local gui = Client:FindFirstChild("PlayerGui")
    if not gui then return 0 end
    local hud = gui:FindFirstChild("TopRightHud", true)
    if not hud then return 0 end
    local label = hud:FindFirstChild("MoneyTextLabel", true)
    if not label or not label.Text then return 0 end
    local text = label.Text:gsub("[$,]", "")
    local num = text:match("%d+")
    return tonumber(num) or 0
end

local function IsATMAvailable(atm)
    return atm and atm.states and atm.states.hacker.get() == nil and atm.states.disabled.get() == false
end

local function GetNearestATM()
    local char = Client.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, dist = nil, math.huge
    for _, atm in pairs(ATMModule.class.objects) do
        if IsATMAvailable(atm) then
            local root = atm.instance:FindFirstChildWhichIsA("BasePart")
            if root then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = atm
                end
            end
        end
    end
    return nearest
end

local function computePath(startPos, endPos)
    local path = PathfindingService:CreatePath({
        AgentCanJump = true,
        AgentJumpHeight = 6,
        AgentHeight = 5,
        AgentRadius = 2,
        WaypointSpacing = 3
    })
    local function try(goal)
        local ok = pcall(function()
            path:ComputeAsync(startPos, goal)
        end)
        return ok and path.Status == Enum.PathStatus.Success
    end
    if try(endPos) then return path end
    for i = 1, 3 do
        local offset = Vector3.new(math.random(-6,6), 0, math.random(-6,6))
        if try(endPos + offset) then
            return path
        end
    end
    return nil
end

local function walkToATM(atm)
    local character = Client.Character or Client.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local root = atm.instance:FindFirstChildWhichIsA("BasePart")
    if not root then return false end
    local path = computePath(rootPart.Position, root.Position)
    if not path then return false end
    for _, wp in ipairs(path:GetWaypoints()) do
        if humanoid.Health <= 0 then return false end
        if not IsATMAvailable(atm) then return false end
        humanoid:MoveTo(wp.Position)
        if wp.Action == Enum.PathWaypointAction.Jump then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        local reached = false
        local conn = humanoid.MoveToFinished:Connect(function()
            reached = true
            if conn then conn:Disconnect() end
        end)
        local start = tick()
        repeat
            task.wait()
            if _G.StopWalking or not _G.AutoATM then
                if conn then conn:Disconnect() end
                return false
            end
            if tick() - start > 3 then
                if conn then conn:Disconnect() end
                return false
            end
        until reached
    end
    return true
end

local function IsNearATM(atm)
    local char = Client.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local root = atm.instance:FindFirstChildWhichIsA("BasePart")
    if not hrp or not root then return false end
    return (hrp.Position - root.Position).Magnitude <= 6
end

local function DepositMoney(amount)
    Net.get("transfer_funds", "hand", "bank", amount)
end

-- ========== SEVEN ELEVEN SYSTEM ==========
local function removeBlockers()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "DoorSystem" or v.Name == "VehicleBlockers" then 
            v:Destroy()
        end
    end
end

local function updateCharacter()
    local Character = Client.Character or Client.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local RootPart = Character:WaitForChild("HumanoidRootPart")
    local Backpack = Client:WaitForChild("Backpack")
    return Character, Humanoid, RootPart, Backpack
end

local function autoApplyJob()
    if Client:GetAttribute("Job") == "shelf_stocker" then 
        return true 
    end
    local jobGui = Client.PlayerGui:FindFirstChild("JobApplication")
    if jobGui and jobGui.Enabled then
        local frame = jobGui:FindFirstChild("JobApplicationFrame") or jobGui:FindFirstChild("Frame")
        local btn = frame and (frame:FindFirstChild("ApplyJob") or frame:FindFirstChild("Apply"))
        if frame and frame.Visible and btn and btn.Visible then
            pcall(function()
                btn.Selectable = true
                GuiService.SelectedObject = btn
                task.wait(0.1)
                VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end)
            task.wait(1.5)
            return Client:GetAttribute("Job") == "shelf_stocker"
        end
    end
    return false
end

local function walkToSeven(destination, char, humanoid, rootPart)
    if not destination or not rootPart then return false end
    if _G.StopWalking then return false end
    
    local path = PathfindingService:CreatePath({
        AgentCanJump = true,
        AgentJumpHeight = 2,
        AgentHeight = 5.5,
        AgentRadius = 2.5,
    })
    
    local success = pcall(function()
        path:ComputeAsync(rootPart.Position, destination)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if _G.StopWalking or not _G.AutoSevenEleven then return false end
            if humanoid and humanoid.Health <= 0 then break end
            
            local finished = false
            local conn = humanoid.MoveToFinished:Connect(function()
                finished = true
                if conn then conn:Disconnect() end
            end)
            
            humanoid:MoveTo(wp.Position)
            if wp.Action == Enum.PathWaypointAction.Jump then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            repeat task.wait() until finished or _G.StopWalking or not _G.AutoSevenEleven
            if _G.StopWalking or not _G.AutoSevenEleven then return false end
        end
    end
    return true
end

local function AutoSevenElevenQuest()
    if _G.StopWalking then return end
    
    local Character, Humanoid, RootPart, Backpack = updateCharacter()
    if not RootPart or not Humanoid or Humanoid.Health <= 0 then return end
    
    if Client:GetAttribute("Job") == "shelf_stocker" then
        if not Backpack:FindFirstChild("BoxTool") and not Character:FindFirstChild("BoxTool") then
            local boxPos = Vector3.new(143, 255, 207)
            walkToSeven(boxPos, Character, Humanoid, RootPart)
            if (RootPart.Position - boxPos).Magnitude < 5 then
                local boxPrompt = workspace:FindFirstChild("Map")
                    and workspace.Map:FindFirstChild("Tiles")
                    and workspace.Map.Tiles:FindFirstChild("GasStationTile")
                    and workspace.Map.Tiles.GasStationTile:FindFirstChild("Quick11")
                    and workspace.Map.Tiles.GasStationTile.Quick11:FindFirstChild("Interior")
                    and workspace.Map.Tiles.GasStationTile.Quick11.Interior:FindFirstChild("ShelfStockingJob")
                    and workspace.Map.Tiles.GasStationTile.Quick11.Interior.ShelfStockingJob:FindFirstChild("NormalBox")
                    and workspace.Map.Tiles.GasStationTile.Quick11.Interior.ShelfStockingJob.NormalBox:FindFirstChild("ProximityPrompt")
                if boxPrompt then
                    local fireproximityprompt = fireproximityprompt or getfenv().fireproximityprompt
                    fireproximityprompt(boxPrompt, 3)
                end
            end
        elseif Character:FindFirstChild("BoxTool") then
            local shelves = workspace:FindFirstChild("Map")
                and workspace.Map:FindFirstChild("Tiles")
                and workspace.Map.Tiles:FindFirstChild("GasStationTile")
                and workspace.Map.Tiles.GasStationTile:FindFirstChild("Quick11")
                and workspace.Map.Tiles.GasStationTile.Quick11:FindFirstChild("Interior")
                and workspace.Map.Tiles.GasStationTile.Quick11.Interior:FindFirstChild("ShelfStockingJob")
                and workspace.Map.Tiles.GasStationTile.Quick11.Interior.ShelfStockingJob:FindFirstChild("Shelves")
            if shelves then
                for _, shelf in ipairs(shelves:GetChildren()) do
                    if not _G.AutoSevenEleven or _G.StopWalking then break end
                    if shelf:FindFirstChild("Attachment") then
                        walkToSeven(shelf.Position, Character, Humanoid, RootPart)
                        task.wait(1)
                    end
                end
            end
        else
            local tool = Backpack:FindFirstChild("BoxTool")
            if tool then Humanoid:EquipTool(tool) end
        end
    else
        local jobPos = Vector3.new(166.34539794921875, 255.19053649902344, 203.02333068847656)
        walkToSeven(jobPos, Character, Humanoid, RootPart)
        task.wait(0.5)
        autoApplyJob()
    end
end

-- ========== MAIN LOOP ==========
task.spawn(function()
    removeBlockers()
    workspace.DescendantAdded:Connect(function(descendant)
        task.wait(0.5)
        if descendant.Name == "DoorSystem" or descendant.Name == "VehicleBlockers" then
            removeBlockers()
        end
    end)
    
    while task.wait(1) do
        if _G.AutoATM and not _G.AutoSevenEleven then
            if not _G.StopWalking then
                local money = GetMoney()
                if money >= DepositAmount then
                    _G.StopWalking = true
                    local atm = GetNearestATM()
                    if atm then
                        local success = walkToATM(atm)
                        if success and IsNearATM(atm) then
                            DepositMoney(DepositAmount)
                            task.wait(2)
                        end
                    end
                    _G.StopWalking = false
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if _G.AutoSevenEleven and not _G.AutoATM then
            if not _G.StopWalking then
                AutoSevenElevenQuest()
            end
        end
        task.wait(0.1)
    end
end)


-- Anti kill

local flickering = false
local undergroundBaseCFrame = nil
local AntiKillEnabled = false  

local function isDowned()
    local hum = CharModule.get_hum()
    return hum and (hum:GetAttribute("HasBeenDowned") or hum:GetAttribute("IsDead") or hum.Health <= 0)
end

local function getHRP()
    local char = CharModule.current_char.get()
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart")
end

local function teleportUnderground()
    local hrp = getHRP()
    if not hrp then return end
    local original = hrp.CFrame
    undergroundBaseCFrame = original + Vector3.new(0, -55, 0)
    hrp.CFrame = undergroundBaseCFrame
end

local function flickerAndMove()
    if flickering then return end
    flickering = true
    task.spawn(function()
        while flickering and AntiKillEnabled and isDowned() do 
            local hrp = getHRP()
            if hrp and undergroundBaseCFrame then
                local angle = math.random() * math.pi * 2
                local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 10
                local randomPos = undergroundBaseCFrame.Position + offset
                hrp.CFrame = CFrame.new(randomPos)
                task.wait(0.05)
                hrp.CFrame = undergroundBaseCFrame
            end
            task.wait(0.1)
        end
        flickering = false
    end)
end
RunService.Heartbeat:Connect(function()
    if not AntiKillEnabled then return end 
    if isDowned() then
        local hrp = getHRP()
        if hrp and not undergroundBaseCFrame then
            teleportUnderground()
        end
        flickerAndMove()
    else
        if undergroundBaseCFrame then
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = undergroundBaseCFrame + Vector3.new(0, 55, 0)
            end
        end
        undergroundBaseCFrame = nil
        flickering = false
    end
end)


        



-- Esp anti aim

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local IMAGEAntiaim_ID = "rbxassetid://94861926327838"
local EspVelocit_limit = 200
local RATIO_LIMIT = 0.35
local MIN_MOVE = 2
local DETECT_FRAMES = 3

local AntiAimEnabled = false

local ESPsAntiAim = {}
local LastData = {}
local Flags = {}

local function createESP(char, player)
    if ESPsAntiAim[player] then return end

    local head = char:FindFirstChild("Head")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 60, 0, 60)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 45, 0, 45)
    img.Position = UDim2.new(0.5, -22, 0, 0)
    img.BackgroundTransparency = 1
    img.Image = IMAGEAntiaim_ID
    img.Parent = billboard

    billboard.Parent = head

    ESPsAntiAim[player] = {
        gui = billboard,
        img = img,
        t = 0
    }
end

local function removeESP(player)
    if ESPsAntiAim[player] then
        ESPsAntiAim[player].gui:Destroy()
        ESPsAntiAim[player] = nil
    end
end

local function clearAllESP()
    for player in pairs(ESPsAntiAim) do
        removeESP(player)
    end
end

function updateAllESPVisibility()
    if not AntiAimEnabled then
        clearAllESP()
    end
end

RunService.RenderStepped:Connect(function(dt)
    if not AntiAimEnabled then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then

                local hrp = char.HumanoidRootPart
                local pos = hrp.Position
                local vel = hrp.Velocity.Magnitude

                local last = LastData[player]
                local suspicious = false

                if last then
                    local distance = (pos - last.pos).Magnitude
                    local expected = vel * dt

                    local ratio = 1
                    if expected > 0 then
                        ratio = distance / expected
                    end

                    if vel > EspVelocit_limit then
                        suspicious = true
                    end

                    if vel > EspVelocit_limit and distance < MIN_MOVE then
                        suspicious = true
                    end

                    if vel > EspVelocit_limit and ratio < RATIO_LIMIT then
                        suspicious = true
                    end
                end

                Flags[player] = Flags[player] or 0

                if suspicious then
                    Flags[player] += 1
                else
                    Flags[player] = 0
                end

                if Flags[player] >= DETECT_FRAMES then
                    createESP(char, player)
                else
                    removeESP(player)
                end

                LastData[player] = {pos = pos}
            else
                removeESP(player)
                LastData[player] = nil
                Flags[player] = nil
            end
        end
    end

    for _, data in pairs(ESPsAntiAim) do
        data.t += dt * 3
        local offset = math.sin(data.t) * 5
        data.img.Position = UDim2.new(0.5, -22, 0, offset)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    LastData[player] = nil
    Flags[player] = nil
end)





local CombatTab = Window:Tab({Title = "COMBAT", Icon = "swords"})


CombatTab:Toggle({
    Title = "Silent Aim",
    Default = false,
    Callback = function(v) SilentAimEnabled = v end
})

CombatTab:Toggle({
    Title = "Show FOV",
    Default = false,
    Callback = function(v) ShowFOV = v end
})

CombatTab:Toggle({
    Title = "Show Tracer + Dot",
    Default = false,
    Callback = function(v) ShowTracer = v end
})

CombatTab:Slider({
    Title = "FOV Size",
    Step = 1,
    Value = {Min = 20, Max = 500},
    Default = 200,
    Callback = function(v)
        FOV = v
        fovCircle.Radius = v  
    end
})

CombatTab:Dropdown({
    Title = "Hit Part",
    Values = {"Head", "Body"},
    Default = "Head",
    Callback = function(v) HitPart = v end
})

CombatTab:Dropdown({
    Title = "Save Friend (ไม่ล็อค)",
    Multi = true,
    Values = (function()
        local t = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(t, p.Name) end
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
            if not espCharConnection then
                espCharConnection = Players.PlayerAdded:Connect(function(p)
                    p.CharacterAdded:Connect(function()
                        task.wait(0.5)
                        if ESPEnabled then createBillboardForPlayer(p) end
                    end)
                end)
            end
        else
            if espCharConnection then
                espCharConnection:Disconnect()
                espCharConnection = nil
            end
            for _, billboard in pairs(BillboardCache) do
                pcall(function() billboard:Destroy() end)
            end
            BillboardCache = {}
        end
    end
})


EspTab:Toggle({
    Title = "ESP Anti aim",
    Desc = "แสดงคนที่เปิดกันล็อค",
    Default = false,
    Callback = function(state)
        AntiAimEnabled = state
        updateAllESPVisibility()
    end
})


local ChaterTab = Window:Tab({Title = "Character", Icon = "user"})

ChaterTab:Divider()

ChaterTab:Section({Title = "Body"})

local staminaConnection
ChaterTab:Toggle({
    Title = "infinity stamina",
    Default = false,
    Callback = function(state)
        if state then
            if not getgenv().Bypassed then
                local NetModule = require(ReplicatedStorage.Modules.Core.Net)
                local func = debug.getupvalue(NetModule.get, 2)
                debug.setconstant(func, 3, '__Bypass')
                debug.setconstant(func, 4, '__Bypass')
                getgenv().Bypassed = true
            end

            repeat task.wait() until getgenv().Bypassed

            local NetModule = require(ReplicatedStorage.Modules.Core.Net)
            local SprintModule = require(ReplicatedStorage.Modules.Game.Sprint)

            -- เธเธฑเธเธเนเธณ
            if staminaConnection then staminaConnection:Disconnect() end

            staminaConnection = RunService.Heartbeat:Connect(function()
                NetModule.send("set_sprinting_1", true)
            end)

            local consume_stamina = SprintModule.consume_stamina
            local SprintBar = debug.getupvalue(consume_stamina, 2).sprint_bar
            local oldUpdate = SprintBar.update

            SprintBar.update = function(...)
                if getgenv().InfiniteStamina then
                    return 1 -- เน€เธ•เนเธกเธ•เธฅเธญเธ”
                end
                return oldUpdate(...)
            end

            getgenv().InfiniteStamina = true
        else
            getgenv().InfiniteStamina = false
            if staminaConnection then
                staminaConnection:Disconnect()
                staminaConnection = nil
            end
        end
    end
})



ChaterTab:Toggle({Title = "jump power", Default = false, Callback = function(state)
    jumpEnabled = state
    if jumpConnection then jumpConnection:Disconnect() jumpConnection = nil end
    if state then
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                char.HumanoidRootPart.Velocity = Vector3.new(char.HumanoidRootPart.Velocity.X, jumpPower, char.HumanoidRootPart.Velocity.Z)
            end
        end)
    end
end})
ChaterTab:Slider({Title = "valu", Step = 5, Value = {Min = 20, Max = 80, Default = 70}, Callback = function(v) jumpPower = v end})


ChaterTab:Divider()

ChaterTab:Section({Title = "Mod"})


local DroppedFolder = workspace:FindFirstChild("DroppedItems")
local NetModule = require(ReplicatedStorage.Modules.Core.Net)
local pick
ChaterTab:Toggle({
    Title = "Auto Pickup item",
    Default = false,
    Callback = function(state)
        if state then
            pick = task.spawn(function()
                while task.wait() do
                    for _, v in pairs(DroppedFolder:GetChildren()) do
                        if v:IsA("Model") and v:FindFirstChild("PickUpZone") then
                            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root and (v:GetPivot().Position - root.Position).Magnitude < 50 then
                                NetModule.get("pickup_dropped_item", v)
                            end
                        end
                    end
                end
            end)
        else
            if pick then
                task.cancel(pick)
                pick = nil
            end
        end
    end
})





local AntiKillToggle = ChaterTab:Toggle({
    Title = "Anti Kill",
    Desc = "(Noob)",
    Default = false,
    Callback = function(state)
        AntiKillEnabled = state 
    end
})


local FarmTab = Window:Tab({Title = "FARM", Icon = "hand-coins"})



FarmTab:Divider()

FarmTab:Toggle({
    Title = "Auto Seven Eleven",
    Desc = "ทำงาน เซเว่น อัตโนมัติ",
    Icon = "bird",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        _G.AutoSevenEleven = state
        if state then
            _G.AutoATM = false
        end
        if not state then
            _G.StopWalking = false
        end
    end
})


FarmTab:Toggle({
    Title = "Auto Deposit",
    Desc = "ฝากเงินอัตโนมัติเมื่อเงินถึงจำนวนที่กำหนด",
    Icon = "bird",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        _G.AutoATM = state
        if state then
            _G.AutoSevenEleven = false
        end
        if not state then
            _G.StopWalking = false
        end
    end
})

FarmTab:Input({
    Title = "DepositAmount",
    Desc = "จำนวนเงินที่จะฝากแต่ละครั้ง",
    Value = "200",
    InputIcon = "bird",
    Type = "Input",
    Placeholder = "ใส่จำนวนเงิน",
    Callback = function(input)
        local num = tonumber(input)
        if num and num > 0 then
            DepositAmount = num
        end
    end
})

















local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local SPEED = 260
local SPEED_MIN = 10
local SPEED_MAX = 500
local DEBOUNCE = 0.35
local SMOOTH = 0

local UI_WIDTH = 132
local UI_HEIGHT = 44
local SPEEDBOX_W = 56
local SPEEDBOX_H = 14

local freecam = false
local dummy = nil
local char, humanoid, hrp = nil, nil, nil
local saved = {}
local pendingStamp = 0
local allowMovement = false
local initialDummyCFrame = nil
local initialCameraCFrame = nil
local initialDistance = nil
local savedPartAnchors = {}
local savedPlatformStand = nil
local yaw = 0
local pitch = 0
local ROT_SENS = 0.0025
local lastInputPos = Vector2.new(0,0)
local ignoreNextInput = false

local function safeSet(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("Spectator: safeSet error:", err) end
end

local function createGui()
    if playerGui:FindFirstChild("SpectatorCleanGUI") then
        local g = playerGui.SpectatorCleanGUI
        return {Gui = g, Frame = g.Container, Toggle = g.Container.Toggle, SpeedBox = g.Container.SpeedBox, Info = g.Container.Info}
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpectatorCleanGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    local frame = Instance.new("Frame")
    frame.Name = "Container"
    frame.Size = UDim2.new(0, UI_WIDTH, 0, UI_HEIGHT)
    frame.Position = UDim2.new(0, 8, 0, 8)
    frame.BackgroundColor3 = Color3.fromRGB(18,20,24)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,6)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(45,50,60); stroke.Transparency = 0.7; stroke.Thickness = 1
    local title = Instance.new("TextLabel", frame)
    title.Name = "Title"
    title.Size = UDim2.new(0.64, 0, 0, 22)
    title.Position = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(235,235,235)
    title.Text = "Free camera"
    title.TextXAlignment = Enum.TextXAlignment.Left
    local toggle = Instance.new("TextButton", frame)
    toggle.Name = "Toggle"
    toggle.Size = UDim2.new(0.32, -8, 0, 22)
    toggle.Position = UDim2.new(0.62, 0, 0, 6)
    toggle.BackgroundColor3 = Color3.fromRGB(36,40,48)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(220,220,220)
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,6)
    Instance.new("UIStroke", toggle).Color = Color3.fromRGB(60,70,80)
    local speedBox = Instance.new("TextBox", frame)
    speedBox.Name = "SpeedBox"
    speedBox.Size = UDim2.new(0, SPEEDBOX_W, 0, SPEEDBOX_H)
    speedBox.Position = UDim2.new(0, 8, 1, -18)
    speedBox.BackgroundColor3 = Color3.fromRGB(34,38,46)
    speedBox.PlaceholderText = tostring(SPEED)
    speedBox.Text = ""
    speedBox.Font = Enum.Font.Gotham
    speedBox.TextSize = 12
    speedBox.TextColor3 = Color3.fromRGB(235,235,235)
    Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,5)
    local sbstroke = Instance.new("UIStroke", speedBox)
    sbstroke.Color = Color3.fromRGB(55,65,75); sbstroke.Transparency = 0.8
    local info = Instance.new("TextLabel", frame)
    info.Name = "Info"
    info.Size = UDim2.new(1, -10, 0, 10)
    info.Position = UDim2.new(0, 5, 1, -10)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextSize = 10
    info.TextColor3 = Color3.fromRGB(210,195,110)
    info.Text = ""
    return {Gui = screenGui, Frame = frame, Toggle = toggle, SpeedBox = speedBox, Info = info}
end

local gui = createGui()
local toggleBtn = gui.Toggle
local speedBox = gui.SpeedBox
local infoLabel = gui.Info

local function makeDummy()
    local name = "SpecDummy_" .. player.UserId
    local ex = workspace:FindFirstChild(name)
    if ex then
        safeSet(function()
            if ex:IsA("BasePart") then
                ex.Anchored = true
                ex.CanCollide = false
                ex.Transparency = 1
            end
        end)
        return ex
    end
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(1,1,1)
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 1
    p.Parent = workspace
    return p
end

local function saveHumanoidValues(h)
    if not h then return end
    saved.WalkSpeed = h.WalkSpeed
    saved.JumpPower = h.JumpPower
    saved.AutoRotate = h.AutoRotate
end

local function restoreHumanoidValues(h)
    if not h then return end
    safeSet(function() if saved.WalkSpeed then h.WalkSpeed = saved.WalkSpeed end end)
    safeSet(function() if saved.JumpPower then h.JumpPower = saved.JumpPower end end)
    safeSet(function() if saved.AutoRotate ~= nil then h.AutoRotate = saved.AutoRotate end end)
end

local function setInfo(text)
    if infoLabel and infoLabel.Parent then
        infoLabel.Text = tostring(text or "")
        delay(1.2, function()
            if infoLabel and infoLabel.Parent then infoLabel.Text = "" end
        end)
    end
end

local function tryApplySpeed(txt)
    if not txt or txt == "" then return end
    local n = tonumber(txt)
    if not n then setInfo("Invalid number"); return end
    n = math.clamp(n, SPEED_MIN, SPEED_MAX)
    SPEED = n
    speedBox.PlaceholderText = tostring(SPEED)
    speedBox.Text = ""
    setInfo("Speed set: " .. tostring(SPEED))
end

local function anchorAllCharacterParts(character)
    savedPartAnchors = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            savedPartAnchors[part] = part.Anchored
            safeSet(function()
                if part.AssemblyLinearVelocity then part.AssemblyLinearVelocity = Vector3.new(0,0,0) end
                if part.AssemblyAngularVelocity then part.AssemblyAngularVelocity = Vector3.new(0,0,0) end
                part.Anchored = true
            end)
        end
    end
end

local function restoreAllCharacterParts()
    for part, prev in pairs(savedPartAnchors) do
        safeSet(function()
            if part and part.Parent then
                part.Anchored = (prev == true)
            end
        end)
    end
    savedPartAnchors = {}
end

UserInputService.InputChanged:Connect(function(input, processed)
    if not freecam then return end
    if allowMovement then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local pos
        if input.Position and typeof(input.Position) == "Vector2" then
            pos = input.Position
        else
            pos = UserInputService:GetMouseLocation()
        end
        if ignoreNextInput then
            lastInputPos = pos
            ignoreNextInput = false
            return
        end
        local d = pos - lastInputPos
        lastInputPos = pos
        yaw = yaw - d.X * ROT_SENS
        pitch = math.clamp(pitch - d.Y * ROT_SENS, -math.rad(89), math.rad(89))
    end
end)

local function startSpectator()
    char = player.Character or player.CharacterAdded:Wait()
    humanoid = char:FindFirstChildOfClass("Humanoid")
    hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then warn("Spectator: no humanoid/hrp"); return end
    dummy = makeDummy()
    local camCFrame = camera.CFrame
    dummy.CFrame = camCFrame
    initialDummyCFrame = dummy.CFrame
    initialCameraCFrame = camCFrame
    local rel = (camera.CFrame.Position - dummy.Position)
    local r = rel.Magnitude
    initialDistance = math.max(r, 1)
    local look = rel.Unit
    yaw = math.atan2(look.X, look.Z)
    pitch = math.asin(math.clamp(look.Y, -1, 1))
    saveHumanoidValues(humanoid)
    anchorAllCharacterParts(char)
    savedPlatformStand = humanoid.PlatformStand
    safeSet(function() humanoid.PlatformStand = true end)
    safeSet(function() humanoid.WalkSpeed = 0 end)
    safeSet(function() humanoid.JumpPower = 0 end)
    safeSet(function() humanoid.AutoRotate = false end)
    savedCameraFOV = camera.FieldOfView or 70
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = savedCameraFOV
    lastInputPos = UserInputService:GetMouseLocation()
    ignoreNextInput = true
    freecam = true
    toggleBtn.Text = "ON"
    toggleBtn.TextColor3 = Color3.fromRGB(120,235,120)
    allowMovement = false
    setInfo("Locked. Move to unlock.")
end

local function stopSpectator()
    freecam = false
    local targetHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if targetHum then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = targetHum
    else
        camera.CameraType = Enum.CameraType.Custom
    end
    if savedCameraFOV then
        safeSet(function() camera.FieldOfView = savedCameraFOV end)
        savedCameraFOV = nil
    end
    initialDistance = nil
    initialDummyCFrame = nil
    initialCameraCFrame = nil
    lastInputPos = Vector2.new(0,0)
    ignoreNextInput = false
    safeSet(function()
        if humanoid and humanoid.Parent then
            if savedPlatformStand ~= nil then
                humanoid.PlatformStand = savedPlatformStand
            else
                humanoid.PlatformStand = false
            end
        end
    end)
    savedPlatformStand = nil
    restoreAllCharacterParts()
    if dummy and dummy.Parent then
        safeSet(function() dummy:Destroy() end)
        dummy = nil
    end
    if humanoid then restoreHumanoidValues(humanoid) end
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(220,220,220)
    setInfo("Disabled")
end

RunService.RenderStepped:Connect(function(dt)
    if not freecam then return end
    if not dummy then return end
    if not allowMovement and initialDummyCFrame and initialCameraCFrame and initialDistance then
        safeSet(function() dummy.CFrame = initialDummyCFrame end)
        for part, _ in pairs(savedPartAnchors) do
            safeSet(function()
                if part and part.Parent then
                    if part.AssemblyLinearVelocity then part.AssemblyLinearVelocity = Vector3.new(0,0,0) end
                    if part.AssemblyAngularVelocity then part.AssemblyAngularVelocity = Vector3.new(0,0,0) end
                    part.Anchored = true
                end
            end)
        end
        local lx = math.sin(yaw) * math.cos(pitch)
        local ly = math.sin(pitch)
        local lz = math.cos(yaw) * math.cos(pitch)
        local lookFromDummy = Vector3.new(lx, ly, lz)
        local camPos = dummy.Position + lookFromDummy * initialDistance
        safeSet(function() camera.CFrame = CFrame.new(camPos, dummy.Position) end)
        if savedCameraFOV and camera.FieldOfView > savedCameraFOV then
            camera.FieldOfView = savedCameraFOV
        end
        local md = (humanoid and humanoid.MoveDirection) or Vector3.new()
        local mdMag = md.Magnitude
        local kbVec = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then kbVec = kbVec + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then kbVec = kbVec - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then kbVec = kbVec - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then kbVec = kbVec + camera.CFrame.RightVector end
        local kbMag = kbVec.Magnitude
        local JOYSTICK_THRESHOLD = 0.14
        if mdMag > JOYSTICK_THRESHOLD or kbMag > 0.01 then
            allowMovement = true
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = dummy
            setInfo("Unlocked")
        end
        return
    end
    if camera.CameraSubject ~= dummy then safeSet(function() camera.CameraSubject = dummy end) end
    if savedCameraFOV and camera.FieldOfView > savedCameraFOV then camera.FieldOfView = savedCameraFOV end
    local md = (humanoid and humanoid.MoveDirection) or Vector3.new()
    local mdMag = md.Magnitude
    local kbVec = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then kbVec = kbVec + camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then kbVec = kbVec - camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then kbVec = kbVec - camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then kbVec = kbVec + camera.CFrame.RightVector end
    local kbMag = kbVec.Magnitude
    local moveVec
    if mdMag > 0.001 and humanoid then
        local camForward = camera.CFrame.LookVector
        local forwardFlat = Vector3.new(camForward.X, 0, camForward.Z)
        if forwardFlat.Magnitude < 1e-6 then forwardFlat = Vector3.new(0,0,-1) end
        forwardFlat = forwardFlat.Unit
        local camRight = camera.CFrame.RightVector
        local xAxis = md:Dot(camRight)
        local zAxis = md:Dot(forwardFlat)
        moveVec = (camRight * xAxis) + (camera.CFrame.LookVector * zAxis)
    else
        moveVec = kbVec
    end
    if moveVec.Magnitude < 1e-6 then return end
    local appliedSpeed = math.clamp(SPEED, SPEED_MIN, SPEED_MAX)
    local displacement = moveVec.Unit * appliedSpeed * dt * math.clamp(mdMag, 0, 1)
    local newC = dummy.CFrame + displacement
    if SMOOTH and SMOOTH > 0 then
        dummy.CFrame = dummy.CFrame:Lerp(newC, math.clamp(SMOOTH*60*dt, 0, 1))
    else
        dummy.CFrame = newC
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    if freecam then stopSpectator() else startSpectator() end
end)

speedBox:GetPropertyChangedSignal("Text"):Connect(function()
    pendingStamp = tick()
    local stamp = pendingStamp
    delay(DEBOUNCE, function()
        if pendingStamp == stamp then tryApplySpeed(speedBox.Text) end
    end)
end)
speedBox.FocusLost:Connect(function()
    tryApplySpeed(speedBox.Text)
end)

player.CharacterAdded:Connect(function(c)
    if savedPlatformStand ~= nil and humanoid and humanoid.Parent then
        safeSet(function() humanoid.PlatformStand = savedPlatformStand end)
        savedPlatformStand = nil
    end
    if next(savedPartAnchors) then restoreAllCharacterParts() end
    char = c
    humanoid = c:FindFirstChildOfClass("Humanoid")
    hrp = c:FindFirstChild("HumanoidRootPart")
    if freecam then stopSpectator() end
end)

speedBox.PlaceholderText = tostring(SPEED)
