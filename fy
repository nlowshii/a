local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- System Loading Lucide Icons
local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
Icons.SetIconsType("lucide")

local function GetIcon(name)
    local ok, result = pcall(function() return Icons.Icon2(name) end)
    if ok and result then return result end
    return nil
end

local function ApplyIcon(img, iconData)
    if not iconData then return end
    local isStr = typeof(iconData) == "string"
    img.Image = isStr and iconData or iconData[1]
    if not isStr and iconData[2] then
        img.ImageRectSize = iconData[2].ImageRectSize
        img.ImageRectOffset = iconData[2].ImageRectPosition
    end
end

-- Main Library Config & Theme
local WindUI = {
    CurrentTheme = {
        Accent      = Color3.fromRGB(210, 32, 32),
        AccentDark  = Color3.fromRGB(140, 18, 18),
        Background  = Color3.fromRGB(8, 8, 10),
        Secondary   = Color3.fromRGB(14, 14, 17),
        Tertiary    = Color3.fromRGB(22, 22, 27),
        Text        = Color3.fromRGB(240, 240, 245),
        SubText     = Color3.fromRGB(118, 118, 132),
        Border      = Color3.fromRGB(30, 30, 37),
        BorderLight = Color3.fromRGB(46, 46, 58),
    },
    CurrentFont = Enum.Font.GothamMedium,
    ScreenGui   = nil,
    NotifyGui   = nil,
    Closed      = false,
    Connections = {}
}

-- Global Animation Helper
local function Tween(obj, info, goal)
    local t = TweenService:Create(obj,
        TweenInfo.new(info.Time or 0.3, info.Style or Enum.EasingStyle.Quart, info.Dir or Enum.EasingDirection.Out),
        goal)
    t:Play()
    return t
end

-- Dynamic Accent Theme Color Recalculator
function WindUI:ApplyThemeAccent(newAccent, newAccentDark)
    local oldAccent = self.CurrentTheme.Accent

    self.CurrentTheme.AccentDark = newAccentDark or Color3.fromRGB(
        math.floor(newAccent.R * 255 * 0.65),
        math.floor(newAccent.G * 255 * 0.65),
        math.floor(newAccent.B * 255 * 0.65)
    )
    if not self.ScreenGui then
        self.CurrentTheme.Accent = newAccent
        return
    end

    local border = self.CurrentTheme.Border

    local function isAccent(c)
        return math.abs(c.R - oldAccent.R) < 0.05
           and math.abs(c.G - oldAccent.G) < 0.05
           and math.abs(c.B - oldAccent.B) < 0.05
    end

    local function isBorder(c)
        return math.abs(c.R - border.R) < 0.03
           and math.abs(c.G - border.G) < 0.03
           and math.abs(c.B - border.B) < 0.03
    end

    local function isNeutral(c)
        return (c.R > 0.95 and c.G > 0.95 and c.B > 0.95)
            or (c.R < 0.05 and c.G < 0.05 and c.B < 0.05)
    end

    local function UpdateAccentColor(inst)
        for _, child in ipairs(inst:GetDescendants()) do
            if child.Name == "SwatchBtn" then continue end
            local p = child.Parent
            if p and p.Name == "SwatchBtn" then continue end
            if child.Name == "NoAccent" then continue end
            if p and p.Name == "NoAccent" then continue end
            
            local skipAncestor = false
            local check = child.Parent
            while check and check ~= inst do
                if check.Name == "NoAccent" then skipAncestor = true break end
                check = check.Parent
            end
            if skipAncestor then continue end

            if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("CanvasGroup") then
                if isAccent(child.BackgroundColor3) then
                    child.BackgroundColor3 = newAccent
                end
            end
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                if isAccent(child.TextColor3) then
                    child.TextColor3 = newAccent
                end
            end
            if child:IsA("ImageLabel") then
                if isAccent(child.ImageColor3) then
                    child.ImageColor3 = newAccent
                end
            end
            if child:IsA("UIStroke") then
                if isAccent(child.Color) and not isBorder(child.Color) and not isNeutral(child.Color) then
                    child.Color = newAccent
                end
            end
            if child:IsA("ScrollingFrame") then
                if isAccent(child.ScrollBarImageColor3) then
                    child.ScrollBarImageColor3 = newAccent
                end
            end
        end
    end

    UpdateAccentColor(self.ScreenGui)
    self.CurrentTheme.Accent = newAccent
    if self.NotifyGui then
        UpdateAccentColor(self.NotifyGui)
    end
end

-- Prestige Compact Notifications System
function WindUI:Notify(title, text, duration)
    if not self.NotifyGui then
        self.NotifyGui = Instance.new("ScreenGui", CoreGui)
        self.NotifyGui.Name = "WindUI_Notifications"
        local holder = Instance.new("Frame", self.NotifyGui)
        holder.Name = "Holder"
        holder.Size = UDim2.new(0, 280, 1, 0)
        holder.Position = UDim2.new(1, -292, 0, 0)
        holder.BackgroundTransparency = 1
        local layout = Instance.new("UIListLayout", holder)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.Padding = UDim.new(0, 6)
        local pad = Instance.new("UIPadding", holder)
        pad.PaddingBottom = UDim.new(0, 22)
    end

    local nFrame = Instance.new("Frame", self.NotifyGui.Holder)
    nFrame.Size = UDim2.new(1, 0, 0, 60)
    nFrame.BackgroundColor3 = self.CurrentTheme.Secondary
    nFrame.BackgroundTransparency = 1
    Instance.new("UICorner", nFrame).CornerRadius = UDim.new(0, 7)

    local nStroke = Instance.new("UIStroke", nFrame)
    nStroke.Color = self.CurrentTheme.Border
    nStroke.Transparency = 1
    nStroke.Thickness = 1

    local accentBar = Instance.new("Frame", nFrame)
    accentBar.Size = UDim2.new(0, 2, 0, 30)
    accentBar.Position = UDim2.new(0, 0, 0.5, -15)
    accentBar.BackgroundColor3 = self.CurrentTheme.Accent
    accentBar.BackgroundTransparency = 1
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

    local topGlow = Instance.new("Frame", nFrame)
    topGlow.Size = UDim2.new(1, 0, 0, 1)
    topGlow.Position = UDim2.new(0, 0, 0, 0)
    topGlow.BackgroundColor3 = self.CurrentTheme.Accent
    topGlow.BackgroundTransparency = 1
    Instance.new("UICorner", topGlow).CornerRadius = UDim.new(0, 7)

    local tLbl = Instance.new("TextLabel", nFrame)
    tLbl.Text = title:upper()
    tLbl.Size = UDim2.new(1, -38, 0, 16)
    tLbl.Position = UDim2.new(0, 14, 0, 10)
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextColor3 = self.CurrentTheme.Accent
    tLbl.TextSize = 9
    tLbl.BackgroundTransparency = 1
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.TextTransparency = 1

    local sLbl = Instance.new("TextLabel", nFrame)
    sLbl.Text = text
    sLbl.Size = UDim2.new(1, -28, 0, 22)
    sLbl.Position = UDim2.new(0, 14, 0, 28)
    sLbl.Font = Enum.Font.GothamMedium
    sLbl.TextColor3 = self.CurrentTheme.Text
    sLbl.TextSize = 10
    sLbl.BackgroundTransparency = 1
    sLbl.TextXAlignment = Enum.TextXAlignment.Left
    sLbl.TextYAlignment = Enum.TextYAlignment.Top
    sLbl.TextWrapped = true
    sLbl.TextTransparency = 1

    local progTrack = Instance.new("Frame", nFrame)
    progTrack.Size = UDim2.new(1, 0, 0, 2)
    progTrack.Position = UDim2.new(0, 0, 1, -2)
    progTrack.BackgroundColor3 = self.CurrentTheme.Border
    progTrack.BackgroundTransparency = 1
    Instance.new("UICorner", progTrack).CornerRadius = UDim.new(1, 0)

    local progFill = Instance.new("Frame", progTrack)
    progFill.Size = UDim2.new(1, 0, 1, 0)
    progFill.BackgroundColor3 = self.CurrentTheme.Accent
    progFill.BackgroundTransparency = 1
    Instance.new("UICorner", progFill).CornerRadius = UDim.new(1, 0)

    nFrame.Position = UDim2.new(0, 0, 0, 70)
    Tween(nFrame,    {Time = 0.35, Style = Enum.EasingStyle.Quart}, {Position = UDim2.new(0,0,0,0), BackgroundTransparency = 0})
    Tween(nStroke,   {Time = 0.35}, {Transparency = 0.3})
    Tween(accentBar, {Time = 0.35}, {BackgroundTransparency = 0})
    Tween(topGlow,   {Time = 0.35}, {BackgroundTransparency = 0.6})
    Tween(tLbl,      {Time = 0.35}, {TextTransparency = 0})
    Tween(sLbl,      {Time = 0.35}, {TextTransparency = 0})
    Tween(progTrack, {Time = 0.35}, {BackgroundTransparency = 0.7})
    Tween(progFill,  {Time = 0.35}, {BackgroundTransparency = 0})

    task.delay(0.35, function()
        Tween(progFill, {Time = (duration or 4) - 0.35, Style = Enum.EasingStyle.Linear}, {Size = UDim2.new(0,0,1,0)})
    end)

    task.delay(duration or 4, function()
        Tween(nFrame,    {Time = 0.3, Style = Enum.EasingStyle.Quart, Dir = Enum.EasingDirection.In}, {Position = UDim2.new(0,0,0,-70), BackgroundTransparency = 1})
        Tween(nStroke,   {Time = 0.25}, {Transparency = 1})
        Tween(tLbl,      {Time = 0.25}, {TextTransparency = 1})
        Tween(sLbl,      {Time = 0.25}, {TextTransparency = 1})
        Tween(accentBar, {Time = 0.25}, {BackgroundTransparency = 1})
        task.wait(0.35)
        nFrame:Destroy()
    end)
end

-- Fixed Draggable Helper (Anti Analog Jumps on Mobile Multi-touch)
local function MakeDraggable(dragPart, mainFrame)
    local dragging, dragStart, startPos, dragInput
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            dragInput = nil
        end
    end)
end

-- Creation of MainWindow
function WindUI:CreateWindow(title)
    if not self.ScreenGui then
        self.ScreenGui = Instance.new("ScreenGui", CoreGui)
        self.ScreenGui.Name = "fyor_UI"
        self.ScreenGui.ResetOnSpawn = false
    end

    local container = Instance.new("Frame", self.ScreenGui)
    container.Name = "UI_Container"
    container.Size = UDim2.new(0, 540, 0, 390)
    container.Position = UDim2.new(0.5, -270, 0.5, -195)
    container.BackgroundTransparency = 1

    local main = Instance.new("CanvasGroup", container)
    main.Name = "MainFrame"
    main.Size = UDim2.new(1, 0, 1, 0)
    main.BackgroundColor3 = self.CurrentTheme.Background
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 7)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = self.CurrentTheme.Border
    mainStroke.Thickness = 1

    local topBar = Instance.new("Frame", main)
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 48)
    topBar.BackgroundColor3 = self.CurrentTheme.Secondary
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 7)

    local topSep = Instance.new("Frame", main)
    topSep.Size = UDim2.new(1, 0, 0, 1)
    topSep.Position = UDim2.new(0, 0, 0, 48)
    topSep.BackgroundColor3 = self.CurrentTheme.Border

    local accentBar = Instance.new("Frame", topBar)
    accentBar.Size = UDim2.new(0, 2, 0, 26)
    accentBar.Position = UDim2.new(0, 14, 0.5, -13)
    accentBar.BackgroundColor3 = self.CurrentTheme.Accent
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

    local titleLbl = Instance.new("TextLabel", topBar)
    titleLbl.Text = title:upper()
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12
    titleLbl.TextColor3 = self.CurrentTheme.Text
    titleLbl.Position = UDim2.new(0, 22, 0, 8)
    titleLbl.Size = UDim2.new(0.45, 0, 0, 16)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local subLbl = Instance.new("TextLabel", topBar)
    subLbl.Text = "Freemium  |  Version 4.0"
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 9
    subLbl.TextColor3 = self.CurrentTheme.SubText
    subLbl.Position = UDim2.new(0, 22, 0, 26)
    subLbl.Size = UDim2.new(0.45, 0, 0, 13)
    subLbl.BackgroundTransparency = 1
    subLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Prestige Style Top Bar Search Engine
    local topSearchBox = Instance.new("Frame", topBar)
    topSearchBox.Size = UDim2.new(0, 140, 0, 26)
    topSearchBox.Position = UDim2.new(1, -220, 0.5, -13)
    topSearchBox.BackgroundColor3 = self.CurrentTheme.Tertiary
    Instance.new("UICorner", topSearchBox).CornerRadius = UDim.new(0, 6)
    local topSearchStroke = Instance.new("UIStroke", topSearchBox)
    topSearchStroke.Color = self.CurrentTheme.Border
    topSearchStroke.Thickness = 1

    local topSearchIco = Instance.new("ImageLabel", topSearchBox)
    topSearchIco.Size = UDim2.new(0, 11, 0, 11)
    topSearchIco.Position = UDim2.new(0, 8, 0.5, -5.5)
    topSearchIco.BackgroundTransparency = 1
    topSearchIco.ImageColor3 = self.CurrentTheme.SubText
    topSearchIco.ScaleType = Enum.ScaleType.Fit
    task.spawn(function() ApplyIcon(topSearchIco, GetIcon("search")) end)

    local topSearchInput = Instance.new("TextBox", topSearchBox)
    topSearchInput.Size = UDim2.new(1, -26, 1, 0)
    topSearchInput.Position = UDim2.new(0, 22, 0, 0)
    topSearchInput.BackgroundTransparency = 1
    topSearchInput.Font = Enum.Font.Gotham
    topSearchInput.Text = ""
    topSearchInput.PlaceholderText = "Search features..."
    topSearchInput.TextColor3 = self.CurrentTheme.Text
    topSearchInput.PlaceholderColor3 = self.CurrentTheme.SubText
    topSearchInput.TextSize = 10
    topSearchInput.TextXAlignment = Enum.TextXAlignment.Left
    topSearchInput.ClearTextOnFocus = false

    -- Performance Badge (FPS Counter)
    local fpsBadge = Instance.new("Frame", topBar)
    fpsBadge.Name = "FPSBadge"
    fpsBadge.Size = UDim2.new(0, 54, 0, 20)
    fpsBadge.Position = UDim2.new(1, -68, 0.5, -10)
    fpsBadge.BackgroundColor3 = self.CurrentTheme.Tertiary
    Instance.new("UICorner", fpsBadge).CornerRadius = UDim.new(0, 6)
    local fpsBadgeStroke = Instance.new("UIStroke", fpsBadge)
    fpsBadgeStroke.Color = self.CurrentTheme.Border
    fpsBadgeStroke.Thickness = 1
    local fpsLabel = Instance.new("TextLabel", fpsBadge)
    fpsLabel.Size = UDim2.new(1, 0, 1, 0)
    fpsLabel.Text = "FPS: --"
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 9
    fpsLabel.TextColor3 = self.CurrentTheme.SubText
    fpsLabel.BackgroundTransparency = 1

    local fpsTimer, fpsCount = 0, 0
    local fpsConn = RunService.RenderStepped:Connect(function(dt)
        fpsCount = fpsCount + 1
        fpsTimer = fpsTimer + dt
        if fpsTimer >= 0.5 then
            fpsLabel.Text = "FPS: " .. math.round(fpsCount / fpsTimer)
            fpsTimer, fpsCount = 0, 0
        end
    end)
    table.insert(self.Connections, fpsConn)

    MakeDraggable(topBar, container)

    -- Dynamic Interactive Resize Engine
    local MIN_W, MIN_H = 420, 300
    local MAX_W, MAX_H = 800, 600
    local resizeHandle = Instance.new("Frame", main)
    resizeHandle.Size = UDim2.new(0, 15, 0, 15)
    resizeHandle.Position = UDim2.new(1, -15, 1, -15)
    resizeHandle.BackgroundTransparency = 1
    
    local resizeBtn = Instance.new("TextButton", resizeHandle)
    resizeBtn.Size = UDim2.new(1,0,1,0)
    resizeBtn.BackgroundTransparency = 1
    resizeBtn.Text = ""

    local resizing, resizeStart, startSize = false, nil, nil
    resizeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = Vector2.new(container.AbsoluteSize.X, container.AbsoluteSize.Y)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newW = math.clamp(startSize.X + delta.X, MIN_W, MAX_W)
            local newH = math.clamp(startSize.Y + delta.Y, MIN_H, MAX_H)
            container.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    -- Floating Close/Open Hotkey Toggle UI Button (Safe from Analog Conflicts)
    local toggleBtn = Instance.new("TextButton", self.ScreenGui)
    toggleBtn.Size = UDim2.new(0, 38, 0, 38)
    toggleBtn.Position = UDim2.new(0.04, 0, 0.04, 0)
    toggleBtn.BackgroundColor3 = self.CurrentTheme.Secondary
    toggleBtn.Text = "F"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextColor3 = self.CurrentTheme.Accent
    toggleBtn.TextSize = 12
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 9)
    local togStroke = Instance.new("UIStroke", toggleBtn)
    togStroke.Color = self.CurrentTheme.Accent
    togStroke.Thickness = 1
    togStroke.Transparency = 0.6
    MakeDraggable(toggleBtn, toggleBtn)

    toggleBtn.MouseButton1Click:Connect(function()
        WindUI.Closed = not WindUI.Closed
        if WindUI.Closed then
            Tween(main, {Time=0.3, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.In}, {GroupTransparency=1, Size=UDim2.new(1,0,0,0)})
            task.delay(0.32, function() container.Visible = false end)
        else
            container.Visible = true
            main.Size = UDim2.new(1,0,0,0)
            Tween(main, {Time=0.45, Style=Enum.EasingStyle.Back}, {Size=UDim2.new(1,0,1,0), GroupTransparency=0})
        end
    end)

    -- Sidebar Area Structure
    local sideBar = Instance.new("Frame", main)
    sideBar.Size = UDim2.new(0, 148, 1, -49)
    sideBar.Position = UDim2.new(0, 0, 0, 49)
    sideBar.BackgroundColor3 = self.CurrentTheme.Secondary

    local sideSep = Instance.new("Frame", main)
    sideSep.Size = UDim2.new(0, 1, 1, -49)
    sideSep.Position = UDim2.new(0, 148, 0, 49)
    sideSep.BackgroundColor3 = self.CurrentTheme.Border

    local tabContainer = Instance.new("ScrollingFrame", sideBar)
    tabContainer.Size = UDim2.new(1, -8, 1, -68)
    tabContainer.Position = UDim2.new(0, 4, 0, 8)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 0
    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout.Padding = UDim.new(0, 2)

    -- Player Account Profile Frame Card
    local profileFrame = Instance.new("Frame", sideBar)
    profileFrame.Size = UDim2.new(1, -10, 0, 48)
    profileFrame.Position = UDim2.new(0, 5, 1, -54)
    profileFrame.BackgroundColor3 = self.CurrentTheme.Tertiary
    Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(0, 8)
    local profStroke = Instance.new("UIStroke", profileFrame)
    profStroke.Color = self.CurrentTheme.Border

    local avatarImg = Instance.new("ImageLabel", profileFrame)
    avatarImg.Size = UDim2.new(0, 32, 0, 32)
    avatarImg.Position = UDim2.new(0, 10, 0.5, -16)
    avatarImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
    local avatarStroke = Instance.new("UIStroke", avatarImg)
    avatarStroke.Color = self.CurrentTheme.Accent
    avatarStroke.Thickness = 1.5

    local playerName = Instance.new("TextLabel", profileFrame)
    playerName.Size = UDim2.new(1, -90, 0, 16)
    playerName.Position = UDim2.new(0, 48, 0, 10)
    playerName.BackgroundTransparency = 1
    playerName.Text = LocalPlayer.DisplayName
    playerName.TextColor3 = self.CurrentTheme.Text
    playerName.Font = Enum.Font.GothamBold
    playerName.TextSize = 10
    playerName.TextXAlignment = Enum.TextXAlignment.Left

    local verBadge = Instance.new("Frame", profileFrame)
    verBadge.Size = UDim2.new(0, 34, 0, 17)
    verBadge.Position = UDim2.new(0, 48, 0, 26)
    verBadge.BackgroundColor3 = self.CurrentTheme.Accent
    verBadge.BackgroundTransparency = 0.82
    Instance.new("UICorner", verBadge).CornerRadius = UDim.new(1, 0)
    local verLbl = Instance.new("TextLabel", verBadge)
    verLbl.Size = UDim2.new(1, 0, 1, 0)
    verLbl.Text = "PRO"
    verLbl.Font = Enum.Font.GothamBold
    verLbl.TextSize = 8
    verLbl.TextColor3 = self.CurrentTheme.Accent
    verLbl.BackgroundTransparency = 1

    local contentArea = Instance.new("Frame", main)
    contentArea.Size = UDim2.new(1, -162, 1, -58)
    contentArea.Position = UDim2.new(0, 157, 0, 54)
    contentArea.BackgroundTransparency = 1

    local Window = { Tabs = {}, CurrentTab = nil }

    -- Setup Event for TopBar Feature Search Filtering
    topSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        if Window.CurrentTab then
            local txt = topSearchInput.Text:lower()
            for _, item in pairs(Window.CurrentTab.Scroll:GetChildren()) do
                if item:IsA("Frame") or item:IsA("TextButton") then
                    local itemText = ""
                    local lbl = item:FindFirstChildOfClass("TextLabel")
                    if lbl then itemText = lbl.Text:lower()
                    elseif item:IsA("TextButton") then itemText = item.Text:lower() end
                    if itemText ~= "" then 
                        item.Visible = (itemText:find(txt) ~= nil)
                    end
                end
            end
        end
    end)

    local TAB_ICONS = {
        ["Home"] = "house", ["Main"] = "settings", ["Script"] = "code",
        ["Player"] = "user", ["Visual"] = "eye", ["Misc"] = "layers",
        ["Combat"] = "sword", ["World"] = "globe", ["Speed"] = "zap"
    }

    -- CreateTab Initialization
    function Window:CreateTab(name, iconName)
        local resolvedIcon = iconName or TAB_ICONS[name] or "circle-dot"

        local btn = Instance.new("TextButton", tabContainer)
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundTransparency = 1
        btn.BackgroundColor3 = WindUI.CurrentTheme.Accent
        btn.Text = ""
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local indicator = Instance.new("Frame", btn)
        indicator.Size = UDim2.new(0, 2, 0, 0)
        indicator.Position = UDim2.new(0, 0, 0.5, 0)
        indicator.AnchorPoint = Vector2.new(0, 0.5)
        indicator.BackgroundColor3 = WindUI.CurrentTheme.Accent
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

        local tabIcon = Instance.new("ImageLabel", btn)
        tabIcon.Size = UDim2.new(0, 13, 0, 13)
        tabIcon.Position = UDim2.new(0, 14, 0.5, -6.5)
        tabIcon.BackgroundTransparency = 1
        tabIcon.ImageColor3 = WindUI.CurrentTheme.SubText
        tabIcon.ScaleType = Enum.ScaleType.Fit
        task.spawn(function() ApplyIcon(tabIcon, GetIcon(resolvedIcon)) end)

        local tabLbl = Instance.new("TextLabel", btn)
        tabLbl.Text = name
        tabLbl.Size = UDim2.new(1, -34, 1, 0)
        tabLbl.Position = UDim2.new(0, 32, 0, 0)
        tabLbl.BackgroundTransparency = 1
        tabLbl.Font = WindUI.CurrentFont
        tabLbl.TextColor3 = WindUI.CurrentTheme.SubText
        tabLbl.TextSize = 11
        tabLbl.TextXAlignment = Enum.TextXAlignment.Left

        local container_tab = Instance.new("CanvasGroup", contentArea)
        container_tab.Size = UDim2.new(1, 0, 1, 0)
        container_tab.BackgroundTransparency = 1
        container_tab.Visible = false

        local scroll = Instance.new("ScrollingFrame", container_tab)
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = WindUI.CurrentTheme.Accent

        local scrollLayout = Instance.new("UIListLayout", scroll)
        scrollLayout.Padding = UDim.new(0, 6)
        scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local scrollPad = Instance.new("UIPadding", scroll)
        scrollPad.PaddingTop = UDim.new(0, 6)
        scrollPad.PaddingBottom = UDim.new(0, 6)

        local Tab = { Container = container_tab, Scroll = scroll, Button = btn }

        local function Activate()
            if Window.CurrentTab == Tab then return end
            for _, t in pairs(Window.Tabs) do
                Tween(t.Button, {Time = 0.15}, {BackgroundTransparency = 1})
                local ind = t.Button:FindFirstChild("Frame")
                if ind then Tween(ind, {Time = 0.25}, {Size = UDim2.new(0, 2, 0, 0)}) end
                local lbl2 = t.Button:FindFirstChildOfClass("TextLabel")
                if lbl2 then Tween(lbl2, {Time = 0.15}, {TextColor3 = WindUI.CurrentTheme.SubText}) end
                local ico2 = t.Button:FindFirstChildOfClass("ImageLabel")
                if ico2 then Tween(ico2, {Time = 0.15}, {ImageColor3 = WindUI.CurrentTheme.SubText}) end
                t.Container.Visible = false
            end
            Window.CurrentTab = Tab
            container_tab.Visible = true
            container_tab.Position = UDim2.new(0, 0, 0, 8)
            container_tab.GroupTransparency = 1
            Tween(container_tab, {Time = 0.3}, {Position = UDim2.new(0,0,0,0), GroupTransparency = 0})
            Tween(btn, {Time = 0.15}, {BackgroundTransparency = 0.9})
            Tween(tabLbl, {Time = 0.15}, {TextColor3 = WindUI.CurrentTheme.Text})
            Tween(tabIcon, {Time = 0.15}, {ImageColor3 = WindUI.CurrentTheme.Accent})
            Tween(indicator, {Time = 0.3, Style = Enum.EasingStyle.Back}, {Size = UDim2.new(0, 2, 0, 18)})
        end

        btn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(btn, {Time = 0.12}, {BackgroundTransparency = 0.95})
                Tween(tabIcon, {Time = 0.12}, {ImageColor3 = WindUI.CurrentTheme.Text})
            end
        end)
        btn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(btn, {Time = 0.12}, {BackgroundTransparency = 1})
                Tween(tabIcon, {Time = 0.12}, {ImageColor3 = WindUI.CurrentTheme.SubText})
            end
        end)
        btn.MouseButton1Click:Connect(Activate)

        -- ── NEW FEATURE: CHANGE TAB/SUBTAB LAYOUT STYLE ──
        function Tab:SetLayoutStyle(style)
            if self.Scroll:FindFirstChildOfClass("UIListLayout") then self.Scroll:FindFirstChildOfClass("UIListLayout"):Destroy() end
            if self.Scroll:FindFirstChildOfClass("UIGridLayout") then self.Scroll:FindFirstChildOfClass("UIGridLayout"):Destroy() end
            
            if style == "Grid" then
                local grid = Instance.new("UIGridLayout", self.Scroll)
                grid.CellSize = UDim2.new(0, 175, 0, 42)
                grid.CellPadding = UDim2.new(0, 6, 0, 6)
                grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
            elseif style == "Horizontal" then
                local list = Instance.new("UIListLayout", self.Scroll)
                list.FillDirection = Enum.FillDirection.Horizontal
                list.Padding = UDim.new(0, 6)
                list.VerticalAlignment = Enum.VerticalAlignment.Center
            else -- "Vertical" (Default List)
                local list = Instance.new("UIListLayout", self.Scroll)
                list.FillDirection = Enum.FillDirection.Vertical
                list.Padding = UDim.new(0, 6)
                list.HorizontalAlignment = Enum.HorizontalAlignment.Center
            end
        end

        -- ── NEW FEATURE: SUBTAB GENERATOR SYSTEM ──
        function Tab:CreateSubTab(subName)
            if not self.SubTabBar then
                self.Scroll.Visible = false
                
                local bar = Instance.new("Frame", self.Container)
                bar.Name = "SubTabBar"
                bar.Size = UDim2.new(1, 0, 0, 32)
                bar.Position = UDim2.new(0, 0, 0, 0)
                bar.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
                Instance.new("UIStroke", bar).Color = WindUI.CurrentTheme.Border
                
                local subLayout = Instance.new("UIListLayout", bar)
                subLayout.FillDirection = Enum.FillDirection.Horizontal
                subLayout.Padding = UDim.new(0, 4)
                subLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                Instance.new("UIPadding", bar).PaddingLeft = UDim.new(0, 6)
                
                self.SubTabBar = bar
                self.SubTabs = {}
                self.CurrentSubTab = nil
            end
            
            local sBtn = Instance.new("TextButton", self.SubTabBar)
            sBtn.Size = UDim2.new(0, 85, 0, 22)
            sBtn.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            sBtn.Text = subName
            sBtn.Font = WindUI.CurrentFont
            sBtn.TextColor3 = WindUI.CurrentTheme.SubText
            sBtn.TextSize = 10
            Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 5)
            Instance.new("UIStroke", sBtn).Color = WindUI.CurrentTheme.Border
            
            local subScroll = Instance.new("ScrollingFrame", self.Container)
            subScroll.Size = UDim2.new(1, 0, 1, -38)
            subScroll.Position = UDim2.new(0, 0, 0, 38)
            subScroll.BackgroundTransparency = 1
            subScroll.ScrollBarThickness = 2
            subScroll.ScrollBarImageColor3 = WindUI.CurrentTheme.Accent
            subScroll.Visible = false
            
            local subList = Instance.new("UIListLayout", subScroll)
            subList.Padding = UDim.new(0, 6)
            subList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            Instance.new("UIPadding", subScroll).PaddingTop = UDim.new(0, 6)
            
            local SubTab = { Scroll = subScroll, Button = sBtn, Container = self.Container }
            
            -- Inherit all parent tab features
            for k, v in pairs(self) do
                if type(v) == "function" and k ~= "CreateSubTab" then
                    SubTab[k] = v
                end
            end
            
            local function ActivateSub()
                if self.CurrentSubTab == SubTab then return end
                for _, st in pairs(self.SubTabs) do
                    st.Scroll.Visible = false
                    st.Button.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
                    st.Button.TextColor3 = WindUI.CurrentTheme.SubText
                    st.Button:FindFirstChildOfClass("UIStroke").Color = WindUI.CurrentTheme.Border
                end
                self.CurrentSubTab = SubTab
                subScroll.Visible = true
                sBtn.BackgroundColor3 = WindUI.CurrentTheme.Accent
                sBtn.TextColor3 = WindUI.CurrentTheme.Text
                sBtn:FindFirstChildOfClass("UIStroke").Color = WindUI.CurrentTheme.Accent
            end
            
            sBtn.MouseButton1Click:Connect(ActivateSub)
            table.insert(self.SubTabs, SubTab)
            if #self.SubTabs == 1 then ActivateSub() end
            
            return SubTab
        end

        -- INTERACTIVE TAB WIDGETS (Updated to support flexible routing)
        
        -- 1. Button Widget
        function Tab:CreateButton(text, callback, iconName)
            local b = Instance.new("TextButton", self.Scroll)
            b.Size = UDim2.new(0.96, 0, 0, 34)
            b.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            b.Text = ""
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            local bStroke = Instance.new("UIStroke", b)
            bStroke.Color = WindUI.CurrentTheme.Border

            local textOffset = 14
            if iconName then
                local iconImg = Instance.new("ImageLabel", b)
                iconImg.Size = UDim2.new(0, 13, 0, 13)
                iconImg.Position = UDim2.new(0, 12, 0.5, -6.5)
                iconImg.BackgroundTransparency = 1
                iconImg.ImageColor3 = WindUI.CurrentTheme.Accent
                task.spawn(function() ApplyIcon(iconImg, GetIcon(iconName)) end)
                textOffset = 32
            end

            local bLbl = Instance.new("TextLabel", b)
            bLbl.Text = text
            bLbl.Size = UDim2.new(1, -50, 1, 0)
            bLbl.Position = UDim2.new(0, textOffset, 0, 0)
            bLbl.Font = WindUI.CurrentFont
            bLbl.TextColor3 = WindUI.CurrentTheme.Text
            bLbl.TextSize = 11
            bLbl.TextXAlignment = Enum.TextXAlignment.Left
            bLbl.BackgroundTransparency = 1

            local arrImg = Instance.new("ImageLabel", b)
            arrImg.Size = UDim2.new(0, 11, 0, 11)
            arrImg.Position = UDim2.new(1, -22, 0.5, -5.5)
            arrImg.BackgroundTransparency = 1
            arrImg.ImageColor3 = WindUI.CurrentTheme.Accent
            arrImg.ImageTransparency = 0.5
            task.spawn(function() ApplyIcon(arrImg, GetIcon("chevron-right")) end)

            b.MouseEnter:Connect(function()
                Tween(b, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary})
                Tween(bStroke, {Time=0.12}, {Color = WindUI.CurrentTheme.Accent})
                Tween(arrImg, {Time=0.12}, {ImageTransparency = 0})
            end)
            b.MouseLeave:Connect(function()
                Tween(b, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary})
                Tween(bStroke, {Time=0.12}, {Color = WindUI.CurrentTheme.Border})
                Tween(arrImg, {Time=0.12}, {ImageTransparency = 0.5})
            end)
            b.MouseButton1Click:Connect(function()
                Tween(b, {Time=0.06}, {BackgroundColor3 = WindUI.CurrentTheme.AccentDark})
                task.delay(0.08, function() b.BackgroundColor3 = WindUI.CurrentTheme.Tertiary end)
                pcall(callback)
            end)
        end

        -- 2. Toggle Widget
        function Tab:CreateToggle(text, default, callback)
            local state = default
            local tBtn = Instance.new("TextButton", self.Scroll)
            tBtn.Size = UDim2.new(0.96, 0, 0, 36)
            tBtn.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            tBtn.Text = ""
            Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
            local tStroke = Instance.new("UIStroke", tBtn)
            tStroke.Color = WindUI.CurrentTheme.Border

            local lbl = Instance.new("TextLabel", tBtn)
            lbl.Text = text
            lbl.Size = UDim2.new(1, -64, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.Font = WindUI.CurrentFont
            lbl.TextColor3 = WindUI.CurrentTheme.Text
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.BackgroundTransparency = 1

            local switch = Instance.new("Frame", tBtn)
            switch.Size = UDim2.new(0, 32, 0, 16)
            switch.Position = UDim2.new(1, -46, 0.5, -8)
            switch.BackgroundColor3 = state and WindUI.CurrentTheme.Accent or Color3.fromRGB(35, 35, 40)
            Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame", switch)
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            tBtn.MouseEnter:Connect(function() Tween(tBtn, {Time=0.12}, {BackgroundColor3=WindUI.CurrentTheme.Tertiary}) end)
            tBtn.MouseLeave:Connect(function() Tween(tBtn, {Time=0.12}, {BackgroundColor3=WindUI.CurrentTheme.Secondary}) end)
            
            tBtn.MouseButton1Click:Connect(function()
                state = not state
                Tween(switch, {Time=0.2}, {BackgroundColor3 = state and WindUI.CurrentTheme.Accent or Color3.fromRGB(35, 35, 40)})
                Tween(knob, {Time=0.2, Style=Enum.EasingStyle.Back}, {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)})
                pcall(callback, state)
            end)
        end

        -- 3. Slider Widget
        function Tab:CreateSlider(text, min, max, default, callback)
            local sFrame = Instance.new("Frame", self.Scroll)
            sFrame.Size = UDim2.new(0.96, 0, 0, 48)
            sFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 6)
            local sfStroke = Instance.new("UIStroke", sFrame)
            sfStroke.Color = WindUI.CurrentTheme.Border

            local lbl = Instance.new("TextLabel", sFrame)
            lbl.Text = text
            lbl.Size = UDim2.new(0.65, 0, 0, 20)
            lbl.Position = UDim2.new(0, 14, 0, 4)
            lbl.TextColor3 = WindUI.CurrentTheme.Text
            lbl.Font = WindUI.CurrentFont
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.BackgroundTransparency = 1

            local valLbl = Instance.new("TextLabel", sFrame)
            valLbl.Text = tostring(default)
            valLbl.Size = UDim2.new(0.35, -14, 0, 20)
            valLbl.Position = UDim2.new(0.65, 0, 0, 4)
            valLbl.TextColor3 = WindUI.CurrentTheme.Accent
            valLbl.Font = Enum.Font.GothamBold
            valLbl.TextSize = 11
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.BackgroundTransparency = 1

            local track = Instance.new("Frame", sFrame)
            track.Size = UDim2.new(1, -28, 0, 4)
            track.Position = UDim2.new(0, 14, 0, 32)
            track.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame", track)
            fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
            fill.BackgroundColor3 = WindUI.CurrentTheme.Accent
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("TextButton", track)
            knob.Size = UDim2.new(0, 10, 0, 14)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new((default-min)/(max-min), 0, 0.5, 0)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.Text = ""
            Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 3)

            local dragging = false
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max - min) * pos)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                knob.Position = UDim2.new(pos, 0, 0.5, 0)
                valLbl.Text = tostring(val)
                pcall(callback, val)
            end

            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateSlider(input) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
        end

        -- 4. Standard Dropdown Widget
        function Tab:CreateDropdown(text, options, callback)
            local expanded = false
            local dFrame = Instance.new("Frame", self.Scroll)
            dFrame.Size = UDim2.new(0.96, 0, 0, 40)
            dFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            dFrame.ClipsDescendants = true
            Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0, 6)
            local dfStroke = Instance.new("UIStroke", dFrame)
            dfStroke.Color = WindUI.CurrentTheme.Border

            local trigger = Instance.new("TextButton", dFrame)
            trigger.Size = UDim2.new(1, 0, 0, 40)
            trigger.BackgroundTransparency = 1
            trigger.Text = ""

            local lbl = Instance.new("TextLabel", dFrame)
            lbl.Text = text
            lbl.Size = UDim2.new(1, -60, 0, 40)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.Font = WindUI.CurrentFont
            lbl.TextColor3 = WindUI.CurrentTheme.Text
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.BackgroundTransparency = 1

            local arrow = Instance.new("ImageLabel", dFrame)
            arrow.Size = UDim2.new(0, 12, 0, 12)
            arrow.Position = UDim2.new(1, -26, 0, 14)
            arrow.BackgroundTransparency = 1
            arrow.ImageColor3 = WindUI.CurrentTheme.SubText
            task.spawn(function() ApplyIcon(arrow, GetIcon("chevron-down")) end)

            local optCont = Instance.new("ScrollingFrame", dFrame)
            optCont.Size = UDim2.new(1, -16, 1, -46)
            optCont.Position = UDim2.new(0, 8, 0, 42)
            optCont.BackgroundTransparency = 1
            optCont.ScrollBarThickness = 2
            optCont.ScrollBarImageColor3 = WindUI.CurrentTheme.Accent

            local optLayout = Instance.new("UIListLayout", optCont)
            optLayout.Padding = UDim.new(0, 3)

            local function refresh()
                for _, c in ipairs(optCont:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, opt in ipairs(options) do
                    local ob = Instance.new("TextButton", optCont)
                    ob.Size = UDim2.new(1, 0, 0, 26)
                    ob.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
                    ob.Text = opt
                    ob.Font = WindUI.CurrentFont
                    ob.TextColor3 = WindUI.CurrentTheme.SubText
                    ob.TextSize = 10
                    Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 4)

                    ob.MouseButton1Click:Connect(function()
                        lbl.Text = text .. " : " .. opt
                        expanded = false
                        Tween(dFrame, {Time=0.2}, {Size = UDim2.new(0.96, 0, 0, 40)})
                        Tween(arrow, {Time=0.2}, {Rotation = 0})
                        pcall(callback, opt)
                    end)
                end
            end
            refresh()

            trigger.MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetH = expanded and math.clamp(46 + (#options * 29), 40, 200) or 40
                Tween(dFrame, {Time=0.25}, {Size = UDim2.new(0.96, 0, 0, targetH)})
                Tween(arrow, {Time=0.25}, {Rotation = expanded and 180 or 0})
            end)
        end

        -- 5. MultiDropdown Widget
        function Tab:CreateMultiDropdown(text, options, callback)
            local expanded = false
            local selected = {}
            local dFrame = Instance.new("Frame", self.Scroll)
            dFrame.Size = UDim2.new(0.96, 0, 0, 40)
            dFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            dFrame.ClipsDescendants = true
            Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0, 6)
            local dfStroke = Instance.new("UIStroke", dFrame)
            dfStroke.Color = WindUI.CurrentTheme.Border

            local trigger = Instance.new("TextButton", dFrame)
            trigger.Size = UDim2.new(1, 0, 0, 40)
            trigger.BackgroundTransparency = 1
            trigger.Text = ""

            local lbl = Instance.new("TextLabel", dFrame)
            lbl.Text = text .. " (0)"
            lbl.Size = UDim2.new(1, -60, 0, 40)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.Font = WindUI.CurrentFont
            lbl.TextColor3 = WindUI.CurrentTheme.Text
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.BackgroundTransparency = 1

            local arrow = Instance.new("ImageLabel", dFrame)
            arrow.Size = UDim2.new(0, 12, 0, 12)
            arrow.Position = UDim2.new(1, -26, 0, 14)
            arrow.BackgroundTransparency = 1
            arrow.ImageColor3 = WindUI.CurrentTheme.SubText
            task.spawn(function() ApplyIcon(arrow, GetIcon("chevron-down")) end)

            local optCont = Instance.new("ScrollingFrame", dFrame)
            optCont.Size = UDim2.new(1, -16, 1, -46)
            optCont.Position = UDim2.new(0, 8, 0, 42)
            optCont.BackgroundTransparency = 1
            optCont.ScrollBarThickness = 2
            optCont.ScrollBarImageColor3 = WindUI.CurrentTheme.Accent
            Instance.new("UIListLayout", optCont).Padding = UDim.new(0, 3)

            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton", optCont)
                ob.Size = UDim2.new(1, 0, 0, 26)
                ob.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
                ob.Text = opt
                ob.Font = WindUI.CurrentFont
                ob.TextColor3 = WindUI.CurrentTheme.SubText
                ob.TextSize = 10
                Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 4)

                ob.MouseButton1Click:Connect(function()
                    if table.find(selected, opt) then
                        table.remove(selected, table.find(selected, opt))
                        ob.TextColor3 = WindUI.CurrentTheme.SubText
                    else
                        table.insert(selected, opt)
                        ob.TextColor3 = WindUI.CurrentTheme.Accent
                    end
                    lbl.Text = text .. " (" .. #selected .. ")"
                    pcall(callback, selected)
                end)
            end

            trigger.MouseButton1Click:Connect(function()
                expanded = not expanded
                local targetH = expanded and math.clamp(46 + (#options * 29), 40, 200) or 40
                Tween(dFrame, {Time=0.25}, {Size = UDim2.new(0.96, 0, 0, targetH)})
                Tween(arrow, {Time=0.25}, {Rotation = expanded and 180 or 0})
            end)
        end

        -- 6. TextBox Input Widget
        function Tab:CreateInput(text, placeholder, callback)
            local iFrame = Instance.new("Frame", self.Scroll)
            iFrame.Size = UDim2.new(0.96, 0, 0, 48)
            iFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            Instance.new("UICorner", iFrame).CornerRadius = UDim.new(0, 6)
            local ifStroke = Instance.new("UIStroke", iFrame)
            ifStroke.Color = WindUI.CurrentTheme.Border

            local bar = Instance.new("Frame", iFrame)
            bar.Size = UDim2.new(0, 2, 0, 24)
            bar.Position = UDim2.new(0, 0, 0.5, -12)
            bar.BackgroundColor3 = WindUI.CurrentTheme.Accent
            bar.BackgroundTransparency = 1

            local iLbl = Instance.new("TextLabel", iFrame)
            iLbl.Text = text
            iLbl.Size = UDim2.new(1, -20, 0, 18)
            iLbl.Position = UDim2.new(0, 14, 0, 4)
            iLbl.Font = WindUI.CurrentFont
            iLbl.TextColor3 = WindUI.CurrentTheme.SubText
            iLbl.TextSize = 10
            iLbl.TextXAlignment = Enum.TextXAlignment.Left
            iLbl.BackgroundTransparency = 1

            local inputBox = Instance.new("TextBox", iFrame)
            inputBox.Size = UDim2.new(1, -28, 0, 22)
            inputBox.Position = UDim2.new(0, 14, 0, 22)
            inputBox.BackgroundTransparency = 1
            inputBox.Font = WindUI.CurrentFont
            inputBox.Text = ""
            inputBox.PlaceholderText = placeholder or "Type here..."
            inputBox.TextColor3 = WindUI.CurrentTheme.Text
            inputBox.PlaceholderColor3 = WindUI.CurrentTheme.SubText
            inputBox.TextSize = 11
            inputBox.TextXAlignment = Enum.TextXAlignment.Left
            inputBox.ClearTextOnFocus = false

            inputBox:GetPropertyChangedSignal("Text"):Connect(function() pcall(callback, inputBox.Text) end)
            inputBox.Focused:Connect(function()
                Tween(ifStroke, {Time=0.2}, {Color = WindUI.CurrentTheme.Accent})
                Tween(bar, {Time=0.2}, {BackgroundTransparency = 0})
            end)
            inputBox.FocusLost:Connect(function()
                Tween(ifStroke, {Time=0.2}, {Color = WindUI.CurrentTheme.Border})
                Tween(bar, {Time=0.2}, {BackgroundTransparency = 1})
            end)
        end

        -- 7. Keybind Capturer Widget
        function Tab:CreateKeybind(text, default, callback)
            local currentKey = default or Enum.KeyCode.Unknown
            local binding = false

            local kFrame = Instance.new("TextButton", self.Scroll)
            kFrame.Size = UDim2.new(0.96, 0, 0, 36)
            kFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            kFrame.Text = ""
            Instance.new("UICorner", kFrame).CornerRadius = UDim.new(0, 6)
            local kStroke = Instance.new("UIStroke", kFrame)
            kStroke.Color = WindUI.CurrentTheme.Border

            local kLbl = Instance.new("TextLabel", kFrame)
            kLbl.Text = text
            kLbl.Size = UDim2.new(0.6, 0, 1, 0)
            kLbl.Position = UDim2.new(0, 14, 0, 0)
            kLbl.Font = WindUI.CurrentFont
            kLbl.TextColor3 = WindUI.CurrentTheme.Text
            kLbl.TextSize = 11
            kLbl.TextXAlignment = Enum.TextXAlignment.Left
            kLbl.BackgroundTransparency = 1

            local bTarget = Instance.new("Frame", kFrame)
            bTarget.Size = UDim2.new(0, 70, 0, 22)
            bTarget.Position = UDim2.new(1, -84, 0.5, -11)
            bTarget.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            Instance.new("UICorner", bTarget).CornerRadius = UDim.new(0, 5)

            local bLbl = Instance.new("TextLabel", bTarget)
            bLbl.Size = UDim2.new(1, 0, 1, 0)
            bLbl.Text = currentKey.Name
            bLbl.Font = Enum.Font.GothamBold
            bLbl.TextColor3 = WindUI.CurrentTheme.Accent
            bLbl.TextSize = 10
            bLbl.BackgroundTransparency = 1

            kFrame.MouseButton1Click:Connect(function()
                binding = true
                bLbl.Text = "..."
            end)

            local inputConn = UserInputService.InputBegan:Connect(function(input)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false
                    currentKey = input.KeyCode
                    bLbl.Text = currentKey.Name
                    pcall(callback, currentKey)
                end
            end)
            table.insert(WindUI.Connections, inputConn)

            local keyMatchConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if not gpe and input.KeyCode == currentKey then pcall(callback, currentKey) end
            end)
            table.insert(WindUI.Connections, keyMatchConn)
        end

        -- 8. Confirm Security Button
        function Tab:CreateConfirmButton(text, confirmText, callback, iconName)
            local b = Instance.new("TextButton", self.Scroll)
            b.Size = UDim2.new(0.96, 0, 0, 34)
            b.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            b.Text = ""
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            local bStroke = Instance.new("UIStroke", b)
            bStroke.Color = WindUI.CurrentTheme.Border

            local bLbl = Instance.new("TextLabel", b)
            bLbl.Text = text
            bLbl.Size = UDim2.new(1, -28, 1, 0)
            bLbl.Position = UDim2.new(0, 14, 0, 0)
            bLbl.Font = WindUI.CurrentFont
            bLbl.TextColor3 = WindUI.CurrentTheme.Text
            bLbl.TextSize = 11
            bLbl.TextXAlignment = Enum.TextXAlignment.Left
            bLbl.BackgroundTransparency = 1

            local isWaitingConfirm = false
            b.MouseButton1Click:Connect(function()
                if not isWaitingConfirm then
                    isWaitingConfirm = true
                    bLbl.Text = confirmText or "Are you sure?"
                    bLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                    Tween(b, {Time=0.15}, {BackgroundColor3 = Color3.fromRGB(45, 20, 20)})
                    task.delay(3, function()
                        if isWaitingConfirm then
                            isWaitingConfirm = false
                            bLbl.Text = text
                            bLbl.TextColor3 = WindUI.CurrentTheme.Text
                            Tween(b, {Time=0.15}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary})
                        end
                    end)
                else
                    isWaitingConfirm = false
                    bLbl.Text = text
                    bLbl.TextColor3 = WindUI.CurrentTheme.Text
                    b.BackgroundColor3 = WindUI.CurrentTheme.AccentDark
                    task.delay(0.1, function() b.BackgroundColor3 = WindUI.CurrentTheme.Secondary end)
                    pcall(callback)
                end
            end)
        end

        -- 9. Section Label Title
        function Tab:CreateSection(text)
            local f = Instance.new("Frame", self.Scroll)
            f.Size = UDim2.new(0.96, 0, 0, 22)
            f.BackgroundTransparency = 1

            local l = Instance.new("TextLabel", f)
            l.Text = text:upper()
            l.Size = UDim2.new(1, 0, 1, 0)
            l.Position = UDim2.new(0, 6, 0, 0)
            l.Font = Enum.Font.GothamBold
            l.TextSize = 9
            l.TextColor3 = WindUI.CurrentTheme.Accent
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.BackgroundTransparency = 1
        end

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Activate() end

        return Tab
    end

    -- ── INTERACTIVE COLOR PICKER THEME CONFIG SECTION ───────────────────────
    function Window:CreateThemeSection(tabObj)
        tabObj:CreateSection("Custom Interface Theme")
        
        local themeCard = Instance.new("Frame", tabObj.Scroll)
        themeCard.Size = UDim2.new(0.96, 0, 0, 42)
        themeCard.BackgroundColor3 = WindUI.CurrentTheme.Secondary
        Instance.new("UICorner", themeCard).CornerRadius = UDim.new(0, 6)
        local tcStroke = Instance.new("UIStroke", themeCard)
        tcStroke.Color = WindUI.CurrentTheme.Border

        local themeLabel = Instance.new("TextLabel", themeCard)
        themeLabel.Text = "Accent Theme Synchronization"
        themeLabel.Size = UDim2.new(0.6, 0, 1, 0)
        themeLabel.Position = UDim2.new(0, 14, 0, 0)
        themeLabel.Font = WindUI.CurrentFont
        themeLabel.TextColor3 = WindUI.CurrentTheme.Text
        themeLabel.TextSize = 11
        themeLabel.TextXAlignment = Enum.TextXAlignment.Left
        themeLabel.BackgroundTransparency = 1

        local previewSwatch = Instance.new("Frame", themeCard)
        previewSwatch.Size = UDim2.new(0, 36, 0, 18)
        previewSwatch.Position = UDim2.new(1, -50, 0.5, -9)
        previewSwatch.BackgroundColor3 = WindUI.CurrentTheme.Accent
        Instance.new("UICorner", previewSwatch).CornerRadius = UDim.new(0, 4)

        local openPickerBtn = Instance.new("TextButton", themeCard)
        openPickerBtn.Size = UDim2.new(1, 0, 1, 0)
        openPickerBtn.BackgroundTransparency = 1
        openPickerBtn.Text = ""

        openPickerBtn.MouseButton1Click:Connect(function()
            local pickerBackdrop = Instance.new("Frame", WindUI.ScreenGui)
            pickerBackdrop.Size = UDim2.new(1, 0, 1, 0)
            pickerBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            pickerBackdrop.BackgroundTransparency = 0.65

            local card = Instance.new("Frame", pickerBackdrop)
            card.Size = UDim2.new(0, 240, 0, 160)
            card.Position = UDim2.new(0.5, -120, 0.5, -80)
            card.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
            Instance.new("UIStroke", card).Color = WindUI.CurrentTheme.Border

            local hLbl = Instance.new("TextLabel", card)
            hLbl.Text = "SELECT ACCENT COLOR"
            hLbl.Size = UDim2.new(1, 0, 0, 30)
            hLbl.Font = Enum.Font.GothamBold
            hLbl.TextSize = 10
            hLbl.TextColor3 = WindUI.CurrentTheme.Text
            hLbl.BackgroundTransparency = 1

            -- Standard Color Presets inside Overlay
            local colors = {Color3.fromRGB(210,32,32), Color3.fromRGB(32,210,32), Color3.fromRGB(32,32,210), Color3.fromRGB(210,210,32), Color3.fromRGB(210,32,210)}
            for i, col in ipairs(colors) do
                local cBtn = Instance.new("TextButton", card)
                cBtn.Size = UDim2.new(0, 30, 0, 30)
                cBtn.Position = UDim2.new(0, 20 + (i-1)*40, 0, 50)
                cBtn.BackgroundColor3 = col
                Instance.new("UICorner", cBtn).CornerRadius = UDim.new(1, 0)

                cBtn.MouseButton1Click:Connect(function()
                    WindUI:ApplyThemeAccent(col)
                    previewSwatch.BackgroundColor3 = col
                    pickerBackdrop:Destroy()
                end)
            end

            local close = Instance.new("TextButton", card)
            close.Text = "Cancel"
            close.Size = UDim2.new(0, 80, 0, 24)
            close.Position = UDim2.new(0.5, -40, 1, -34)
            close.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            close.Font = WindUI.CurrentFont
            close.TextColor3 = WindUI.CurrentTheme.Text
            close.TextSize = 10
            Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)
            close.MouseButton1Click:Connect(function() pickerBackdrop:Destroy() end)
        end)
    end

    -- ── INTERACTIVE DISCORD CARD COMPONENT ─────────────────────────────────
    function Window:CreateDiscordCard(tabObj, inviteLink)
        local discordCard = Instance.new("Frame", tabObj.Scroll)
        discordCard.Size = UDim2.new(0.96, 0, 0, 50)
        discordCard.BackgroundColor3 = WindUI.CurrentTheme.Secondary
        Instance.new("UICorner", discordCard).CornerRadius = UDim.new(0, 7)
        local dStroke = Instance.new("UIStroke", discordCard)
        dStroke.Color = WindUI.CurrentTheme.Border

        local discordIcoBox = Instance.new("Frame", discordCard)
        discordIcoBox.Size = UDim2.new(0, 30, 0, 30)
        discordIcoBox.Position = UDim2.new(0, 10, 0.5, -15)
        discordIcoBox.BackgroundColor3 = WindUI.CurrentTheme.Accent
        discordIcoBox.BackgroundTransparency = 0.82
        Instance.new("UICorner", discordIcoBox).CornerRadius = UDim.new(0, 6)

        local dIco = Instance.new("ImageLabel", discordIcoBox)
        dIco.Size = UDim2.new(0, 14, 0, 14)
        dIco.Position = UDim2.new(0.5, -7, 0.5, -7)
        dIco.BackgroundTransparency = 1
        dIco.ImageColor3 = WindUI.CurrentTheme.Accent
        task.spawn(function() ApplyIcon(dIco, GetIcon("message-square")) end)

        local dTitle = Instance.new("TextLabel", discordCard)
        dTitle.Text = "Join Our Discord Community"
        dTitle.Size = UDim2.new(0.5, 0, 0, 18)
        dTitle.Position = UDim2.new(0, 48, 0, 8)
        dTitle.Font = Enum.Font.GothamBold
        dTitle.TextColor3 = WindUI.CurrentTheme.Text
        dTitle.TextSize = 11
        dTitle.TextXAlignment = Enum.TextXAlignment.Left
        dTitle.BackgroundTransparency = 1

        local dSub = Instance.new("TextLabel", discordCard)
        dSub.Text = inviteLink or "discord.gg/nanzzz"
        dSub.Size = UDim2.new(0.5, 0, 0, 14)
        dSub.Position = UDim2.new(0, 48, 0, 24)
        dSub.Font = WindUI.CurrentFont
        dSub.TextColor3 = WindUI.CurrentTheme.SubText
        dSub.TextSize = 9
        dSub.TextXAlignment = Enum.TextXAlignment.Left
        dSub.BackgroundTransparency = 1

        local discordCopy = Instance.new("TextButton", discordCard)
        discordCopy.Size = UDim2.new(0, 58, 0, 24)
        discordCopy.Position = UDim2.new(1, -68, 0.5, -12)
        discordCopy.BackgroundColor3 = WindUI.CurrentTheme.Accent
        discordCopy.BackgroundTransparency = 0.8
        discordCopy.Text = "Copy"
        discordCopy.Font = Enum.Font.GothamBold
        discordCopy.TextColor3 = WindUI.CurrentTheme.Accent
        discordCopy.TextSize = 10
        Instance.new("UICorner", discordCopy).CornerRadius = UDim.new(0, 6)
        
        local cStroke = Instance.new("UIStroke", discordCopy)
        cStroke.Color = WindUI.CurrentTheme.Accent
        cStroke.Thickness = 1
        cStroke.Transparency = 0.5

        discordCard.MouseEnter:Connect(function() Tween(discordCard, {Time=0.12}, {BackgroundColor3=WindUI.CurrentTheme.Tertiary}) end)
        discordCard.MouseLeave:Connect(function() Tween(discordCard, {Time=0.12}, {BackgroundColor3=WindUI.CurrentTheme.Secondary}) end)
        discordCopy.MouseEnter:Connect(function() Tween(discordCopy, {Time=0.12}, {BackgroundTransparency=0.5}) end)
        discordCopy.MouseLeave:Connect(function() Tween(discordCopy, {Time=0.12}, {BackgroundTransparency=0.8}) end)

        discordCopy.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(inviteLink or "discord.gg/nanzzz") end)
            discordCopy.Text = "Done"
            discordCopy.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.delay(2, function()
                discordCopy.Text = "Copy"
                discordCopy.TextColor3 = WindUI.CurrentTheme.Accent
            end)
        end)
    end

    return Window
end

return WindUI
