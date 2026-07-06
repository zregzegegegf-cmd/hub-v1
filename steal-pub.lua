local UI_OPEN = true
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local isTablet = UIS.TouchEnabled and workspace.CurrentCamera.ViewportSize.X >= 768

local function getScaleFactor()
    local scale = math.clamp(workspace.CurrentCamera.ViewportSize.X / 1920, 0.5, 1.2)
    if isMobile and not isTablet then return math.clamp(scale * 0.85, 0.6, 0.9) end
    if isTablet then return math.clamp(scale * 1.0, 0.8, 1.1) end
    return scale
end
local Camera = workspace.CurrentCamera
local FriendsESPEnabled = false
local FriendsESPConnections = {}
local PlayerESPEnabled = false
local PlayerESPData = {}
local PlayerESPConnections = {}

-- =============================================
-- RE-EXECUTE CLEANUP: Disconnect old connections & stop old loops
-- =============================================
if _G.ZenoHubConnections then
    for _, conn in ipairs(_G.ZenoHubConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
_G.ZenoHubConnections = {}
_G.ZenoHubAlive = false -- signal old while loops to stop
task.wait() -- let old loops check the flag
_G.ZenoHubAlive = true

local function trackConnection(conn)
    table.insert(_G.ZenoHubConnections, conn)
    return conn
end

local function openAdminSpammerUI()
_G.AdminSpammerRunning = true
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- 🔥 REPLACE ALL CONFIG CODE WITH THIS (put at top, line ~100)

local function saveConfig()
    print("💾 SAVING FULL CONFIG | Anti-Ragdoll:", Config.toggles["anti_ragdoll"])
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
        print("✅ FULL CONFIG SAVED!")
    end)
end

local function loadConfig()
    print("📂 LOADING FULL CONFIG...")
    if isfile(CONFIG_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success then
            Config.toggles = data.toggles or { anti_ragdoll = false }  -- 🔥 ADDED
            Config.panels = data.panels or {}
            Config.sliders = data.sliders or {}
            Config.keybinds = data.keybinds or {}
            Config.spammer = data.spammer or {
                SemiKeybind = "F", FullKeybind = "Y", 
                ToggleUIKeybind = "F4", BalloonEnabled = false
            }
            print("✅ FULL CONFIG LOADED | Anti-Ragdoll:", Config.toggles["anti_ragdoll"])
            return true
        end
    end
    print("📄 Fresh config")
    return false
end

-- Load immediately
loadConfig()

local SemiKeybind = Enum.KeyCode[configData.SemiKeybind]
local FullKeybind = Enum.KeyCode[configData.FullKeybind]
local ToggleUIKeybind = Enum.KeyCode[configData.ToggleUIKeybind]
local BalloonEnabled = configData.BalloonEnabled

local waitingSemi = false
local waitingFull = false
local waitingToggleUI = false

local function getAdminFrames()
	local adminPanel = LocalPlayer.PlayerGui:FindFirstChild("AdminPanel")
	if not adminPanel then return end
	local panel = adminPanel:FindFirstChild("AdminPanel")
	if not panel then return end
	local content = panel:FindFirstChild("Content")
	local profiles = panel:FindFirstChild("Profiles")
	if not content or not profiles then return end
	return content:FindFirstChild("ScrollingFrame"), profiles:FindFirstChild("ScrollingFrame")
end

local function fireButton(guiObject)
	local ok, conns = pcall(getconnections, guiObject.Activated)
	if ok and type(conns) == "table" then
		for _, conn in ipairs(conns) do
			if type(conn.Function) == "function" then
				task.spawn(conn.Function)
			end
		end
	end
end

local function runCommandOnPlayer(commandName, target)
	local commandFrame, profileFrame = getAdminFrames()
	if not commandFrame or not profileFrame then return end

	local profileButton = profileFrame:FindFirstChild(target.Name)
	local commandButton = commandFrame:FindFirstChild(commandName)
	if not profileButton or not commandButton then return end

	fireButton(profileButton)
	task.wait(0.05)
	fireButton(commandButton)
	task.wait(0.05)
	fireButton(profileButton)
	task.wait(0.05)
	fireButton(commandButton)
end

pcall(function()
    LocalPlayer.PlayerGui:FindFirstChild("ZenoAdminPanel"):Destroy()
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "ZenoAdminPanel"
ScreenGui.DisplayOrder = 999999
-- =============================================
-- ZENO TOGGLE BUTTON (ON UI - TOP RIGHT)
-- =============================================
local ZenoToggleBtn = Instance.new("TextButton")
ZenoToggleBtn.Name = "ZenoToggle"
ZenoToggleBtn.Size = isMobile and UDim2.new(0, 80, 0, 32) or UDim2.new(0, 90, 0, 32)
ZenoToggleBtn.Position = UDim2.new(1, isMobile and -88 or -98, 0, 8)
ZenoToggleBtn.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
ZenoToggleBtn.BackgroundTransparency = 0.28  -- black with ~72% opacity = transparency
ZenoToggleBtn.Text = "Zeno ▼"
ZenoToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ZenoToggleBtn.Font = Enum.Font.GothamBold
ZenoToggleBtn.TextSize = isMobile and 13 or 15
ZenoToggleBtn.BorderSizePixel = 0
ZenoToggleBtn.ZIndex = 1001
ZenoToggleBtn.Parent = ScreenGui  -- keeps it anchored to main frame

local ZenoCorner = Instance.new("UICorner")
ZenoCorner.CornerRadius = UDim.new(1, 0)  -- 
ZenoCorner.Parent = ZenoToggleBtn

local ZenoStroke = Instance.new("UIStroke")
ZenoStroke.Color = Color3.fromRGB(204, 17, 17)  -- red border
ZenoStroke.Thickness = 2
ZenoStroke.Parent = ZenoToggleBtn

-- Hover
ZenoToggleBtn.MouseEnter:Connect(function()
    TweenService:Create(ZenoToggleBtn, TweenInfo.new(0.18), {
        BackgroundTransparency = 0.15,
    }):Play()
end)
ZenoToggleBtn.MouseLeave:Connect(function()
    TweenService:Create(ZenoToggleBtn, TweenInfo.new(0.18), {
        BackgroundTransparency = 0.28,
    }):Play()
end)

-- Toggle
ZenoToggleBtn.MouseButton1Click:Connect(function()
    UI_OPEN = not UI_OPEN
    if UI_OPEN then
        MainFrame.Visible = true
        uiScale.Scale = 0.3
        TweenService:Create(uiScale, TweenInfo.new(0.35), {Scale = 1}):Play()
        ZenoToggleBtn.Text = "Zeno ▼"
    else
        TweenService:Create(uiScale, TweenInfo.new(0.25), {Scale = 0.3}):Play()
        task.delay(0.25, function() MainFrame.Visible = false end)
        ZenoToggleBtn.Text = "Zeno ▲"
    end
end)

-- Mobile touch
ZenoToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        UI_OPEN = not UI_OPEN
        if UI_OPEN then
            MainFrame.Visible = true
            uiScale.Scale = 0.3
            TweenService:Create(uiScale, TweenInfo.new(0.35), {Scale = 1}):Play()
            ZenoToggleBtn.Text = "Zeno ▼"
        else
            TweenService:Create(uiScale, TweenInfo.new(0.25), {Scale = 0.3}):Play()
            task.delay(0.25, function() MainFrame.Visible = false end)
            ZenoToggleBtn.Text = "Zeno ▲"
        end
    end
end)


-- Mobile responsive sizing
local frameWidth = isMobile and 230 or 300
local frameHeight = isMobile and 290 or 380

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, frameWidth, 0, frameHeight)
Main.Position = UDim2.new(0.5, -frameWidth/2, 0.5, -frameHeight/2)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(18,18,18)
Main.BackgroundTransparency = 0.08
Main.Active = true
Main.Parent = ScreenGui
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,8)

local Stroke = Instance.new("UIStroke",Main)
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 1.8
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local Top = Instance.new("Frame",Main)
Top.Size = UDim2.new(1,0,0,38)
Top.BackgroundColor3 = Color3.fromRGB(22,22,22)
Instance.new("UICorner",Top).CornerRadius = UDim.new(0,8)

-- Mobile drag handle
local DragHandle = Instance.new("TextButton")
DragHandle.Parent = Top
DragHandle.Size = UDim2.new(0,22,0,22)
DragHandle.Position = UDim2.new(0,6,0.5,-11)
DragHandle.BackgroundTransparency = 1
DragHandle.Text = "⋮⋮"
DragHandle.Font = Enum.Font.GothamBold
DragHandle.TextSize = 12
DragHandle.TextColor3 = Color3.fromRGB(150,150,150)
DragHandle.TextXAlignment = Enum.TextXAlignment.Center

local Title = Instance.new("TextLabel",Top)
Title.Size = UDim2.new(1,-55,1,0)
Title.Position = UDim2.new(0,8,0,0)
Title.BackgroundTransparency = 1
Title.Text = "ZENO SPAMMER"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = isMobile and 12 or 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local Minimize = Instance.new("TextButton",Top)
Minimize.Size = UDim2.new(0,24,0,24)
Minimize.Position = UDim2.new(1,-30,0.5,-12)
Minimize.BackgroundColor3 = Color3.fromRGB(40,40,40)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1,1,1)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 14
Instance.new("UICorner",Minimize)

local ToggleUI = Instance.new("TextButton", Top)
ToggleUI.Size = UDim2.new(0, 95, 0, 24)
ToggleUI.Position = UDim2.new(1, -135, 0.5, -12)
ToggleUI.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleUI.Text = "TOGGLE: " .. configData.ToggleUIKeybind
ToggleUI.TextColor3 = Color3.new(1, 1, 1)
ToggleUI.Font = Enum.Font.GothamBold
ToggleUI.TextSiz
