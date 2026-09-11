--[[
    ================================================
     AURORA UI  —  Lightweight Roblox Interface Library
    ================================================
    Single-file, self-contained. Drop into any executor/script.

    -- [ESP PREVIEW] --
    Attached ESP Preview window on the right of the menu.
    Auto-follows the menu, independently draggable, and hides
    with the menu. Matches the Aurora theme.

    -- [ULTIMATE] --
    Undercover Ultimate feature set built on Aurora components.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ================= CONFIG =================
local CONFIG = {
    Title           = "UNDERCOVER",
    SubTitle        = "ULTIMATE v1.2",
    ToggleKey       = Enum.KeyCode.RightShift,
    AccentColor     = Color3.fromRGB(132, 97, 255),
    AccentColorAlt  = Color3.fromRGB(255, 215, 0),
    WindowSize      = Vector2.new(700, 394),
    StarCountMain   = 90,
    StarCountSide   = 42,
    StarGlowRadius  = 95,
    SnowCount       = 46,

    -- [ESP PREVIEW]
    PreviewWidth    = 200,
    PreviewGap      = 12,
    PreviewEnabled  = true,
    PreviewOnTab    = "Visuals",
}

-- ================= SERVICES =================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local Camera            = workspace.CurrentCamera
local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer:GetMouse()

local HAS_MOUSEMOVEREL  = pcall(function() return mousemoverel end)
local HAS_MOUSE1CLICK   = pcall(function() return mouse1click end)

pcall(function() CoreGui:FindFirstChild("AuroraUI"):Destroy() end)
pcall(function() CoreGui.UndercoverSlotted:Destroy() end)

-- ================= COLOR SCHEME =================
local COLORS = {
    Background    = Color3.fromRGB(12, 12, 15),
    Sidebar       = Color3.fromRGB(9, 9, 12),
    TitleBar      = Color3.fromRGB(8, 8, 10),
    Content       = Color3.fromRGB(6, 6, 8),
    Card          = Color3.fromRGB(20, 20, 25),
    CardHover     = Color3.fromRGB(25, 25, 31),
    Accent        = CONFIG.AccentColor,
    AccentAlt     = CONFIG.AccentColorAlt,
    Text          = Color3.fromRGB(237, 237, 242),
    TextSecondary = Color3.fromRGB(148, 148, 160),
    TextMuted     = Color3.fromRGB(92, 92, 104),
    Border        = Color3.fromRGB(34, 34, 41),
    SliderTrack   = Color3.fromRGB(30, 30, 36),
    Button        = Color3.fromRGB(25, 25, 31),
    Success       = Color3.fromRGB(46, 204, 113),
    Danger        = Color3.fromRGB(231, 76, 60),
    PremiumGold   = Color3.fromRGB(255, 215, 0),
}

local BASE_WIDTH    = CONFIG.WindowSize.X
local BASE_HEIGHT   = CONFIG.WindowSize.Y
local SIDEBAR_WIDTH = 150
local TAB_ROW_H     = 34
local TAB_ROW_GAP   = 4

local function tw(obj, time, style, dir, props)
    local tween = TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
    tween:Play()
    return tween
end

-- ================= ULTIMATE CONFIGURATION =================
local Configuration = {
    Aimbot = false, OnePressAimingMode = false,
    AimKey = Enum.UserInputType.MouseButton2, AimMode = "Mouse", AimPart = "Head",
    AimPartDropdownValues = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },

    SilentAim = false, SilentAimKey = Enum.KeyCode.E, AlwaysOnSilent = false,
    ShowSilentFOV = false, SilentFOVRadius = 150,
    SilentPrediction = false, SilentPredictionX = 1.0, SilentPredictionY = 1.0,
    SilentVisualizer = false, SilentTargetBone = "Head",
    SilentBoneDropdownValues = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot" },

    UseOffset = false, StaticOffsetIncrement = 10, AutoOffset = false, MaxAutoOffset = 50,
    UseSensitivity = false, Sensitivity = 50, UseNoise = false, NoiseFrequency = 50,

    TriggerBot = false, OnePressTriggeringMode = false, SmartTriggerBot = true,
    TriggerKey = Enum.KeyCode.E, TriggerBotChance = 100,

    AliveCheck = true, GodCheck = false, TeamCheck = false, FriendCheck = true,
    FollowCheck = false, VerifiedBadgeCheck = false, WallCheck = false, WaterCheck = false,
    FoVCheck = false, FoVRadius = 250, MagnitudeCheck = false, TriggerMagnitude = 500,
    TransparencyCheck = false, IgnoredTransparency = 0.5,

    FoV = false, FoVThickness = 2, FoVOpacity = 0.8, FoVFilled = false,
    FoVColour = Color3.fromRGB(132, 97, 255),
    ESPBox = false, ESPBoxFilled = false, CorneredBox = false, CornerLength = 6,
    NameESP = false, HealthESP = false, TracerESP = false, SkeletonESP = false,
    HighlightESP = false, HeadCircle = false, ESPThickness = 2,
    ESPColour = Color3.fromRGB(132, 97, 255),
    RainbowVisuals = false, RainbowDelay = 5,

    RageMode = false, AutoWallbang = false, InstantKill = false, RageFOV = 180, HitChance = 80,
    SpinBot = false, SpinBotVelocity = 50, SpinPart = "HumanoidRootPart",
    AntiAim = false, AntiAimMode = "Jitter", AntiAimAngle = 90,

    ToggleKey = CONFIG.ToggleKey,
}

-- ================= AIMBOT / SILENT / PREVIEW STATE =================
local Aiming = false
local Target = nil
local Triggering = false
local ShowingFoV = false
local ShowingESP = false

local SilentAimActive = false
local SilentTarget = nil
local SilentTargetScreenPos = nil
local SilentFOVCircle = nil
local TargetVisualizer = nil

-- [ESP PREVIEW] Single source of truth — Visuals toggles write here.
local PreviewState = {
    ESPBox = false, ESPBoxFilled = false, CorneredBox = false, CornerLength = 6,
    NameESP = false, HealthESP = false, TracerESP = false, SkeletonESP = false,
    HighlightESP = false, HeadCircle = false, ESPThickness = 2,
    ESPColour = Color3.fromRGB(132, 97, 255),
}

local MathHandler = {}
function MathHandler:CalculateChance(p)
    return typeof(p) == "number" and math.random(1, 100) <= p or false
end

-- ================= CHARACTER MANAGEMENT =================
local Character, Humanoid, HRP
local function getChar()
    if LocalPlayer.Character then
        Character = LocalPlayer.Character
        task.wait(0.05)
        Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        HRP = Character:FindFirstChild("HumanoidRootPart")
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    task.wait(0.2)
    Humanoid = char:WaitForChild("Humanoid", 3)
    HRP = char:WaitForChild("HumanoidRootPart", 3)
    Camera = workspace.CurrentCamera
end)

getChar()

-- ================= ROOT =================
local gui = Instance.new("ScreenGui")
gui.Name = "AuroraUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, BASE_WIDTH, 0, BASE_HEIGHT)
mainContainer.Position = UDim2.new(0.5, -BASE_WIDTH / 2, 0.5, -BASE_HEIGHT / 2)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = gui

-- [SHADOW REMOVED] main menu drop-shadow was here

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = mainContainer
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Border
mainStroke.Thickness = 1
mainStroke.Transparency = 0.35
mainStroke.Parent = mainFrame

local depthGradient = Instance.new("Frame")
depthGradient.Size = UDim2.new(1, 0, 1, 0)
depthGradient.BackgroundColor3 = Color3.new(1, 1, 1)
depthGradient.BackgroundTransparency = 1
depthGradient.BorderSizePixel = 0
depthGradient.ZIndex = 50
depthGradient.Parent = mainFrame
local depthGrad = Instance.new("UIGradient")
depthGrad.Rotation = 90
depthGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.94),
    NumberSequenceKeypoint.new(1, 1),
})
depthGrad.Parent = depthGradient

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 2)
accentBar.BackgroundColor3 = Color3.new(1, 1, 1)
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 51
accentBar.Parent = mainFrame
local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COLORS.Accent),
    ColorSequenceKeypoint.new(0.5, COLORS.AccentAlt),
    ColorSequenceKeypoint.new(1, COLORS.Accent),
})
accentGrad.Parent = accentBar

-- ================= TITLE BAR =================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 2)
titleBar.BackgroundColor3 = COLORS.TitleBar
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLine = Instance.new("Frame")
titleLine.Size = UDim2.new(1, 0, 0, 1)
titleLine.Position = UDim2.new(0, 0, 1, -1)
titleLine.BackgroundColor3 = COLORS.Border
titleLine.BorderSizePixel = 0
titleLine.BackgroundTransparency = 0.25
titleLine.Parent = titleBar

local logoDot = Instance.new("Frame")
logoDot.Size = UDim2.new(0, 7, 0, 7)
logoDot.Position = UDim2.new(0, 14, 0.5, -3)
logoDot.BackgroundColor3 = COLORS.Accent
logoDot.BorderSizePixel = 0
logoDot.Parent = titleBar
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(1, 0)

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(0, 220, 1, 0)
logoText.Position = UDim2.new(0, 28, 0, 0)
logoText.BackgroundTransparency = 1
logoText.Text = CONFIG.Title
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 14
logoText.TextColor3 = COLORS.Text
logoText.TextXAlignment = Enum.TextXAlignment.Left
logoText.Parent = titleBar

local subText = Instance.new("TextLabel")
subText.Size = UDim2.new(0, 120, 0, 12)
subText.Position = UDim2.new(0, 28 + logoText.TextBounds.X + 8, 0.5, -6)
subText.BackgroundTransparency = 1
subText.Text = CONFIG.SubTitle
subText.Font = Enum.Font.Gotham
subText.TextSize = 10
subText.TextColor3 = COLORS.PremiumGold
subText.TextXAlignment = Enum.TextXAlignment.Left
subText.Parent = titleBar

local premiumBadge = Instance.new("TextLabel")
premiumBadge.Size = UDim2.new(0, 62, 0, 16)
premiumBadge.Position = UDim2.new(1, -104, 0.5, -8)
premiumBadge.BackgroundColor3 = COLORS.Accent
premiumBadge.BackgroundTransparency = 0.3
premiumBadge.BorderSizePixel = 0
premiumBadge.Text = "PREMIUM"
premiumBadge.Font = Enum.Font.GothamBold
premiumBadge.TextSize = 8
premiumBadge.TextColor3 = COLORS.PremiumGold
premiumBadge.Parent = titleBar
Instance.new("UICorner", premiumBadge).CornerRadius = UDim.new(0, 4)

local closeDot = Instance.new("TextButton")
closeDot.Size = UDim2.new(0, 26, 0, 26)
closeDot.Position = UDim2.new(1, -34, 0.5, -13)
closeDot.BackgroundColor3 = COLORS.Button
closeDot.BorderSizePixel = 0
closeDot.Text = "—"
closeDot.Font = Enum.Font.GothamBold
closeDot.TextSize = 13
closeDot.TextColor3 = COLORS.TextSecondary
closeDot.AutoButtonColor = false
closeDot.Parent = titleBar
Instance.new("UICorner", closeDot).CornerRadius = UDim.new(0, 7)
closeDot.MouseEnter:Connect(function() tw(closeDot, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, {BackgroundColor3 = COLORS.CardHover}) end)
closeDot.MouseLeave:Connect(function() tw(closeDot, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, {BackgroundColor3 = COLORS.Button}) end)

-- ================= DRAGGING (menu) =================
do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainContainer.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainContainer.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ================= SIDEBAR =================
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -38)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = COLORS.Sidebar
sidebar.BorderSizePixel = 0
sidebar.ClipsDescendants = true
sidebar.Parent = mainFrame

local sidebarLine = Instance.new("Frame")
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.Position = UDim2.new(1, -1, 0, 0)
sidebarLine.BackgroundColor3 = COLORS.Border
sidebarLine.BackgroundTransparency = 0.25
sidebarLine.BorderSizePixel = 0
sidebarLine.Parent = sidebar

-- ================= STARFIELD =================
local allStars = {}
local function buildStarfield(parent, count)
    local layer = Instance.new("Frame")
    layer.Size = UDim2.new(1, 0, 1, 0)
    layer.BackgroundTransparency = 1
    layer.ZIndex = 1
    layer.Parent = parent

    math.randomseed(tick() + count)
    for _ = 1, count do
        local size = math.random(2, 4)
        local star = Instance.new("Frame")
        star.Size = UDim2.new(0, size, 0, size)
        star.Position = UDim2.new(math.random(), 0, math.random(), 0)
        star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        star.BorderSizePixel = 0
        star.ZIndex = 1
        star.Parent = layer
        Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)

        local baseTransparency = 1 - math.random(8, 30) / 100
        star.BackgroundTransparency = baseTransparency
        allStars[#allStars + 1] = { obj = star, baseTransparency = baseTransparency, baseSize = size, layer = layer }
    end
    return layer
end

RunService.RenderStepped:Connect(function()
    if not gui.Enabled or not mainContainer.Visible then return end
    local mouse = UserInputService:GetMouseLocation()
    for _, s in ipairs(allStars) do
        if s.layer.Visible then
            local obj = s.obj
            local absPos = obj.AbsolutePosition + obj.AbsoluteSize / 2
            local dist = (mouse - absPos).Magnitude
            if dist < CONFIG.StarGlowRadius then
                local strength = 1 - (dist / CONFIG.StarGlowRadius)
                obj.BackgroundTransparency = math.clamp(s.baseTransparency - strength * 0.92, 0, 1)
                local grow = s.baseSize + strength * 3.5
                obj.Size = UDim2.new(0, grow, 0, grow)
            else
                obj.BackgroundTransparency = s.baseTransparency
                obj.Size = UDim2.new(0, s.baseSize, 0, s.baseSize)
            end
        end
    end
end)

buildStarfield(sidebar, CONFIG.StarCountSide)

local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -16, 1, -16)
tabHolder.Position = UDim2.new(0, 8, 0, 12)
tabHolder.BackgroundTransparency = 1
tabHolder.ZIndex = 3
tabHolder.Parent = sidebar

local pill = Instance.new("Frame")
pill.Size = UDim2.new(1, 0, 0, TAB_ROW_H)
pill.Position = UDim2.new(0, 0, 0, 0)
pill.BackgroundColor3 = COLORS.Card
pill.BackgroundTransparency = 0.1
pill.BorderSizePixel = 0
pill.ZIndex = 2
pill.Parent = tabHolder
Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 7)
local pillStroke = Instance.new("UIStroke")
pillStroke.Color = COLORS.Accent
pillStroke.Thickness = 1
pillStroke.Transparency = 0.55
pillStroke.Parent = pill
local pillAccentEdge = Instance.new("Frame")
pillAccentEdge.Size = UDim2.new(0, 3, 0, 16)
pillAccentEdge.Position = UDim2.new(0, 5, 0.5, -8)
pillAccentEdge.BackgroundColor3 = COLORS.Accent
pillAccentEdge.BorderSizePixel = 0
pillAccentEdge.Parent = pill
Instance.new("UICorner", pillAccentEdge).CornerRadius = UDim.new(1, 0)

-- ================= PLAYER PROFILE =================
local profileArea = Instance.new("Frame")
profileArea.Size = UDim2.new(1, -16, 0, 52)
profileArea.Position = UDim2.new(0, 8, 1, -60)
profileArea.BackgroundColor3 = COLORS.Card
profileArea.BorderSizePixel = 0
profileArea.ZIndex = 3
profileArea.Parent = sidebar
Instance.new("UICorner", profileArea).CornerRadius = UDim.new(0, 6)
local profileStroke = Instance.new("UIStroke")
profileStroke.Color = COLORS.Border
profileStroke.Thickness = 1
profileStroke.Transparency = 0.3
profileStroke.Parent = profileArea

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 32, 0, 32)
avatarImage.Position = UDim2.new(0, 8, 0.5, -16)
avatarImage.BackgroundColor3 = COLORS.Border
avatarImage.BorderSizePixel = 0
avatarImage.ZIndex = 4
avatarImage.Parent = profileArea
Instance.new("UICorner", avatarImage).CornerRadius = UDim.new(1, 0)

local usernameLabel = Instance.new("TextLabel")
usernameLabel.Size = UDim2.new(1, -52, 0, 16)
usernameLabel.Position = UDim2.new(0, 46, 0, 10)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Text = LocalPlayer.Name
usernameLabel.Font = Enum.Font.GothamBold
usernameLabel.TextSize = 11
usernameLabel.TextColor3 = COLORS.Text
usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
usernameLabel.ZIndex = 4
usernameLabel.Parent = profileArea

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -52, 0, 14)
statusLabel.Position = UDim2.new(0, 46, 0, 28)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "● Premium"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 9
statusLabel.TextColor3 = COLORS.PremiumGold
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 4
statusLabel.Parent = profileArea

local function updateAvatar()
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    if ok then avatarImage.Image = content end
end
updateAvatar()
LocalPlayer:GetPropertyChangedSignal("Name"):Connect(function()
    usernameLabel.Text = LocalPlayer.Name
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    updateAvatar()
end)

-- ================= CONTENT AREA =================
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -38)
contentArea.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 38)
contentArea.BackgroundColor3 = COLORS.Content
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.Parent = mainFrame

local contentStarLayer = buildStarfield(contentArea, CONFIG.StarCountMain)

-- ================= SNOWFALL =================
local snowLayer = Instance.new("Frame")
snowLayer.Size = UDim2.new(1, 0, 1, 0)
snowLayer.BackgroundTransparency = 1
snowLayer.ZIndex = 1
snowLayer.Visible = false
snowLayer.Parent = contentArea

local snowflakes = {}
do
    math.randomseed(tick() + 999)
    for _ = 1, CONFIG.SnowCount do
        local size = math.random(2, 5)
        local flake = Instance.new("Frame")
        flake.Size = UDim2.new(0, size, 0, size)
        flake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        flake.BackgroundTransparency = 1 - math.random(35, 85) / 100
        flake.BorderSizePixel = 0
        flake.ZIndex = 1
        flake.Parent = snowLayer
        Instance.new("UICorner", flake).CornerRadius = UDim.new(1, 0)

        snowflakes[#snowflakes + 1] = {
            obj = flake, baseX = math.random(), y = math.random(0, BASE_HEIGHT),
            speed = math.random(14, 34), swayAmp = math.random(4, 14),
            swayFreq = math.random(30, 90) / 100, phase = math.random() * math.pi * 2,
        }
    end
end

local snowEnabled = false
RunService.RenderStepped:Connect(function(dt)
    if not snowEnabled or not gui.Enabled or not mainContainer.Visible then return end
    local height = snowLayer.AbsoluteSize.Y
    if height <= 0 then height = BASE_HEIGHT end
    for _, flake in ipairs(snowflakes) do
        flake.y = flake.y + flake.speed * dt
        if flake.y > height + 6 then flake.y = -6 end
        local sway = math.sin(tick() * flake.swayFreq + flake.phase) * flake.swayAmp
        flake.obj.Position = UDim2.new(flake.baseX, sway, 0, flake.y)
    end
end)

local function setSnowMode(enabled)
    snowEnabled = enabled
    contentStarLayer.Visible = not enabled
    snowLayer.Visible = enabled
end

-- ================= MENU SHOW/HIDE =================
local ANIM_TIME  = 0.28
local ANIM_STYLE = Enum.EasingStyle.Quint
local ANIM_DIR   = Enum.EasingDirection.Out

local menuVisible = true
local currentTween = nil

local setMenuVisible -- forward-declare for the preview block

-- ================= ESP PREVIEW =================
-- Declared before setMenuVisible so the function can reference it safely.
local ESPPreview
local previewContainer, previewFrame, previewContent

if CONFIG.PreviewEnabled then
    ESPPreview = { Visible = false, UserMoved = false }

    local PW = CONFIG.PreviewWidth
    local PH = BASE_HEIGHT
    local GAP = CONFIG.PreviewGap

    previewContainer = Instance.new("Frame")
    previewContainer.Name = "PreviewContainer"
    previewContainer.Size = UDim2.new(0, PW, 0, PH)
    previewContainer.Position = UDim2.new(0.5, BASE_WIDTH / 2 + GAP, 0.5, -PH / 2)
    previewContainer.BackgroundTransparency = 1
    previewContainer.Visible = false
    previewContainer.Active = true
    previewContainer.Parent = gui

    -- [SHADOW REMOVED] preview drop-shadow was here

    previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(1, 0, 1, 0)
    previewFrame.BackgroundColor3 = COLORS.Background
    previewFrame.BorderSizePixel = 0
    previewFrame.ClipsDescendants = true
    previewFrame.Parent = previewContainer
    Instance.new("UICorner", previewFrame).CornerRadius = UDim.new(0, 12)

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = COLORS.Border
    pStroke.Thickness = 1
    pStroke.Transparency = 0.35
    pStroke.Parent = previewFrame

    local pDepth = Instance.new("Frame")
    pDepth.Size = UDim2.new(1, 0, 1, 0)
    pDepth.BackgroundColor3 = Color3.new(1, 1, 1)
    pDepth.BackgroundTransparency = 1
    pDepth.BorderSizePixel = 0
    pDepth.ZIndex = 50
    pDepth.Parent = previewFrame
    local pDepthGrad = Instance.new("UIGradient")
    pDepthGrad.Rotation = 90
    pDepthGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.94),
        NumberSequenceKeypoint.new(1, 1),
    })
    pDepthGrad.Parent = pDepth

    local pAccentBar = Instance.new("Frame")
    pAccentBar.Size = UDim2.new(1, 0, 0, 2)
    pAccentBar.BackgroundColor3 = Color3.new(1, 1, 1)
    pAccentBar.BorderSizePixel = 0
    pAccentBar.ZIndex = 51
    pAccentBar.Parent = previewFrame
    local pAccentGrad = Instance.new("UIGradient")
    pAccentGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.Accent),
        ColorSequenceKeypoint.new(0.5, COLORS.AccentAlt),
        ColorSequenceKeypoint.new(1, COLORS.Accent),
    })
    pAccentGrad.Parent = pAccentBar

    local pTitleBar = Instance.new("Frame")
    pTitleBar.Size = UDim2.new(1, 0, 0, 36)
    pTitleBar.Position = UDim2.new(0, 0, 0, 2)
    pTitleBar.BackgroundColor3 = COLORS.TitleBar
    pTitleBar.BorderSizePixel = 0
    pTitleBar.Parent = previewFrame

    local pTitleLine = Instance.new("Frame")
    pTitleLine.Size = UDim2.new(1, 0, 0, 1)
    pTitleLine.Position = UDim2.new(0, 0, 1, -1)
    pTitleLine.BackgroundColor3 = COLORS.Border
    pTitleLine.BorderSizePixel = 0
    pTitleLine.BackgroundTransparency = 0.25
    pTitleLine.Parent = pTitleBar

    local pLogoDot = Instance.new("Frame")
    pLogoDot.Size = UDim2.new(0, 7, 0, 7)
    pLogoDot.Position = UDim2.new(0, 14, 0.5, -3)
    pLogoDot.BackgroundColor3 = COLORS.AccentAlt
    pLogoDot.BorderSizePixel = 0
    pLogoDot.Parent = pTitleBar
    Instance.new("UICorner", pLogoDot).CornerRadius = UDim.new(1, 0)

    local pTitle = Instance.new("TextLabel")
    pTitle.Size = UDim2.new(1, -30, 1, 0)
    pTitle.Position = UDim2.new(0, 28, 0, 0)
    pTitle.BackgroundTransparency = 1
    pTitle.Text = "ESP PREVIEW"
    pTitle.Font = Enum.Font.GothamBlack
    pTitle.TextSize = 12
    pTitle.TextColor3 = COLORS.Text
    pTitle.TextXAlignment = Enum.TextXAlignment.Left
    pTitle.Parent = pTitleBar

    previewContent = Instance.new("Frame")
    previewContent.Size = UDim2.new(1, -16, 1, -50)
    previewContent.Position = UDim2.new(0, 8, 0, 42)
    previewContent.BackgroundColor3 = COLORS.Content
    previewContent.BorderSizePixel = 0
    previewContent.Parent = previewFrame
    Instance.new("UICorner", previewContent).CornerRadius = UDim.new(0, 7)

    local pContentStroke = Instance.new("UIStroke")
    pContentStroke.Color = COLORS.Border
    pContentStroke.Thickness = 1
    pContentStroke.Transparency = 0.4
    pContentStroke.Parent = previewContent

    -- ---- PREVIEW DRAG (independent of menu) ----
    do
        local dragging, dragStart, startPos = false, nil, nil
        pTitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                ESPPreview.UserMoved = true
                dragStart = input.Position
                startPos = previewContainer.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                previewContainer.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- ---- Drawing objects ----
    local pBox          = Drawing.new("Square")
    local pTracer       = Drawing.new("Line")
    local pHealth       = Drawing.new("Line")
    local pName         = Drawing.new("Text")
    local pHighlight    = Drawing.new("Square")
    local pHeadCircle   = Drawing.new("Circle")
    local pCorneredBox  = {}
    for i = 1, 8 do pCorneredBox[i] = Drawing.new("Line") end

    local pSkeleton = {}
    local skeletonPoints = {
        {Vector2.new(0, -25), Vector2.new(0, 0)},
        {Vector2.new(0, 0), Vector2.new(18, 4)},
        {Vector2.new(0, 0), Vector2.new(-18, 4)},
        {Vector2.new(18, 4), Vector2.new(26, 25)},
        {Vector2.new(-18, 4), Vector2.new(-26, 25)},
        {Vector2.new(0, 0), Vector2.new(0, 35)},
        {Vector2.new(0, 35), Vector2.new(12, 60)},
        {Vector2.new(0, 35), Vector2.new(-12, 60)}
    }
    for i = 1, #skeletonPoints do
        pSkeleton[i] = Drawing.new("Line")
        pSkeleton[i].Thickness = 2
        pSkeleton[i].Visible = false
    end

    pBox.Thickness = 2
    pTracer.Thickness = 2
    pHealth.Thickness = 3
    pName.Size = 14
    pName.Center = true
    pName.Font = 2
    pName.Text = "Preview"
    pName.Outline = true
    pName.OutlineColor = Color3.fromRGB(0, 0, 0)
    pHighlight.Filled = true
    pHeadCircle.Thickness = 2
    pHeadCircle.Filled = false
    pHeadCircle.NumSides = 100

    local function clearPreview()
        pBox.Visible = false
        pTracer.Visible = false
        pHealth.Visible = false
        pName.Visible = false
        pHighlight.Visible = false
        pHeadCircle.Visible = false
        for i = 1, 8 do pCorneredBox[i].Visible = false end
        for i = 1, #pSkeleton do pSkeleton[i].Visible = false end
    end
    clearPreview()

    local function updateCorneredBox(pos, size, color, thickness, transparency, cornerLen)
        local tl, tr = pos, Vector2.new(pos.X + size.X, pos.Y)
        local bl, br = Vector2.new(pos.X, pos.Y + size.Y), Vector2.new(pos.X + size.X, pos.Y + size.Y)
        local cl = math.min(cornerLen or 8, size.X/2, size.Y/2)
        local segs = {
            {tl, Vector2.new(tl.X + cl, tl.Y)},
            {tl, Vector2.new(tl.X, tl.Y + cl)},
            {Vector2.new(tr.X - cl, tr.Y), tr},
            {tr, Vector2.new(tr.X, tr.Y + cl)},
            {bl, Vector2.new(bl.X + cl, bl.Y)},
            {bl, Vector2.new(bl.X, bl.Y - cl)},
            {Vector2.new(br.X - cl, br.Y), br},
            {br, Vector2.new(br.X, br.Y - cl)},
        }
        for i, seg in ipairs(segs) do
            local line = pCorneredBox[i]
            line.From = seg[1]; line.To = seg[2]; line.Color = color
            line.Thickness = thickness; line.Transparency = transparency; line.Visible = true
        end
    end

    -- ---- Follow main menu (unless the user has dragged the preview) ----
    local function syncToMenu()
        if ESPPreview.UserMoved then return end
        if not mainContainer.Visible then return end
        previewContainer.Position = UDim2.new(
            mainContainer.Position.X.Scale,
            mainContainer.Position.X.Offset + BASE_WIDTH + GAP,
            mainContainer.Position.Y.Scale,
            mainContainer.Position.Y.Offset
        )
    end
    mainContainer:GetPropertyChangedSignal("Position"):Connect(syncToMenu)
    mainContainer:GetPropertyChangedSignal("Visible"):Connect(syncToMenu)
    syncToMenu()

    -- ---- Show / Hide with no tween-chain desync ----
    local pTween = nil
    function ESPPreview:Show()
        if self.Visible then return end
        self.Visible = true
        if pTween then pTween:Cancel() end
        previewContainer.Visible = true
        previewContainer.Size = UDim2.new(0, PW, 0, PH)
        previewFrame.Size = UDim2.new(0, 0, 1, 1)
        pTween = tw(previewFrame, ANIM_TIME, ANIM_STYLE, ANIM_DIR, { Size = UDim2.new(1, 0, 1, 0) })
        syncToMenu()
    end

    function ESPPreview:Hide()
        if not self.Visible and not previewContainer.Visible then
            clearPreview()
            return
        end
        self.Visible = false
        if pTween then pTween:Cancel(); pTween = nil end
        previewFrame.Size = UDim2.new(0, 0, 1, 1)
        previewContainer.Visible = false
        clearPreview()
    end

    function ESPPreview:Toggle()
        if self.Visible then self:Hide() else self:Show() end
    end

    -- ---- Render loop (always reads PreviewState) ----
    RunService.RenderStepped:Connect(function()
        -- only render when both the preview and the menu are on screen
        if not ESPPreview.Visible or not previewContainer.Visible or not mainContainer.Visible then
            if not ESPPreview.Visible then clearPreview() end
            return
        end

        local center = Vector2.new(
            previewContent.AbsolutePosition.X + previewContent.AbsoluteSize.X / 2,
            previewContent.AbsolutePosition.Y + previewContent.AbsoluteSize.Y / 2
        )
        if center.X == 0 or center.Y == 0 then return end

        local boxW, boxH = 55, 85
        local boxPos = Vector2.new(center.X - boxW / 2, center.Y - boxH / 2)
        local headCenter = Vector2.new(center.X, center.Y - 30)

        local espColor = PreviewState.ESPColour or COLORS.Accent
        local espThickness = PreviewState.ESPThickness or 2

        pBox.Visible = PreviewState.ESPBox == true
        if pBox.Visible then
            pBox.Size = Vector2.new(boxW, boxH); pBox.Position = boxPos
            pBox.Color = espColor; pBox.Thickness = espThickness
            pBox.Transparency = 0.8; pBox.Filled = PreviewState.ESPBoxFilled == true
        end

        if PreviewState.CorneredBox then
            updateCorneredBox(boxPos, Vector2.new(boxW, boxH), espColor, espThickness, 0.8, PreviewState.CornerLength or 8)
        else
            for i = 1, 8 do pCorneredBox[i].Visible = false end
        end

        pHealth.Visible = PreviewState.HealthESP == true
        if pHealth.Visible then
            pHealth.From = boxPos + Vector2.new(-5, boxH)
            pHealth.To = boxPos + Vector2.new(-5, boxH * 0.6)
            pHealth.Color = Color3.fromRGB(100, 255, 100); pHealth.Thickness = 2
        end

        pName.Visible = PreviewState.NameESP == true
        if pName.Visible then
            pName.Position = Vector2.new(center.X, boxPos.Y - 16)
            pName.Color = espColor; pName.Size = 12
        end

        pTracer.Visible = PreviewState.TracerESP == true
        if pTracer.Visible then
            pTracer.From = Vector2.new(center.X, previewContent.AbsolutePosition.Y + previewContent.AbsoluteSize.Y)
            pTracer.To = center; pTracer.Color = espColor; pTracer.Thickness = espThickness
        end

        pHeadCircle.Visible = PreviewState.HeadCircle == true
        if pHeadCircle.Visible then
            pHeadCircle.Position = headCenter; pHeadCircle.Radius = 12
            pHeadCircle.Color = espColor; pHeadCircle.Thickness = espThickness
            pHeadCircle.Transparency = 0.8
        end

        if PreviewState.SkeletonESP then
            for i = 1, #pSkeleton do
                pSkeleton[i].Visible = true
                pSkeleton[i].From = center + skeletonPoints[i][1] * 0.65
                pSkeleton[i].To = center + skeletonPoints[i][2] * 0.65
                pSkeleton[i].Color = espColor; pSkeleton[i].Thickness = espThickness
                pSkeleton[i].Transparency = 0.8
            end
        else
            for i = 1, #pSkeleton do pSkeleton[i].Visible = false end
        end

        pHighlight.Visible = PreviewState.HighlightESP == true
        if pHighlight.Visible then
            pHighlight.Size = Vector2.new(boxW + 6, boxH + 6)
            pHighlight.Position = boxPos - Vector2.new(3, 3)
            pHighlight.Color = espColor; pHighlight.Transparency = 0.5
        end
    end)

    gui.AncestryChanged:Connect(function(_, parent)
        if not parent then
            for _, d in ipairs({pBox, pTracer, pHealth, pName, pHighlight, pHeadCircle}) do
                pcall(function() d:Remove() end)
            end
            for i = 1, 8 do pcall(function() pCorneredBox[i]:Remove() end) end
            for i = 1, #pSkeleton do pcall(function() pSkeleton[i]:Remove() end) end
        end
    end)
end

-- ================= MENU SHOW/HIDE (wired to preview) =================
function setMenuVisible(show)
    if currentTween then currentTween:Cancel() end
    menuVisible = show
    if show then
        mainContainer.Visible = true
        currentTween = tw(mainContainer, ANIM_TIME, ANIM_STYLE, ANIM_DIR,
            { Size = UDim2.new(0, BASE_WIDTH, 0, BASE_HEIGHT) })
        -- [ESP PREVIEW] re-show only when on the preview's tab
        if ESPPreview and activeTab and _G.__aurora_activeTabName == CONFIG.PreviewOnTab then
            ESPPreview:Show()
        end
    else
        -- [ESP PREVIEW] hard-hide the preview immediately — no tween dependency
        if ESPPreview then ESPPreview:Hide() end
        currentTween = tw(mainContainer, ANIM_TIME, ANIM_STYLE, ANIM_DIR,
            { Size = UDim2.new(0, BASE_WIDTH, 0, 0) })
        currentTween.Completed:Connect(function()
            if not menuVisible then mainContainer.Visible = false end
        end)
    end
end

closeDot.MouseButton1Click:Connect(function() setMenuVisible(false) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Configuration.ToggleKey then
        setMenuVisible(not menuVisible)
    end
end)

mainContainer.Size = UDim2.new(0, BASE_WIDTH, 0, 0)
task.defer(setMenuVisible, true)

-- ================================================
--   COMPONENT LIBRARY
-- ================================================
local Library = {}
Library.Tabs = {}
_G.__aurora_activeTabName = nil

local activeTab = nil
local openDropdown = nil

function Library:CreateTab(name, icon)
    local tabIndex = #Library.Tabs

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, TAB_ROW_H)
    btn.Position = UDim2.new(0, 0, 0, tabIndex * (TAB_ROW_H + TAB_ROW_GAP))
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = tabHolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icon and (icon .. "  ") or "") .. name
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextColor3 = COLORS.TextSecondary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = btn

    local pageGroup = Instance.new("CanvasGroup")
    pageGroup.Size = UDim2.new(1, -28, 1, -28)
    pageGroup.Position = UDim2.new(0, 14, 0, 14)
    pageGroup.BackgroundTransparency = 1
    pageGroup.GroupTransparency = 0
    pageGroup.ZIndex = 2
    pageGroup.Visible = false
    pageGroup.Parent = contentArea

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.SliderTrack
    page.ScrollBarImageTransparency = 0.2
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Parent = pageGroup

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = page
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
    end)

    local orderCounter = 0

    local function select()
        if activeTab then
            activeTab.pageGroup.Visible = false
            tw(activeTab.label, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = COLORS.TextSecondary })
        end

        tw(pill, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out,
            { Position = UDim2.new(0, 0, 0, tabIndex * (TAB_ROW_H + TAB_ROW_GAP)) })
        tw(label, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = COLORS.Text })

        pageGroup.Visible = true
        pageGroup.GroupTransparency = 1
        pageGroup.Position = UDim2.new(0, 20, 0, 14)
        tw(pageGroup, 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { GroupTransparency = 0 })
        tw(pageGroup, 0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Position = UDim2.new(0, 14, 0, 14) })

        activeTab = { label = label, pageGroup = pageGroup }
        _G.__aurora_activeTabName = name

        -- [ESP PREVIEW] toggle visibility based on the newly-selected tab
        if ESPPreview then
            if name == CONFIG.PreviewOnTab and menuVisible and mainContainer.Visible then
                ESPPreview:Show()
            else
                ESPPreview:Hide()
            end
        end
    end

    btn.MouseButton1Click:Connect(select)
    btn.MouseEnter:Connect(function()
        if activeTab and activeTab.label == label then return end
        tw(label, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = COLORS.Text })
    end)
    btn.MouseLeave:Connect(function()
        if activeTab and activeTab.label == label then return end
        tw(label, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = COLORS.TextSecondary })
    end)

    if #Library.Tabs == 0 then select() end

    local Tab = {}

    local function nextOrder()
        orderCounter = orderCounter + 2
        return orderCounter
    end

    local function attachHover(card)
        local leftAccent = Instance.new("Frame")
        leftAccent.Size = UDim2.new(0, 2, 1, -12)
        leftAccent.Position = UDim2.new(0, 0, 0, 6)
        leftAccent.BackgroundColor3 = COLORS.Accent
        leftAccent.BackgroundTransparency = 1
        leftAccent.BorderSizePixel = 0
        leftAccent.ZIndex = 2
        leftAccent.Parent = card
        Instance.new("UICorner", leftAccent).CornerRadius = UDim.new(1, 0)

        card.MouseEnter:Connect(function()
            tw(card, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = COLORS.CardHover })
            tw(leftAccent, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundTransparency = 0.2 })
        end)
        card.MouseLeave:Connect(function()
            tw(card, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = COLORS.Card })
            tw(leftAccent, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
        end)
    end

    function Tab:AddSection(text)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, 0, 0, 24)
        section.BackgroundTransparency = 1
        section.LayoutOrder = nextOrder()
        section.Parent = page

        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 3, 0, 13)
        accent.Position = UDim2.new(0, 0, 0.5, -6)
        accent.BackgroundColor3 = COLORS.Accent
        accent.BorderSizePixel = 0
        accent.Parent = section
        Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -12, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = string.upper(text)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextColor3 = COLORS.TextSecondary
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = section
        return section
    end

    local function baseCard(height)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, height)
        card.BackgroundColor3 = COLORS.Card
        card.BorderSizePixel = 0
        card.LayoutOrder = nextOrder()
        card.ClipsDescendants = false
        card.Parent = page
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
        local stroke = Instance.new("UIStroke")
        stroke.Color = COLORS.Border
        stroke.Thickness = 1
        stroke.Transparency = 0.35
        stroke.Parent = card
        attachHover(card)
        return card
    end

    function Tab:AddButton(text, callback)
        local card = baseCard(34)
        local btn2 = Instance.new("TextButton")
        btn2.Size = UDim2.new(1, 0, 1, 0)
        btn2.BackgroundTransparency = 1
        btn2.Text = ""
        btn2.ZIndex = 3
        btn2.Parent = card

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = COLORS.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -26, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "→"
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 12
        arrow.TextColor3 = COLORS.TextMuted
        arrow.Parent = card

        btn2.MouseButton1Click:Connect(function()
            tw(arrow, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = COLORS.Accent })
            task.delay(0.3, function()
                tw(arrow, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = COLORS.TextMuted })
            end)
            if callback then callback() end
        end)
        return card
    end

    function Tab:AddToggle(text, default, callback)
        local card = baseCard(34)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = COLORS.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        local track = Instance.new("Frame")
        track.Size = UDim2.new(0, 38, 0, 20)
        track.Position = UDim2.new(1, -50, 0.5, -10)
        track.BackgroundColor3 = default and COLORS.Accent or COLORS.SliderTrack
        track.BorderSizePixel = 0
        track.Parent = card
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, default and 20 or 2, 0.5, -8)
        knob.BackgroundColor3 = COLORS.Text
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local clickArea = Instance.new("TextButton")
        clickArea.Size = UDim2.new(1, 0, 1, 0)
        clickArea.BackgroundTransparency = 1
        clickArea.Text = ""
        clickArea.ZIndex = 3
        clickArea.Parent = card

        local state = default
        clickArea.MouseButton1Click:Connect(function()
            state = not state
            tw(track, 0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = state and COLORS.Accent or COLORS.SliderTrack })
            tw(knob, 0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Position = UDim2.new(0, state and 20 or 2, 0.5, -8) })
            if callback then callback(state) end
        end)
        return card
    end

    function Tab:AddSlider(text, min, max, default, callback, suffix)
        local card = baseCard(46)
        suffix = suffix or ""

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 200, 0, 16)
        lbl.Position = UDim2.new(0, 14, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextColor3 = COLORS.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 70, 0, 16)
        valLbl.Position = UDim2.new(1, -84, 0, 6)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(default) .. suffix
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 11
        valLbl.TextColor3 = COLORS.Accent
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = card

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -28, 0, 4)
        track.Position = UDim2.new(0, 14, 0, 30)
        track.BackgroundColor3 = COLORS.SliderTrack
        track.BorderSizePixel = 0
        track.Parent = card
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = COLORS.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 0, 0, 0)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
        knob.BackgroundColor3 = COLORS.Text
        knob.BorderSizePixel = 0
        knob.Parent = track
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = min + rel * (max - min)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            valLbl.Text = tostring(math.floor(value * 100) / 100) .. suffix
            if callback then callback(value) end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                tw(knob, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Size = UDim2.new(0, 12, 0, 12) })
                update(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    tw(knob, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Size = UDim2.new(0, 0, 0, 0) })
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end)
        return card
    end

    function Tab:AddDropdown(text, options, defaultIndex, callback)
        local rowOrder = nextOrder()
        local index = defaultIndex or 1

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 34)
        card.BackgroundColor3 = COLORS.Card
        card.BorderSizePixel = 0
        card.LayoutOrder = rowOrder
        card.ClipsDescendants = false
        card.Parent = page
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
        local stroke = Instance.new("UIStroke")
        stroke.Color = COLORS.Border
        stroke.Thickness = 1
        stroke.Transparency = 0.35
        stroke.Parent = card
        attachHover(card)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 180, 0, 34)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextColor3 = COLORS.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        local ddBtn = Instance.new("TextButton")
        ddBtn.Size = UDim2.new(0, 170, 0, 24)
        ddBtn.Position = UDim2.new(1, -182, 0, 5)
        ddBtn.BackgroundColor3 = COLORS.Button
        ddBtn.BorderSizePixel = 0
        ddBtn.AutoButtonColor = false
        ddBtn.Text = ""
        ddBtn.ZIndex = 3
        ddBtn.Parent = card
        Instance.new("UICorner", ddBtn).CornerRadius = UDim.new(0, 5)

        local ddLabel = Instance.new("TextLabel")
        ddLabel.Size = UDim2.new(1, -24, 1, 0)
        ddLabel.Position = UDim2.new(0, 10, 0, 0)
        ddLabel.BackgroundTransparency = 1
        ddLabel.Text = tostring(options[index] or options[1])
        ddLabel.Font = Enum.Font.Gotham
        ddLabel.TextSize = 11
        ddLabel.TextColor3 = COLORS.Text
        ddLabel.TextXAlignment = Enum.TextXAlignment.Left
        ddLabel.Parent = ddBtn

        local chevron = Instance.new("TextLabel")
        chevron.Size = UDim2.new(0, 14, 0, 14)
        chevron.AnchorPoint = Vector2.new(0.5, 0.5)
        chevron.Position = UDim2.new(1, -12, 0.5, 0)
        chevron.BackgroundTransparency = 1
        chevron.Text = "▾"
        chevron.TextColor3 = COLORS.TextMuted
        chevron.TextSize = 10
        chevron.Font = Enum.Font.Gotham
        chevron.Parent = ddBtn

        local body = Instance.new("Frame")
        body.Size = UDim2.new(1, 0, 0, 0)
        body.BackgroundColor3 = COLORS.Button
        body.BorderSizePixel = 0
        body.ClipsDescendants = true
        body.LayoutOrder = rowOrder + 1
        body.Parent = page
        Instance.new("UICorner", body).CornerRadius = UDim.new(0, 7)
        local bodyStroke = Instance.new("UIStroke")
        bodyStroke.Color = COLORS.Border
        bodyStroke.Thickness = 1
        bodyStroke.Transparency = 0.4
        bodyStroke.Parent = body

        local bodyLayout = Instance.new("UIListLayout")
        bodyLayout.Parent = body
        local bodyPad = Instance.new("UIPadding")
        bodyPad.PaddingTop = UDim.new(0, 4)
        bodyPad.PaddingBottom = UDim.new(0, 4)
        bodyPad.Parent = body

        local rowHeight = 26
        local isOpen = false

        local function closeDropdownBody(instant)
            isOpen = false
            local time = instant and 0 or 0.18
            tw(body, time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Size = UDim2.new(1, 0, 0, 0) })
            tw(chevron, time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Rotation = 0 })
        end

        local function openDropdownBody()
            if openDropdown and openDropdown ~= closeDropdownBody then openDropdown(false) end
            isOpen = true
            openDropdown = closeDropdownBody
            local targetHeight = rowHeight * #options + 8
            tw(body, 0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Size = UDim2.new(1, 0, 0, targetHeight) })
            tw(chevron, 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Rotation = 180 })
        end

        for i, optionText in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -12, 0, rowHeight)
            optBtn.Position = UDim2.new(0, 6, 0, 0)
            optBtn.BackgroundTransparency = 1
            optBtn.AutoButtonColor = false
            optBtn.Text = ""
            optBtn.LayoutOrder = i
            optBtn.Parent = body

            local optLbl = Instance.new("TextLabel")
            optLbl.Size = UDim2.new(1, -10, 1, 0)
            optLbl.Position = UDim2.new(0, 8, 0, 0)
            optLbl.BackgroundTransparency = 1
            optLbl.Text = tostring(optionText)
            optLbl.Font = i == index and Enum.Font.GothamBold or Enum.Font.Gotham
            optLbl.TextSize = 11
            optLbl.TextColor3 = i == index and COLORS.Accent or COLORS.TextSecondary
            optLbl.TextXAlignment = Enum.TextXAlignment.Left
            optLbl.Parent = optBtn

            optBtn.MouseEnter:Connect(function()
                tw(optLbl, 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = COLORS.Text })
            end)
            optBtn.MouseLeave:Connect(function()
                tw(optLbl, 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { TextColor3 = i == index and COLORS.Accent or COLORS.TextSecondary })
            end)
            optBtn.MouseButton1Click:Connect(function()
                index = i
                ddLabel.Text = tostring(optionText)
                for _, child in ipairs(body:GetChildren()) do
                    if child:IsA("TextButton") then
                        local l = child:FindFirstChildOfClass("TextLabel")
                        if l then
                            l.Font = (child == optBtn) and Enum.Font.GothamBold or Enum.Font.Gotham
                            l.TextColor3 = (child == optBtn) and COLORS.Accent or COLORS.TextSecondary
                        end
                    end
                end
                closeDropdownBody(false)
                if callback then callback(optionText, i) end
            end)
        end

        ddBtn.MouseButton1Click:Connect(function()
            if isOpen then closeDropdownBody(false) else openDropdownBody() end
        end)
        ddBtn.MouseEnter:Connect(function()
            tw(ddBtn, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = COLORS.CardHover })
        end)
        ddBtn.MouseLeave:Connect(function()
            tw(ddBtn, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = COLORS.Button })
        end)

        return card
    end

    function Tab:AddKeybind(text, defaultKey, callback)
        local card = baseCard(34)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -110, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextColor3 = COLORS.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        local keyBtn = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0, 90, 0, 24)
        keyBtn.Position = UDim2.new(1, -102, 0.5, -12)
        keyBtn.BackgroundColor3 = COLORS.Button
        keyBtn.BorderSizePixel = 0
        keyBtn.AutoButtonColor = false
        keyBtn.Text = defaultKey and (defaultKey.Name or "RMB") or "None"
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.TextSize = 10
        keyBtn.TextColor3 = COLORS.Accent
        keyBtn.ZIndex = 3
        keyBtn.Parent = card
        Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 5)

        local listening = false
        keyBtn.MouseButton1Click:Connect(function()
            listening = true
            keyBtn.Text = "..."
            tw(keyBtn, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = COLORS.CardHover })
        end)
        UserInputService.InputBegan:Connect(function(input)
            if not listening then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keyBtn.Text = input.KeyCode.Name
                listening = false
                tw(keyBtn, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = COLORS.Button })
                if callback then callback(input.KeyCode) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                keyBtn.Text = "RMB"
                listening = false
                tw(keyBtn, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundColor3 = COLORS.Button })
                if callback then callback(Enum.UserInputType.MouseButton2) end
            end
        end)
        return card
    end

    Library.Tabs[#Library.Tabs + 1] = Tab
    return Tab
end

-- ================================================
--   BUILD THE ULTIMATE INTERFACE
-- ================================================

-- ================= AIMBOT TAB =================
local aimbotTab = Library:CreateTab("Aimbot", "")
aimbotTab:AddSection("Aimbot Settings")
aimbotTab:AddToggle("Enable Aimbot", Configuration.Aimbot, function(v) Configuration.Aimbot = v end)
aimbotTab:AddToggle("One Press Mode", Configuration.OnePressAimingMode, function(v) Configuration.OnePressAimingMode = v end)
aimbotTab:AddKeybind("Aim Key", Configuration.AimKey, function(v) Configuration.AimKey = v end)

local aimModes = {"Mouse", "Camera"}
if not HAS_MOUSEMOVEREL then aimModes = {"Camera"} end
aimbotTab:AddDropdown("Aim Mode", aimModes, 1, function(opt) Configuration.AimMode = opt end)
aimbotTab:AddDropdown("Aim Part", Configuration.AimPartDropdownValues, 1, function(opt) Configuration.AimPart = opt end)
aimbotTab:AddSlider("FOV Radius", 10, 500, Configuration.FoVRadius, function(v) Configuration.FoVRadius = v end)
aimbotTab:AddToggle("Show FOV Circle", Configuration.FoVCheck, function(v) Configuration.FoVCheck = v; ShowingFoV = v end)
aimbotTab:AddToggle("Mouse Smoothing", Configuration.UseSensitivity, function(v) Configuration.UseSensitivity = v end)
aimbotTab:AddSlider("Smoothness", 10, 100, Configuration.Sensitivity, function(v) Configuration.Sensitivity = v end, "%")

aimbotTab:AddSection("Silent Aim")
aimbotTab:AddToggle("Enable Silent Aim", Configuration.SilentAim, function(v) Configuration.SilentAim = v end)
aimbotTab:AddToggle("Always On", Configuration.AlwaysOnSilent, function(v) Configuration.AlwaysOnSilent = v end)
aimbotTab:AddKeybind("Silent Aim Key", Configuration.SilentAimKey, function(v) Configuration.SilentAimKey = v end)
aimbotTab:AddToggle("Show Silent FOV", Configuration.ShowSilentFOV, function(v) Configuration.ShowSilentFOV = v end)
aimbotTab:AddSlider("Silent FOV Radius", 10, 500, Configuration.SilentFOVRadius, function(v) Configuration.SilentFOVRadius = v end)
aimbotTab:AddToggle("Use Prediction", Configuration.SilentPrediction, function(v) Configuration.SilentPrediction = v end)
aimbotTab:AddToggle("Target Visualizer", Configuration.SilentVisualizer, function(v) Configuration.SilentVisualizer = v end)
aimbotTab:AddDropdown("Target Bone", Configuration.SilentBoneDropdownValues, 1, function(opt) Configuration.SilentTargetBone = opt end)

aimbotTab:AddSection("TriggerBot")
if HAS_MOUSE1CLICK then
    aimbotTab:AddToggle("Enable TriggerBot", Configuration.TriggerBot, function(v) Configuration.TriggerBot = v end)
    aimbotTab:AddToggle("One Press Mode", Configuration.OnePressTriggeringMode, function(v) Configuration.OnePressTriggeringMode = v end)
    aimbotTab:AddToggle("Smart Trigger", Configuration.SmartTriggerBot, function(v) Configuration.SmartTriggerBot = v end)
    aimbotTab:AddKeybind("Trigger Key", Configuration.TriggerKey, function(v) Configuration.TriggerKey = v end)
    aimbotTab:AddSlider("Trigger Chance", 1, 100, Configuration.TriggerBotChance, function(v) Configuration.TriggerBotChance = v end, "%")
else
    aimbotTab:AddButton("⚠ TriggerBot Not Supported", function() end)
end

aimbotTab:AddSection("Target Checks")
aimbotTab:AddToggle("Alive Check", Configuration.AliveCheck, function(v) Configuration.AliveCheck = v end)
aimbotTab:AddToggle("Team Check", Configuration.TeamCheck, function(v) Configuration.TeamCheck = v end)
aimbotTab:AddToggle("Wall Check", Configuration.WallCheck, function(v) Configuration.WallCheck = v end)
aimbotTab:AddToggle("Friend Check", Configuration.FriendCheck, function(v) Configuration.FriendCheck = v end)
aimbotTab:AddToggle("Transparency Check", Configuration.TransparencyCheck, function(v) Configuration.TransparencyCheck = v end)

-- ================= RAGE TAB =================
local rageTab = Library:CreateTab("Rage", "")
rageTab:AddSection("Rage Settings")
rageTab:AddToggle("Enable Rage Mode", Configuration.RageMode, function(v) Configuration.RageMode = v end)
rageTab:AddToggle("Instant Kill", Configuration.InstantKill, function(v) Configuration.InstantKill = v end)
rageTab:AddSlider("Rage FOV", 10, 360, Configuration.RageFOV, function(v) Configuration.RageFOV = v end)
rageTab:AddSlider("Hit Chance", 1, 100, Configuration.HitChance, function(v) Configuration.HitChance = v end, "%")

rageTab:AddSection("SpinBot")
rageTab:AddToggle("Enable SpinBot", Configuration.SpinBot, function(v) Configuration.SpinBot = v end)
rageTab:AddSlider("Spin Velocity", 10, 100, Configuration.SpinBotVelocity, function(v) Configuration.SpinBotVelocity = v end)
rageTab:AddDropdown("Spin Part", {"HumanoidRootPart", "Head", "UpperTorso"}, 1, function(opt) Configuration.SpinPart = opt end)

rageTab:AddSection("Anti-Aim")
rageTab:AddToggle("Enable Anti-Aim", Configuration.AntiAim, function(v) Configuration.AntiAim = v end)
rageTab:AddDropdown("Anti-Aim Mode", {"Jitter", "Spin", "Static", "Random"}, 1, function(opt) Configuration.AntiAimMode = opt end)

-- ================= VISUALS TAB =================
local visualsTab = Library:CreateTab("Visuals", "")

visualsTab:AddSection("ESP Settings")

visualsTab:AddToggle("Box ESP", PreviewState.ESPBox, function(v)
    Configuration.ESPBox = v
    PreviewState.ESPBox = v
    if v then
        Configuration.CorneredBox = false
        PreviewState.CorneredBox = false
    end
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddToggle("Cornered Box", PreviewState.CorneredBox, function(v)
    Configuration.CorneredBox = v
    PreviewState.CorneredBox = v
    if v then
        Configuration.ESPBox = false
        PreviewState.ESPBox = false
    end
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddSlider("Corner Length", 2, 20, PreviewState.CornerLength, function(v)
    Configuration.CornerLength = v
    PreviewState.CornerLength = v
end)

visualsTab:AddToggle("Tracer ESP", PreviewState.TracerESP, function(v)
    Configuration.TracerESP = v
    PreviewState.TracerESP = v
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddToggle("Health ESP", PreviewState.HealthESP, function(v)
    Configuration.HealthESP = v
    PreviewState.HealthESP = v
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddToggle("Name ESP", PreviewState.NameESP, function(v)
    Configuration.NameESP = v
    PreviewState.NameESP = v
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddToggle("Skeleton ESP", PreviewState.SkeletonESP, function(v)
    Configuration.SkeletonESP = v
    PreviewState.SkeletonESP = v
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddToggle("Highlight ESP", PreviewState.HighlightESP, function(v)
    Configuration.HighlightESP = v
    PreviewState.HighlightESP = v
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddToggle("Head Circle", PreviewState.HeadCircle, function(v)
    Configuration.HeadCircle = v
    PreviewState.HeadCircle = v
    ShowingESP = Configuration.ESPBox or Configuration.CorneredBox or Configuration.NameESP
        or Configuration.HealthESP or Configuration.TracerESP or Configuration.SkeletonESP
        or Configuration.HighlightESP or Configuration.HeadCircle
end)

visualsTab:AddToggle("Filled Box", PreviewState.ESPBoxFilled, function(v)
    Configuration.ESPBoxFilled = v
    PreviewState.ESPBoxFilled = v
end)

visualsTab:AddSlider("ESP Thickness", 1, 5, PreviewState.ESPThickness, function(v)
    Configuration.ESPThickness = v
    PreviewState.ESPThickness = v
end)

visualsTab:AddSection("Background")
visualsTab:AddToggle("Snowfall Background", false, function(v)
    setSnowMode(v)
end)

-- ================= SETTINGS TAB =================
local settingsTab = Library:CreateTab("Settings", "")
settingsTab:AddSection("UI Settings")
settingsTab:AddKeybind("Menu Toggle", Configuration.ToggleKey, function(v)
    Configuration.ToggleKey = v
    CONFIG.ToggleKey = v
end)
settingsTab:AddButton("Reset Preview Position", function()
    if ESPPreview and previewContainer then
        ESPPreview.UserMoved = false
        previewContainer.Position = UDim2.new(
            mainContainer.Position.X.Scale,
            mainContainer.Position.X.Offset + BASE_WIDTH + CONFIG.PreviewGap,
            mainContainer.Position.Y.Scale,
            mainContainer.Position.Y.Offset
        )
    end
end)

-- ================================================
--   FEATURE IMPLEMENTATION
-- ================================================

local function IsReady(TargetChar)
    if not TargetChar or not TargetChar:IsA("Model") then return false end
    local Hum = TargetChar:FindFirstChildWhichIsA("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end

    local TargetPart = TargetChar:FindFirstChild(Configuration.AimPart)
    if not TargetPart or not TargetPart:IsA("BasePart") then
        TargetPart = TargetChar:FindFirstChild("Head") or TargetChar:FindFirstChild("HumanoidRootPart")
        if not TargetPart then return false end
    end

    if not LocalPlayer.Character then return false end
    local NativePart = LocalPlayer.Character:FindFirstChild("Head") or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not NativePart or not NativePart:IsA("BasePart") then return false end

    local _Player = Players:GetPlayerFromCharacter(TargetChar)
    if not _Player or _Player == LocalPlayer then return false end

    if Configuration.TeamCheck and _Player.TeamColor == LocalPlayer.TeamColor then return false end
    if Configuration.FriendCheck and _Player:IsFriendsWith(LocalPlayer.UserId) then return false end

    if Configuration.WallCheck then
        local dir = (TargetPart.Position - NativePart.Position)
        local dist = dir.Magnitude
        if dist > 0 then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { LocalPlayer.Character }
            params.IgnoreWater = not Configuration.WaterCheck
            local result = workspace:Raycast(NativePart.Position, dir.Unit * dist, params)
            if result and result.Instance then
                local hitPlr = Players:GetPlayerFromCharacter(result.Instance:FindFirstAncestorOfClass("Model"))
                if hitPlr and hitPlr ~= _Player then return false end
            end
        end
    end

    local vp, onScreen = Camera:WorldToViewportPoint(TargetPart.Position)
    if not onScreen then return false end
    return true, _Player, TargetChar, vp, TargetPart.Position, (TargetPart.Position - NativePart.Position).Magnitude
end

local function GetTargetBone(char, boneName)
    if not char then return nil end
    return char:FindFirstChild(boneName) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function CalculatePredictedPosition(targetPart, char)
    if not targetPart or not char then return targetPart.Position end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and Configuration.SilentPrediction then
        local v = root.Velocity
        return targetPart.Position + Vector3.new(
            v.X * (Configuration.SilentPredictionX or 0) * 0.1,
            v.Y * (Configuration.SilentPredictionY or 0) * 0.1,
            v.Z * (Configuration.SilentPredictionX or 0) * 0.1
        )
    end
    return targetPart.Position
end

local function IsValidSilentTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Configuration.TeamCheck and player.TeamColor == LocalPlayer.TeamColor then return false end
    if Configuration.FriendCheck and player:IsFriendsWith(LocalPlayer.UserId) then return false end
    return true
end

local function DrawSkeleton(char, color, thickness, transparency)
    local skeleton = {}
    local p = {
        Head = char:FindFirstChild("Head"),
        UpperTorso = char:FindFirstChild("UpperTorso"),
        LowerTorso = char:FindFirstChild("LowerTorso"),
        LeftUpperArm = char:FindFirstChild("LeftUpperArm"),
        LeftLowerArm = char:FindFirstChild("LeftLowerArm"),
        LeftHand = char:FindFirstChild("LeftHand"),
        RightUpperArm = char:FindFirstChild("RightUpperArm"),
        RightLowerArm = char:FindFirstChild("RightLowerArm"),
        RightHand = char:FindFirstChild("RightHand"),
        LeftUpperLeg = char:FindFirstChild("LeftUpperLeg"),
        LeftLowerLeg = char:FindFirstChild("LeftLowerLeg"),
        LeftFoot = char:FindFirstChild("LeftFoot"),
        RightUpperLeg = char:FindFirstChild("RightUpperLeg"),
        RightLowerLeg = char:FindFirstChild("RightLowerLeg"),
        RightFoot = char:FindFirstChild("RightFoot")
    }
    if not (p.Head and p.UpperTorso and p.LowerTorso) then return {} end
    local conns = {
        {p.Head, p.UpperTorso}, {p.UpperTorso, p.LowerTorso},
        {p.UpperTorso, p.LeftUpperArm}, {p.LeftUpperArm, p.LeftLowerArm}, {p.LeftLowerArm, p.LeftHand},
        {p.UpperTorso, p.RightUpperArm}, {p.RightUpperArm, p.RightLowerArm}, {p.RightLowerArm, p.RightHand},
        {p.LowerTorso, p.LeftUpperLeg}, {p.LeftUpperLeg, p.LeftLowerLeg}, {p.LeftLowerLeg, p.LeftFoot},
        {p.LowerTorso, p.RightUpperLeg}, {p.RightUpperLeg, p.RightLowerLeg}, {p.RightLowerLeg, p.RightFoot}
    }
    for _, c in ipairs(conns) do
        if c[1] and c[2] then
            local pos1, on1 = Camera:WorldToViewportPoint(c[1].Position)
            local pos2, on2 = Camera:WorldToViewportPoint(c[2].Position)
            if on1 and on2 then
                local line = Drawing.new("Line")
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Color = color; line.Thickness = thickness
                line.Transparency = transparency; line.Visible = true
                table.insert(skeleton, line)
            end
        end
    end
    return skeleton
end

local function CreateHighlight(char, color, transparency)
    local hl = Instance.new("Highlight")
    hl.Parent = char
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = transparency
    hl.OutlineTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    return hl
end

local function DrawCorneredBox(boxPos, boxSize, color, thickness, transparency, cornerLength)
    local tl = boxPos
    local tr = Vector2.new(boxPos.X + boxSize.X, boxPos.Y)
    local bl = Vector2.new(boxPos.X, boxPos.Y + boxSize.Y)
    local br = Vector2.new(boxPos.X + boxSize.X, boxPos.Y + boxSize.Y)
    local cl = math.min(cornerLength or 8, boxSize.X / 2, boxSize.Y / 2)
    local lines = {}
    local segs = {
        {tl, Vector2.new(tl.X + cl, tl.Y)},
        {tl, Vector2.new(tl.X, tl.Y + cl)},
        {Vector2.new(tr.X - cl, tr.Y), tr},
        {tr, Vector2.new(tr.X, tr.Y + cl)},
        {bl, Vector2.new(bl.X + cl, bl.Y)},
        {bl, Vector2.new(bl.X, bl.Y - cl)},
        {Vector2.new(br.X - cl, br.Y), br},
        {br, Vector2.new(br.X, br.Y - cl)},
    }
    for _, s in ipairs(segs) do
        local line = Drawing.new("Line")
        line.From = s[1]; line.To = s[2]
        line.Color = color; line.Thickness = thickness
        line.Transparency = transparency; line.Visible = true
        table.insert(lines, line)
    end
    return lines
end

local ESP = {}
local SkeletonLines = {}
local Highlights = {}
local HeadCircles = {}
local CorneredBoxLines = {}

local function newESP(plr)
    if plr == LocalPlayer then return end
    ESP[plr] = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Health = Drawing.new("Line"),
        Name = Drawing.new("Text")
    }
    SkeletonLines[plr] = {}
    Highlights[plr] = nil
    HeadCircles[plr] = Drawing.new("Circle")
    HeadCircles[plr].Thickness = 2
    HeadCircles[plr].Filled = false
    HeadCircles[plr].NumSides = 100
    HeadCircles[plr].Visible = false
    CorneredBoxLines[plr] = {}

    for _, d in pairs(ESP[plr]) do d.Visible = false end
    ESP[plr].Name.Size = 16
    ESP[plr].Name.Center = true
    ESP[plr].Name.Font = 2
    ESP[plr].Name.Outline = true
    ESP[plr].Name.OutlineColor = Color3.fromRGB(0, 0, 0)
end

for _, p in ipairs(Players:GetPlayers()) do newESP(p) end
Players.PlayerAdded:Connect(newESP)
Players.PlayerRemoving:Connect(function(p)
    if ESP[p] then for _, d in pairs(ESP[p]) do d:Remove() end; ESP[p] = nil end
    if SkeletonLines[p] then for _, l in ipairs(SkeletonLines[p]) do l:Remove() end; SkeletonLines[p] = nil end
    if Highlights[p] and Highlights[p].Parent then Highlights[p]:Destroy(); Highlights[p] = nil end
    if HeadCircles[p] then HeadCircles[p]:Remove(); HeadCircles[p] = nil end
    if CorneredBoxLines[p] then
        for _, l in ipairs(CorneredBoxLines[p]) do l:Remove() end
        CorneredBoxLines[p] = nil
    end
end)

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Configuration.FoVColour
FOVCircle.Thickness = Configuration.FoVThickness
FOVCircle.NumSides = 100
FOVCircle.Transparency = Configuration.FoVOpacity
FOVCircle.Filled = Configuration.FoVFilled
FOVCircle.Visible = false

-- ================= INPUT =================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if Configuration.Aimbot then
        local keyMatches = false
        if typeof(Configuration.AimKey) == "EnumItem" then
            keyMatches = Configuration.AimKey == Enum.UserInputType.MouseButton2 and input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Configuration.AimKey
        end
        if keyMatches then
            Aiming = Configuration.OnePressAimingMode and not Aiming or true
        end
    end

    if Configuration.TriggerBot and HAS_MOUSE1CLICK then
        local keyMatches = false
        if typeof(Configuration.TriggerKey) == "EnumItem" then
            keyMatches = Configuration.TriggerKey == Enum.UserInputType.MouseButton2 and input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Configuration.TriggerKey
        end
        if keyMatches then
            Triggering = Configuration.OnePressTriggeringMode and not Triggering or true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Configuration.Aimbot and not Configuration.OnePressAimingMode then
        local keyMatches = false
        if typeof(Configuration.AimKey) == "EnumItem" then
            keyMatches = Configuration.AimKey == Enum.UserInputType.MouseButton2 and input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Configuration.AimKey
        end
        if keyMatches then Aiming = false; Target = nil end
    end
    if Configuration.TriggerBot and not Configuration.OnePressTriggeringMode and HAS_MOUSE1CLICK then
        local keyMatches = false
        if typeof(Configuration.TriggerKey) == "EnumItem" then
            keyMatches = Configuration.TriggerKey == Enum.UserInputType.MouseButton2 and input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Configuration.TriggerKey
        end
        if keyMatches then Triggering = false end
    end
end)

-- ================= MAIN RENDER LOOP =================
local hue = 0

RunService.RenderStepped:Connect(function(dt)
    if not Character or not Character.Parent then getChar(); return end
    if not Humanoid or not HRP then return end

    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Configuration.FoVRadius
    FOVCircle.Visible = Configuration.FoVCheck and ShowingFoV
    FOVCircle.Color = Configuration.FoVColour

    if Configuration.RainbowVisuals then
        hue = (hue + dt / Configuration.RainbowDelay) % 1
        Configuration.ESPColour = Color3.fromHSV(hue, 1, 1)
        PreviewState.ESPColour = Configuration.ESPColour
        FOVCircle.Color = Configuration.ESPColour
    else
        Configuration.ESPColour = COLORS.Accent
        PreviewState.ESPColour = COLORS.Accent
    end

    -- ESP
    for plr, esp in pairs(ESP) do
        local char = plr.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if char and hum and hrp and hum.Health > 0 and plr ~= LocalPlayer then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if Configuration.HighlightESP then
                if not Highlights[plr] or not Highlights[plr].Parent then
                    Highlights[plr] = CreateHighlight(char, Configuration.ESPColour, 0.8)
                else
                    Highlights[plr].FillColor = Configuration.ESPColour
                    Highlights[plr].FillTransparency = 0.8
                end
            elseif Highlights[plr] and Highlights[plr].Parent then
                Highlights[plr]:Destroy(); Highlights[plr] = nil
            end

            if onScreen and ShowingESP then
                local headPos = head and head.Position or hrp.Position + Vector3.new(0, 2, 0)
                local headScreen, headOn = Camera:WorldToViewportPoint(headPos)
                local footPos = hrp.Position - Vector3.new(0, 2.5, 0)
                local footScreen, footOn = Camera:WorldToViewportPoint(footPos)

                if headOn and footOn then
                    local headY = headScreen.Y
                    local footY = footScreen.Y
                    local height = math.abs(footY - headY)
                    local width = height * 0.4
                    local centerX = pos.X
                    local topLeft = Vector2.new(centerX - width/2, headY)

                    esp.Box.Visible = Configuration.ESPBox
                    if Configuration.ESPBox then
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = topLeft
                        esp.Box.Color = Configuration.ESPColour
                        esp.Box.Thickness = Configuration.ESPThickness
                        esp.Box.Transparency = 0.8
                        esp.Box.Filled = Configuration.ESPBoxFilled
                    end

                    if Configuration.CorneredBox then
                        if CorneredBoxLines[plr] then
                            for _, l in ipairs(CorneredBoxLines[plr]) do l:Remove() end
                        end
                        CorneredBoxLines[plr] = DrawCorneredBox(topLeft, Vector2.new(width, height), Configuration.ESPColour, Configuration.ESPThickness, 0.8, Configuration.CornerLength)
                    elseif CorneredBoxLines[plr] then
                        for _, l in ipairs(CorneredBoxLines[plr]) do l:Remove() end
                        CorneredBoxLines[plr] = {}
                    end

                    esp.Tracer.Visible = Configuration.TracerESP
                    if Configuration.TracerESP then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                        esp.Tracer.Color = Configuration.ESPColour
                        esp.Tracer.Thickness = Configuration.ESPThickness
                        esp.Tracer.Transparency = 0.8
                    end

                    esp.Health.Visible = Configuration.HealthESP
                    if Configuration.HealthESP then
                        local hp = hum.Health / hum.MaxHealth
                        local hHeight = height * hp
                        esp.Health.From = topLeft + Vector2.new(-6, height)
                        esp.Health.To = topLeft + Vector2.new(-6, height - hHeight)
                        esp.Health.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
                        esp.Health.Thickness = 3
                    end

                    esp.Name.Visible = Configuration.NameESP
                    if Configuration.NameESP then
                        esp.Name.Position = Vector2.new(centerX, topLeft.Y - 20)
                        esp.Name.Text = plr.Name
                        esp.Name.Color = Configuration.ESPColour
                        esp.Name.Size = 14
                        esp.Name.Transparency = 0.2
                    end
                else
                    esp.Box.Visible = false
                    if CorneredBoxLines[plr] then
                        for _, l in ipairs(CorneredBoxLines[plr]) do l:Remove() end
                        CorneredBoxLines[plr] = {}
                    end
                end

                if head and Configuration.HeadCircle then
                    local hp, hOn = Camera:WorldToViewportPoint(head.Position)
                    if hOn and HeadCircles[plr] then
                        HeadCircles[plr].Visible = true
                        HeadCircles[plr].Position = Vector2.new(hp.X, hp.Y)
                        local dist = (Camera.CFrame.Position - head.Position).Magnitude
                        local radius = math.clamp(1200 / dist, 6, 30)
                        HeadCircles[plr].Radius = radius
                        HeadCircles[plr].Color = Configuration.ESPColour
                        HeadCircles[plr].Thickness = Configuration.ESPThickness
                        HeadCircles[plr].Transparency = 0.8
                    elseif HeadCircles[plr] then
                        HeadCircles[plr].Visible = false
                    end
                elseif HeadCircles[plr] then
                    HeadCircles[plr].Visible = false
                end

                if Configuration.SkeletonESP then
                    if SkeletonLines[plr] then for _, l in ipairs(SkeletonLines[plr]) do l:Remove() end end
                    SkeletonLines[plr] = DrawSkeleton(char, Configuration.ESPColour, Configuration.ESPThickness, 0.8)
                elseif SkeletonLines[plr] then
                    for _, l in ipairs(SkeletonLines[plr]) do l:Remove() end
                    SkeletonLines[plr] = {}
                end
            else
                for _, d in pairs(esp) do d.Visible = false end
                if SkeletonLines[plr] then for _, l in ipairs(SkeletonLines[plr]) do l.Visible = false end end
                if HeadCircles[plr] then HeadCircles[plr].Visible = false end
                if CorneredBoxLines[plr] then
                    for _, l in ipairs(CorneredBoxLines[plr]) do l:Remove() end
                    CorneredBoxLines[plr] = {}
                end
            end
        else
            for _, d in pairs(esp) do d.Visible = false end
            if SkeletonLines[plr] then for _, l in ipairs(SkeletonLines[plr]) do l.Visible = false end end
            if Highlights[plr] and Highlights[plr].Parent then Highlights[plr]:Destroy(); Highlights[plr] = nil end
            if HeadCircles[plr] then HeadCircles[plr].Visible = false end
            if CorneredBoxLines[plr] then
                for _, l in ipairs(CorneredBoxLines[plr]) do l:Remove() end
                CorneredBoxLines[plr] = {}
            end
        end
    end

    -- Silent Aim
    local silentKeyPressed = false
    if typeof(Configuration.SilentAimKey) == "EnumItem" then
        silentKeyPressed = Configuration.SilentAimKey == Enum.UserInputType.MouseButton2
            and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            or UserInputService:IsKeyDown(Configuration.SilentAimKey)
    end
    SilentAimActive = Configuration.SilentAim and (Configuration.AlwaysOnSilent or silentKeyPressed)

    if SilentAimActive then
        local mousePos = UserInputService:GetMouseLocation()
        local cTarget, cDist, cScreen = nil, Configuration.SilentFOVRadius, nil
        for _, player in ipairs(Players:GetPlayers()) do
            if IsValidSilentTarget(player) then
                local bone = GetTargetBone(player.Character, Configuration.SilentTargetBone)
                if bone then
                    local predPos = CalculatePredictedPosition(bone, player.Character)
                    local screenPos, onScreen = Camera:WorldToViewportPoint(predPos)
                    if onScreen then
                        local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist <= Configuration.SilentFOVRadius and dist < cDist then
                            cDist = dist; cTarget = player; cScreen = screenPos
                        end
                    end
                end
            end
        end
        SilentTarget = cTarget; SilentTargetScreenPos = cScreen
    else
        SilentTarget = nil; SilentTargetScreenPos = nil
    end

    if Configuration.ShowSilentFOV and SilentAimActive then
        if not SilentFOVCircle then
            SilentFOVCircle = Drawing.new("Circle")
            SilentFOVCircle.NumSides = 100
            SilentFOVCircle.Thickness = 2
            SilentFOVCircle.Filled = false
            SilentFOVCircle.Color = Color3.fromRGB(255, 100, 100)
            SilentFOVCircle.Transparency = 0.5
        end
        SilentFOVCircle.Position = UserInputService:GetMouseLocation()
        SilentFOVCircle.Radius = Configuration.SilentFOVRadius
        SilentFOVCircle.Visible = true
    elseif SilentFOVCircle then
        SilentFOVCircle.Visible = false
    end

    if Configuration.SilentVisualizer and SilentTarget and SilentTargetScreenPos then
        if not TargetVisualizer then
            TargetVisualizer = {
                Circle = Drawing.new("Circle"), InnerCircle = Drawing.new("Circle"),
                Line1 = Drawing.new("Line"), Line2 = Drawing.new("Line")
            }
            TargetVisualizer.Circle.NumSides = 50; TargetVisualizer.Circle.Thickness = 2; TargetVisualizer.Circle.Filled = false
            TargetVisualizer.Circle.Color = Color3.fromRGB(255, 255, 255)
            TargetVisualizer.InnerCircle.NumSides = 30; TargetVisualizer.InnerCircle.Thickness = 1; TargetVisualizer.InnerCircle.Filled = true
            TargetVisualizer.InnerCircle.Color = Color3.fromRGB(255, 0, 0); TargetVisualizer.InnerCircle.Transparency = 0.3
            TargetVisualizer.Line1.Thickness = 2; TargetVisualizer.Line2.Thickness = 2
        end
        local pos = Vector2.new(SilentTargetScreenPos.X, SilentTargetScreenPos.Y)
        TargetVisualizer.Circle.Position = pos; TargetVisualizer.Circle.Radius = 15 + math.sin(os.clock()*10)*3; TargetVisualizer.Circle.Visible = true
        TargetVisualizer.InnerCircle.Position = pos; TargetVisualizer.InnerCircle.Radius = 5; TargetVisualizer.InnerCircle.Visible = true
        TargetVisualizer.Line1.From = pos - Vector2.new(20,20); TargetVisualizer.Line1.To = pos + Vector2.new(20,20); TargetVisualizer.Line1.Visible = true
        TargetVisualizer.Line2.From = pos + Vector2.new(-20,20); TargetVisualizer.Line2.To = pos + Vector2.new(20,-20); TargetVisualizer.Line2.Visible = true
    elseif TargetVisualizer then
        for _, obj in pairs(TargetVisualizer) do obj.Visible = false end
    end

    -- Aimbot
    if Configuration.Aimbot and Aiming then
        local mousePos = UserInputService:GetMouseLocation()
        local cTarget, cDist = nil, Configuration.FoVCheck and Configuration.FoVRadius or math.huge

        if Target and Target:IsA("Model") then
            local success, _, _, vp = IsReady(Target)
            if success and vp then
                cTarget = Target
                cDist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(vp.X, vp.Y)).Magnitude
            else
                Target = nil
            end
        end

        if not Target then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local success, _, _, vp = IsReady(player.Character)
                    if success and vp then
                        local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(vp.X, vp.Y)).Magnitude
                        if (Configuration.FoVCheck and dist <= Configuration.FoVRadius or not Configuration.FoVCheck) and dist < cDist then
                            cDist = dist; cTarget = player.Character
                        end
                    end
                end
            end
        end

        if cTarget then
            Target = cTarget
            local success, _, _, vp, wp = IsReady(Target)
            if success and vp and wp then
                if Configuration.AimMode == "Camera" then
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, wp), Configuration.UseSensitivity and Configuration.Sensitivity/100 or 0.3)
                elseif Configuration.AimMode == "Mouse" and HAS_MOUSEMOVEREL then
                    local dx, dy = vp.X - mousePos.X, vp.Y - mousePos.Y
                    if Configuration.UseSensitivity then
                        local s = math.max(Configuration.Sensitivity/5, 1)
                        dx, dy = math.clamp(dx/s, -25, 25), math.clamp(dy/s, -25, 25)
                    else
                        dx, dy = math.clamp(dx, -50, 50), math.clamp(dy, -50, 50)
                    end
                    pcall(function() mousemoverel(dx, dy) end)
                end
            end
        else
            Target = nil
        end
    else
        Target = nil
    end

    -- TriggerBot
    if Configuration.TriggerBot and Triggering and HAS_MOUSE1CLICK and not (Configuration.SmartTriggerBot and not Aiming) then
        local mt = Mouse.Target
        if mt then
            local char = mt:FindFirstAncestorOfClass("Model")
            if char then
                local plr = Players:GetPlayerFromCharacter(char)
                if plr and plr ~= LocalPlayer then
                    local success = IsReady(char)
                    if success and MathHandler:CalculateChance(Configuration.TriggerBotChance) then
                        pcall(function() mouse1click() end)
                        task.wait(0.03)
                    end
                end
            end
        end
    end
end)

-- Cleanup
CoreGui.ChildRemoved:Connect(function(child)
    if child.Name == "AuroraUI" then
        if SilentFOVCircle then SilentFOVCircle:Remove() end
        if TargetVisualizer then for _, obj in pairs(TargetVisualizer) do obj:Remove() end end
        for _, esp in pairs(ESP) do
            for _, d in pairs(esp) do d:Remove() end
        end
        for _, lines in pairs(CorneredBoxLines) do
            for _, l in ipairs(lines) do l:Remove() end
        end
    end
end)

Library.PreviewState = PreviewState
Library.Preview = ESPPreview
Library.Configuration = Configuration

return Library