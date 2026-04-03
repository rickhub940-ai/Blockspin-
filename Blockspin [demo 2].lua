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













local MainTab = Window:Tab({Title = "MAIN", Icon = "user"})
