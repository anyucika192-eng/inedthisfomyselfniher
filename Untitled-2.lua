--[[
    BetaUI.lua
    quick n dirty ui lib, single file, drop in whatever

    -- [ULTIMATE] -- Undercover Ultimate feature set on BetaUI components
    -- [ESP PREVIEW] -- Attached preview window on the right of the menu.
    --                  Auto-follows, independently draggable, hides with menu,
    --                  shows only on the Visuals tab.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ============ CONFIG (edit me) ============
local CFG = {
    Title       = "UNDERCOVER",
    SubTitle    = "beta",
    ToggleKey   = Enum.KeyCode.RightShift,
    AccentColor = Color3.fromRGB(220, 60, 60),
    WindowSize  = Vector2.new(620, 380),

    -- [ESP PREVIEW]
    PreviewWidth   = 200,
    PreviewGap     = 12,
    PreviewEnabled = true,
    PreviewOnTab   = "Visuals",
}

-- ============ SERVICES ============
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()

local HAS_MOUSEMOVEREL = pcall(function() return mousemoverel end)
local HAS_MOUSE1CLICK  = pcall(function() return mouse1click end)

pcall(function() CoreGui:FindFirstChild("BetaUI_gui"):Destroy() end)
pcall(function() CoreGui.UndercoverSlotted:Destroy() end)

-- ============ FONT ============
local FONT      = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

-- ============ colors ============
local COL = {
    Bg       = Color3.fromRGB(22, 22, 22),
    TopBar   = Color3.fromRGB(16, 16, 16),
    TabBar   = Color3.fromRGB(18, 18, 18),
    Content  = Color3.fromRGB(22, 22, 22),
    Card     = Color3.fromRGB(28, 28, 28),
    CardHov  = Color3.fromRGB(34, 34, 34),
    Border   = Color3.fromRGB(50, 50, 50),
    Text     = Color3.fromRGB(225, 225, 225),
    TextDim  = Color3.fromRGB(130, 130, 130),
    Accent   = CFG.AccentColor,
    Success  = Color3.fromRGB(46, 204, 113),
    Danger   = Color3.fromRGB(231, 76, 60),
    Gold     = Color3.fromRGB(255, 215, 0),
}

local W, H = CFG.WindowSize.X, CFG.WindowSize.Y
local TOPBAR_H = 30
local TABBAR_H = 26

-- tween helper (pulled from the second script so tab animations match)
local function tw(obj, t, props)
    local tween = TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
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
    FoVColour = Color3.fromRGB(220, 60, 60),
    ESPBox = false, ESPBoxFilled = false, CorneredBox = false, CornerLength = 6,
    NameESP = false, HealthESP = false, TracerESP = false, SkeletonESP = false,
    HighlightESP = false, HeadCircle = false, ESPThickness = 2,
    ESPColour = Color3.fromRGB(220, 60, 60),
    RainbowVisuals = false, RainbowDelay = 5,

    RivalsSilentAim = false,

    ToggleKey = CFG.ToggleKey,
}

-- ================= STATE =================
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

-- [ESP PREVIEW] single source of truth for the preview's render loop
local PreviewState = {
    ESPBox = false, ESPBoxFilled = false, CorneredBox = false, CornerLength = 6,
    NameESP = false, HealthESP = false, TracerESP = false, SkeletonESP = false,
    HighlightESP = false, HeadCircle = false, ESPThickness = 2,
    ESPColour = CFG.AccentColor,
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

-- ============ root ============
local gui = Instance.new("ScreenGui")
gui.Name = "BetaUI_gui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
main.BackgroundColor3 = COL.Bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local outline = Instance.new("UIStroke")
outline.Color = COL.Border
outline.Thickness = 1
outline.Parent = main

-- ============ top bar ============
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
topBar.BackgroundColor3 = COL.TopBar
topBar.BorderSizePixel = 0
topBar.Parent = main

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 200, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = CFG.Title
titleLbl.Font = FONT_BOLD
titleLbl.TextSize = 14
titleLbl.TextColor3 = COL.Text
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(0, 120, 0, 14)
subLbl.Position = UDim2.new(0, 10 + titleLbl.TextBounds.X + 6, 0.5, -7)
subLbl.BackgroundTransparency = 1
subLbl.Text = CFG.SubTitle
subLbl.Font = FONT
subLbl.TextSize = 11
subLbl.TextColor3 = COL.Gold
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Parent = topBar

-- drag
do
    local dragging, startMouse, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startMouse = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startMouse
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ============ tab bar ============
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, TABBAR_H)
tabBar.Position = UDim2.new(0, 0, 0, TOPBAR_H)
tabBar.BackgroundColor3 = COL.TabBar
tabBar.BorderSizePixel = 0
tabBar.Parent = main

local tabBarLine = Instance.new("Frame")
tabBarLine.Size = UDim2.new(1, 0, 0, 1)
tabBarLine.Position = UDim2.new(0, 0, 1, -1)
tabBarLine.BackgroundColor3 = COL.Border
tabBarLine.BorderSizePixel = 0
tabBarLine.Parent = tabBar

local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -12, 1, 0)
tabHolder.Position = UDim2.new(0, 6, 0, 0)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = tabBar

local tabListLayout = Instance.new("UIListLayout")
tabListLayout.FillDirection = Enum.FillDirection.Horizontal
tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabListLayout.Padding = UDim.new(0, 2)
tabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabListLayout.Parent = tabHolder

local underline = Instance.new("Frame")
underline.Size = UDim2.new(0, 0, 0, 2)
underline.Position = UDim2.new(0, 0, 1, -2)
underline.BackgroundColor3 = COL.Accent
underline.BorderSizePixel = 0
underline.ZIndex = 5
underline.Parent = tabBar
underline.Visible = false

-- ============ content area ============
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -(TOPBAR_H + TABBAR_H))
content.Position = UDim2.new(0, 0, 0, TOPBAR_H + TABBAR_H)
content.BackgroundColor3 = COL.Content
content.BorderSizePixel = 0
content.ClipsDescendants = true
content.Parent = main

-- footer / watermark text bottom right (styled like the second script)
local wm = Instance.new("TextLabel")
wm.Name = "Footer"
wm.Size = UDim2.new(0, 220, 0, 14)
wm.Position = UDim2.new(1, -226, 1, -18)
wm.BackgroundTransparency = 1
wm.Text = "work in progress - stuff might break"
wm.Font = Enum.Font.Gotham
wm.TextSize = 9
wm.TextColor3 = COL.TextDim
wm.TextTransparency = 0.4
wm.TextXAlignment = Enum.TextXAlignment.Right
wm.ZIndex = 10
wm.Parent = content

-- ============ show/hide ============
local visible = true

-- ================= ESP PREVIEW =================
local ESPPreview
local previewContainer, previewFrame, previewContent

if CFG.PreviewEnabled then
    ESPPreview = { Visible = false, UserMoved = false }

    local PW = CFG.PreviewWidth
    local PH = H
    local GAP = CFG.PreviewGap

    previewContainer = Instance.new("Frame")
    previewContainer.Name = "PreviewContainer"
    previewContainer.Size = UDim2.new(0, PW, 0, PH)
    previewContainer.Position = UDim2.new(0.5, W/2 + GAP, 0.5, -PH/2)
    previewContainer.BackgroundTransparency = 1
    previewContainer.Visible = false
    previewContainer.Active = true
    previewContainer.Parent = gui

    previewFrame = Instance.new("Frame")
    previewFrame.Size = UDim2.new(1, 0, 1, 0)
    previewFrame.BackgroundColor3 = COL.Bg
    previewFrame.BorderSizePixel = 0
    previewFrame.ClipsDescendants = true
    previewFrame.Parent = previewContainer

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = COL.Border
    pStroke.Thickness = 1
    pStroke.Parent = previewFrame

    local pTopBar = Instance.new("Frame")
    pTopBar.Size = UDim2.new(1, 0, 0, TOPBAR_H)
    pTopBar.BackgroundColor3 = COL.TopBar
    pTopBar.BorderSizePixel = 0
    pTopBar.Parent = previewFrame

    local pTitleLine = Instance.new("Frame")
    pTitleLine.Size = UDim2.new(1, 0, 0, 1)
    pTitleLine.Position = UDim2.new(0, 0, 1, -1)
    pTitleLine.BackgroundColor3 = COL.Border
    pTitleLine.BorderSizePixel = 0
    pTitleLine.Parent = pTopBar

    local pTitle = Instance.new("TextLabel")
    pTitle.Size = UDim2.new(1, -20, 1, 0)
    pTitle.Position = UDim2.new(0, 10, 0, 0)
    pTitle.BackgroundTransparency = 1
    pTitle.Text = "ESP PREVIEW"
    pTitle.Font = FONT_BOLD
    pTitle.TextSize = 12
    pTitle.TextColor3 = COL.Text
    pTitle.TextXAlignment = Enum.TextXAlignment.Left
    pTitle.Parent = pTopBar

    previewContent = Instance.new("Frame")
    previewContent.Size = UDim2.new(1, -12, 1, -50)
    previewContent.Position = UDim2.new(0, 6, 0, TOPBAR_H + 6)
    previewContent.BackgroundColor3 = COL.Content
    previewContent.BorderSizePixel = 0
    previewContent.Parent = previewFrame

    local pContentStroke = Instance.new("UIStroke")
    pContentStroke.Color = COL.Border
    pContentStroke.Thickness = 1
    pContentStroke.Parent = previewContent

    -- ---- PREVIEW DRAG (independent of menu) ----
    do
        local dragging, startMouse, startPos
        pTopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                ESPPreview.UserMoved = true
                startMouse = input.Position
                startPos = previewContainer.Position
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - startMouse
                previewContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
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

    local function syncToMenu()
        if ESPPreview.UserMoved then return end
        if not main.Visible then return end
        previewContainer.Position = UDim2.new(
            main.Position.X.Scale,
            main.Position.X.Offset + W + GAP,
            main.Position.Y.Scale,
            main.Position.Y.Offset
        )
    end
    main:GetPropertyChangedSignal("Position"):Connect(syncToMenu)
    main:GetPropertyChangedSignal("Visible"):Connect(syncToMenu)
    syncToMenu()

    function ESPPreview:Show()
        if self.Visible then return end
        self.Visible = true
        previewContainer.Visible = true
        syncToMenu()
    end

    function ESPPreview:Hide()
        if not self.Visible and not previewContainer.Visible then
            clearPreview()
            return
        end
        self.Visible = false
        previewContainer.Visible = false
        clearPreview()
    end

    function ESPPreview:Toggle()
        if self.Visible then self:Hide() else self:Show() end
    end

    -- Render loop
    RunService.RenderStepped:Connect(function()
        if not ESPPreview.Visible or not previewContainer.Visible or not main.Visible then
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

        local espColor = PreviewState.ESPColour or COL.Accent
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

-- ============ menu toggle (wired to preview) ============
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Configuration.ToggleKey then
        visible = not visible
        main.Visible = visible
        if ESPPreview then
            if visible then
                if _G.__beta_activeTabName == CFG.PreviewOnTab then ESPPreview:Show() end
            else
                ESPPreview:Hide()
            end
        end
    end
end)

-- ============================================
--   COMPONENTS
-- ============================================
local Library = {}
Library.Tabs = {}
_G.__beta_activeTabName = nil

local activeTab = nil
local openDrop = nil

function Library:CreateTab(name)
    local idx = #Library.Tabs

    local btn = Instance.new("TextButton")
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.Size = UDim2.new(0, 0, 1, -4)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.LayoutOrder = idx
    btn.Parent = tabHolder

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = FONT_BOLD
    lbl.TextSize = 12
    lbl.TextColor3 = COL.TextDim
    lbl.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
    end)

    local order = 0

    local function select()
        if activeTab then
            activeTab.page.Visible = false
            activeTab.lbl.TextColor3 = COL.TextDim
        end
        page.Visible = true
        lbl.TextColor3 = COL.Text
        underline.Visible = true
        -- animated underline slide (matches the second script)
        tw(underline, 0.15, {
            Position = UDim2.new(0, btn.AbsolutePosition.X - tabBar.AbsolutePosition.X, 1, -2),
            Size = UDim2.new(0, btn.AbsoluteSize.X, 0, 2),
        })
        activeTab = { page = page, lbl = lbl }
        _G.__beta_activeTabName = name

        if ESPPreview then
            if name == CFG.PreviewOnTab and main.Visible then
                ESPPreview:Show()
            else
                ESPPreview:Hide()
            end
        end
    end

    btn.MouseButton1Click:Connect(select)
    btn.MouseEnter:Connect(function()
        if activeTab and activeTab.lbl == lbl then return end
        lbl.TextColor3 = COL.Text
    end)
    btn.MouseLeave:Connect(function()
        if activeTab and activeTab.lbl == lbl then return end
        lbl.TextColor3 = COL.TextDim
    end)

    if #Library.Tabs == 0 then
        task.defer(select)
    end

    local Tab = {}

    local function nextOrder()
        order = order + 2
        return order
    end

    local function card(height)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, 0, 0, height)
        c.BackgroundColor3 = COL.Card
        c.BorderSizePixel = 0
        c.LayoutOrder = nextOrder()
        c.Parent = page
        return c
    end

    function Tab:AddSection(text)
        local s = Instance.new("Frame")
        s.Size = UDim2.new(1, 0, 0, 18)
        s.BackgroundTransparency = 1
        s.LayoutOrder = nextOrder()
        s.Parent = page

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = string.upper(text)
        l.Font = FONT_BOLD
        l.TextSize = 10
        l.TextColor3 = COL.Accent
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = s
        return s
    end

    function Tab:AddButton(text, callback)
        local c = card(28)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 1, 0)
        b.BackgroundTransparency = 1
        b.Text = ""
        b.AutoButtonColor = false
        b.Parent = c

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = FONT
        l.TextSize = 12
        l.TextColor3 = COL.Text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = c

        b.MouseEnter:Connect(function() c.BackgroundColor3 = COL.CardHov end)
        b.MouseLeave:Connect(function() c.BackgroundColor3 = COL.Card end)
        b.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
        return c
    end

    -- toggle: blocky checkbox, no X mark, just fills solid when on
    function Tab:AddToggle(text, default, callback)
        local c = card(28)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -44, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = FONT
        l.TextSize = 12
        l.TextColor3 = COL.Text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = c

        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 16, 0, 16)
        box.Position = UDim2.new(1, -26, 0.5, -8)
        box.BackgroundColor3 = default and COL.Accent or COL.Card
        box.BorderSizePixel = 0
        box.Parent = c

        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = default and COL.Accent or COL.Border
        boxStroke.Thickness = 1
        boxStroke.Parent = box

        local click = Instance.new("TextButton")
        click.Size = UDim2.new(1, 0, 1, 0)
        click.BackgroundTransparency = 1
        click.Text = ""
        click.AutoButtonColor = false
        click.Parent = c

        local state = default
        click.MouseButton1Click:Connect(function()
            state = not state
            tw(box, 0.1, { BackgroundColor3 = state and COL.Accent or COL.Card })
            tw(boxStroke, 0.1, { Color = state and COL.Accent or COL.Border })
            if callback then callback(state) end
        end)
        return c
    end

    function Tab:AddSlider(text, min, max, default, callback, suffix)
        suffix = suffix or ""
        local c = card(38)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0, 160, 0, 14)
        l.Position = UDim2.new(0, 10, 0, 4)
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = FONT
        l.TextSize = 12
        l.TextColor3 = COL.Text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = c

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 60, 0, 14)
        valLbl.Position = UDim2.new(1, -70, 0, 4)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(default) .. suffix
        valLbl.Font = FONT_BOLD
        valLbl.TextSize = 12
        valLbl.TextColor3 = COL.Accent
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = c

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 4)
        track.Position = UDim2.new(0, 10, 0, 24)
        track.BackgroundColor3 = COL.Border
        track.BorderSizePixel = 0
        track.Parent = c

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = COL.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track

        local dragging = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = min + rel * (max - min)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valLbl.Text = tostring(math.floor(val * 100) / 100) .. suffix
            if callback then callback(val) end
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end)
        return c
    end

    function Tab:AddDropdown(text, options, defaultIndex, callback)
        local rowOrder = nextOrder()
        local index = defaultIndex or 1

        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, 0, 0, 28)
        c.BackgroundColor3 = COL.Card
        c.BorderSizePixel = 0
        c.ClipsDescendants = false
        c.LayoutOrder = rowOrder
        c.Parent = page

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0, 150, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = FONT
        l.TextSize = 12
        l.TextColor3 = COL.Text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = c

        local ddBtn = Instance.new("TextButton")
        ddBtn.Size = UDim2.new(0, 150, 0, 20)
        ddBtn.Position = UDim2.new(1, -160, 0.5, -10)
        ddBtn.BackgroundColor3 = COL.Bg
        ddBtn.BorderSizePixel = 0
        ddBtn.AutoButtonColor = false
        ddBtn.Text = ""
        ddBtn.Parent = c

        local ddLbl = Instance.new("TextLabel")
        ddLbl.Size = UDim2.new(1, -16, 1, 0)
        ddLbl.Position = UDim2.new(0, 8, 0, 0)
        ddLbl.BackgroundTransparency = 1
        ddLbl.Text = tostring(options[index] or options[1])
        ddLbl.Font = FONT
        ddLbl.TextSize = 12
        ddLbl.TextColor3 = COL.Text
        ddLbl.TextXAlignment = Enum.TextXAlignment.Left
        ddLbl.Parent = ddBtn

        local body = Instance.new("Frame")
        body.Size = UDim2.new(1, 0, 0, 0)
        body.BackgroundColor3 = COL.Bg
        body.BorderSizePixel = 0
        body.ClipsDescendants = true
        body.LayoutOrder = rowOrder + 1
        body.Parent = page

        local bodyLayout = Instance.new("UIListLayout")
        bodyLayout.Parent = body

        local rowH = 22
        local open = false

        local function closeBody()
            open = false
            tw(body, 0.12, { Size = UDim2.new(1, 0, 0, 0) })
        end
        local function openBody()
            if openDrop and openDrop ~= closeBody then openDrop() end
            open = true
            openDrop = closeBody
            tw(body, 0.15, { Size = UDim2.new(1, 0, 0, rowH * #options) })
        end

        for i, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, rowH)
            ob.BackgroundTransparency = 1
            ob.AutoButtonColor = false
            ob.Text = ""
            ob.LayoutOrder = i
            ob.Parent = body

            local ol = Instance.new("TextLabel")
            ol.Size = UDim2.new(1, -16, 1, 0)
            ol.Position = UDim2.new(0, 10, 0, 0)
            ol.BackgroundTransparency = 1
            ol.Text = tostring(opt)
            ol.Font = FONT
            ol.TextSize = 12
            ol.TextColor3 = i == index and COL.Accent or COL.TextDim
            ol.TextXAlignment = Enum.TextXAlignment.Left
            ol.Parent = ob

            ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0.9 end)
            ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)

            ob.MouseButton1Click:Connect(function()
                index = i
                ddLbl.Text = tostring(opt)
                for _, ch in ipairs(body:GetChildren()) do
                    if ch:IsA("TextButton") then
                        local ll = ch:FindFirstChildOfClass("TextLabel")
                        if ll then
                            ll.TextColor3 = (ch == ob) and COL.Accent or COL.TextDim
                        end
                    end
                end
                closeBody()
                if callback then callback(opt, i) end
            end)
        end

        ddBtn.MouseButton1Click:Connect(function()
            if open then closeBody() else openBody() end
        end)

        return c
    end

    function Tab:AddKeybind(text, defaultKey, callback)
        local c = card(28)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -100, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = FONT
        l.TextSize = 12
        l.TextColor3 = COL.Text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = c

        local keyBtn = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0, 80, 0, 20)
        keyBtn.Position = UDim2.new(1, -90, 0.5, -10)
        keyBtn.BackgroundColor3 = COL.Bg
        keyBtn.BorderSizePixel = 0
        keyBtn.AutoButtonColor = false
        keyBtn.Text = defaultKey and (defaultKey.Name or "RMB") or "none"
        keyBtn.Font = FONT_BOLD
        keyBtn.TextSize = 11
        keyBtn.TextColor3 = COL.Accent
        keyBtn.Parent = c

        local listening = false
        keyBtn.MouseButton1Click:Connect(function()
            listening = true
            keyBtn.Text = "..."
        end)
        UserInputService.InputBegan:Connect(function(input)
            if not listening then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keyBtn.Text = input.KeyCode.Name
                listening = false
                if callback then callback(input.KeyCode) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                keyBtn.Text = "RMB"
                listening = false
                if callback then callback(Enum.UserInputType.MouseButton2) end
            end
        end)
        return c
    end

    -- expose the page so external code can add custom frames to it
    Tab.page = page

    Library.Tabs[#Library.Tabs + 1] = Tab
    return Tab
end

-- ============================================
--   ULTIMATE MENU
-- ============================================

-- ================= AIMBOT TAB =================
local aimbotTab = Library:CreateTab("Aimbot")
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
-- wiped clean: single unbound toggle + info box describing how it works
local rageTab = Library:CreateTab("Rage")
rageTab:AddSection("Rage")
rageTab:AddToggle("Rivals Silent Aim", Configuration.RivalsSilentAim, function(v)
    Configuration.RivalsSilentAim = v
    -- intentionally not bound to anything
end)

-- about / how-it-works text box
do
    local infoCard = Instance.new("Frame")
    infoCard.Size = UDim2.new(1, 0, 0, 0)
    infoCard.AutomaticSize = Enum.AutomaticSize.Y
    infoCard.BackgroundColor3 = COL.Card
    infoCard.BorderSizePixel = 0
    infoCard.LayoutOrder = 1000
    infoCard.Parent = rageTab.page

    local infoStroke = Instance.new("UIStroke")
    infoStroke.Color = COL.Border
    infoStroke.Thickness = 1
    infoStroke.Parent = infoCard

    local infoPad = Instance.new("UIPadding")
    infoPad.PaddingTop = UDim.new(0, 8)
    infoPad.PaddingBottom = UDim.new(0, 8)
    infoPad.PaddingLeft = UDim.new(0, 12)
    infoPad.PaddingRight = UDim.new(0, 12)
    infoPad.Parent = infoCard

    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, 0, 0, 0)
    infoText.AutomaticSize = Enum.AutomaticSize.Y
    infoText.BackgroundTransparency = 1
    infoText.Text = table.concat({
        "HOW IT WORKS",
        "",
        "Rivals Silent Aim is a bit broken",
        "When you turn it on you can shoot once with mouse1",
        "And when you press down mouse2 it shoots continuesly",
        "",
        "WHEN YOU TURN IT ON IT WILL BREAK NORMAL ESP",
        "USE CHAMS AS ESP WHEN TURNED ON FOR WALLHACKS",
        "",
        "Will try to fix",
    }, "\n")
    infoText.Font = FONT
    infoText.TextSize = 11
    infoText.TextColor3 = COL.TextDim
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.TextWrapped = true
    infoText.RichText = false
    infoText.Parent = infoCard
end

-- ================= VISUALS TAB =================
local visualsTab = Library:CreateTab("Visuals")

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

visualsTab:AddToggle("Chams", PreviewState.HighlightESP, function(v)
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

-- ================= SETTINGS TAB =================
local settingsTab = Library:CreateTab("Settings")
settingsTab:AddSection("UI Settings")
settingsTab:AddKeybind("Menu Toggle", Configuration.ToggleKey, function(v)
    Configuration.ToggleKey = v
    CFG.ToggleKey = v
end)
settingsTab:AddButton("Reset Preview Position", function()
    if ESPPreview and previewContainer then
        ESPPreview.UserMoved = false
        previewContainer.Position = UDim2.new(
            main.Position.X.Scale,
            main.Position.X.Offset + W + CFG.PreviewGap,
            main.Position.Y.Scale,
            main.Position.Y.Offset
        )
    end
end)

-- ============================================
--   FEATURE IMPLEMENTATION
-- ============================================

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
        Configuration.ESPColour = COL.Accent
        PreviewState.ESPColour = COL.Accent
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
                        esp.Name.Transparency = 0.8
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
    if child.Name == "BetaUI_gui" then
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
