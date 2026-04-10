



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



local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local Janitor = require(ReplicatedStorage.Modules.Game.Jobs.Janitor)
local JobUtil = require(ReplicatedStorage.Modules.Game.Jobs.JobUtil)

local JanitorSettings = {
    Enabled = false,
}

local CONFIG = {
    JobPositions = {
        Vector3.new(109.13, 257.80, -243.59),
        Vector3.new(110.61, 255.21, -309.56)
    },
    WalkSpeed = 25,
    AgentRadius = 2.5,
    AgentHeight = 5,
    WaypointSpacing = 2,
    StuckThreshold = 2.5,
    StuckDistance = 0.2,
    RecomputeInterval = 3.5,
    ObstacleDistance = 5.5,
    JumpCooldown = 0.8,
    WaypointReachDistance = 4,
}
local targetAnchor = Instance.new("Part")
targetAnchor.Transparency, targetAnchor.CanCollide, targetAnchor.Anchored = 1, false, true
targetAnchor.Name = "AI_Target"
targetAnchor.Parent = workspace
local arrowInstance = nil
local currentJobIndex = 1
local isRunning = false

local AIState = {
    lastPos = Vector3.new(),
    stuckTimer = 0,
    recomputeTimer = 0,
    lastJumpTime = 0,
    waypoints = {},
    wpIndex = 1,
}
local function hasJob()
    local job = plr:GetAttribute("Job")
    return job ~= nil and job ~= ""
end

local function equipMop()
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and (string.find(tool.Name:lower(), "mop") or tool:HasTag("Mop")) then 
        return true 
    end
    local bpTool = plr.Backpack:FindFirstChild("Mop") or plr.Backpack:FindFirstChildOfClass("Tool")
    if bpTool and (string.find(bpTool.Name:lower(), "mop") or bpTool:HasTag("Mop")) then
        hum:EquipTool(bpTool)
        return true
    end
    return false
end

local function isDoor(inst)
    if not inst or not inst:IsA("BasePart") then return false end
    local name = inst.Name:lower()
    if name:find("door") or name:find("gate") or name:find("entrance") then return true end
    local parent = inst.Parent
    if parent and parent.Name and parent.Name:lower():find("door") then return true end
    return false
end

local lastObstacleTime = 0
local function hasObstacleAhead()
    local now = tick()
    if now - lastObstacleTime < 0.08 then return false end
    lastObstacleTime = now
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {char, targetAnchor}
    
    local lookDir = hrp.CFrame.LookVector
    local hit = workspace:Raycast(hrp.Position, lookDir * CONFIG.ObstacleDistance, rayParams)
    
    if hit and hit.Instance and hit.Instance.CanCollide and not isDoor(hit.Instance) then
        local name = hit.Instance.Name:lower()
        if name ~= "baseplate" and name ~= "ground" and name ~= "floor" then
            return true, hit.Instance, hit.Position
        end
    end
    return false, nil, nil
end

local function getAvoidanceDirection()
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {char, targetAnchor}
    
    local right = hrp.CFrame.RightVector
    local left = -right
    
    local rightHit = workspace:Raycast(hrp.Position, right * 4, rayParams)
    local leftHit = workspace:Raycast(hrp.Position, left * 4, rayParams)
    
    local canGoRight = not rightHit or not rightHit.Instance.CanCollide or isDoor(rightHit.Instance)
    local canGoLeft = not leftHit or not leftHit.Instance.CanCollide or isDoor(leftHit.Instance)
    
    if canGoRight and canGoLeft then
        return (math.random() > 0.5 and right or left)
    elseif canGoRight then
        return right
    elseif canGoLeft then
        return left
    else
        if tick() - AIState.lastJumpTime > CONFIG.JumpCooldown then
            hum.Jump = true
            AIState.lastJumpTime = tick()
        end
        return -hrp.CFrame.LookVector
    end
end

local function updatePath(targetPos)
    local path = PathfindingService:CreatePath({
        AgentRadius = CONFIG.AgentRadius,
        AgentHeight = CONFIG.AgentHeight,
        AgentCanJump = true,
        WaypointSpacing = CONFIG.WaypointSpacing
    })
    
    local success = pcall(function()
        path:ComputeAsync(hrp.Position, targetPos)
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        if #waypoints > 0 then
            AIState.waypoints = waypoints
            AIState.wpIndex = 1
            return true
        end
    end
    
    AIState.waypoints = {{Position = targetPos}}
    AIState.wpIndex = 1
    return false
end

local function moveToTarget(targetInstance, isPuddle)
    local targetPos = (typeof(targetInstance) == "Vector3") and targetInstance or targetInstance:GetPivot().Position
    
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and isDoor(item) then
            item.CanQuery = false
        end
    end
    
    local originalSpeed = hum.WalkSpeed
    hum.WalkSpeed = CONFIG.WalkSpeed
    
    updatePath(targetPos)
    
    targetAnchor.Position = targetPos
    if arrowInstance then arrowInstance:Destroy() end
    arrowInstance = JobUtil.create_arrow(hrp, targetAnchor)
    
    AIState.lastPos = hrp.Position
    AIState.stuckTimer = 0
    AIState.recomputeTimer = 0
    
    while AIState.wpIndex <= #AIState.waypoints and hum.Health > 0 and JanitorSettings.Enabled do
        local waypointPos = AIState.waypoints[AIState.wpIndex].Position
        
        local hasObs = hasObstacleAhead()
        
        if hasObs then
            local avoidDir = getAvoidanceDirection()
            local avoidPos = hrp.Position + avoidDir * 3.5
            hum:MoveTo(avoidPos)
        else
            hum:MoveTo(waypointPos)
        end
        
        AIState.recomputeTimer = AIState.recomputeTimer + 0.2
        if AIState.recomputeTimer > CONFIG.RecomputeInterval then
            updatePath(targetPos)
            AIState.recomputeTimer = 0
        end
        
        local distMoved = (hrp.Position - AIState.lastPos).Magnitude
        if distMoved < CONFIG.StuckDistance then
            AIState.stuckTimer = AIState.stuckTimer + 0.2
            if AIState.stuckTimer > CONFIG.StuckThreshold then
                hum:MoveTo(hrp.Position + hrp.CFrame.LookVector * 2 + hrp.CFrame.RightVector * (math.random() - 0.5) * 3)
                task.wait(0.15)
                updatePath(targetPos)
                AIState.stuckTimer = 0
            end
        else
            AIState.stuckTimer = math.max(0, AIState.stuckTimer - 0.2)
        end
        AIState.lastPos = hrp.Position
        
        if (hrp.Position - waypointPos).Magnitude < CONFIG.WaypointReachDistance then
            AIState.wpIndex = AIState.wpIndex + 1
        end
        
        task.wait()
    end
    
    if isPuddle and (hrp.Position - targetPos).Magnitude < 6 then
        local tween = TweenService:Create(hrp, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            CFrame = CFrame.new(targetPos.X, hrp.Position.Y, targetPos.Z)
        })
        tween:Play()
        task.wait(0.25)
    end
    
    hum.WalkSpeed = originalSpeed
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and isDoor(item) then
            item.CanQuery = true
        end
    end
    if arrowInstance then
        arrowInstance:Destroy()
        arrowInstance = nil
    end
end

local function autoApplyJob()
    if hasJob() then return end
    
    local jobGui = plr.PlayerGui:FindFirstChild("JobApplication")
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
        end
    end
end

local function goToJobPosition()
    local targetPos = CONFIG.JobPositions[currentJobIndex]
    moveToTarget(targetPos, false)
    
    currentJobIndex = currentJobIndex + 1
    if currentJobIndex > #CONFIG.JobPositions then
        currentJobIndex = 1
    end
end

local function farmPuddles()
    if not equipMop() then
        task.wait(2)
        return
    end
    
    local closest, minDist = nil, math.huge
    for _, puddle in pairs(Janitor.class.objects) do
        if puddle and puddle.instance and not puddle.states.mopped.get() then
            local dist = (puddle.instance.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = puddle
            end
        end
    end
    
    if closest then
        moveToTarget(closest.instance, true)
        local mopTime = closest.states.mop_length.get() or 3
        task.wait(mopTime + 0.3)
    else
        task.wait(1)
    end
end

-- ========== MAIN LOOP ==========
local function startAutoFarm()
    if isRunning then return end
    isRunning = true
    
    while JanitorSettings.Enabled do
        task.wait(0.3)
        
        char = plr.Character or plr.CharacterAdded:Wait()
        hrp = char:WaitForChild("HumanoidRootPart")
        hum = char:WaitForChild("Humanoid")
        
        if hum.Health <= 0 then
            task.wait(3)
            continue
        end
        
        autoApplyJob()
        
        if not hasJob() then
            goToJobPosition()
        elseif plr:GetAttribute("Job") == "janitor" then
            farmPuddles()
        else
            task.wait(2)
        end
    end
    
    isRunning = false
end

-- มุดดิน


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local snapEnabled = false
local snapHeight = 10

local function snapUnderMap()
    if not HumanoidRootPart then return end
    local pos = HumanoidRootPart.Position
    HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y - snapHeight, pos.Z)
end

local connection
local function startLock()
    if connection then connection:Disconnect() end
    connection = RunService.Heartbeat:Connect(function()
        if snapEnabled and HumanoidRootPart then
            local pos = HumanoidRootPart.Position
            HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y - snapHeight, pos.Z)
        end
    end)
end



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
    Callback = function(v) FOV = v end
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

local SnapToggle = ChaterTab:Toggle({
    Title = "Snap Under Map",
    Default = false,
    Callback = function(state)
        snapEnabled = state
        if state then 
            snapUnderMap()
            startLock()
        elseif connection then
            connection:Disconnect()
        end
    end
})

local SnapSlider = ChaterTab:Slider({
    Title = "Snap Height",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = 10 },
    Callback = function(value)
        snapHeight = value
    end
})

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z then
        SnapToggle:Set(not snapEnabled)
        end
    end)

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





local FarmTab = Window:Tab({Title = "FARM", Icon = "hand-coins"})



FarmTab:Divider()

FarmTab:Toggle({
    Title = "Auto Farm Janitor 🪣🧹",
    Desc = "",
    Default = false,
    Callback = function(state)
        JanitorSettings.Enabled = state
        if state then
            task.spawn(startAutoFarm)
        end
    end
})

