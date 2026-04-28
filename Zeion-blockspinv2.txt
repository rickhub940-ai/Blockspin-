if not game:IsLoaded() then
    repeat
        task.wait()
    until game:IsLoaded()
end
if not (game.PlaceId == 104715542330896 or game.PlaceId == 97556409405464) then
    return
end
-- ========================================
-- PART 1: Hook TransitionUI (หน้าจอ Loading)
-- ========================================
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

-- ========================================
-- PART 2: Hook CharacterCreator (ตัวสร้างตัวละคร)
-- ========================================
pcall(
    function()
        local CharCreator = require(RS.Modules.Game.CharacterCreator.CharacterCreator)

        -- Hook start() - บล็อกตลอด
        if CharCreator.start then
            local old_start = CharCreator.start
            CharCreator.start = function(...)
                -- Loop รอแบบไม่มีที่สิ้นสุด
                while true do
                    task.wait(1)
                end
            end
        end

        -- Hook load_page() - โหลดหน้า character creation
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

-- ========================================
-- PART 3: Hook Character Spawn (สำรอง)
-- ========================================
local VehiclesFolder = workspace:WaitForChild("Vehicles")

-- --- เก็บ Model ที่มี DriverSeat ---
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


-- --- ฟังก์ชันตรวจว่าที่นั่งนี้อยู่ในยานที่ต้องป้องกันหรือไม่ ---
local function isProtectedSeat(seat)
    local vehicle = seat:FindFirstAncestorOfClass("Model")
    return vehicle and protectedVehicles[vehicle] == true
end


-- --- ลบที่นั่งที่ไม่ได้อยู่ในยานพาหนะที่มี DriverSeat ---
local function removeSeatIfNotInProtectedVehicle(seat)
    if isProtectedSeat(seat) then
        return -- ของรถจริง → ห้ามลบ
    end

    seat:Destroy()
end


-- --- ลบที่นั่งเดิมทั้งหมด (ยกเว้นของรถใน Vehicles) ---
for _, seat in ipairs(workspace:GetDescendants()) do
    if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
        if not isProtectedSeat(seat) then
            removeSeatIfNotInProtectedVehicle(seat)
        end
    end
end


-- --- อัปเดต whitelist แบบ realtime ถ้ารถถูกเพิ่มเข้ามา ---
VehiclesFolder.DescendantAdded:Connect(function(obj)
    if obj:IsA("VehicleSeat") and obj.Name == "DriverSeat" then
        updateVehicleList()
    end
end)


-- --- ลบ seat ที่ถูกสร้างใหม่แบบ realtime ---
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
        if not isProtectedSeat(obj) then
            removeSeatIfNotInProtectedVehicle(obj)
        end
    end
end)





game:GetService("ReplicatedStorage")

-- ========================================
-- วิธีที่ 3: Hook identifyexecutor ก่อนทุกอย่าง
-- ========================================
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

-- ========================================
-- วิธีที่ 1: แทนที่ฟังก์ชัน v_u_19 ให้ข้ามการตรวจสอบ
-- ========================================
local function v_u_19(p12, p13, p14, p15, ...)
	-- ลบการตรวจสอบ executor ทั้งหมด
	return p12(p13, p14, p15, ...)
end

task.wait(0.1)

local v_u_20 = v_u_3.send
local v_u_21 = v_u_3.send.FireServer

-- ========================================
-- วิธีที่ 2: แก้ไข Net.send โดยตรง
-- ========================================
function v_u_1.send(p22, ...)
	v_u_4.event = v_u_4.event + 1
	-- เรียก FireServer โดยตรงไม่ผ่าน v_u_19
	v_u_21(v_u_20, v_u_4.event, p22, ...)
end

local v_u_23 = v_u_3.get
local v_u_24 = v_u_3.get.InvokeServer

-- ========================================
-- วิธีที่ 2: แก้ไข Net.get โดยตรง
-- ========================================
function v_u_1.get(p25, ...)
	v_u_4.func = v_u_4.func + 1
	-- เรียก InvokeServer โดยตรงไม่ผ่าน v_u_19
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


local holdingJump = false

-- UI Initialization
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Icons = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main.lua"))()

Icons.SetIconsType("lucide") -- lucide, craft and more...

local Window =
    WindUI:CreateWindow(
    {
        Icon = "rbxassetid://116912491561156", -- my custom vector* icon
        IconThemed = true,
        
        Title = "Zeion Hub | Block Spin ",
        Author = "by x2SAXZRLzzz",
        Folder = "zeion's",
        Size = UDim2.fromOffset(400, 400),
        MinSize = Vector2.new(560, 350),
        MaxSize = Vector2.new(850, 560),
        Transparent = true,
        Theme = "Dark",
        Resizable = true,
        SideBarWidth = 200,
        BackgroundImageTransparency = 0.42,
        HideSearchBar = false,
        ScrollBarEnabled = false,
        
        OpenButton = {
            Title = "Zeion Hub",
            CornerRadius = UDim.new(1, 0),
            StrokeThickness = 3,
            Enabled = true,
            Draggable = true,
            OnlyMobile = false
        }
    }
)

Window:Tag(
    {
        Title = "Blockspin",
        Color = Color3.fromHex("#FF0000"),
        Radius = 13
    }
)
--====================================================
-- 🧍 MAIN TAB
--====================================================
local MainTab =
    Window:Tab(
    {
        Title = "General",
        Icon = "globe"
    }
)

--== Money Reader ==--
local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild("PlayerGui")

local BankBalance =
    MainTab:Button(
    {
        Title = "🏦 Bank Balance",
        Desc = "N/A"
    }
)
local HandBalance =
    MainTab:Button(
    {
        Title = "💸 Hand Balance",
        Desc = "N/A"
    }
)

local function HandMoney()
    return tonumber(PlayerGui.TopRightHud.Holder.Frame.MoneyTextLabel.Text:match("%$(%d+)"))
end

local function ATMMoney()
    for _, v in ipairs(PlayerGui:GetDescendants()) do
        if v:IsA("TextLabel") and string.find(v.Text, "Bank Balance") then
            return tonumber(v.Text:match("%$(%d+)"))
        end
    end
    return 0
end

task.spawn(
    function()
        while task.wait(0.2) do
            BankBalance:SetDesc('<b><font color="#00FF00">$' .. (ATMMoney() or 0) .. "</font></b>")
            HandBalance:SetDesc('<b><font color="#00f2ff">$' .. (HandMoney() or 0) .. "</font></b>")
        end
    end
)

--====================================================
-- ⚙️ Player Modifier Section
--====================================================
MainTab:Section(
    {
        Title = "Player Modifier:"
    }
)

local DesyncButton = MainTab:Button({
    Title = "Invisible",
    Locked = false,
    Callback = function()
	   Net.send("request_respawn")
		task.wait(6.1)
		Net.get("death_screen_request_respawn")
        setfflag("NextGenReplicatorEnabledWrite4", "true")
		        WindUI:Notify({
            Title = "Invisible Success",
            Content = "Enjoy ครับผม <3",
            Duration = 3,
            Icon = "rbxassetid://116912491561156",
        })
    end,
})

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require Net module และ SprintModule
local Net = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("Net"))

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- ค่า default
local SpeedAmount = 35
local EnabledSpeed = false

-- Function c() แทนค่าที่ UI Toggle จะอ่าน
local function c()
	return {
		SpeedModifies = EnabledSpeed,
		SpeedAmount = SpeedAmount
	}
end

-- Loop ปรับ speed แบบปลอดภัย
local function SpeedLoop()
	task.spawn(function()
		while task.wait(0.1) do
			if Humanoid and Humanoid.Parent then
				if c().SpeedModifies then
					pcall(function()
						Net.send("set_sprinting_1", true)
						SprintModule.sprinting.set(true)
						Humanoid:SetAttribute("TargetWalkSpeed", c().SpeedAmount)
						Humanoid.WalkSpeed = c().SpeedAmount
					end)
				else
					pcall(function()
						Humanoid:SetAttribute("TargetWalkSpeed", 8)
						Humanoid.WalkSpeed = 8
					end)
				end
			end
		end
	end)
end

-- เรียก loop
SpeedLoop()

-- Toggle UI เชื่อม EnabledSpeed
MainTab:Toggle({
	Title = "Walk Speed",
	Flag = "Walk Speed",
	Icon = "check",
	Type = "Checkbox",
	Value = false,
	Callback = function(Value)
		EnabledSpeed = Value
	end
})

-- Slider UI ปรับ SpeedAmount (เชื่อมกับ loop)
MainTab:Slider({
	Title = "Speed Value",
	Flag = "speed_value",
	Step = 1,
	Value = {
		Min = 8,
		Max = 45,
		Default = SpeedAmount
	},
	Callback = function(Value)
		SpeedAmount = Value
		if Humanoid and EnabledSpeed then
			Humanoid.WalkSpeed = Value
		end
	end
})

-- รีเซ็ต Humanoid ตอน respawn
Player.CharacterAdded:Connect(function(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid")
end)


-- 🔹 ตัวแปรเก็บสถานะการเปิด Fly Jump
local EnabledFlyJump = false

MainTab:Toggle(
    {
        Title = "Fly Jump",
        Flag = "Fly",
        Icon = "check",
        Type = "Checkbox",
        Value = false,
        Callback = function(Value)
            EnabledFlyJump = Value
        end
    }
)

UserInputService.JumpRequest:Connect(
    function()
        if not EnabledFlyJump or not RootPart or not Humanoid then
            return
        end
        holdingJump = true
        task.spawn(
            function()
                while holdingJump and EnabledFlyJump do
                    RunService.Heartbeat:Wait()
                    if RootPart then
                        RootPart.Velocity = Vector3.new(RootPart.Velocity.X, 30, RootPart.Velocity.Z)
                    else
                        break
                    end
                end
            end
        )
    end
)

-- 🔹 Event หยุดบินเมื่อไม่ได้กระโดด (รองรับทั้ง PC และมือถือ)
if Humanoid then
    Humanoid.StateChanged:Connect(
        function(oldState, newState)
            -- หยุดบินเมื่อตัวละครไม่ได้อยู่ในสถานะกระโดด/ตกลงมา
            if newState ~= Enum.HumanoidStateType.Freefall and newState ~= Enum.HumanoidStateType.Jumping then
                holdingJump = false
            end
        end
    )
end

-- 🔹 Event ปล่อยปุ่ม Space (สำหรับ PC)
UserInputService.InputEnded:Connect(
    function(input)
        if input.KeyCode == Enum.KeyCode.Space then
            holdingJump = false
        end
    end
)

-- ตั้งค่าตัวแปรเริ่มต้น
local EnabledInfiniteStamina = false

-- สร้าง toggle บนเมนู
MainTab:Toggle(
    {
        Title = "Infinite Stamina",
        Flag = "Inf",
        Icon = "check",
        Type = "Checkbox",
        Value = false,
        Callback = function(Value)
            EnabledInfiniteStamina = Value
        end
    }
)

-- เก็บฟังก์ชันเดิมของ SprintBar.update ไว้
local OldUpdate = SprintBar.update

-- เขียนฟังก์ชันใหม่แทนที่
SprintBar.update = function(...)
    if EnabledInfiniteStamina then
        -- ถ้าเปิดโหมด Infinite Stamina ให้คืนค่าเต็ม (1)
        return 0.9
    else
        -- ถ้าปิด ให้ทำงานตามปกติ
        return OldUpdate(...)
    end
end


--====================================================
-- 🕶️ Utility
--====================================================
MainTab:Section(
    {
        Title = "Utility:"
    }
)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local dropfolder = workspace:WaitForChild("DroppedItems")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Net = require(ReplicatedStorage.Modules.Core.Net)

-- ฟังก์ชันหาความห่างจาก HumanoidRootPart
local function GetDistanceFromRootPart(target)
    if not target then
        return math.huge
    end
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        return math.huge
    end
    return (root.Position - target.Position).Magnitude
end

_G.AutoPickItems = false
_G.BlacklistRarity = {}

local function IsBlacklisted(item)
    if not item then return false end

    local dropName = item:GetAttribute("ItemName") or item.Name
    if not dropName then return false end

    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not itemsFolder then return false end

    for _, template in ipairs(itemsFolder:GetDescendants()) do
        if template:IsA("ModuleScript") or template:IsA("Folder") then
            continue
        end

        if template.Name == dropName then
            local rarity = template:GetAttribute("RarityName")
            if rarity then
                for _, r in ipairs(_G.BlacklistRarity) do
                    if r == rarity then
                        return true
                    end
                end
            end
        end
    end

    return false
end


-- ฟังก์ชันหลัก Auto Pick (เพิ่มขยาย PickUpZone เท่านั้น)
task.spawn(function()
    while task.wait(0) do
        if _G.AutoPickItems then
            for _, v in pairs(dropfolder:GetChildren()) do
                if v and not v:GetAttribute("Locked") then

                    if not IsBlacklisted(v) then
                        local zone = v:FindFirstChild("PickUpZone")
                        if zone then

                            -- ⭐ เพิ่มแค่ขยาย hitbox ⭐
                            zone.Size = Vector3.new(22, 22, 22)
                            zone.CanCollide = false

                            local dist = GetDistanceFromRootPart(zone)
                            if dist < math.huge then
                                Net.get("pickup_dropped_item", v)
                            end
                        end
                    else
                    end

                end
            end
        end
    end
end)

-- ปุ่ม Toggle Auto Pick
MainTab:Toggle({
    Title = "Auto Pick Item",
    Flag = "Pickitem",
    Desc = "Pick up items that are far away",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(value)
        _G.AutoPickItems = value
    end
})

-- 🔹 Dropdown เลือก Rarity ไม่เก็บ
local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary"}
MainTab:Dropdown({
    Title = "Blacklist Rarity",
    Flag = "BlacklistRarity",
    Values = rarities,
    Default = {},
    Multi = true,
	AllowNone = true,
    Callback = function(selected)
        _G.BlacklistRarity = selected
    end
})


_G.AntiLock = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local CharModule = require(ReplicatedStorage.Modules.Core.Char)

-- Animation Anti-Aim
local AntiAimAnimTrack = nil
local ANIM_ID = "rbxassetid://104767795538635"

local function playDanceAntiAim()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")

    if AntiAimAnimTrack then
        AntiAimAnimTrack:Stop()
        AntiAimAnimTrack:Destroy()
        AntiAimAnimTrack = nil
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = ANIM_ID

    AntiAimAnimTrack = humanoid:LoadAnimation(anim)
    AntiAimAnimTrack.Looped = true
    AntiAimAnimTrack:Play()
    AntiAimAnimTrack:AdjustSpeed(99999999999999999999999999999999999)
end

local function stopDanceAntiAim()
    if AntiAimAnimTrack then
        AntiAimAnimTrack:Stop()
        AntiAimAnimTrack:Destroy()
        AntiAimAnimTrack = nil
    end
end

-- Velocity Desync + CustomPhysicalProperties
local function VelocityDesync()
    local hrp = CharModule.get_hrp()
    if not hrp then
        return
    end

    local OldVec = hrp.Velocity
    local Lin = hrp.AssemblyLinearVelocity
    local Ang = hrp.AssemblyAngularVelocity

    local RandomVec = Vector3.new(
        math.random(-16000,16000),
        math.random(-16000,16000),
        math.random(-16000,16000)
    )

    hrp.Velocity = RandomVec
    hrp.AssemblyLinearVelocity = RandomVec
    hrp.AssemblyAngularVelocity = RandomVec

    RunService.RenderStepped:Wait()

    hrp.Velocity = OldVec
    hrp.AssemblyLinearVelocity = Lin
    hrp.AssemblyAngularVelocity = Ang
end

local function SetPhysics()
    local hrp = CharModule.get_hrp()
    if hrp then
        hrp.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.001, 0.001)
    end
end

-- Loop ทำงานถ้าเปิด AntiLock
RunService.Heartbeat:Connect(function()
    if _G.AntiLock then
        VelocityDesync()
        SetPhysics()
    end
end)

-- UI Toggle
MainTab:Toggle({
    Title = "Anti Lock",
    Flag = "antilock",
    Desc = "Prevent you from Aimlock",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        _G.AntiLock = Value

        if Value then
            playDanceAntiAim()
        else
            stopDanceAntiAim()
        end
    end
})

-- Anti Ragdoll Function
local function AntiRagdollLoop()
    while _G.AntiRagdoll do
        task.wait(0.1)

        pcall(function()
            local isRagdolled = RagdollModule.is_ragdolling.get()
            if isRagdolled then
                RagdollModule.is_ragdolling.set(false)
                
                -- ลองส่ง remote ทั้ง 2 แบบ
                pcall(function() Net.send("end_ragdoll_early") end)
                pcall(function() Net.send("clear_ragdoll") end)
                pcall(function() Net.get("end_ragdoll_early") end)
                pcall(function() Net.get("clear_ragdoll") end)
            end
        end)
    end
end

-- Toggle UI
MainTab:Toggle({
    Title = "Anti Ragdoll",
    Desc = "No ragdoll lol",
    Flag = "AntiRagdoll",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        _G.AntiRagdoll = Value

        if Value then
            task.spawn(AntiRagdollLoop)
        end
    end
})

local func = {}
local EverDown = false
local WasAntiLockEnabled = false

-- ✅ ฟังก์ชัน Anti Kill สมบูรณ์
func["AntiDied"] = function()
    while task.wait(0.240) do
        if Settings.AntiDied then
            -- ตรวจสอบตัวแปรหลักมีอยู่จริง
            if not Character or not Humanoid or not RootPart then
                Character = Client.Character or Client.CharacterAdded:Wait()
                Humanoid = Character:WaitForChild("Humanoid")
                RootPart = Character:WaitForChild("HumanoidRootPart")
            end
            
            local hum = CharModule.get_hum()
            
            if hum then
                if hum:GetAttribute("HasBeenDowned") then
                    if not hum:GetAttribute("IsDead") then
                        if Humanoid.Health > 0 then
                            
                            -- ปิด Anti Lock ชั่วคราว
                            if _G.AntiLock then
                                WasAntiLockEnabled = true
                                _G.AntiLock = false
                                stopDanceAntiAim()
                                WindUI:Notify({
                                    Title = "Anti System",
                                    Content = "Anti Lock disabled (Anti Kill active)",
                                    Duration = 2
                                })
                            end
                            
                            -- ตรวจสอบ DeathScreen
                            local deathScreenExists = PlayerGui:FindFirstChild("DeathScreen")
                            if deathScreenExists then
                                local deathscreen = PlayerGui.DeathScreen.DeathScreenHolder
                                if not deathscreen.Visible then
                                    local Radius = 15
                                    local targetY = RootPart.Position.Y - Radius
                                    local currentY = RootPart.Position.Y
                                    local deltaY = targetY - currentY
                                    local Gan = math.random(-5, 15)

                                    RootPart.Anchored = false
                                    RootPart.CanCollide = false
                                    RootPart.CFrame = RootPart.CFrame * CFrame.new(Gan, deltaY, Gan)
                                    RootPart.Velocity = Vector3.new(RootPart.Velocity.X, -11, RootPart.Velocity.Z)

                                    for i, v in pairs(Character:GetChildren()) do
                                        if v:IsA("BasePart") then
                                            v.CanCollide = false
                                            v.Anchored = false
                                            v.CFrame = v.CFrame * CFrame.new(0, deltaY, 0)
                                            v.Velocity = Vector3.new(v.Velocity.X, -11, v.Velocity.Z)
                                        end
                                    end
                                    EverDown = true
                                end
                            end
                        else
                            EverDown = false
                        end
                    else
                        EverDown = false
                    end
                else
                    if EverDown then
                        local ganys = 15
                        local targetY = RootPart.Position.Y - ganys
                        local currentY = RootPart.Position.Y
                        local deltaY = targetY - currentY
                        RootPart.CFrame = RootPart.CFrame * CFrame.new(0, deltaY, 0)
                        
                        if not Client:GetAttribute("IsInCombat") then
                            EverDown = false
                            Net.send("request_respawn")
                            
                            -- เปิด Anti Lock กลับมา
                            if WasAntiLockEnabled then
                                _G.AntiLock = true
                                playDanceAntiAim()
                                WasAntiLockEnabled = false
                                WindUI:Notify({
                                    Title = "Anti System",
                                    Content = "Anti Lock re-enabled",
                                    Duration = 2
                                })
                            end
                        end
                    end
                end
            end
        else
            EverDown = false
            
            -- รีเซ็ตสถานะเมื่อปิด Anti Kill
            if WasAntiLockEnabled then
                WasAntiLockEnabled = false
            end
        end
    end
end

-- ✅ Toggle UI สำหรับ Anti Kill
MainTab:Toggle(
    {
        Title = "Anti Kill",
        Desc = "Normal Player cant Finish",
		Flag = "antikill",
        Icon = "check",
        Type = "Checkbox",
        Value = false,
        Callback = function(state)
            Settings.AntiDied = state

            if state then
                task.spawn(func["AntiDied"])
            end
        end
    }
)

MainTab:Toggle(
    {
        Title = "Auto Mask",
        Flag = "automask",
        Desc = "Equip Shiesty",
        Icon = "check",
        Type = "Checkbox",
        Callback = function(Value)
            if not Value then
                return
            end
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Player = game.Players.LocalPlayer
            local PlayerGui = Player:WaitForChild("PlayerGui")
            local Net = require(ReplicatedStorage.Modules.Core.Net)
            function GetAllInfos(itemName)
                local infos = {}
                local Items = PlayerGui.Items
                local Holding = Items:FindFirstChild("ItemsHolder").ItemsScrollingFrame
                for _, v in ipairs(Holding:GetChildren()) do
                    if v.Name ~= "Folder" and v.Name ~= "UIGridLayout" and v.Name ~= "ItemTemplate" then
                        if v.ItemName.Text == itemName then
                            table.insert(
                                infos,
                                {
                                    Uid = v.Name,
                                    Using = v:FindFirstChild("ItemEquipped").Visible,
                                    Drowning = v:FindFirstChild("DestroyedItemIcon").Visible
                                }
                            )
                        end
                    end
                end
                return infos
            end
            function EquipAccessory(itemName)
                local infos = GetAllInfos(itemName)
                for _, info in ipairs(infos) do
                    if not info.Using and not info.Drowning then
                        Net.get("toggle_equip_item", info.Uid)
                        repeat
                            task.wait()
                        until GetAllInfos(itemName)[1].Using
                    end
                end
            end
            EquipAccessory("Shiesty")
        end
    }
)

MainTab:Toggle({
    Title = "Auto Health",
    Flag = "autohealth",
    Desc = "Auto use Bloodbag",
    Icon = "check",
    Type = "Checkbox",
    Callback = function(state)
        c().AutoBlood = state
        if not state then return end

        local Player = game.Players.LocalPlayer
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local Humanoid = Character:WaitForChild("Humanoid")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Net = require(ReplicatedStorage.Modules.Core.Net)
        local ItemsUI = Player.PlayerGui.Items.ItemsHolder.ItemsScrollingFrame
        local Busy = false

        -- หา UID ของ Blood Bag
        local function GetBloodBagUID()
            for _, v in ipairs(ItemsUI:GetChildren()) do
                if v:IsA("Frame") or v:IsA("ImageButton") then
                    local itemType = v:GetAttribute("ItemType")
                    if itemType and itemType:lower() == "consumable" then
                        return v.Name
                    end
                end
            end
            return nil
        end

local function UseBloodBag(uid)
    if Busy then return end
    Busy = true

    local tool = Character:FindFirstChild("Blood Bag")

    -- ถ้า tool ไม่มีใน Character → equip
    local didEquip = false
    if not tool then
        Net.get("toggle_equip_item", uid)
        didEquip = true
        task.wait(0.1) -- รอให้ equip สำเร็จ
        tool = Character:FindFirstChild("Blood Bag") or Player.Backpack:FindFirstChild("Blood Bag")
    end

    if tool then
        -- ใช้ซ้ำ ๆ จน HP >= 90
        while Humanoid.Health < 90 do
            Net.get("consume_power_up", tool)
            task.wait(0.1)
        end

        -- หลังใช้ครบ HP >= 90 → unequip ถ้าเคย equip
        if didEquip then
            Net.get("toggle_equip_item", uid)
        end
    else
        warn(" Blood Bag tool not found.")
    end

    Busy = false
end


        task.spawn(function()
            while c().AutoBlood do
                task.wait(0.2)

                if Humanoid.Health <= 50 then
                    local uid = GetBloodBagUID()
                    if uid then
                        UseBloodBag(uid)
                    else
                        warn("⚠ No bloodbag found.")
                    end
                end
            end
        end)
    end
})

MainTab:Divider()

local EnabledSnapRunning = false
local SnapThread = nil
local YoffsetValue = 70

func["EnabledSnap"] = function()
    local basePosition = RootPart.Position
    while EnabledSnapRunning do
        task.wait()
        if not EnabledSnapRunning then
            break
        end
        local currentY = RootPart.Position.Y
        local targetY = basePosition.Y - YoffsetValue
        local deltaY = targetY - currentY
        RootPart.CFrame = RootPart.CFrame * CFrame.new(0, deltaY, 0)
    end
end

-- 🔘 Toggle & Keybind Sync System
local function SetSnapState(value)
    if EnabledSnapRunning == value then
        return
    end -- ไม่ต้องทำซ้ำ
    EnabledSnapRunning = value
    if value then
        if not SnapThread then
            SnapThread = task.spawn(func["EnabledSnap"])
        end
    else
        SnapThread = nil
    end

    -- Sync UI Toggle ให้ตรงกับสถานะ
    MainTab:Get("UndergroundToggle"):SetValue(value)
end

-- 🧩 Toggle
MainTab:Toggle(
    {
        Title = "Underground",
        Icon = "check",
        Type = "Checkbox",
        Value = false,
        Flag = "UndergroundToggle", -- ต้องมี flag เพื่อให้ sync ได้
        Callback = function(value)
            SetSnapState(value)
        end
    }
)

-- 🎹 Keybind
MainTab:Keybind(
    {
        Title = "Keybind",
        Flag = "keybind",
        Value = "G",
        Callback = function()
            SetSnapState(not EnabledSnapRunning)
        end
    }
)

-- 📏 Slider Snap Height
MainTab:Slider(
    {
        Title = "Snap Height",
        Flag = "snap_height",
        Step = 1,
        Value = {
            Min = 1,
            Max = 100,
            Default = 10
        },
        Callback = function(value)
            YoffsetValue = value
        end
    }
)

local CombatTab =
    Window:Tab(
    {
        Title = "Combat",
        Icon = "swords"
    }
)

local FOVRadius = 120
local SilentAimEnabled = false
local ShowFOVEnabled = false
local WallbangEnabled = false
local CurrentTarget = nil
local UseSmartPredict = true -- ✅ รวม Anti-Lock Resolver เข้ากับ Smart Predict แล้ว
local TargetMode = "Head"
local VelocityThreshold = 250 -- เกณฑ์ velocity ที่ถือว่าเป็น anti-lock

-- ===== ตรวจสอบว่าเป็น Mobile หรือ PC =====
local UserInputService = game:GetService("UserInputService")
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== สร้าง Gradient FOV Circle =====
local FOVCircleSegments = {}
local FOVCircleGui = nil
local FOVCircleFrame = nil
local Tracer = nil
local TracerGui = nil
local TracerFrame = nil
local TargetHeadCircle = nil
local TargetCircleGui = nil
local TargetCircleFrame = nil

if not IsMobile then
    -- ===== PC: ใช้ Drawing API แบบ Gradient =====
    for i = 1, 64 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Visible = false
        table.insert(FOVCircleSegments, line)
    end

    Tracer = Drawing.new("Line")
    Tracer.Thickness = 1.5
    Tracer.Color = Color3.fromRGB(124, 252, 0)
    Tracer.Transparency = 1
    Tracer.Visible = false

    TargetHeadCircle = Drawing.new("Circle")
    TargetHeadCircle.Color = Color3.fromRGB(255, 250, 250)
    TargetHeadCircle.Thickness = 2
    TargetHeadCircle.NumSides = 32
    TargetHeadCircle.Filled = false
    TargetHeadCircle.Transparency = 1
    TargetHeadCircle.Radius = 15
    TargetHeadCircle.Visible = false
else
    -- ===== Mobile: ใช้ ScreenGui แบบ Gradient =====
    
    -- FOV Circle GUI
    FOVCircleGui = Instance.new("ScreenGui")
    FOVCircleGui.Name = "SilentAimFOV"
    FOVCircleGui.IgnoreGuiInset = true
    FOVCircleGui.ResetOnSpawn = false
    FOVCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    FOVCircleGui.Parent = game:GetService("CoreGui")
    
    FOVCircleFrame = Instance.new("Frame")
    FOVCircleFrame.Name = "Circle"
    FOVCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVCircleFrame.BackgroundTransparency = 1
    FOVCircleFrame.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
    FOVCircleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    FOVCircleFrame.Visible = false
    FOVCircleFrame.Parent = FOVCircleGui
    
    local FOVStroke = Instance.new("UIStroke")
    FOVStroke.Thickness = 3
    FOVStroke.Transparency = 0
    FOVStroke.Parent = FOVCircleFrame
    
    local FOVGradient = Instance.new("UIGradient")
    FOVGradient.Parent = FOVStroke
    
    local FOVCorner = Instance.new("UICorner")
    FOVCorner.CornerRadius = UDim.new(1, 0)
    FOVCorner.Parent = FOVCircleFrame
    
    -- Tracer GUI
    TracerGui = Instance.new("ScreenGui")
    TracerGui.Name = "SilentAimTracer"
    TracerGui.IgnoreGuiInset = true
    TracerGui.ResetOnSpawn = false
    TracerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TracerGui.Parent = game:GetService("CoreGui")
    
    TracerFrame = Instance.new("Frame")
    TracerFrame.Name = "Line"
    TracerFrame.BackgroundColor3 = Color3.fromRGB(124, 252, 0)
    TracerFrame.BorderSizePixel = 0
    TracerFrame.AnchorPoint = Vector2.new(0, 0.5)
    TracerFrame.Size = UDim2.new(0, 0, 0, 2)
    TracerFrame.Visible = false
    TracerFrame.Parent = TracerGui
    
    -- Target Circle GUI
    TargetCircleGui = Instance.new("ScreenGui")
    TargetCircleGui.Name = "SilentAimTarget"
    TargetCircleGui.IgnoreGuiInset = true
    TargetCircleGui.ResetOnSpawn = false
    TargetCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    TargetCircleGui.Parent = game:GetService("CoreGui")
    
    TargetCircleFrame = Instance.new("Frame")
    TargetCircleFrame.Name = "Circle"
    TargetCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    TargetCircleFrame.BackgroundTransparency = 1
    TargetCircleFrame.Size = UDim2.new(0, 30, 0, 30)
    TargetCircleFrame.Visible = false
    TargetCircleFrame.Parent = TargetCircleGui
    
    local TargetStroke = Instance.new("UIStroke")
    TargetStroke.Color = Color3.fromRGB(255, 250, 250)
    TargetStroke.Thickness = 2
    TargetStroke.Transparency = 0
    TargetStroke.Parent = TargetCircleFrame
    
    local TargetCorner = Instance.new("UICorner")
    TargetCorner.CornerRadius = UDim.new(1, 0)
    TargetCorner.Parent = TargetCircleFrame
end

-- ฟังก์ชันคำนวณจุดบนวงกลม
local function GetCirclePoint(center, radius, angle)
    local x = center.X + radius * math.cos(angle)
    local y = center.Y + radius * math.sin(angle)
    return Vector2.new(x, y)
end

-- ระบบติดตาม velocity ของ target
local TargetHistory = {}
local VelocitySpikes = {} -- ✅ ติดตามการกระโดด velocity

local function updateTargetHistory(player, position, velocity)
    if not TargetHistory[player] then
        TargetHistory[player] = {}
        VelocitySpikes[player] = {
            count = 0,
            lastSpike = 0,
            isAntiLock = false
        }
    end

    table.insert(
        TargetHistory[player],
        {
            pos = position,
            vel = velocity,
            time = tick()
        }
    )

    if #TargetHistory[player] > 8 then
        table.remove(TargetHistory[player], 1)
    end
    
    -- ✅ ตรวจจับ Anti-Lock Velocity (ทำงานร่วมกับ Smart Predict)
    if UseSmartPredict and #TargetHistory[player] >= 2 then
        local current = TargetHistory[player][#TargetHistory[player]]
        local previous = TargetHistory[player][#TargetHistory[player] - 1]
        
        local velChange = (current.vel - previous.vel).Magnitude
        
        -- ถ้า velocity เปลี่ยนแปลงมากกว่าเกณฑ์ = anti-lock
        if velChange > VelocityThreshold then
            VelocitySpikes[player].count = VelocitySpikes[player].count + 1
            VelocitySpikes[player].lastSpike = tick()
            
            -- ถ้ามี spike เกิน 3 ครั้งใน 2 วินาที = แน่นอนว่าเป็น anti-lock
            if VelocitySpikes[player].count >= 3 then
                VelocitySpikes[player].isAntiLock = true
            end
        end
        
        -- รีเซ็ตถ้าไม่มี spike นานเกิน 3 วินาที
        if tick() - VelocitySpikes[player].lastSpike > 3 then
            VelocitySpikes[player].count = 0
            VelocitySpikes[player].isAntiLock = false
        end
    end
end

local function getAverageVelocity(player)
    local history = TargetHistory[player]
    if not history or #history < 2 then
        return Vector3.zero
    end

    -- ✅ Smart Predict รวม Anti-Lock Resolver: ใช้ Median เมื่อตรวจพบ velocity spike
    if UseSmartPredict and VelocitySpikes[player] and VelocitySpikes[player].isAntiLock then
        -- คำนวณ median เพื่อกำจัด velocity spike
        local velocities = {}
        for i = 2, #history do
            local dt = history[i].time - history[i - 1].time
            if dt > 0 then
                local vel = (history[i].pos - history[i - 1].pos) / dt
                table.insert(velocities, vel)
            end
        end
        
        if #velocities > 0 then
            -- เรียงลำดับตามขนาด magnitude
            table.sort(velocities, function(a, b)
                return a.Magnitude < b.Magnitude
            end)
            
            -- เอาค่ากลาง (median) เพื่อตัด spike ออก
            local midIndex = math.ceil(#velocities / 2)
            return velocities[midIndex]
        end
    end

    -- ใช้ average ปกติ
    local totalVel = Vector3.zero
    for i = 2, #history do
        local dt = history[i].time - history[i - 1].time
        if dt > 0 then
            local vel = (history[i].pos - history[i - 1].pos) / dt
            totalVel = totalVel + vel
        end
    end

    return totalVel / (#history - 1)
end

local function getPing()
    local stats = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("NetworkStats")
    if stats then
        local pingText = stats:FindFirstChild("PingLabel")
        if pingText then
            local ping = tonumber(pingText.Text:match("%d+"))
            return ping and ping / 1000 or 0.2
        end
    end
    return 0.2
end

local function getClosestTarget()
    local closest = nil
    local shortestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            local isInSafeZone = false
            if hrp then
                local billboardGui = hrp:FindFirstChild("CharacterBillboardGui")
                if billboardGui then
                    local playerName = billboardGui:FindFirstChild("PlayerName")
                    if playerName then
                        local levelImage = playerName:FindFirstChild("LevelImage")
                        if levelImage then
                            local frame = levelImage:FindFirstChild("Frame")
                            if frame then
                                local safeZone = frame:FindFirstChild("InSafeZone")
                                if safeZone and safeZone.Visible then
                                    isInSafeZone = true
                                end
                            end
                        end
                    end
                end
            end

            local isDead = humanoid and humanoid.Health <= 0

            if not isInSafeZone and not isDead then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local distFromCenter = (screenPos - center).Magnitude
                    if distFromCenter <= FOVRadius then
                        local toTarget = (head.Position - Camera.CFrame.Position).Unit
                        local forward = Camera.CFrame.LookVector
                        local dot = forward:Dot(toTarget)
                        if dot > 0.5 then
                            local distance3D = (head.Position - LocalPlayer.Character.Head.Position).Magnitude
                            if distance3D < shortestDistance then
                                shortestDistance = distance3D
                                closest = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function getSmartAimPart(character)
    if TargetMode == "Torso" then
        return character:FindFirstChild("HumanoidRootPart")
    elseif TargetMode == "Smart" then
        local head = character:FindFirstChild("Head")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if head and hrp then
            local headVel = head.AssemblyLinearVelocity or head.Velocity or Vector3.zero
            local hrpVel = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero

            if headVel.Magnitude > hrpVel.Magnitude + 50 then
                return hrp
            end
        end
        return head
    else
        return character:FindFirstChild("Head")
    end
end

local function predictPosition(targetPart, character)
    local ping = getPing()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local player = Players:GetPlayerFromCharacter(character)

    -- ✅ Smart Predict รวม Anti-Lock Resolver
    if UseSmartPredict and player and TargetHistory[player] then
        local avgVel = getAverageVelocity(player)
        
        -- ถ้าตรวจพบ Anti-Lock ให้ลด multiplier
        if VelocitySpikes[player] and VelocitySpikes[player].isAntiLock then
            -- ใช้ prediction แบบน้อยที่สุดเพื่อไม่ให้ถูก juke
            return targetPart.Position + (avgVel * ping * 0.6)
        else
            -- Prediction ปกติ
            return targetPart.Position + (avgVel * ping * 1.3)
        end
    else
        -- ไม่เปิด Smart Predict ใช้ velocity ปกติ
        local velocity = hrp and (hrp.AssemblyLinearVelocity or hrp.Velocity) or Vector3.zero
        return targetPart.Position + (velocity * ping * 1.15)
    end
end

-- อัพเดท history ของ targets
RunService.Heartbeat:Connect(
    function()
        if CurrentTarget and CurrentTarget.Character then
            local head = CurrentTarget.Character:FindFirstChild("Head")
            local hrp = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
            if head and hrp then
                local velocity = hrp.AssemblyLinearVelocity or hrp.Velocity or Vector3.zero
                updateTargetHistory(CurrentTarget, head.Position, velocity)
            end
        end
    end
)

-- ===== Fake Head สำหรับ Anti-Lock =====
local FakeHead = nil

local function UpdateFakeHead()
    -- ✅ ถ้าปิด Anti-Lock ให้ลบ FakeHead ทิ้งทันที
    if not _G.AntiLock then
        if FakeHead then
            FakeHead:Destroy()
            FakeHead = nil
        end
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local realHead = char:FindFirstChild("Head")
    if not realHead then return end
    
    -- สร้าง Fake Head ถ้ายังไม่มี
    if not FakeHead or not FakeHead.Parent then
        FakeHead = Instance.new("Part")
        FakeHead.Name = "FakeHead"
        FakeHead.Size = Vector3.new(2, 1, 1)
        FakeHead.Transparency = 1
        FakeHead.CanCollide = false
        FakeHead.Anchored = true
        FakeHead.Parent = workspace
    end
    
    -- อัพเดทตำแหน่ง Fake Head ให้อยู่ตรงกลางหน้าจอ
    local camera = workspace.CurrentCamera
    if camera then
        FakeHead.CFrame = camera.CFrame * CFrame.new(0, 0, -5)
    end
end

-- ลบ Fake Head เมื่อตาย/ออกจากเกม
LocalPlayer.CharacterRemoving:Connect(function()
    if FakeHead then
        FakeHead:Destroy()
        FakeHead = nil
    end
end)

-- ✅ อัพเดท Fake Head ทุกเฟรม (เฉพาะเมื่อเปิด Anti-Lock)
RunService.Heartbeat:Connect(function()
    UpdateFakeHead()
end)

-- ===== Render Loop (Gradient FOV + รองรับทั้ง PC และ Mobile) =====
RunService.RenderStepped:Connect(
    function()
        local centerX = Camera.ViewportSize.X / 2
        local centerY = Camera.ViewportSize.Y / 2
        local center = Vector2.new(centerX, centerY)
        
        -- 🌈 คำนวณ Rainbow Gradient
        local time = tick() * 2
        
        -- อัพเดท Gradient FOV Circle
        if not IsMobile then
            -- ===== PC: Drawing API แบบ Gradient =====
            local numSegments = #FOVCircleSegments
            local angleStep = (math.pi * 2) / numSegments
            
            for i = 1, numSegments do
                local line = FOVCircleSegments[i]
                
                if SilentAimEnabled and ShowFOVEnabled then
                    local angle1 = angleStep * (i - 1)
                    local angle2 = angleStep * i
                    
                    local point1 = GetCirclePoint(center, FOVRadius, angle1)
                    local point2 = GetCirclePoint(center, FOVRadius, angle2)
                    
                    -- 🎨 สร้างสี Rainbow แบบไล่เฉด
                    local hue = ((i / numSegments) + (time * 0.1)) % 1
                    local color = Color3.fromHSV(hue, 0.8, 1)
                    
                    line.From = point1
                    line.To = point2
                    line.Color = color
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        else
            -- ===== Mobile: GUI Gradient =====
            if FOVCircleFrame then
                FOVCircleFrame.Visible = SilentAimEnabled and ShowFOVEnabled
                FOVCircleFrame.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
                
                -- อัพเดท Gradient
                local stroke = FOVCircleFrame:FindFirstChildOfClass("UIStroke")
                if stroke then
                    local gradient = stroke:FindFirstChildOfClass("UIGradient")
                    if gradient then
                        local hue1 = (time * 0.1) % 1
                        local hue2 = (time * 0.1 + 0.33) % 1
                        local hue3 = (time * 0.1 + 0.66) % 1
                        
                        gradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(hue1, 0.8, 1)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(hue2, 0.8, 1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(hue3, 0.8, 1))
                        })
                        
                        -- หมุน Gradient
                        gradient.Rotation = (time * 50) % 360
                    end
                end
            end
        end

        if SilentAimEnabled then
            CurrentTarget = getClosestTarget()
        else
            CurrentTarget = nil
        end

        if CurrentTarget and CurrentTarget.Character then
            local targetPart = getSmartAimPart(CurrentTarget.Character)
            
            local myHead
            if _G.AntiLock and FakeHead and FakeHead.Parent then
                myHead = FakeHead
            else
                myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            end

            if targetPart and myHead then
                local myScreenPos, myOnScreen = Camera:WorldToViewportPoint(myHead.Position)
                local targetScreenPos, targetOnScreen = Camera:WorldToViewportPoint(targetPart.Position)

                if targetOnScreen then
                    if not IsMobile then
                        Tracer.Visible = true
                        Tracer.From = Vector2.new(myScreenPos.X, myScreenPos.Y)
                        Tracer.To = Vector2.new(targetScreenPos.X, targetScreenPos.Y)

                        TargetHeadCircle.Visible = true
                        TargetHeadCircle.Position = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                    else
                        if TracerFrame then
                            local dx = targetScreenPos.X - myScreenPos.X
                            local dy = targetScreenPos.Y - myScreenPos.Y
                            local length = math.sqrt(dx * dx + dy * dy)
                            local angle = math.deg(math.atan2(dy, dx))
                            
                            TracerFrame.Size = UDim2.new(0, length, 0, 2)
                            TracerFrame.Position = UDim2.new(0, myScreenPos.X, 0, myScreenPos.Y)
                            TracerFrame.Rotation = angle
                            TracerFrame.Visible = true
                        end
                        
                        if TargetCircleFrame then
                            TargetCircleFrame.Position = UDim2.new(0, targetScreenPos.X, 0, targetScreenPos.Y)
                            TargetCircleFrame.Visible = true
                        end
                    end
                else
                    if not IsMobile then
                        Tracer.Visible = false
                        TargetHeadCircle.Visible = false
                    else
                        if TracerFrame then TracerFrame.Visible = false end
                        if TargetCircleFrame then TargetCircleFrame.Visible = false end
                    end
                end
            end
        else
            if not IsMobile then
                Tracer.Visible = false
                TargetHeadCircle.Visible = false
            else
                if TracerFrame then TracerFrame.Visible = false end
                if TargetCircleFrame then TargetCircleFrame.Visible = false end
            end
        end
    end
)

-- ===== Hook FireServer =====
local oldFire
oldFire =
    hookfunction(
    game:GetService("ReplicatedStorage").Remotes.Send.FireServer,
    function(self, ...)
        local args = {...}
        if SilentAimEnabled and args[2] == "shoot_gun" and CurrentTarget and CurrentTarget.Character then
            local targetPart = getSmartAimPart(CurrentTarget.Character)

            if targetPart then
                local aimPos = predictPosition(targetPart, CurrentTarget.Character)
                local realHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                local myHeadPos = realHead and realHead.Position or Camera.CFrame.Position

                args[4] = CFrame.new(myHeadPos, aimPos)
                args[4] = CFrame.new(math.huge, math.huge, math.huge)

                args[5] = {
                    [1] = {
                        [1] = {
                            ["Instance"] = targetPart,
                            ["Normal"] = Vector3.new(0, 1, 0),
                            ["Position"] = aimPos
                        }
                    }
                }

                local beam = Instance.new("Part", workspace)
                beam.Anchored = true
                beam.CanCollide = false
                beam.Size = Vector3.new(0.05, 0.05, (aimPos - myHeadPos).Magnitude)
                beam.CFrame = CFrame.new(myHeadPos, aimPos) * CFrame.new(0, 0, -beam.Size.Z / 2)
                beam.Color = Color3.fromRGB(255, 50, 50)
                beam.Material = Enum.Material.Neon
                beam.Transparency = 0.25
                game:GetService("Debris"):AddItem(beam, 1.5)
            end
        end
        return oldFire(self, unpack(args))
    end
)

-- ===== UI Controls =====
CombatTab:Toggle(
    {
        Title = "Silent Aim",
        Flag = "silent aim",
        Desc = "Auto aim to target",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(state)
            SilentAimEnabled = state
        end
    }
)

CombatTab:Toggle(
    {
        Title = "Show FOV",
        Flag = "show",
        Desc = "Display FOV circle",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(state)
            ShowFOVEnabled = state
        end
    }
)

CombatTab:Toggle(
    {
        Title = "Smart Predict",
        Flag = "smartpredict",
        Desc = "Advanced velocity prediction + Anti-Lock Resolver",
        Icon = "check",
        Type = "Checkbox",
        Default = true,
        Callback = function(state)
            UseSmartPredict = state
        end
    }
)

CombatTab:Toggle(
    {
        Title = "Wallbang",
        Flag = "wallbang",
        Desc = "Shoot through walls",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(state)
            WallbangEnabled = state
        end
    }
)

CombatTab:Dropdown(
    {
        Title = "Target Mode",
        Flag = "target_mode",
        Desc = "Select aim target part",
        Icon = "target",
        Values = {"Head", "Torso", "Smart"},
        Default = "Head",
        Callback = function(value)
            TargetMode = value
        end
    }
)

CombatTab:Slider(
    {
        Title = "FOV Size",
        Flag = "fov_size",
        Step = 1,
        Value = {
            Min = 20,
            Max = 1000,
            Default = FOVRadius
        },
        Callback = function(value)
            FOVRadius = tonumber(value) or 120
            
            -- อัพเดทขนาด (Mobile)
            if IsMobile and FOVCircleFrame then
                FOVCircleFrame.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
            end
        end
    }
)

CombatTab:Slider(
    {
        Title = "Velocity Threshold",
        Flag = "velocity_threshold",
        Step = 10,
        Value = {
            Min = 100,
            Max = 500,
            Default = VelocityThreshold
        },
        Callback = function(value)
            VelocityThreshold = tonumber(value) or 250
        end
    }
)

-- ✅ 1. สร้าง helper function ก่อน
local function GetDistanceFromRootPart(targetRoot)
    if not targetRoot or not RootPart then
        return math.huge
    end
    return (RootPart.Position - targetRoot.Position).Magnitude
end

-- ✅ 2. ประกาศฟังก์ชัน Hit Aura ก่อน Toggle
func["HitAura"] = function()
    while task.wait() do
        if not c().HitAura then
            break -- หยุดลูปเมื่อปิด toggle
        end

        for _, vx in pairs(Players:GetPlayers()) do
            if vx ~= Client and vx.Character and vx.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = vx.Character:FindFirstChild("HumanoidRootPart")
                local dist = GetDistanceFromRootPart(targetRoot)

                if dist < 0 then -- ระยะคงที่ 20 studs
                    for i, v in pairs(Character:GetChildren()) do
                        if v:IsA("Tool") and v.Name == "Fists" then
                            local keys = {}
                            for x in pairs(v:GetAttributes()) do
                                table.insert(keys, x)
                            end
                            table.sort(keys)

                            -- ตั้งค่า attributes
                            v:SetAttribute(keys[7], 20)
                            v:SetAttribute(keys[8], 10000)

                            -- โจมตี
                            Net.send("melee_attack", v, {vx}, targetRoot.CFrame, 0)
                            task.wait(0) -- delay หลังโจมตี
                        end
                    end
                end
            end
        end
    end
end

-- ✅ 3. สร้าง Toggle (รับค่า state)
CombatTab:Toggle(
    {
        Title = "Hit Aura",
        Flag = "hitaura",
        Desc = "Auto attack near player",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(state)
            c().HitAura = state

            if state then
                -- เปิด: เริ่มทำงาน
                task.spawn(func["HitAura"])
            end
            -- ปิด: ฟังก์ชันจะหยุดเองเมื่อ c().HitAura = false
        end
    }
)

local WeaponTab = Window:Tab({
    Title = "Weapon",
    Icon = "wrench"
})

WeaponTab:Section({
    Title = "Gun Modification:"
})

-- ตัวแปรเก็บค่า Settings (ตั้งค่า MAX ทั้งหมด)
local GunModSettings = {
    Enabled = false,
    accuracy = math.huge,
    range = math.huge,
    Recoil = 0,
    fire_rate = math.huge,
    reload_time = 0,
    automatic = true
}

-- เก็บชื่อ attribute ที่หาเจอ
local FireRateAttributeName = "fire_rate"
local AutomaticAttributeName = "automatic"

-- Label แสดงปืนปัจจุบัน
local CurrentGunLabel = WeaponTab:Button({
    Title = "Current Gun",
    Desc = "None"
})

-- ฟังก์ชันหาชื่อ fire_rate attribute (ลงท้ายด้วย 486)
local function FindFireRateAttribute(gun)
    if not gun then return nil end
    
    -- ลองชื่อปกติก่อน
    if gun:GetAttribute("fire_rate") ~= nil then
        return "fire_rate"
    end
    
    -- หาชื่อที่ลงท้ายด้วย 486
    for attrName, attrValue in pairs(gun:GetAttributes()) do
        if type(attrName) == "string" and attrName:sub(-3) == "486" then
            return attrName
        end
    end
    
    return nil
end

-- ฟังก์ชันหาชื่อ automatic attribute (ลงท้ายด้วย 492)
local function FindAutomaticAttribute(gun)
    if not gun then return nil end
    
    -- ลองชื่อปกติก่อน
    if gun:GetAttribute("automatic") ~= nil then
        return "automatic"
    end
    
    -- หาชื่อที่ลงท้ายด้วย 492
    for attrName, attrValue in pairs(gun:GetAttributes()) do
        if type(attrName) == "string" and attrName:sub(-3) == "492" then
            return attrName
        end
    end
    
    return nil
end

-- ฟังก์ชันตรวจสอบว่าเป็นปืนหรือไม่
local function IsGun(tool)
    if not tool or not tool:IsA("Tool") then return false end
    return tool:GetAttribute("reload_time") or tool:GetAttribute("AmmoType") or FindFireRateAttribute(tool)
end

-- ฟังก์ชันแก้ไขปืน
local function ModifyGunAttributes(gun)
    if not gun or not gun:IsA("Tool") then
        return false
    end
    
    pcall(function()
        gun:SetAttribute("accuracy", GunModSettings.accuracy)
        gun:SetAttribute("range", GunModSettings.range)
        gun:SetAttribute("Recoil", GunModSettings.Recoil)
        gun:SetAttribute("reload_time", GunModSettings.reload_time)
        
        -- หาและตั้งค่า fire_rate
        local fireRateAttr = FindFireRateAttribute(gun)
        if fireRateAttr then
            gun:SetAttribute(fireRateAttr, GunModSettings.fire_rate)
            FireRateAttributeName = fireRateAttr
        else
            gun:SetAttribute("fire_rate", GunModSettings.fire_rate)
        end
        
        -- หาและตั้งค่า automatic
        local automaticAttr = FindAutomaticAttribute(gun)
        if automaticAttr then
            gun:SetAttribute(automaticAttr, GunModSettings.automatic)
            AutomaticAttributeName = automaticAttr
        else
            gun:SetAttribute("automatic", GunModSettings.automatic)
        end
    end)
    
    return true
end

-- ฟังก์ชัน Mod ปืนทั้งหมดใน Backpack
local function ModAllGunsInBackpack()
    local count = 0
    for _, tool in pairs(Backpack:GetChildren()) do
        if IsGun(tool) then
            ModifyGunAttributes(tool)
            count = count + 1
        end
    end
    return count
end

-- ฟังก์ชัน Mod ปืนที่ถืออยู่
local function ModEquippedGun()
    local char = Client.Character
    if not char then return false end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and IsGun(tool) then
        ModifyGunAttributes(tool)
        CurrentGunLabel:SetDesc(tool.Name)
        return true
    end
    return false
end

-- Realtime Monitor สำหรับ fire_rate
local RealtimeConnections = {}

local function StartRealtimeMonitor(gun)
    if not gun or RealtimeConnections[gun] then return end
    
    local fireRateAttr = FindFireRateAttribute(gun)
    if not fireRateAttr then return end
    
    -- Monitor การเปลี่ยนแปลงของ fire_rate
    local connection = gun:GetAttributeChangedSignal(fireRateAttr):Connect(function()
        if GunModSettings.Enabled then
            local currentValue = gun:GetAttribute(fireRateAttr)
            
            -- ถ้าค่าไม่ใช่ math.huge หรือ infinity ให้ตั้งใหม่
            if currentValue ~= math.huge and currentValue ~= GunModSettings.fire_rate then
                gun:SetAttribute(fireRateAttr, GunModSettings.fire_rate)
            end
        end
    end)
    
    RealtimeConnections[gun] = connection
end

local function StopRealtimeMonitor(gun)
    if RealtimeConnections[gun] then
        RealtimeConnections[gun]:Disconnect()
        RealtimeConnections[gun] = nil
    end
end

local function StopAllRealtimeMonitors()
    for gun, connection in pairs(RealtimeConnections) do
        connection:Disconnect()
    end
    RealtimeConnections = {}
end

-- ฟังก์ชัน Auto Mod Loop
local BackpackConnection = nil
local CharacterConnection = nil
local RealtimeUpdateLoop = nil

local function StartAutoMod()
    -- หยุด connection เก่า
    if BackpackConnection then
        BackpackConnection:Disconnect()
    end
    if CharacterConnection then
        CharacterConnection:Disconnect()
    end
    if RealtimeUpdateLoop then
        RealtimeUpdateLoop:Disconnect()
    end
    
    StopAllRealtimeMonitors()
    
    -- Mod ปืนทั้งหมดใน Backpack ทันที
    local count = ModAllGunsInBackpack()
    
    -- Mod ปืนที่ถืออยู่ถ้ามี
    local equipped = ModEquippedGun()
    
    -- เริ่ม realtime monitor สำหรับปืนทุกตัว
    for _, tool in pairs(Backpack:GetChildren()) do
        if IsGun(tool) then
            StartRealtimeMonitor(tool)
        end
    end
    
    local char = Client.Character
    if char then
        local equippedTool = char:FindFirstChildOfClass("Tool")
        if equippedTool and IsGun(equippedTool) then
            StartRealtimeMonitor(equippedTool)
        end
    end
    
    if count > 0 or equipped then
        WindUI:Notify({
            Title = "Gun Mod",
            Content = "Modified " .. count .. " gun(s) + Realtime active",
            Duration = 2
        })
    else
        CurrentGunLabel:SetDesc("No Gun Found")
    end
    
    -- ฟัง Backpack เมื่อมีปืนเพิ่มเข้ามา
    BackpackConnection = Backpack.ChildAdded:Connect(function(tool)
        if GunModSettings.Enabled and IsGun(tool) then
            task.wait(0.05)
            ModifyGunAttributes(tool)
            StartRealtimeMonitor(tool)
        end
    end)
    
    -- ฟัง Character เมื่อจับปืน
    local char = Client.Character
    if char then
        CharacterConnection = char.ChildAdded:Connect(function(tool)
            if GunModSettings.Enabled and IsGun(tool) then
                task.wait(0.05)
                ModifyGunAttributes(tool)
                CurrentGunLabel:SetDesc(tool.Name)
                StartRealtimeMonitor(tool)
            end
        end)
    end
    
    -- Realtime update loop ทุก frame (0 วินาที)
    RealtimeUpdateLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if not GunModSettings.Enabled then return end
        
        -- Update ปืนที่ถือ
        local char = Client.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and IsGun(tool) then
                ModifyGunAttributes(tool)
            end
        end
        
        -- Update ทุกปืนใน Backpack
        for _, tool in pairs(Backpack:GetChildren()) do
            if IsGun(tool) then
                ModifyGunAttributes(tool)
            end
        end
    end)
end

local function StopAutoMod()
    if BackpackConnection then
        BackpackConnection:Disconnect()
        BackpackConnection = nil
    end
    
    if CharacterConnection then
        CharacterConnection:Disconnect()
        CharacterConnection = nil
    end
    
    if RealtimeUpdateLoop then
        RealtimeUpdateLoop:Disconnect()
        RealtimeUpdateLoop = nil
    end
    
    StopAllRealtimeMonitors()
    CurrentGunLabel:SetDesc("None")
end

-- ===== UI Controls (ปุ่มทั้งหมด) =====

-- Toggle เปิด/ปิด Gun Mod
WeaponTab:Toggle({
    Title = "Enable Gun Mod",
    Flag = "gun_mod_enabled",
    Icon = "check",
    Type = "Checkbox",
    Default = false,
    Callback = function(Value)
        GunModSettings.Enabled = Value
        
        if Value then
            StartAutoMod()
            WindUI:Notify({
                Title = "Gun Mod",
                Content = "Enabled + Realtime Monitor",
                Duration = 2
            })
        else
            StopAutoMod()
            WindUI:Notify({
                Title = "Gun Mod",
                Content = "Disabled",
                Duration = 2
            })
        end
    end
})

WeaponTab:Divider()

-- Toggle: Max Accuracy
WeaponTab:Toggle({
    Title = "INFINITE Accuracy",
    Flag = "gun_max_accuracy",
    Icon = "crosshair",
    Type = "Checkbox",
    Default = true,
    Callback = function(Value)
        GunModSettings.accuracy = Value and math.huge or 1
        
        if GunModSettings.Enabled then
            ModAllGunsInBackpack()
            ModEquippedGun()
        end
    end
})

-- Toggle: Max Range
WeaponTab:Toggle({
    Title = "INFINITE Range",
    Flag = "gun_max_range",
    Icon = "crosshair",
    Type = "Checkbox",
    Default = true,
    Callback = function(Value)
        GunModSettings.range = Value and math.huge or 100
        
        if GunModSettings.Enabled then
            ModAllGunsInBackpack()
            ModEquippedGun()
        end
    end
})

-- Toggle: No Recoil
WeaponTab:Toggle({
    Title = "NO Recoil",
    Flag = "gun_no_recoil",
    Icon = "check",
    Type = "Checkbox",
    Default = true,
    Callback = function(Value)
        GunModSettings.Recoil = Value and 0 or 1
        
        if GunModSettings.Enabled then
            ModAllGunsInBackpack()
            ModEquippedGun()
        end
    end
})

-- Toggle: Infinite Fire Rate
WeaponTab:Toggle({
    Title = "INFINITE Fire Rate",
    Flag = "gun_infinite_firerate",
    Icon = "zap",
    Type = "Checkbox",
    Default = true,
    Callback = function(Value)
        GunModSettings.fire_rate = Value and math.huge or 0.1
        
        if GunModSettings.Enabled then
            ModAllGunsInBackpack()
            ModEquippedGun()
        end
    end
})

-- Toggle: Min Reload Time
WeaponTab:Toggle({
    Title = "MIN Reload Time",
    Flag = "gun_min_reload",
    Icon = "check",
    Type = "Checkbox",
    Default = true,
    Callback = function(Value)
        GunModSettings.reload_time = Value and 0 or 2
        
        if GunModSettings.Enabled then
            ModAllGunsInBackpack()
            ModEquippedGun()
        end
    end
})

-- Toggle: Automatic
WeaponTab:Toggle({
    Title = "Automatic Mode",
    Flag = "gun_automatic",
    Icon = "check",
    Type = "Checkbox",
    Default = true,
    Callback = function(Value)
        GunModSettings.automatic = Value
        
        if GunModSettings.Enabled then
            ModAllGunsInBackpack()
            ModEquippedGun()
        end
    end
})

WeaponTab:Divider()

-- ปุ่ม Force Refresh
WeaponTab:Button({
    Title = "Refresh All Guns",
    Desc = "Reapply modifications to all guns",
    Callback = function()
        if GunModSettings.Enabled then
            local count = ModAllGunsInBackpack()
            ModEquippedGun()
            
            WindUI:Notify({
                Title = "Gun Mod",
                Content = "Refreshed " .. count .. " gun(s)",
                Duration = 2
            })
        end
    end
})

-- รีเซ็ตเมื่อตาย
Client.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    Backpack = Client:WaitForChild("Backpack")
    
    StopAllRealtimeMonitors()
    
    if GunModSettings.Enabled then
        task.wait(0.5)
        StartAutoMod()
    end
end)

local MainTab =
    Window:Tab(
    {
        Title = "Vehicle",
        Icon = "car"
    }
)

-- Bump Aura Function
local function BumpAuraLoop()
    while _G.BumpAura do
        task.wait(0.1)

        local car = Vechine.get_car_player_is_in()
        if not car then
            continue
        end

        for _, target in CharModule.get_all() do  -- เปลี่ยนจาก Char เป็น CharModule
            if target ~= Character then
                local hrp = target:FindFirstChild("HumanoidRootPart")
                if hrp and GetDistanceFromRootPart(hrp) < 100 then
                    
                    -- เพิ่มแรงกระแทก
                    local Assembly = car.DriverSeat.AssemblyLinearVelocity 
                                     + Vector3.new(65, 65, 65)

                    Net.send("run_over", car, target, Assembly)
                end
            end 
        end
    end
end

-- Toggle UI
MainTab:Toggle({
    Title = "Bump Aura",
    Flag = "BumpAura",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        _G.BumpAura = Value

        if Value then
            task.spawn(BumpAuraLoop)
        end
    end
})



local VisualTab =
    Window:Tab(
    {
        Title = "Visual",
        Icon = "eye"
    }
)

VisualTab:Section(
    {
        Title = "Players:"
    }
)

local ESPModule = {
    Settings = {
        Box = {
            Enabled = false,
            Color = Color3.fromRGB(255, 250, 250)
        },
        Name = {
            Enabled = false,
            Color = Color3.fromRGB(255, 250, 250)
        },
        Tracer = {
            Enabled = false,
            Color = Color3.fromRGB(255, 250, 250)
        },
        Distance = {
            Enabled = false,
            Color = Color3.fromRGB(255, 250, 250)
        },
        Skeleton = {
            Enabled = false,
            Color = Color3.fromRGB(255, 250, 250)
        },
        RGBEnabled = false,
        Gradient = {
            From = Color3.fromRGB(255, 250, 250)
        }
    },
    drawings = {}
}

function ESPModule.CreateDrawings(player)
    if ESPModule.drawings[player] then
        return
    end
    local drawings = {
        BoxLines = {},
        NameShadow = Drawing.new("Text"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        DistanceShadow = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        -- Skeleton Lines
        skel_head = Drawing.new("Line"),
        skel_torso = Drawing.new("Line"),
        skel_leftarm = Drawing.new("Line"),
        skel_leftforearm = Drawing.new("Line"),
        skel_lefthand = Drawing.new("Line"),
        skel_rightarm = Drawing.new("Line"),
        skel_rightforearm = Drawing.new("Line"),
        skel_righthand = Drawing.new("Line"),
        skel_leftleg = Drawing.new("Line"),
        skel_leftshin = Drawing.new("Line"),
        skel_leftfoot = Drawing.new("Line"),
        skel_rightleg = Drawing.new("Line"),
        skel_rightshin = Drawing.new("Line"),
        skel_rightfoot = Drawing.new("Line")
    }

    -- สร้าง 12 เส้นสำหรับ 3D Box
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Visible = false
        table.insert(drawings.BoxLines, line)
    end

    -- Name Shadow
    drawings.NameShadow.Color = Color3.new(0, 0, 0)
    drawings.NameShadow.Transparency = 0.5
    drawings.NameShadow.Outline = false
    drawings.NameShadow.Center = true
    drawings.NameShadow.Size = 16
    drawings.NameShadow.Font = 2
    drawings.NameShadow.Visible = false

    -- Name
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Visible = false
    drawings.Name.Size = 16
    drawings.Name.Font = 2

    -- Tracer
    drawings.Tracer.Visible = false
    drawings.Tracer.Thickness = 2

    -- Distance Shadow
    drawings.DistanceShadow.Color = Color3.new(0, 0, 0)
    drawings.DistanceShadow.Transparency = 0.5
    drawings.DistanceShadow.Outline = false
    drawings.DistanceShadow.Center = true
    drawings.DistanceShadow.Size = 14
    drawings.DistanceShadow.Font = 2
    drawings.DistanceShadow.Visible = false

    -- Distance
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Visible = false
    drawings.Distance.Size = 14
    drawings.Distance.Font = 2

    -- Skeleton Lines Setup
    local skelLines = {
        drawings.skel_head,
        drawings.skel_torso,
        drawings.skel_leftarm,
        drawings.skel_leftforearm,
        drawings.skel_lefthand,
        drawings.skel_rightarm,
        drawings.skel_rightforearm,
        drawings.skel_righthand,
        drawings.skel_leftleg,
        drawings.skel_leftshin,
        drawings.skel_leftfoot,
        drawings.skel_rightleg,
        drawings.skel_rightshin,
        drawings.skel_rightfoot
    }

    for _, line in pairs(skelLines) do
        line.Thickness = 1.5
        line.Visible = false
    end

    ESPModule.drawings[player] = drawings
end

-- 🟩 Toggle Controls
VisualTab:Toggle(
    {
        Title = "3D Box ESP",
        Flag = "boxesp",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(Value)
            ESPModule.Settings.Box.Enabled = Value
        end
    }
)

VisualTab:Toggle(
    {
        Title = "Name ESP",
        Flag = "nameesp",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(Value)
            ESPModule.Settings.Name.Enabled = Value
        end
    }
)

VisualTab:Toggle(
    {
        Title = "Tracer ESP",
        Flag = "traceresp",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(Value)
            ESPModule.Settings.Tracer.Enabled = Value
        end
    }
)

VisualTab:Toggle(
    {
        Title = "Distance ESP",
        Flag = "distance",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(Value)
            ESPModule.Settings.Distance.Enabled = Value
        end
    }
)

-- ⭐ Skeleton ESP Toggle
VisualTab:Toggle(
    {
        Title = "Skeleton ESP",
        Flag = "skeletonesp",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(Value)
            ESPModule.Settings.Skeleton.Enabled = Value
        end
    }
)

-- 🌈 RGB Effect Toggle
VisualTab:Toggle(
    {
        Title = "Enable RGB Color",
        Flag = "rgbcolor",
        Icon = "check",
        Type = "Checkbox",
        Default = false,
        Callback = function(Value)
            ESPModule.Settings.RGBEnabled = Value
        end
    }
)

-- 🎨 Color Picker
VisualTab:Colorpicker(
    {
        Title = "Esp Color",
        Flag = "esp_color",
        Icon = "check",
        Type = "Checkbox",
        Default = ESPModule.Settings.Gradient.From,
        Callback = function(Color)
            ESPModule.Settings.Gradient.From = Color
        end
    }
)

-- ฟังก์ชันสร้าง 3D Box ที่พอดีกับตัวจริง
local function Create3DBox(character, drawings, color)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    
    if not hrp or not head then
        return false
    end
    
    -- หาขนาดจริงของตัวละคร
    local function getCharacterBounds()
        local minX, maxX = math.huge, -math.huge
        local minY, maxY = math.huge, -math.huge
        local minZ, maxZ = math.huge, -math.huge
        
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local pos = part.Position
                local size = part.Size
                
                minX = math.min(minX, pos.X - size.X/2)
                maxX = math.max(maxX, pos.X + size.X/2)
                minY = math.min(minY, pos.Y - size.Y/2)
                maxY = math.max(maxY, pos.Y + size.Y/2)
                minZ = math.min(minZ, pos.Z - size.Z/2)
                maxZ = math.max(maxZ, pos.Z + size.Z/2)
            end
        end
        
        return {
            width = (maxX - minX) * 0.55,  -- ยืดเล็กน้อย
            height = (maxY - minY) * 0.52, -- ยืดเล็กน้อย
            depth = (maxZ - minZ) * 0.55   -- ยืดเล็กน้อย
        }
    end
    
    local bounds = getCharacterBounds()
    local width = bounds.width
    local height = bounds.height
    local depth = bounds.depth
    
    -- ใช้ตำแหน่งกึ่งกลางระหว่าง head กับ hrp
    local centerY = (head.Position.Y + hrp.Position.Y) / 2
    local centerPos = Vector3.new(hrp.Position.X, centerY, hrp.Position.Z)
    local cf = CFrame.new(centerPos) * hrp.CFrame.Rotation
    
    -- 8 มุมของกล่อง 3D
    local corners = {
        cf * CFrame.new(-width/2, height/2, -depth/2),  -- 1: ซ้ายบนหน้า
        cf * CFrame.new(width/2, height/2, -depth/2),   -- 2: ขวาบนหน้า
        cf * CFrame.new(-width/2, -height/2, -depth/2), -- 3: ซ้ายล่างหน้า
        cf * CFrame.new(width/2, -height/2, -depth/2),  -- 4: ขวาล่างหน้า
        cf * CFrame.new(-width/2, height/2, depth/2),   -- 5: ซ้ายบนหลัง
        cf * CFrame.new(width/2, height/2, depth/2),    -- 6: ขวาบนหลัง
        cf * CFrame.new(-width/2, -height/2, depth/2),  -- 7: ซ้ายล่างหลัง
        cf * CFrame.new(width/2, -height/2, depth/2)    -- 8: ขวาล่างหลัง
    }
    
    -- แปลงเป็น 2D
    local points2D = {}
    local allOnScreen = true
    
    for i, corner in ipairs(corners) do
        local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(corner.Position)
        points2D[i] = Vector2.new(pos.X, pos.Y)
        if not onScreen then
            allOnScreen = false
        end
    end
    
    if not allOnScreen then
        return false
    end
    
    -- 12 เส้นของกล่อง 3D
    local connections = {
        {1, 2}, {2, 4}, {4, 3}, {3, 1}, -- หน้า (Front face)
        {5, 6}, {6, 8}, {8, 7}, {7, 5}, -- หลัง (Back face)
        {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- เชื่อมหน้า-หลัง
    }
    
    for i, conn in ipairs(connections) do
        local line = drawings.BoxLines[i]
        if line then
            line.From = points2D[conn[1]]
            line.To = points2D[conn[2]]
            line.Color = color
            line.Visible = true
        end
    end
    
    return true
end

-- แทนที่ฟังก์ชัน Create3DBox เดิมในโค้ด ESP ด้วยฟังก์ชันนี้
-- ในส่วน Main Render Loop ที่มี:
-- if ESPModule.Settings.Box.Enabled then
--     local boxVisible = Create3DBox(hrp, drawings, boxColor)
--     ...
-- end
-- 
-- เปลี่ยนเป็น:
-- if ESPModule.Settings.Box.Enabled then
--     local boxVisible = Create3DBox(char, drawings, boxColor)  -- ส่ง character แทน hrp
--     ...
-- end

-- 🔄 Main Render Loop
RunService.RenderStepped:Connect(
    function()
        local time = tick() * 1.5
        local hue1 = (time % 6) / 6
        local hue2 = ((time + 1.5) % 6) / 6
        local hue3 = ((time + 3) % 6) / 6

        for player, drawings in pairs(ESPModule.drawings) do
            local shouldProcess = false

            if player ~= game.Players.LocalPlayer and player.Character then
                local char = player.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")

                if hrp and head then
                    shouldProcess = true

                    -- ฟังก์ชันแปลง 3D -> 2D
                    local function to2d(part)
                        local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                        return Vector2.new(pos.X, pos.Y), onScreen
                    end

                    -- คำนวณสีตาม RGB toggle
                    local boxColor = ESPModule.Settings.RGBEnabled and Color3.fromHSV(hue1, 0.8, 1) or ESPModule.Settings.Gradient.From
                    local nameColor = ESPModule.Settings.RGBEnabled and Color3.fromHSV(hue1, 0.6, 1) or ESPModule.Settings.Gradient.From
                    local tracerColor = ESPModule.Settings.RGBEnabled and Color3.fromHSV(hue2, 0.8, 1) or ESPModule.Settings.Gradient.From
                    local distColor = ESPModule.Settings.RGBEnabled and Color3.fromHSV(hue3, 0.7, 1) or ESPModule.Settings.Gradient.From
                    local skelColor = ESPModule.Settings.RGBEnabled and Color3.fromHSV(hue1, 0.8, 1) or ESPModule.Settings.Gradient.From

                    -- 📦 3D Box ESP
-- 📦 3D Box ESP
if ESPModule.Settings.Box.Enabled then
    local boxVisible = Create3DBox(char, drawings, boxColor)  -- ✅ ถูกต้อง (ส่ง char แทน hrp)
    if not boxVisible then
        for _, line in pairs(drawings.BoxLines) do
            line.Visible = false
        end
    end
                    else
                        for _, line in pairs(drawings.BoxLines) do
                            line.Visible = false
                        end
                    end

                    -- คำนวณตำแหน่งสำหรับ Name และ Distance
                    local headTop = head.Position + Vector3.new(0, 0.5, 0)
                    local headPos, headOnScreen = workspace.CurrentCamera:WorldToViewportPoint(headTop)
                    local rootPos, rootOnScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                    local feetPosition = hrp.Position - Vector3.new(0, 3.3, 0)
                    local feetPos, feetOnScreen = workspace.CurrentCamera:WorldToViewportPoint(feetPosition)
                    local onScreen = headOnScreen and feetOnScreen

                    -- 📝 Name ESP
                    if ESPModule.Settings.Name.Enabled and onScreen then
                        drawings.NameShadow.Text = player.Name
                        drawings.NameShadow.Position = Vector2.new(headPos.X + 2, headPos.Y - 22)
                        drawings.NameShadow.Visible = true

                        drawings.Name.Text = player.Name
                        drawings.Name.Color = nameColor
                        drawings.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
                        drawings.Name.Visible = true
                    else
                        drawings.NameShadow.Visible = false
                        drawings.Name.Visible = false
                    end

                    -- 📏 Tracer ESP
                    if ESPModule.Settings.Tracer.Enabled and rootOnScreen then
                        drawings.Tracer.Visible = true
                        drawings.Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, 0)
                        drawings.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                        drawings.Tracer.Color = tracerColor
                    else
                        drawings.Tracer.Visible = false
                    end

                    -- 📍 Distance ESP
                    if ESPModule.Settings.Distance.Enabled and onScreen then
                        local distance =
                            math.floor(
                            (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                        )

                        drawings.DistanceShadow.Text = distance .. "m"
                        drawings.DistanceShadow.Position = Vector2.new(feetPos.X + 2, feetPos.Y + 7)
                        drawings.DistanceShadow.Visible = true

                        drawings.Distance.Text = distance .. "m"
                        drawings.Distance.Color = distColor
                        drawings.Distance.Position = Vector2.new(feetPos.X, feetPos.Y + 5)
                        drawings.Distance.Visible = true
                    else
                        drawings.DistanceShadow.Visible = false
                        drawings.Distance.Visible = false
                    end

                    -- 💀 Skeleton ESP
                    if ESPModule.Settings.Skeleton.Enabled then
                        local torso_upper = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                        local torso_lower = char:FindFirstChild("LowerTorso") or torso_upper
                        local leftupperarm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
                        local leftlowerarm = char:FindFirstChild("LeftLowerArm")
                        local lefthand = char:FindFirstChild("LeftHand")
                        local rightupperarm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
                        local rightlowerarm = char:FindFirstChild("RightLowerArm")
                        local righthand = char:FindFirstChild("RightHand")
                        local leftupperleg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
                        local leftlowerleg = char:FindFirstChild("LeftLowerLeg")
                        local leftfoot = char:FindFirstChild("LeftFoot")
                        local rightupperleg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
                        local rightlowerleg = char:FindFirstChild("RightLowerLeg")
                        local rightfoot = char:FindFirstChild("RightFoot")

                        if torso_upper and torso_lower then
                            local head2d, headOn = to2d(head)
                            local torsoU2d, torsoUOn = to2d(torso_upper)
                            local torsoL2d, torsoLOn = to2d(torso_lower)

                            if headOn and torsoUOn then
                                drawings.skel_head.From = head2d
                                drawings.skel_head.To = torsoU2d
                                drawings.skel_head.Color = skelColor
                                drawings.skel_head.Visible = true

                                if torsoLOn then
                                    drawings.skel_torso.From = torsoU2d
                                    drawings.skel_torso.To = torsoL2d
                                    drawings.skel_torso.Color = skelColor
                                    drawings.skel_torso.Visible = true
                                else
                                    drawings.skel_torso.Visible = false
                                end

                                -- Left Arm
                                if leftupperarm then
                                    local lUpperArm2d, lUpperArmOn = to2d(leftupperarm)
                                    if lUpperArmOn then
                                        drawings.skel_leftarm.From = torsoU2d
                                        drawings.skel_leftarm.To = lUpperArm2d
                                        drawings.skel_leftarm.Color = skelColor
                                        drawings.skel_leftarm.Visible = true

                                        if leftlowerarm then
                                            local lLowerArm2d, lLowerArmOn = to2d(leftlowerarm)
                                            if lLowerArmOn then
                                                drawings.skel_leftforearm.From = lUpperArm2d
                                                drawings.skel_leftforearm.To = lLowerArm2d
                                                drawings.skel_leftforearm.Color = skelColor
                                                drawings.skel_leftforearm.Visible = true

                                                if lefthand then
                                                    local lHand2d, lHandOn = to2d(lefthand)
                                                    if lHandOn then
                                                        drawings.skel_lefthand.From = lLowerArm2d
                                                        drawings.skel_lefthand.To = lHand2d
                                                        drawings.skel_lefthand.Color = skelColor
                                                        drawings.skel_lefthand.Visible = true
                                                    else
                                                        drawings.skel_lefthand.Visible = false
                                                    end
                                                end
                                            else
                                                drawings.skel_leftforearm.Visible = false
                                                drawings.skel_lefthand.Visible = false
                                            end
                                        end
                                    else
                                        drawings.skel_leftarm.Visible = false
                                        drawings.skel_leftforearm.Visible = false
                                        drawings.skel_lefthand.Visible = false
                                    end
                                end

                                -- Right Arm
                                if rightupperarm then
                                    local rUpperArm2d, rUpperArmOn = to2d(rightupperarm)
                                    if rUpperArmOn then
                                        drawings.skel_rightarm.From = torsoU2d
                                        drawings.skel_rightarm.To = rUpperArm2d
                                        drawings.skel_rightarm.Color = skelColor
                                        drawings.skel_rightarm.Visible = true

                                        if rightlowerarm then
                                            local rLowerArm2d, rLowerArmOn = to2d(rightlowerarm)
                                            if rLowerArmOn then
                                                drawings.skel_rightforearm.From = rUpperArm2d
                                                drawings.skel_rightforearm.To = rLowerArm2d
                                                drawings.skel_rightforearm.Color = skelColor
                                                drawings.skel_rightforearm.Visible = true

                                                if righthand then
                                                    local rHand2d, rHandOn = to2d(righthand)
                                                    if rHandOn then
                                                        drawings.skel_righthand.From = rLowerArm2d
                                                        drawings.skel_righthand.To = rHand2d
                                                        drawings.skel_righthand.Color = skelColor
                                                        drawings.skel_righthand.Visible = true
                                                    else
                                                        drawings.skel_righthand.Visible = false
                                                    end
                                                end
                                            else
                                                drawings.skel_rightforearm.Visible = false
                                                drawings.skel_righthand.Visible = false
                                            end
                                        end
                                    else
                                        drawings.skel_rightarm.Visible = false
                                        drawings.skel_rightforearm.Visible = false
                                        drawings.skel_righthand.Visible = false
                                    end
                                end

                                -- Left Leg
                                if leftupperleg and torsoLOn then
                                    local lUpperLeg2d, lUpperLegOn = to2d(leftupperleg)
                                    if lUpperLegOn then
                                        drawings.skel_leftleg.From = torsoL2d
                                        drawings.skel_leftleg.To = lUpperLeg2d
                                        drawings.skel_leftleg.Color = skelColor
                                        drawings.skel_leftleg.Visible = true

                                        if leftlowerleg then
                                            local lLowerLeg2d, lLowerLegOn = to2d(leftlowerleg)
                                            if lLowerLegOn then
                                                drawings.skel_leftshin.From = lUpperLeg2d
                                                drawings.skel_leftshin.To = lLowerLeg2d
                                                drawings.skel_leftshin.Color = skelColor
                                                drawings.skel_leftshin.Visible = true

                                                if leftfoot then
                                                    local lFoot2d, lFootOn = to2d(leftfoot)
                                                    if lFootOn then
                                                        drawings.skel_leftfoot.From = lLowerLeg2d
                                                        drawings.skel_leftfoot.To = lFoot2d
                                                        drawings.skel_leftfoot.Color = skelColor
                                                        drawings.skel_leftfoot.Visible = true
                                                    else
                                                        drawings.skel_leftfoot.Visible = false
                                                    end
                                                end
                                            else
                                                drawings.skel_leftshin.Visible = false
                                                drawings.skel_leftfoot.Visible = false
                                            end
                                        end
                                    else
                                        drawings.skel_leftleg.Visible = false
                                        drawings.skel_leftshin.Visible = false
                                        drawings.skel_leftfoot.Visible = false
                                    end
                                end

                                -- Right Leg
                                if rightupperleg and torsoLOn then
                                    local rUpperLeg2d, rUpperLegOn = to2d(rightupperleg)
                                    if rUpperLegOn then
                                        drawings.skel_rightleg.From = torsoL2d
                                        drawings.skel_rightleg.To = rUpperLeg2d
                                        drawings.skel_rightleg.Color = skelColor
                                        drawings.skel_rightleg.Visible = true

                                        if rightlowerleg then
                                            local rLowerLeg2d, rLowerLegOn = to2d(rightlowerleg)
                                            if rLowerLegOn then
                                                drawings.skel_rightshin.From = rUpperLeg2d
                                                drawings.skel_rightshin.To = rLowerLeg2d
                                                drawings.skel_rightshin.Color = skelColor
                                                drawings.skel_rightshin.Visible = true

                                                if rightfoot then
                                                    local rFoot2d, rFootOn = to2d(rightfoot)
                                                    if rFootOn then
                                                        drawings.skel_rightfoot.From = rLowerLeg2d
                                                        drawings.skel_rightfoot.To = rFoot2d
                                                        drawings.skel_rightfoot.Color = skelColor
                                                        drawings.skel_rightfoot.Visible = true
                                                    else
                                                        drawings.skel_rightfoot.Visible = false
                                                    end
                                                end
                                            else
                                                drawings.skel_rightshin.Visible = false
                                                drawings.skel_rightfoot.Visible = false
                                            end
                                        end
                                    else
                                        drawings.skel_rightleg.Visible = false
                                        drawings.skel_rightshin.Visible = false
                                        drawings.skel_rightfoot.Visible = false
                                    end
                                end
                            else
                                -- ซ่อนทั้งหมดถ้า head หรือ torso นอกจอ
                                drawings.skel_head.Visible = false
                                drawings.skel_torso.Visible = false
                                drawings.skel_leftarm.Visible = false
                                drawings.skel_leftforearm.Visible = false
                                drawings.skel_lefthand.Visible = false
                                drawings.skel_rightarm.Visible = false
                                drawings.skel_rightforearm.Visible = false
                                drawings.skel_righthand.Visible = false
                                drawings.skel_leftleg.Visible = false
                                drawings.skel_leftshin.Visible = false
                                drawings.skel_leftfoot.Visible = false
                                drawings.skel_rightleg.Visible = false
                                drawings.skel_rightshin.Visible = false
                                drawings.skel_rightfoot.Visible = false
                            end
                        end
                    else
                        -- ซ่อน Skeleton ถ้าปิด
                        local skelParts = {
                            drawings.skel_head,
                            drawings.skel_torso,
                            drawings.skel_leftarm,
                            drawings.skel_leftforearm,
                            drawings.skel_lefthand,
                            drawings.skel_rightarm,
                            drawings.skel_rightforearm,
                            drawings.skel_righthand,
                            drawings.skel_leftleg,
                            drawings.skel_leftshin,
                            drawings.skel_leftfoot,
                            drawings.skel_rightleg,
                            drawings.skel_rightshin,
                            drawings.skel_rightfoot
                        }
                        for _, d in pairs(skelParts) do
                            d.Visible = false
                        end
                    end
                end
            end

            if not shouldProcess then
                for _, line in pairs(drawings.BoxLines) do
                    line.Visible = false
                end
                drawings.NameShadow.Visible = false
                drawings.Name.Visible = false
                drawings.Tracer.Visible = false
                drawings.DistanceShadow.Visible = false
                drawings.Distance.Visible = false

                local skelParts = {
                    drawings.skel_head,
                    drawings.skel_torso,
                    drawings.skel_leftarm,
                    drawings.skel_leftforearm,
                    drawings.skel_lefthand,
                    drawings.skel_rightarm,
                    drawings.skel_rightforearm,
                    drawings.skel_righthand,
                    drawings.skel_leftleg,
                    drawings.skel_leftshin,
                    drawings.skel_leftfoot,
                    drawings.skel_rightleg,
                    drawings.skel_rightshin,
                    drawings.skel_rightfoot
                }
                for _, d in pairs(skelParts) do
                    d.Visible = false
                end
            end
        end
    end
)

-- สร้าง Drawings ให้ player ทุกคน
for _, plr in pairs(game.Players:GetPlayers()) do
    if plr ~= game.Players.LocalPlayer then
        ESPModule.CreateDrawings(plr)
    end
end

game.Players.PlayerAdded:Connect(ESPModule.CreateDrawings)
game.Players.PlayerRemoving:Connect(
    function(plr)
        if ESPModule.drawings[plr] then
            for _, line in pairs(ESPModule.drawings[plr].BoxLines) do
                line:Remove()
            end
            for _, d in pairs(ESPModule.drawings[plr]) do
                if d.Remove then
                    d:Remove()
                end
            end
            ESPModule.drawings[plr] = nil
        end
    end
)

VisualTab:Toggle(
    {
        Title = "Inventory Viewer",
		Flag = "inventoryviewer",
        Icon = "check",
        Type = "Checkbox",
        Default = true,
        Callback = function(Value)
            _G.InventoryViewerEnabled = Value
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local Client = Players.LocalPlayer

            local function GetColorFromRarity(rarityName)
                local colors = {
                    ["Common"] = Color3.fromRGB(255, 255, 255),
                    ["UnCommon"] = Color3.fromRGB(99, 255, 52),
                    ["Rare"] = Color3.fromRGB(51, 170, 255),
                    ["Legendary"] = Color3.fromRGB(255, 150, 0),
                    ["Epic"] = Color3.fromRGB(237, 44, 255),
                    ["Omega"] = Color3.fromRGB(255, 20, 51)
                }
                return colors[rarityName] or Color3.fromRGB(255, 255, 255)
            end

            if Value then
                if not _G.ViewerRunning then
                    _G.ViewerRunning = true
                    task.spawn(
                        function()
                            while task.wait(0.2) do
                                if _G.InventoryViewerEnabled then
                                    pcall(
                                        function()
                                            for _, v in pairs(Players:GetPlayers()) do
                                                if
                                                    v ~= Client and v.Character and
                                                        v.Character:FindFirstChild("HumanoidRootPart")
                                                 then
                                                    local root = v.Character.HumanoidRootPart
                                                    local gui = root:FindFirstChild("ItemBillboard")

                                                    if not gui then
                                                        gui = Instance.new("BillboardGui")
                                                        gui.Name = "ItemBillboard"
                                                        gui.AlwaysOnTop = true
                                                        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                                                        gui.Size = UDim2.new(0, 300, 0, 80)
                                                        gui.StudsOffset = Vector3.new(0, -5, 0)
                                                        gui.ExtentsOffset = Vector3.new(0, 1, 0)
                                                        gui.LightInfluence = 1
                                                        gui.Parent = root

                                                        local bg = Instance.new("Frame")
                                                        bg.Name = "BG"
                                                        bg.BackgroundTransparency = 1
                                                        bg.Size = UDim2.new(1, 0, 1, 0)
                                                        bg.AnchorPoint = Vector2.new(0.5, 0.5)
                                                        bg.Position = UDim2.new(0.5, 0, 0.5, 0)
                                                        bg.Parent = gui

                                                        local layout = Instance.new("UIListLayout")
                                                        layout.FillDirection = Enum.FillDirection.Horizontal
                                                        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                                                        layout.VerticalAlignment = Enum.VerticalAlignment.Center
                                                        layout.Padding = UDim.new(0, 8)
                                                        layout.Parent = bg
                                                    end

                                                    local bg = gui:FindFirstChild("BG")
                                                    if bg then
                                                        local Items = {}

                                                        for _, child in pairs(bg:GetChildren()) do
                                                            if child:IsA("Frame") then
                                                                child:Destroy()
                                                            end
                                                        end

                                                        for _, container in pairs(
                                                            {
                                                                v:FindFirstChild("Backpack"),
                                                                v.Character
                                                            }
                                                        ) do
                                                            if container then
                                                                for _, tool in pairs(container:GetChildren()) do
                                                                    if
                                                                        tool:IsA("Tool") and
                                                                            not tool:GetAttribute("JobTool") and
                                                                            not tool:GetAttribute("Locked")
                                                                     then
                                                                        local itemFolder =
                                                                            tool:GetAttribute("AmmoType") and
                                                                            ReplicatedStorage.Items.gun or
                                                                            ReplicatedStorage.Items.melee
                                                                        for _, z in pairs(itemFolder:GetChildren()) do
                                                                            if
                                                                                tool:GetAttribute("RarityName") ==
                                                                                    z:GetAttribute("RarityName") and
                                                                                    tool:GetAttribute("RarityPrice") ==
                                                                                        z:GetAttribute("RarityPrice")
                                                                             then
                                                                                local imageId =
                                                                                    z:GetAttribute("ImageId")
                                                                                if imageId then
                                                                                    Items[z.Name] = true
                                                                                    if
                                                                                        not bg:FindFirstChild(
                                                                                            z.Name .. "_bg"
                                                                                        )
                                                                                     then
                                                                                        local itemContainer =
                                                                                            Instance.new("Frame")
                                                                                        itemContainer.Name =
                                                                                            z.Name .. "_bg"
                                                                                        itemContainer.Size =
                                                                                            UDim2.new(0, 50, 0, 70)
                                                                                        itemContainer.BackgroundTransparency =
                                                                                            1
                                                                                        itemContainer.BorderSizePixel =
                                                                                            0
                                                                                        itemContainer.Parent = bg

                                                                                        local iconBg =
                                                                                            Instance.new("Frame")
                                                                                        iconBg.Name = "IconBg"
                                                                                        iconBg.Size =
                                                                                            UDim2.new(0, 50, 0, 50)
                                                                                        iconBg.Position =
                                                                                            UDim2.new(0, 0, 0, 0)
                                                                                        iconBg.BackgroundColor3 =
                                                                                            GetColorFromRarity(
                                                                                            z:GetAttribute("RarityName")
                                                                                        )
                                                                                        iconBg.BackgroundTransparency =
                                                                                            1
                                                                                        iconBg.BorderSizePixel = 0
                                                                                        iconBg.Parent = itemContainer

                                                                                        local bgImage =
                                                                                            Instance.new("ImageLabel")
                                                                                        bgImage.Name = "Background"
                                                                                        bgImage.Size =
                                                                                            UDim2.new(1, 0, 1, 0)
                                                                                        bgImage.BackgroundTransparency =
                                                                                            1
                                                                                        bgImage.Image =
                                                                                            "rbxassetid://137066731814190"
                                                                                        bgImage.ImageColor3 =
                                                                                            GetColorFromRarity(
                                                                                            z:GetAttribute("RarityName")
                                                                                        )
                                                                                        bgImage.ZIndex = 0
                                                                                        bgImage.Parent = iconBg

                                                                                        local corner =
                                                                                            Instance.new("UICorner")
                                                                                        corner.CornerRadius =
                                                                                            UDim.new(0.15, 0)
                                                                                        corner.Parent = iconBg

                                                                                        local icon =
                                                                                            Instance.new("ImageLabel")
                                                                                        icon.Name = z.Name
                                                                                        icon.Image = imageId
                                                                                        icon.BackgroundTransparency = 1
                                                                                        icon.BorderSizePixel = 0
                                                                                        icon.Size =
                                                                                            UDim2.new(0.85, 0, 0.85, 0)
                                                                                        icon.Position =
                                                                                            UDim2.new(
                                                                                            0.075,
                                                                                            0,
                                                                                            0.075,
                                                                                            0
                                                                                        )
                                                                                        icon.Parent = iconBg

                                                                                        local corner2 =
                                                                                            Instance.new("UICorner")
                                                                                        corner2.CornerRadius =
                                                                                            UDim.new(0, 9)
                                                                                        corner2.Parent = icon

                                                                                        local nameLabel =
                                                                                            Instance.new("TextLabel")
                                                                                        nameLabel.Name = "WeaponName"
                                                                                        nameLabel.Size =
                                                                                            UDim2.new(1, 0, 0, 20)
                                                                                        nameLabel.Position =
                                                                                            UDim2.new(0, 0, 0, 52)
                                                                                        nameLabel.BackgroundTransparency =
                                                                                            1
                                                                                        nameLabel.Text = z.Name
                                                                                        nameLabel.TextColor3 =
                                                                                            Color3.fromRGB(
                                                                                            255,
                                                                                            255,
                                                                                            255
                                                                                        )
                                                                                        nameLabel.TextStrokeTransparency =
                                                                                            0.5
                                                                                        nameLabel.TextStrokeColor3 =
                                                                                            Color3.fromRGB(0, 0, 0)
                                                                                        nameLabel.TextScaled = true
                                                                                        nameLabel.Font =
                                                                                            Enum.Font.GothamBold
                                                                                        nameLabel.Parent = itemContainer

                                                                                        local textSizeConstraint =
                                                                                            Instance.new(
                                                                                            "UITextSizeConstraint"
                                                                                        )
                                                                                        textSizeConstraint.MaxTextSize =
                                                                                            10
                                                                                        textSizeConstraint.Parent =
                                                                                            nameLabel
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end

                                                        gui.Enabled = _G.InventoryViewerEnabled
                                                        for _, child in pairs(bg:GetChildren()) do
                                                            if child:IsA("Frame") then
                                                                local itemName = child.Name:gsub("_bg$", "")
                                                                if not Items[itemName] then
                                                                    child:Destroy()
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    )
                                end
                            end
                        end
                    )
                end
            else
                for _, v in pairs(Players:GetPlayers()) do
                    if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                        local gui = v.Character.HumanoidRootPart:FindFirstChild("ItemBillboard")
                        if gui then
                            gui:Destroy()
                        end
                    end
                end
            end
        end
    }
)

local item_drawings = {}
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- สร้าง ScreenGui สำหรับแสดงรูป
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DropItemViewerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

VisualTab:Toggle(
    {
        Title = "Drop Item Viewer",
        Flag = "dropitem_viewer",
        Icon = "check",
        Type = "Checkbox",
        Default = true,
        Callback = function(state)
            c().EnabledItemDrop = state
        end
    }
)

-- ฟังก์ชันหา Image ID จาก ReplicatedStorage
local function getItemImageId(itemName)
    -- ถ้าเป็น Money ให้ใช้ MoneyViewport
    if itemName == "Money" then
        local success, moneyModel = pcall(function()
            return LocalPlayer.PlayerGui.TopRightHud.Holder.Frame.Frame.MoneyViewport.MoneyModel
        end)
        
        if success and moneyModel then
            return moneyModel -- คืนค่า Model แทน ImageId
        end
    end
    
    local Items = ReplicatedStorage:FindFirstChild("Items")
    if not Items then
        return nil
    end
    
    -- ค้นหาใน folder ย่อยทั้งหมด
    for _, category in ipairs(Items:GetChildren()) do
        if category:IsA("Folder") then
            local itemData = category:FindFirstChild(itemName)
            if itemData then
                -- ลองหาจาก Attributes
                local imageId = itemData:GetAttribute("ImageId")
                if imageId then
                    return imageId
                end
                
                -- ลองหาจาก attributes อื่นๆ
                for _, attrName in ipairs({"Image", "Icon", "TextureId", "Texture"}) do
                    local attr = itemData:GetAttribute(attrName)
                    if attr then
                        return attr
                    end
                end
            end
        end
    end
    
    return nil
end

-- ฟังก์ชันแปลง Image ID ให้ถูกต้อง (ไม่ต้องแปลงเพราะมันเป็น rbxassetid:// อยู่แล้ว)
local function formatImageId(imageId)
    if not imageId or imageId == "" then
        return nil
    end
    return imageId
end

RunService.RenderStepped:Connect(
    function()
        if not c().EnabledItemDrop then
            for _, d in pairs(item_drawings) do
                if d.shadowFrame then
                    d.shadowFrame.Visible = false
                end
                if d.imageFrame then
                    d.imageFrame.Visible = false
                end
                if d.nameShadow then
                    d.nameShadow.Visible = false
                end
                if d.name then
                    d.name.Visible = false
                end
                if d.distShadow then
                    d.distShadow.Visible = false
                end
                if d.dist then
                    d.dist.Visible = false
                end
            end
            return
        end

        local Dropped = workspace:FindFirstChild("DroppedItems")
        if not Dropped then
            return
        end

        -- ล้างของที่หายไป
        for item, d in pairs(item_drawings) do
            if not item or not item.Parent then
                if d.shadowFrame then
                    d.shadowFrame:Destroy()
                end
                if d.imageFrame then
                    d.imageFrame:Destroy()
                end
                if d.nameShadow then
                    d.nameShadow:Remove()
                end
                if d.name then
                    d.name:Remove()
                end
                if d.distShadow then
                    d.distShadow:Remove()
                end
                if d.dist then
                    d.dist:Remove()
                end
                item_drawings[item] = nil
            end
        end

        -- เก็บ item ใกล้
        local nearbyItems = {}
        for _, item in ipairs(Dropped:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChild("PickUpZone") and not item:GetAttribute("Locked") then
                local dist = (CurrentCamera.CFrame.Position - item.PickUpZone.Position).Magnitude
                table.insert(nearbyItems, {item = item, dist = dist})
            end
        end

        -- เรียงใกล้ → ไกล
        table.sort(
            nearbyItems,
            function(a, b)
                return a.dist < b.dist
            end
        )

        -- ขนาดรูป
        local IMAGE_SIZE = 60

        -- แสดงสูงสุด 20 อัน
        for i = 1, math.min(20, #nearbyItems) do
            local item = nearbyItems[i].item
            local d = item_drawings[item]

            if not d then
                d = {
                    nameShadow = Drawing.new("Text"),
                    name = Drawing.new("Text"),
                    distShadow = Drawing.new("Text"),
                    dist = Drawing.new("Text")
                }

                -- สร้าง Shadow Frame
                local shadowFrame = Instance.new("Frame")
                shadowFrame.Name = "ShadowFrame"
                shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                shadowFrame.BackgroundTransparency = 0.5
                shadowFrame.Size = UDim2.new(0, IMAGE_SIZE + 8, 0, IMAGE_SIZE + 8)
                shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                shadowFrame.BorderSizePixel = 0
                shadowFrame.Parent = screenGui
                
                local shadowCorner = Instance.new("UICorner")
                shadowCorner.CornerRadius = UDim.new(0, 10)
                shadowCorner.Parent = shadowFrame
                
                d.shadowFrame = shadowFrame

                -- สร้าง ImageLabel สำหรับแสดงรูป
                local imageFrame = Instance.new("ImageLabel")
                imageFrame.Name = "ItemImage_" .. item.Name
                imageFrame.BackgroundTransparency = 1
                imageFrame.Size = UDim2.new(0, IMAGE_SIZE, 0, IMAGE_SIZE)
                imageFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                imageFrame.ScaleType = Enum.ScaleType.Fit
                imageFrame.Parent = screenGui
                
                -- โหลดรูป
                local rawImageId = getItemImageId(item.Name)
                
                -- ถ้าเป็น Money และได้ Model มา ให้ใช้ ViewportFrame
                if item.Name == "Money" and typeof(rawImageId) == "Instance" and rawImageId:IsA("Model") then
                    imageFrame:Destroy()
                    
                    -- สร้าง ViewportFrame แทน
                    local viewportFrame = Instance.new("ViewportFrame")
                    viewportFrame.Name = "MoneyViewport_" .. item.Name
                    viewportFrame.BackgroundTransparency = 1
                    viewportFrame.Size = UDim2.new(0, IMAGE_SIZE, 0, IMAGE_SIZE)
                    viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                    viewportFrame.Parent = screenGui
                    
                    -- Clone Money Model
                    local moneyClone = rawImageId:Clone()
                    moneyClone.Parent = viewportFrame
                    
                    -- สร้างกล้องสำหรับ Viewport
                    local camera = Instance.new("Camera")
                    camera.Parent = viewportFrame
                    viewportFrame.CurrentCamera = camera
                    
                    -- ตั้งตำแหน่งกล้อง
                    local modelCF = moneyClone:GetBoundingBox()
                    camera.CFrame = modelCF * CFrame.new(0, 0, 3)
                    camera.Focus = modelCF
                    
                    imageFrame = viewportFrame
                else
                    -- ใช้รูปปกติ
                    local imageId = formatImageId(rawImageId)
                    if imageId then
                        imageFrame.Image = imageId
                    else
                        -- ถ้าไม่มีรูป ใช้สีพื้นหลังแทน
                        imageFrame.BackgroundTransparency = 0.3
                        imageFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 8)
                        corner.Parent = imageFrame
                    end
                end
                
                d.imageFrame = imageFrame

                -- Shadow สำหรับชื่อ
                d.nameShadow.Color = Color3.new(0, 0, 0)
                d.nameShadow.Transparency = 0.5
                d.nameShadow.Outline = false
                d.nameShadow.Center = true
                d.nameShadow.Size = 16
                d.nameShadow.Font = 2

                -- ชื่อหลัก
                d.name.Color = Color3.new(1, 1, 1)
                d.name.Outline = true
                d.name.Center = true
                d.name.Size = 16
                d.name.Font = 2

                -- Shadow สำหรับจำนวน
                d.distShadow.Color = Color3.new(0, 0, 0)
                d.distShadow.Transparency = 0.5
                d.distShadow.Outline = false
                d.distShadow.Center = true
                d.distShadow.Size = 14
                d.distShadow.Font = 2

                -- จำนวนหลัก
                d.dist.Color = Color3.new(1, 1, 1)
                d.dist.Outline = true
                d.dist.Center = true
                d.dist.Size = 14
                d.dist.Font = 2

                item_drawings[item] = d
            end

            -- อัพเดทตำแหน่ง
            local pos, onScreen = CurrentCamera:WorldToViewportPoint(item.PickUpZone.Position)

            if onScreen then
                local halfSize = IMAGE_SIZE / 2

                -- คำนวณตำแหน่งกรอบจากศูนย์กลาง
                local centerX = pos.X
                local centerY = pos.Y

                -- สร้าง gradient effect สำหรับสีต่างๆ
                local time = tick() * 1.5
                local hue1 = (time % 6) / 6
                local hue3 = ((time + 3) % 6) / 6

                local color1 = Color3.fromHSV(hue1, 0.9, 1)
                local color3 = Color3.fromHSV(hue3, 0.7, 1)

                -- แสดง Shadow Frame (อยู่ข้างหลัง)
                d.shadowFrame.Position = UDim2.new(0, centerX + 3, 0, centerY + 3)
                d.shadowFrame.Visible = true

                -- แสดงรูป (อยู่ข้างหน้า)
                d.imageFrame.Position = UDim2.new(0, centerX, 0, centerY)
                d.imageFrame.Visible = true

                -- ชื่อไอเทม (มี shadow)
                local nameY = centerY - halfSize - 25

                d.nameShadow.Text = item.Name
                d.nameShadow.Position = Vector2.new(centerX + 2, nameY + 2)
                d.nameShadow.Visible = true

                d.name.Text = item.Name
                d.name.Color = Color3.fromHSV(hue1, 0.6, 1)
                d.name.Position = Vector2.new(centerX, nameY)
                d.name.Visible = true

                -- จำนวน (มี shadow)
                local amount = item:FindFirstChild("AmountBillboardGui")
                amount = amount and amount:FindFirstChild("TextLabel") and amount.TextLabel.Text or "?"
                local amountText = "[ " .. amount .. " ]"

                local distY = centerY + halfSize + 10

                -- Shadow
                d.distShadow.Text = amountText
                d.distShadow.Position = Vector2.new(centerX + 2, distY + 2)
                d.distShadow.Visible = true

                -- Text หลัก
                d.dist.Text = amountText
                d.dist.Color = color3
                d.dist.Position = Vector2.new(centerX, distY)
                d.dist.Visible = true
            else
                if d.shadowFrame then
                    d.shadowFrame.Visible = false
                end
                if d.imageFrame then
                    d.imageFrame.Visible = false
                end
                d.nameShadow.Visible = false
                d.name.Visible = false
                d.distShadow.Visible = false
                d.dist.Visible = false
            end
        end
    end
)

local MiscTab =
    Window:Tab(
    {
        Title = "Misc",
        Icon = "circle-ellipsis"
    }
)

local EnabledSkip = false

-- ปุ่ม Toggle
MiscTab:Toggle({
    Title = "Skip Animation",
    Flag = "skip_anim",
    Icon = "check",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        EnabledSkip = Value

        -- ถ้าเปิดใช้งานทันที ให้ skip ทุก crate ที่กำลัง spin หรือจะ spin ใหม่
        if EnabledSkip then
            task.spawn(function()
                while EnabledSkip do
                    -- ตรวจสอบทุก crate ที่มีอยู่
                    for _, crate in pairs(CrateController.class.objects) do
                        -- ตั้งให้ skip 100%
                        crate.states.open.set(true)       -- บังคับ crate เปิด
                        CrateController.skipping.set(true) -- บังคับ skip
                    end
                    task.wait(0.05) -- เช็คต่อเนื่อง
                end
            end)
        end
    end
})

-- ถ้าอยากใช้ loop แบบเดิมก็ได้ แต่ไม่จำเป็น เพราะเรา spawn loop ภายใน callback แล้ว


MiscTab:Toggle({
    Title = "Infinite Hotbar",
    Flag = "infhotbar",
    Icon = "check",
    Type = "Checkbox",

    Callback = function(Value)
        if not Value then
            return
        end
        
        -- 🔍 ค้นหาและ Hook ฟังก์ชัน get_max_items
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" then
                local info = debug.getinfo(v)

                if info.name == "get_max_items" then

                    hookfunction(v, function(...)
                    return 999
                    end)

                end
            end
        end
    end
})

local GraphicsTab =
    Window:Tab(
    {
        Title = "Graphic",
        Icon = "monitor" -- optional
    }
)

GraphicsTab:Button(
    {
        Title = "BoostFps",
        Desc = "SuperVeryUltraLowPotato Graphic",
        Icon = "rocket",
        Locked = false,
        Callback = function()
            loadstring(game:HttpGet("https://pastefy.app/Pmu7jqMe/raw"))()
        end
    }
)

-- ตัวแปรเก็บสถานะ WhiteScreen
local WhiteScreenEnabled = false

GraphicsTab:Toggle(
    {
        Title = "White Screen",
        Flag = "white_screen",
        Desc = "<<<3",
        Locked = false,
        Callback = function(Value)
            WhiteScreenEnabled = Value -- เก็บสถานะ toggle
            local RunService = game:GetService("RunService")

            -- เปิด/ปิด rendering ตามสถานะ toggle
            RunService:Set3dRenderingEnabled(not WhiteScreenEnabled)
        end
    }
)

--====================================================
-- 📜 Config TAB
--====================================================

local ConfigTab =
    Window:Tab(
    {
        Title = "Config",
        Icon = "settings"
    }
)

ConfigTab:Section(
    {
        Title = "Config Manager:"
    }
)

local ConfigManager = Window.ConfigManager
local ConfigName = ""

-- Input กรอกชื่อ Config
ConfigTab:Input(
    {
        Title = "Config Name",
        Placeholder = "Enter config name...",
        Callback = function(value)
            ConfigName = value
        end
    }
)

-- ปุ่ม Save
ConfigTab:Button(
    {
        Title = "Save Config",
        Icon = "save",
        Callback = function()
            if ConfigName ~= "" then
                local config = ConfigManager:CreateConfig(ConfigName)
                config:Save()
                WindUI:Notify(
                    {
                        Title = "Config Manager",
                        Content = "Saved: " .. ConfigName,
                        Duration = 2
                    }
                )
            else
                WindUI:Notify(
                    {
                        Title = "Config Manager",
                        Content = "Please enter config name!",
                        Duration = 2
                    }
                )
            end
        end
    }
)

-- ปุ่ม Load
ConfigTab:Button(
    {
        Title = "Load Config",
        Icon = "folder-open",
        Callback = function()
            if ConfigName ~= "" then
                local config = ConfigManager:CreateConfig(ConfigName)
                config:Load()
                WindUI:Notify(
                    {
                        Title = "Config Manager",
                        Content = "Loaded: " .. ConfigName,
                        Duration = 2
                    }
                )
            else
                WindUI:Notify(
                    {
                        Title = "Config Manager",
                        Content = "Please enter config name!",
                        Duration = 2
                    }
                )
            end
        end
    }
)

-- ปุ่ม Delete
ConfigTab:Button(
    {
        Title = "Delete Config",
        Icon = "trash-2",
        Callback = function()
            if ConfigName ~= "" then
                local config = ConfigManager:CreateConfig(ConfigName)
                config:Delete()
                WindUI:Notify(
                    {
                        Title = "Config Manager",
                        Content = "Deleted: " .. ConfigName,
                        Duration = 2
                    }
                )
            else
                WindUI:Notify(
                    {
                        Title = "Config Manager",
                        Content = "Please enter config name!",
                        Duration = 2
                    }
                )
            end
        end
    }
)

task.wait(0.1)
local RS = game:GetService("ReplicatedStorage")

pcall(function()
    local BuyPromptUI = require(RS.Modules.Game.UI.BuyPromptUI)
    
    if BuyPromptUI.loaded then
        local old_loaded = BuyPromptUI.loaded
        
        BuyPromptUI.loaded = function(...)
            -- เรียกฟังก์ชันเดิม
            local result = old_loaded(...)
            
            -- แก้เวลากดค้างหลังจาก UI โหลดเสร็จ
            task.spawn(function()
                task.wait(0.5) -- รอให้ UI setup เสร็จ
                
                local Util = require(RS.Modules.Core.Util)
                local UI = require(RS.Modules.Core.UI)
                local sellButton = UI.get("SellPromptSellButton")
                
                if sellButton and Util.tween then
                    
                    -- Hook ฟังก์ชัน tween ของ Util
                    local old_tween = Util.tween
                    Util.tween = function(instance, tweenInfo, properties, ...)
                        -- ถ้าเป็น tween ของปุ่ม sell/drop และเป็นการเปลี่ยน Value
                        if instance:IsA("NumberValue") and properties.Value == 1 then
                            -- เปลี่ยน duration จาก 0.5-2 วิ เป็น 0.1 วิ
                            if tweenInfo.Time > 0 then
                                tweenInfo = TweenInfo.new(
                                    0, -- เวลาใหม่
                                    tweenInfo.EasingStyle,
                                    tweenInfo.EasingDirection,
                                    tweenInfo.RepeatCount,
                                    tweenInfo.Reverses,
                                    tweenInfo.DelayTime
                                )
                            end
                        end
                        
                        return old_tween(instance, tweenInfo, properties, ...)
                    end
                    
                end
            end)
            
            return result
        end
        
    end
end)

-- วิธีสำรอง: Hook tween โดยตรง
pcall(function()
    local Util = require(RS.Modules.Core.Util)
    
    if Util.tween then
        local old_tween = Util.tween
        
        Util.tween = function(instance, tweenInfo, properties, ...)
            -- ตรวจจับ tween ของปุ่ม sell (NumberValue.Value -> 1)
            if instance:IsA("NumberValue") and properties.Value == 1 then
                -- ถ้าเวลามากกว่า 0.1 วิ ให้ลดเหลือ 0.1 วิ
                if tweenInfo.Time > 0.1 then
                    tweenInfo = TweenInfo.new(
                        0.1,
                        tweenInfo.EasingStyle,
                        tweenInfo.EasingDirection,
                        tweenInfo.RepeatCount,
                        tweenInfo.Reverses,
                        tweenInfo.DelayTime
                    )
                end
            end
            
            return old_tween(instance, tweenInfo, properties, ...)
        end
        
    end
end)
