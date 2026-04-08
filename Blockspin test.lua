
if not game:IsLoaded() then
    repeat
        task.wait()
    until game:IsLoaded()
end
if not (game.PlaceId == 104715542330896 or game.PlaceId == 97556409405464) then
    return
end

pcall(
    function()
        local TransitionModule = require(RS.Modules.Game.UI.TransitionUI)

        -- Hook transition() - บังคับรอ 10 วิ
        local old_transition = TransitionModule.transition
        TransitionModule.transition = function(p_in, p_wait, p_out, noLogo)
            return result
        end
    end
)


pcall(
    function()
        local CharCreator = require(RS.Modules.Game.CharacterCreator.CharacterCreator)

        
        if CharCreator.start then
            local old_start = CharCreator.start
            CharCreator.start = function(...)
                
                while true do
                    task.wait(1)
                end
            end
        end

        
        if CharCreator.load_page then
            local old_load = CharCreator.load_page
            CharCreator.load_page = function(...)
                return old_load(...)
            end
        end

        -- Hook initiate() - เริ่มต้น character creator
        if CharCreator.initiate then
            local old_initiate = CharCreator.initiate
            CharCreator.initiate = function(...)
                return old_initiate(...)
            end
        end
    end
)


local VehiclesFolder = workspace:WaitForChild("Vehicles")


local protectedVehicles = {}

local function updateVehicleList()
    protectedVehicles = {}

    for _, model in ipairs(VehiclesFolder:GetDescendants()) do
        if model:IsA("VehicleSeat") and model.Name == "DriverSeat" then
            local vehicle = model:FindFirstAncestorOfClass("Model")
            if vehicle then
                protectedVehicles[vehicle] = true
            end
        end
    end
end

updateVehicleList()



local function isProtectedSeat(seat)
    local vehicle = seat:FindFirstAncestorOfClass("Model")
    return vehicle and protectedVehicles[vehicle] == true
end



local function removeSeatIfNotInProtectedVehicle(seat)
    if isProtectedSeat(seat) then
        return 
    end

    seat:Destroy()
end



for _, seat in ipairs(workspace:GetDescendants()) do
    if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
        if not isProtectedSeat(seat) then
            removeSeatIfNotInProtectedVehicle(seat)
        end
    end
end



VehiclesFolder.DescendantAdded:Connect(function(obj)
    if obj:IsA("VehicleSeat") and obj.Name == "DriverSeat" then
        updateVehicleList()
    end
end)



workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
        if not isProtectedSeat(obj) then
            removeSeatIfNotInProtectedVehicle(obj)
        end
    end
end)

game:GetService("ReplicatedStorage")


if getgenv then
    getgenv().identifyexecutor = nil
end
if getfenv then
    local env = getfenv()
    env.identifyexecutor = nil
end

local v_u_1 = {}
local v2 = game.ReplicatedStorage:WaitForChild("Remotes")
local v_u_3 = {
	["send"] = v2:WaitForChild("Send"),
	["get"] = v2:WaitForChild("Get")
}
local v_u_4 = {
	["event"] = 0,
	["func"] = 0
}
local v_u_5 = {}
local v_u_6 = false
local v_u_7 = {}

function v_u_1.on_connect(p8)
	if v_u_6 then
		p8()
	else
		v_u_7[#v_u_7 + 1] = p8
	end
end

function v_u_1.hook(p_u_9, p_u_10)
	if not p_u_10 then
		error("Function nil for hook " .. p_u_9)
	end
	if v_u_6 then
		if v_u_5[p_u_9] then
			warn("Overwriting hook \'" .. p_u_9 .. "\'.")
		else
			v_u_5[p_u_9] = p_u_10
		end
	else
		v_u_1.on_connect(function()
			v_u_1.hook(p_u_9, p_u_10)
		end)
		return
	end
end

function v_u_1.is_connected(p11)
	return p11:GetAttribute("IsConnected") and true or false
end


local function v_u_19(p12, p13, p14, p15, ...)
	
	return p12(p13, p14, p15, ...)
end

task.wait(0.1)

local v_u_20 = v_u_3.send
local v_u_21 = v_u_3.send.FireServer


function v_u_1.send(p22, ...)
	v_u_4.event = v_u_4.event + 1
	
	v_u_21(v_u_20, v_u_4.event, p22, ...)
end

local v_u_23 = v_u_3.get
local v_u_24 = v_u_3.get.InvokeServer


function v_u_1.get(p25, ...)
	v_u_4.func = v_u_4.func + 1
	
	return v_u_24(v_u_23, v_u_4.func, p25, ...)
end

task.wait(0.1)

local function v_u_29()
	v_u_3.send.OnClientEvent:connect(function(p26, ...)
		if v_u_5[p26] then
			v_u_5[p26](...)
		else
			error("Invalid hook \'" .. p26 .. "\' fired!", 0)
		end
	end)
	
	function v_u_3.get.OnClientInvoke(p27, ...)
		if v_u_5[p27] then
			return v_u_5[p27](...)
		end
		error("Invalid hook \'" .. p27 .. "\' invoked!", 0)
	end
	
	if not pcall(function()
		for v28 = 1, #v_u_7 do
			v_u_7[v28]()
		end
	end) then
		pcall(function()
			print("On connect failed for client")
			v_u_1.send("issue", "On connect failed for client")
		end)
	end
end

function v_u_1.initiate() end

function v_u_1.loaded()
	function v_u_3.get.OnClientInvoke(p30)
		if p30 == "connect" then
			v_u_6 = true
			v_u_29()
			return true
		end
	end
	
	v_u_1.hook("ping", function()
		return true
	end)
end

print("bypassed")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local Debris = game:GetService("Debris")

local Players, RunService, Camera, LocalPlayer, Mouse =
    game:GetService("Players"),
    game:GetService("RunService"),
    workspace.CurrentCamera,
    game.Players.LocalPlayer,
    game.Players.LocalPlayer:GetMouse()

local Net = require(ReplicatedStorage.Modules.Core.Net)
local RagdollModule = require(ReplicatedStorage.Modules.Game.Ragdoll)
local Vechine = require(ReplicatedStorage.Modules.Game.VehicleSystem.Vehicle)
local CharModule = require(ReplicatedStorage.Modules.Core.Char)
local SprintModule = require(ReplicatedStorage.Modules.Game.Sprint)
local CrateController = require(ReplicatedStorage.Modules.Game.CrateSystem.Crate)

local Settings = {}
function c()
    return Settings
end

local Client = Players.LocalPlayer
local Character = Client.Character or Client.CharacterAdded:Wait()
local UserId = Client.UserId
local PlayerGui = Client.PlayerGui
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Backpack = Client:WaitForChild("Backpack")

Client.CharacterAdded:Connect(
    function(newCharacter)
        Character = newCharacter
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        Backpack = Client:WaitForChild("Backpack")
    end
)

local Sf = {}

local Sprint = require(game:GetService("ReplicatedStorage").Modules.Game.Sprint)

local consume_stamina = Sprint.consume_stamina
local SprintBar = debug.getupvalue(consume_stamina, 2).sprint_bar



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


-- Walkspeed


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local walkSpeedEnabled = false
local speedValue = 0.5
local moveConnection = nil

local function setupWalkSpeed(char)
    if moveConnection then pcall(function() moveConnection:Disconnect() end) end
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end
    moveConnection = RunService.Heartbeat:Connect(function(dt)
        if walkSpeedEnabled and char and hrp and humanoid and humanoid.Health > 0 then
            if humanoid.MoveDirection.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (humanoid.MoveDirection.Unit * speedValue)
            end
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5) setupWalkSpeed(char) end)
if LocalPlayer.Character then setupWalkSpeed(LocalPlayer.Character) end


-- Jumppower  local


local UserInputService = game:GetService("UserInputService")

local jumpEnabled = false
local jumpPower = 70
local jumpConnection = nil






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




local CombatTab = Window:Tab({Title = "COMBAT", Icon = "swords"})



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




local ChaterTab = Window:Tab({Title = "Character", Icon = "user"})

ChaterTab:Divider()

ChaterTab:Section({Title = "Body"})

ChaterTab:Toggle({
    Title = "walk speed", 
    Default = false, 
    Callback = function(state) 
        walkSpeedEnabled = state 
    end
})

ChaterTab:Slider({
    Title = "speed", 
    Step = 0.1, 
    Value = {Min = 0.1, Max = 1, Default = 0.5}, 
    Callback = function(v) 
        speedValue = v 
    end
})


ChaterTab:Toggle({
    Title = "jump power", 
    Default = false, 
    Callback = function(state)
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
    end
})

ChaterTab:Slider({
    Title = "jump valu", 
    Step = 5, 
    Value = {Min = 20, Max = 150, Default = 70}, 
    Callback = function(v) 
        jumpPower = v 
    end
})


local EnabledInfiniteStamina = false
ChaterTab:Toggle(
    {
        Title = "Infinite Stamina",
        Flag = "Inf",
        Type = "Checkbox",
        Value = false,
        Callback = function(Value)
            EnabledInfiniteStamina = Value
        end
    }
)
local OldUpdate = SprintBar.update
SprintBar.update = function(...)
    if EnabledInfiniteStamina then
        return 0.9
    else
        return OldUpdate(...)
    end
end

ChaterTab:Divider()
ChaterTab:Section({Title = ""})








local FarmTab = Window:Tab({Title = "FARM", Icon = "hand-coins"})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local function formatMoney(amount)
    amount = tonumber(amount) or 0
    if amount >= 1e6 then
        return string.format("$%.1fM", amount / 1e6)
    elseif amount >= 1e3 then
        return string.format("$%.1fK", amount / 1e3)
    else
        return string.format("$%d", amount)
    end
end

local function greenText(text)
    return string.format('<font color="#00C853"><b>%s</b></font>', text)
end

local function getHandMoney()
    local success, value = pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if not gui then return 0 end
        local hud = gui:FindFirstChild("TopRightHud")
        if not hud then return 0 end
        local holder = hud:FindFirstChild("Holder")
        if not holder then return 0 end
        local frame = holder:FindFirstChild("Frame")
        if not frame then return 0 end
        local label = frame:FindFirstChild("MoneyTextLabel")
        if not label then return 0 end
        return tonumber(label.Text:gsub("[$,]", "")) or 0
    end)
    return success and value or 0
end

local function getBankMoney()
    local success, value = pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if not gui then return 0 end
        for _, v in ipairs(gui:GetDescendants()) do
            if v:IsA("TextLabel") then
                if v.Text:find("Bank") or v.Text:find("Balance") then
                    local num = v.Text:gsub("[$,]", ""):gsub("Bank", ""):gsub("Balance", ""):gsub(":", ""):match("%d+")
                    return tonumber(num) or 0
                end
            end
        end
        return 0
    end)
    return success and value or 0
end



local BankBalance = FarmTab:Button({
    Title = "Money in Bank",
    Desc = "<b>$0</b>",
    Callback = function() end
})

local HandBalance = FarmTab:Button({
    Title = "Money player",
    Desc = "<b>$0</b>",
    Callback = function() end
})
task.spawn(function()
    while true do
        local hand = getHandMoney()
        local bank = getBankMoney()
        HandBalance:SetDesc(greenText(formatMoney(hand)))
        BankBalance:SetDesc(greenText(formatMoney(bank)))
        task.wait(0.2)
    end
end)

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

