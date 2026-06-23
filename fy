local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

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
    CurrentFont  = Enum.Font.GothamMedium,
    ScreenGui    = nil,
    NotifyGui    = nil,
    Closed       = false,
    Connections  = {},
    GetIcon      = GetIcon,
    ApplyIcon    = ApplyIcon,
    _allTabs     = {},
    _allBtns     = {},
    _layoutStyle = "Default",
    _sidebarStyle = "Icon + Text",
}

local function Tween(obj, info, goal)
    local t = TweenService:Create(obj,
        TweenInfo.new(info.Time or 0.3, info.Style or Enum.EasingStyle.Quart, info.Dir or Enum.EasingDirection.Out),
        goal)
    t:Play(); return t
end

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
                local bc = child.BackgroundColor3
                if isAccent(bc) then
                    child.BackgroundColor3 = newAccent
                end
            end
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local tc = child.TextColor3
                if isAccent(tc) then
                    child.TextColor3 = newAccent
                end
            end
            if child:IsA("ImageLabel") then
                local ic = child.ImageColor3
                if isAccent(ic) then
                    child.ImageColor3 = newAccent
                end
            end
            if child:IsA("UIStroke") then
                local sc = child.Color
                if isAccent(sc) and not isBorder(sc) and not isNeutral(sc) then
                    child.Color = newAccent
                end
            end
            if child:IsA("ScrollingFrame") then
                local sc = child.ScrollBarImageColor3
                if isAccent(sc) then
                    child.ScrollBarImageColor3 = newAccent
                end
            end
        end
    end

    UpdateAccentColor(self.ScreenGui)
    self.CurrentTheme.Accent = newAccent
    if self.NotifyGui then
        UpdateAccentColor(self.NotifyGui)
        self.CurrentTheme.Accent = newAccent
    end
    if floatGui then
        UpdateAccentColor(floatGui)
    end
end

function WindUI:Notify(title, text, duration)
    if not self.NotifyGui then
        self.NotifyGui = Instance.new("ScreenGui", CoreGui)
        self.NotifyGui.Name = "WindUI_Notifications"
        self.NotifyGui.DisplayOrder = 99
        local holder = Instance.new("Frame", self.NotifyGui)
        holder.Name = "Holder"
        holder.Size = UDim2.new(0, 300, 1, 0)
        holder.Position = UDim2.new(1, -312, 0, 0)
        holder.BackgroundTransparency = 1
        local layout = Instance.new("UIListLayout", holder)
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)
        local pad = Instance.new("UIPadding", holder)
        pad.PaddingBottom = UDim.new(0, 28)
        pad.PaddingRight = UDim.new(0, 0)
    end

    local dur = duration or 4

    local nFrame = Instance.new("CanvasGroup", self.NotifyGui.Holder)
    nFrame.Size = UDim2.new(1, 0, 0, 72)
    nFrame.BackgroundColor3 = self.CurrentTheme.Secondary
    nFrame.GroupTransparency = 0
    nFrame.ClipsDescendants = false
    Instance.new("UICorner", nFrame).CornerRadius = UDim.new(0, 10)

    local nStroke = Instance.new("UIStroke", nFrame)
    nStroke.Color = self.CurrentTheme.Border
    nStroke.Thickness = 1
    nStroke.Transparency = 0

    local topShine = Instance.new("Frame", nFrame)
    topShine.Size = UDim2.new(0.6, 0, 0, 1)
    topShine.Position = UDim2.new(0.2, 0, 0, 0)
    topShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topShine.BackgroundTransparency = 0.85
    topShine.BorderSizePixel = 0
    Instance.new("UICorner", topShine).CornerRadius = UDim.new(1, 0)

    local accentBar = Instance.new("Frame", nFrame)
    accentBar.Size = UDim2.new(0, 3, 1, -16)
    accentBar.Position = UDim2.new(0, 0, 0, 8)
    accentBar.BackgroundColor3 = self.CurrentTheme.Accent
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)

    local iconBadge = Instance.new("Frame", nFrame)
    iconBadge.Size = UDim2.new(0, 34, 0, 34)
    iconBadge.Position = UDim2.new(0, 14, 0.5, -17)
    iconBadge.BackgroundColor3 = self.CurrentTheme.Accent
    iconBadge.BackgroundTransparency = 0.78
    Instance.new("UICorner", iconBadge).CornerRadius = UDim.new(1, 0)
    local iconStroke = Instance.new("UIStroke", iconBadge)
    iconStroke.Color = self.CurrentTheme.Accent
    iconStroke.Thickness = 1
    iconStroke.Transparency = 0.5

    local iconImg = Instance.new("ImageLabel", iconBadge)
    iconImg.Size = UDim2.new(0, 15, 0, 15)
    iconImg.Position = UDim2.new(0.5, -7.5, 0.5, -7.5)
    iconImg.BackgroundTransparency = 1
    iconImg.ImageColor3 = self.CurrentTheme.Accent
    iconImg.ScaleType = Enum.ScaleType.Fit
    task.spawn(function() ApplyIcon(iconImg, GetIcon("bell")) end)

    local tLbl = Instance.new("TextLabel", nFrame)
    tLbl.Text = title:upper()
    tLbl.Size = UDim2.new(1, -110, 0, 14)
    tLbl.Position = UDim2.new(0, 58, 0, 14)
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextColor3 = self.CurrentTheme.Accent
    tLbl.TextSize = 9
    tLbl.BackgroundTransparency = 1
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local sLbl = Instance.new("TextLabel", nFrame)
    sLbl.Text = text
    sLbl.Size = UDim2.new(1, -68, 0, 28)
    sLbl.Position = UDim2.new(0, 58, 0, 30)
    sLbl.Font = Enum.Font.GothamMedium
    sLbl.TextColor3 = self.CurrentTheme.Text
    sLbl.TextSize = 10
    sLbl.BackgroundTransparency = 1
    sLbl.TextXAlignment = Enum.TextXAlignment.Left
    sLbl.TextYAlignment = Enum.TextYAlignment.Top
    sLbl.TextWrapped = true

    local durBadge = Instance.new("Frame", nFrame)
    durBadge.Size = UDim2.new(0, 0, 0, 16)
    durBadge.AutomaticSize = Enum.AutomaticSize.X
    durBadge.Position = UDim2.new(1, -8, 0, 8)
    durBadge.AnchorPoint = Vector2.new(1, 0)
    durBadge.BackgroundColor3 = self.CurrentTheme.Tertiary
    durBadge.BackgroundTransparency = 0.3
    Instance.new("UICorner", durBadge).CornerRadius = UDim.new(1, 0)
    local durPad = Instance.new("UIPadding", durBadge)
    durPad.PaddingLeft = UDim.new(0, 6)
    durPad.PaddingRight = UDim.new(0, 6)
    local durLbl = Instance.new("TextLabel", durBadge)
    durLbl.Size = UDim2.new(0, 0, 1, 0)
    durLbl.AutomaticSize = Enum.AutomaticSize.X
    durLbl.BackgroundTransparency = 1
    durLbl.Text = dur .. "s"
    durLbl.Font = Enum.Font.GothamBold
    durLbl.TextColor3 = self.CurrentTheme.SubText
    durLbl.TextSize = 8

    local progTrack = Instance.new("Frame", nFrame)
    progTrack.Size = UDim2.new(1, -16, 0, 2)
    progTrack.Position = UDim2.new(0, 8, 1, -6)
    progTrack.BackgroundColor3 = self.CurrentTheme.Tertiary
    progTrack.BackgroundTransparency = 0
    Instance.new("UICorner", progTrack).CornerRadius = UDim.new(1, 0)

    local progFill = Instance.new("Frame", progTrack)
    progFill.Size = UDim2.new(1, 0, 1, 0)
    progFill.BackgroundColor3 = self.CurrentTheme.Accent
    progFill.BackgroundTransparency = 0.2
    Instance.new("UICorner", progFill).CornerRadius = UDim.new(1, 0)

    local closeBtn = Instance.new("TextButton", nFrame)
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -26, 0, 28)
    closeBtn.BackgroundColor3 = self.CurrentTheme.Tertiary
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = ""
    closeBtn.ZIndex = 5
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
    local closeIco = Instance.new("ImageLabel", closeBtn)
    closeIco.Size = UDim2.new(0, 9, 0, 9)
    closeIco.Position = UDim2.new(0.5, -4.5, 0.5, -4.5)
    closeIco.BackgroundTransparency = 1
    closeIco.ImageColor3 = self.CurrentTheme.SubText
    closeIco.ScaleType = Enum.ScaleType.Fit
    closeIco.ZIndex = 6
    task.spawn(function() ApplyIcon(closeIco, GetIcon("x")) end)

    nFrame.Size = UDim2.new(1, 0, 0, 0)
    nFrame.ClipsDescendants = true
    Tween(nFrame, {Time = 0.3, Style = Enum.EasingStyle.Quart, Dir = Enum.EasingDirection.Out},
        {Size = UDim2.new(1, 0, 0, 72)})

    task.delay(0.4, function()
        Tween(progFill, {Time = dur - 0.4, Style = Enum.EasingStyle.Linear},
            {Size = UDim2.new(0, 0, 1, 0)})
    end)

    local dismissed = false

    task.spawn(function()
        local remaining = dur
        while remaining > 0 and not dismissed do
            task.wait(1)
            remaining = remaining - 1
            if durLbl and durLbl.Parent then
                durLbl.Text = remaining .. "s"
            end
        end
    end)

    local function Dismiss()
        if dismissed then return end
        dismissed = true
        nFrame.ClipsDescendants = true
        Tween(nFrame, {Time = 0.25, Style = Enum.EasingStyle.Quart, Dir = Enum.EasingDirection.In},
            {Size = UDim2.new(1, 0, 0, 0)})
        task.wait(0.27)
        if nFrame and nFrame.Parent then nFrame:Destroy() end
    end

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {Time=0.1}, {BackgroundTransparency=0})
        Tween(closeIco, {Time=0.1}, {ImageColor3=self.CurrentTheme.Text})
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {Time=0.1}, {BackgroundTransparency=0.5})
        Tween(closeIco, {Time=0.1}, {ImageColor3=self.CurrentTheme.SubText})
    end)
    closeBtn.MouseButton1Click:Connect(function() task.spawn(Dismiss) end)

    task.delay(dur, function() task.spawn(Dismiss) end)
end

local function MakeDraggable(dragPart, mainFrame)
    local dragging, dragStart, startPos
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

WindUI.MakeDraggable = MakeDraggable

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
    main.ClipsDescendants = false
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
    topBar.BackgroundTransparency = 0
    topBar.BorderSizePixel = 0
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 7)

    local topSep = Instance.new("Frame", main)
    topSep.Size = UDim2.new(1, 0, 0, 1)
    topSep.Position = UDim2.new(0, 0, 0, 48)
    topSep.BackgroundColor3 = self.CurrentTheme.Border
    topSep.BorderSizePixel = 0

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
    subLbl.Text = "Freemium  |  Version 2.0"
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 9
    subLbl.TextColor3 = self.CurrentTheme.SubText
    subLbl.Position = UDim2.new(0, 22, 0, 26)
    subLbl.Size = UDim2.new(0.45, 0, 0, 13)
    subLbl.BackgroundTransparency = 1
    subLbl.TextXAlignment = Enum.TextXAlignment.Left

    local topSearchBox = Instance.new("Frame", topBar)
    topSearchBox.Size = UDim2.new(0, 120, 0, 26)
    topSearchBox.Position = UDim2.new(1, -200, 0.5, -13)
    topSearchBox.BackgroundColor3 = self.CurrentTheme.Tertiary
    topSearchBox.BorderSizePixel = 0
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
    topSearchInput.PlaceholderText = "Search..."
    topSearchInput.TextColor3 = self.CurrentTheme.Text
    topSearchInput.PlaceholderColor3 = self.CurrentTheme.SubText
    topSearchInput.TextSize = 10
    topSearchInput.TextXAlignment = Enum.TextXAlignment.Left
    topSearchInput.ClearTextOnFocus = false

    local fpsBadge = Instance.new("Frame", topBar)
    fpsBadge.Name = "FPSBadge"
    fpsBadge.Size = UDim2.new(0, 54, 0, 20)
    fpsBadge.Position = UDim2.new(1, -68, 0.5, -10)
    fpsBadge.BackgroundColor3 = self.CurrentTheme.Tertiary
    fpsBadge.BorderSizePixel = 0
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

    local fpsTimer = 0
    local fpsCount = 0
    local fpsConn
    fpsConn = RunService.RenderStepped:Connect(function(dt)
        fpsCount = fpsCount + 1
        fpsTimer = fpsTimer + dt
        if fpsTimer >= 0.5 then
            local fps = math.round(fpsCount / fpsTimer)
            fpsLabel.Text = "FPS: " .. fps
            fpsTimer = 0; fpsCount = 0
        end
    end)
    table.insert(self.Connections, fpsConn)

    MakeDraggable(topBar, container)

    local dragLine = Instance.new("Frame", container)
    dragLine.Name = "ExternalDrag"
    dragLine.Size = UDim2.new(0, 60, 0, 5)
    dragLine.Position = UDim2.new(0.5, -30, 1, 12)
    dragLine.BackgroundColor3 = WindUI.CurrentTheme.Border
    dragLine.BackgroundTransparency = 0.2
    Instance.new("UICorner", dragLine).CornerRadius = UDim.new(1, 0)
    local dragHitbox = Instance.new("TextButton", dragLine)
    dragHitbox.Size = UDim2.new(3, 0, 8, 0)
    dragHitbox.Position = UDim2.new(-1, 0, -3.5, 0)
    dragHitbox.BackgroundTransparency = 1
    dragHitbox.Text = ""
    MakeDraggable(dragHitbox, container)

    local MIN_W, MIN_H = 400, 280
    local MAX_W, MAX_H = 800, 600

    local resizeHandle = Instance.new("Frame", main)
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.new(0, 40, 0, 40)
    resizeHandle.Position = UDim2.new(1, -40, 1, -40)
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.ZIndex = 10

    local resizeBtn = Instance.new("TextButton", resizeHandle)
    resizeBtn.Size = UDim2.new(1, 0, 1, 0)
    resizeBtn.Position = UDim2.new(0, 0, 0, 0)
    resizeBtn.BackgroundTransparency = 1
    resizeBtn.Text = ""
    resizeBtn.ZIndex = 10

    local resizing = false
    local resizeStart = nil
    local startSize = nil

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
            container.Position = UDim2.new(0.5, -newW / 2, 0.5, -newH / 2)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

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
            Tween(main, {Time=0.3, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.In}, {GroupTransparency=1, Size=UDim2.new(0,540,0,0)})
            Tween(dragLine, {Time=0.2}, {BackgroundTransparency=1})
            task.delay(0.32, function() container.Visible = false end)
        else
            container.Visible = true
            main.Size = UDim2.new(0,540,0,0)
            main.GroupTransparency = 1
            Tween(main, {Time=0.45, Style=Enum.EasingStyle.Back}, {Size=UDim2.new(1,0,1,0), GroupTransparency=0})
            Tween(dragLine, {Time=0.3}, {BackgroundTransparency=0.2})
        end
    end)

    local sideBar = Instance.new("Frame", main)
    sideBar.Size = UDim2.new(0, 148, 1, -49)
    sideBar.Position = UDim2.new(0, 0, 0, 49)
    sideBar.BackgroundColor3 = self.CurrentTheme.Secondary
    sideBar.BackgroundTransparency = 0
    sideBar.BorderSizePixel = 0
    sideBar.ClipsDescendants = true
    Instance.new("UICorner", sideBar).CornerRadius = UDim.new(0, 7)

    local sideSep = Instance.new("Frame", main)
    sideSep.Size = UDim2.new(0, 1, 1, -49)
    sideSep.Position = UDim2.new(0, 148, 0, 49)
    sideSep.BackgroundColor3 = self.CurrentTheme.Border
    sideSep.BackgroundTransparency = 1
    sideSep.BorderSizePixel = 0

    local searchInput = topSearchInput

    local tabContainer = Instance.new("ScrollingFrame", sideBar)
    tabContainer.Size = UDim2.new(1, -8, 1, -68)
    tabContainer.Position = UDim2.new(0, 4, 0, 8)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 0
    tabContainer.ClipsDescendants = true
    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout.Padding = UDim.new(0, 2)

    local profileFrame = Instance.new("Frame", sideBar)
    profileFrame.Size = UDim2.new(1, -10, 0, 48)
    profileFrame.Position = UDim2.new(0, 5, 1, -54)
    profileFrame.BackgroundColor3 = self.CurrentTheme.Tertiary
    profileFrame.BackgroundTransparency = 0
    Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(0, 8)
    local profStroke = Instance.new("UIStroke", profileFrame)
    profStroke.Color = self.CurrentTheme.Border
    profStroke.Thickness = 1

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
    playerName.TextSize = 11
    playerName.TextXAlignment = Enum.TextXAlignment.Left

    local verBadge = Instance.new("Frame", profileFrame)
    verBadge.Size = UDim2.new(0, 34, 0, 17)
    verBadge.Position = UDim2.new(0, 48, 0, 28)
    verBadge.BackgroundColor3 = self.CurrentTheme.Accent
    verBadge.BackgroundTransparency = 0.82
    Instance.new("UICorner", verBadge).CornerRadius = UDim.new(1, 0)
    local verStroke = Instance.new("UIStroke", verBadge)
    verStroke.Color = self.CurrentTheme.Accent
    verStroke.Thickness = 1
    verStroke.Transparency = 0.5
    local verLbl = Instance.new("TextLabel", verBadge)
    verLbl.Size = UDim2.new(1, 0, 1, 0)
    verLbl.Text = "v2.0"
    verLbl.Font = Enum.Font.GothamBold
    verLbl.TextSize = 9
    verLbl.TextColor3 = self.CurrentTheme.Accent
    verLbl.BackgroundTransparency = 1

    local contentArea = Instance.new("Frame", main)
    contentArea.Size = UDim2.new(1, -162, 1, -58)
    contentArea.Position = UDim2.new(0, 157, 0, 54)
    contentArea.BackgroundTransparency = 1

    local Window = { Tabs = {}, CurrentTab = nil }

    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        if Window.CurrentTab then
            local txt = searchInput.Text:lower()
            for _, item in pairs(Window.CurrentTab.Scroll:GetChildren()) do
                if item:IsA("Frame") or item:IsA("TextButton") then
                    local itemText = ""
                    local lbl = item:FindFirstChildOfClass("TextLabel")
                    if lbl then itemText = lbl.Text:lower()
                    elseif item:IsA("TextButton") then itemText = item.Text:lower() end
                    if itemText ~= "" then item.Visible = itemText:find(txt) ~= nil end
                end
            end
        end
    end)

    local TAB_ICONS = {
        ["Home"]     = "house",
        ["Main"]     = "settings",
        ["Script"]   = "code",
        ["Player"]   = "user",
        ["Visual"]   = "eye",
        ["Misc"]     = "layers",
        ["Combat"]   = "sword",
        ["World"]    = "globe",
        ["Speed"]    = "zap",
        ["Fly"]      = "wind",
        ["ESP"]      = "scan-eye",
        ["Aimbot"]   = "crosshair",
        ["Movement"] = "move",
        ["Items"]    = "package",
        ["Farm"]     = "leaf",
        ["Auto"]     = "bot",
        ["Teleport"] = "map-pin",
        ["Chat"]     = "message-circle",
        ["Kill"]     = "skull",
        ["Safe"]     = "shield",
    }

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
        indicator.BorderSizePixel = 0
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
        scroll.ScrollBarImageTransparency = 0.6

        local scrollLayout = Instance.new("UIListLayout", scroll)
        scrollLayout.Padding = UDim.new(0, 6)
        scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local scrollPad = Instance.new("UIPadding", scroll)
        scrollPad.PaddingTop = UDim.new(0, 8)
        scrollPad.PaddingBottom = UDim.new(0, 8)

        local Tab = { Container = container_tab, Scroll = scroll, Button = btn, _scrollLayout = scrollLayout, _scrollPad = scrollPad, _tabIcon = tabIcon, _tabLbl = tabLbl }
        table.insert(WindUI._allTabs, Tab)
        table.insert(WindUI._allBtns, {btn=btn, icon=tabIcon, lbl=tabLbl})

        local function Activate()
            if Window.CurrentTab == Tab then return end
            local prev = Window.CurrentTab
            if prev and prev.Container then
                local prevC = prev.Container
                Tween(prevC, {Time=0.18, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.In},
                    {Position=UDim2.new(0,0,0,-10), GroupTransparency=1})
                task.delay(0.19, function()
                    if prevC and prevC.Parent then
                        prevC.Visible = false
                        prevC.Position = UDim2.new(0,0,0,0)
                        prevC.GroupTransparency = 1
                    end
                end)
            end
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
            container_tab.Position = UDim2.new(0, 0, 0, 14)
            container_tab.GroupTransparency = 1
            container_tab.Visible = true
            Tween(container_tab, {Time=0.28, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.Out},
                {Position=UDim2.new(0,0,0,0), GroupTransparency=0})
            Tween(btn, {Time = 0.15}, {BackgroundTransparency = 0.9})
            Tween(tabLbl, {Time = 0.15}, {TextColor3 = WindUI.CurrentTheme.Text})
            Tween(tabIcon, {Time = 0.15}, {ImageColor3 = WindUI.CurrentTheme.Accent})
            Tween(indicator, {Time = 0.35, Style = Enum.EasingStyle.Back}, {Size = UDim2.new(0, 2, 0, 18)})
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

        function Tab:CreateSection(text) end

        function Tab:CreateButton(text, callback, iconName)
            local b = Instance.new("TextButton", scroll)
            b.Size = UDim2.new(0.96, 0, 0, 34)
            b.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            b.Text = ""
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            local bStroke = Instance.new("UIStroke", b)
            bStroke.Color = WindUI.CurrentTheme.Border
            bStroke.Thickness = 1

            local iconImg = Instance.new("ImageLabel", b)
            iconImg.Size = UDim2.new(0, 13, 0, 13)
            iconImg.Position = UDim2.new(0, 12, 0.5, -6.5)
            iconImg.BackgroundTransparency = 1
            iconImg.ImageColor3 = WindUI.CurrentTheme.Accent
            iconImg.ScaleType = Enum.ScaleType.Fit
            iconImg.Visible = false

            local textOffset = 12
            if iconName then
                task.spawn(function()
                    local iconData = GetIcon(iconName)
                    if iconData then ApplyIcon(iconImg, iconData); iconImg.Visible = true end
                end)
                textOffset = 30
            end

            local bLbl = Instance.new("TextLabel", b)
            bLbl.Text = text
            bLbl.Size = UDim2.new(1, -(textOffset + 28), 1, 0)
            bLbl.Position = UDim2.new(0, textOffset, 0, 0)
            bLbl.BackgroundTransparency = 1
            bLbl.Font = WindUI.CurrentFont
            bLbl.TextColor3 = WindUI.CurrentTheme.Text
            bLbl.TextSize = 11
            bLbl.TextXAlignment = Enum.TextXAlignment.Left

            local arrImg = Instance.new("ImageLabel", b)
            arrImg.Size = UDim2.new(0, 11, 0, 11)
            arrImg.Position = UDim2.new(1, -22, 0.5, -5.5)
            arrImg.BackgroundTransparency = 1
            arrImg.ImageColor3 = WindUI.CurrentTheme.Accent
            arrImg.ImageTransparency = 0.6
            arrImg.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(arrImg, GetIcon("chevron-right")) end)

            b.MouseEnter:Connect(function()
                Tween(b, {Time = 0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary})
                Tween(bStroke, {Time = 0.12}, {Color = WindUI.CurrentTheme.Accent, Transparency = 0.5})
                Tween(arrImg, {Time = 0.12}, {ImageTransparency = 0})
            end)
            b.MouseLeave:Connect(function()
                Tween(b, {Time = 0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary})
                Tween(bStroke, {Time = 0.12}, {Color = WindUI.CurrentTheme.Border, Transparency = 0})
                Tween(arrImg, {Time = 0.12}, {ImageTransparency = 0.6})
            end)
            b.MouseButton1Click:Connect(function()
                Tween(b, {Time = 0.07}, {BackgroundColor3 = WindUI.CurrentTheme.AccentDark})
                task.delay(0.1, function() Tween(b, {Time = 0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary}) end)
                pcall(callback)
            end)
        end

        function Tab:CreateToggle(text, default, callback)
            local state = default
            local tBtn = Instance.new("TextButton", scroll)
            tBtn.Size = UDim2.new(0.96, 0, 0, 36)
            tBtn.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            tBtn.Text = ""
            Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
            local tStroke = Instance.new("UIStroke", tBtn)
            tStroke.Color = WindUI.CurrentTheme.Border
            tStroke.Thickness = 1

            local lbl = Instance.new("TextLabel", tBtn)
            lbl.Text = text
            lbl.Size = UDim2.new(1, -64, 1, 0)
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = WindUI.CurrentFont
            lbl.TextColor3 = WindUI.CurrentTheme.Text
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left

            local switch = Instance.new("Frame", tBtn)
            switch.Size = UDim2.new(0, 34, 0, 17)
            switch.Position = UDim2.new(1, -46, 0.5, -8.5)
            switch.BackgroundColor3 = state and WindUI.CurrentTheme.Accent or Color3.fromRGB(36, 26, 26)
            Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame", switch)
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            tBtn.MouseEnter:Connect(function() Tween(tBtn, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary}) end)
            tBtn.MouseLeave:Connect(function() Tween(tBtn, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary}) end)
            tBtn.MouseButton1Click:Connect(function()
                state = not state
                Tween(switch, {Time = 0.2, Style = Enum.EasingStyle.Quart}, {BackgroundColor3 = state and WindUI.CurrentTheme.Accent or Color3.fromRGB(36, 26, 26)})
                Tween(knob, {Time = 0.2, Style = Enum.EasingStyle.Back}, {Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)})
                pcall(callback, state)
            end)
        end

        function Tab:CreateSlider(text, min, max, default, callback)
            local sFrame = Instance.new("Frame", scroll)
            sFrame.Size = UDim2.new(0.96, 0, 0, 50)
            sFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 6)
            local sfStroke = Instance.new("UIStroke", sFrame)
            sfStroke.Color = WindUI.CurrentTheme.Border
            sfStroke.Thickness = 1

            local lbl = Instance.new("TextLabel", sFrame)
            lbl.Text = text
            lbl.Size = UDim2.new(0.65, 0, 0, 20)
            lbl.Position = UDim2.new(0, 12, 0, 6)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = WindUI.CurrentTheme.Text
            lbl.Font = WindUI.CurrentFont
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left

            local valLbl = Instance.new("TextLabel", sFrame)
            valLbl.Text = tostring(default)
            valLbl.Size = UDim2.new(0.35, -12, 0, 20)
            valLbl.Position = UDim2.new(0.65, 0, 0, 6)
            valLbl.BackgroundTransparency = 1
            valLbl.TextColor3 = WindUI.CurrentTheme.Accent
            valLbl.Font = Enum.Font.GothamBold
            valLbl.TextSize = 11
            valLbl.TextXAlignment = Enum.TextXAlignment.Right

            local track = Instance.new("Frame", sFrame)
            track.Size = UDim2.new(1, -24, 0, 4)
            track.Position = UDim2.new(0, 12, 0, 34)
            track.BackgroundColor3 = Color3.fromRGB(30, 22, 22)
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame", track)
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = WindUI.CurrentTheme.Accent
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("TextButton", track)
            knob.Size = UDim2.new(0, 10, 0, 16)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
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
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
        end

        function Tab:CreateDropdown(text, options, callback)
            local scroll = self.Scroll
            local expanded = false
            local selected = options[1] or "None"
            local MAX_ROWS = 5
            local ITEM_H   = 34
            local visibleH = math.min(#options, MAX_ROWS) * ITEM_H
            local expandedH = 40 + 1 + 30 + 6 + visibleH + 6

            local dFrame = Instance.new("Frame", scroll)
            dFrame.Size = UDim2.new(0.96, 0, 0, 40)
            dFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            dFrame.ClipsDescendants = true
            Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0, 9)
            local dfStroke = Instance.new("UIStroke", dFrame)
            dfStroke.Color = WindUI.CurrentTheme.Border
            dfStroke.Thickness = 1

            local ddBar = Instance.new("Frame", dFrame)
            ddBar.Size = UDim2.new(0, 3, 0, 22)
            ddBar.Position = UDim2.new(0, 0, 0, 9)
            ddBar.BackgroundColor3 = WindUI.CurrentTheme.Accent
            ddBar.BackgroundTransparency = 0.3
            Instance.new("UICorner", ddBar).CornerRadius = UDim.new(1, 0)

            local header = Instance.new("TextButton", dFrame)
            header.Size = UDim2.new(1, 0, 0, 40)
            header.BackgroundTransparency = 1
            header.Text = ""

            local lbl = Instance.new("TextLabel", header)
            lbl.Text = text
            lbl.Size = UDim2.new(0.45, 0, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = WindUI.CurrentTheme.SubText
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = WindUI.CurrentFont
            lbl.TextSize = 11

            local selPill = Instance.new("Frame", header)
            selPill.Size = UDim2.new(0, 0, 0, 22)
            selPill.AutomaticSize = Enum.AutomaticSize.X
            selPill.Position = UDim2.new(0.45, 4, 0.5, -11)
            selPill.BackgroundColor3 = WindUI.CurrentTheme.Accent
            selPill.BackgroundTransparency = 0.78
            Instance.new("UICorner", selPill).CornerRadius = UDim.new(1, 0)
            local selPillPad = Instance.new("UIPadding", selPill)
            selPillPad.PaddingLeft = UDim.new(0, 8)
            selPillPad.PaddingRight = UDim.new(0, 8)
            local selPillStroke = Instance.new("UIStroke", selPill)
            selPillStroke.Color = WindUI.CurrentTheme.Accent
            selPillStroke.Thickness = 1
            selPillStroke.Transparency = 0.5

            local selLbl = Instance.new("TextLabel", selPill)
            selLbl.Text = selected
            selLbl.Size = UDim2.new(0, 0, 1, 0)
            selLbl.AutomaticSize = Enum.AutomaticSize.X
            selLbl.BackgroundTransparency = 1
            selLbl.TextColor3 = WindUI.CurrentTheme.Accent
            selLbl.Font = Enum.Font.GothamBold
            selLbl.TextSize = 10

            local arrow = Instance.new("ImageLabel", header)
            arrow.Size = UDim2.new(0, 13, 0, 13)
            arrow.Position = UDim2.new(1, -24, 0.5, -6.5)
            arrow.BackgroundTransparency = 1
            arrow.ImageColor3 = WindUI.CurrentTheme.Accent
            arrow.ImageTransparency = 0.4
            arrow.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(arrow, GetIcon("chevron-down")) end)

            local divider = Instance.new("Frame", dFrame)
            divider.Size = UDim2.new(1, -24, 0, 1)
            divider.Position = UDim2.new(0, 12, 0, 40)
            divider.BackgroundColor3 = WindUI.CurrentTheme.Border
            divider.BorderSizePixel = 0

            local searchFrame = Instance.new("Frame", dFrame)
            searchFrame.Size = UDim2.new(1, -16, 0, 26)
            searchFrame.Position = UDim2.new(0, 8, 0, 45)
            searchFrame.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
            local searchStroke = Instance.new("UIStroke", searchFrame)
            searchStroke.Color = WindUI.CurrentTheme.Border
            searchStroke.Thickness = 1

            local searchIco = Instance.new("ImageLabel", searchFrame)
            searchIco.Size = UDim2.new(0, 11, 0, 11)
            searchIco.Position = UDim2.new(0, 8, 0.5, -5.5)
            searchIco.BackgroundTransparency = 1
            searchIco.ImageColor3 = WindUI.CurrentTheme.SubText
            searchIco.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(searchIco, GetIcon("search")) end)

            local searchInput = Instance.new("TextBox", searchFrame)
            searchInput.Size = UDim2.new(1, -28, 1, 0)
            searchInput.Position = UDim2.new(0, 24, 0, 0)
            searchInput.BackgroundTransparency = 1
            searchInput.Font = Enum.Font.Gotham
            searchInput.Text = ""
            searchInput.PlaceholderText = "Search options..."
            searchInput.TextColor3 = WindUI.CurrentTheme.Text
            searchInput.PlaceholderColor3 = WindUI.CurrentTheme.SubText
            searchInput.TextSize = 10
            searchInput.TextXAlignment = Enum.TextXAlignment.Left
            searchInput.ClearTextOnFocus = false

            searchInput.Focused:Connect(function()
                Tween(searchStroke, {Time=0.15}, {Color = WindUI.CurrentTheme.Accent, Transparency = 0.4})
            end)
            searchInput.FocusLost:Connect(function()
                Tween(searchStroke, {Time=0.15}, {Color = WindUI.CurrentTheme.Border, Transparency = 0})
            end)

            local optCont = Instance.new("ScrollingFrame", dFrame)
            optCont.Size = UDim2.new(1, -8, 0, visibleH)
            optCont.Position = UDim2.new(0, 4, 0, 40 + 1 + 30 + 6)
            optCont.BackgroundTransparency = 1
            optCont.ScrollBarThickness = 2
            optCont.ScrollBarImageColor3 = WindUI.CurrentTheme.Accent
            optCont.ScrollBarImageTransparency = 0.5
            optCont.CanvasSize = UDim2.new(0, 0, 0, #options * ITEM_H)
            optCont.ClipsDescendants = true
            local optLayout = Instance.new("UIListLayout", optCont)
            optLayout.Padding = UDim.new(0, 2)
            local optPad = Instance.new("UIPadding", optCont)
            optPad.PaddingLeft = UDim.new(0, 4)
            optPad.PaddingRight = UDim.new(0, 4)

            local optButtons = {}

            for i, opt in ipairs(options) do
                local o = Instance.new("TextButton", optCont)
                o.Size = UDim2.new(1, 0, 0, ITEM_H - 2)
                o.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
                o.BackgroundTransparency = 1
                o.Text = ""
                Instance.new("UICorner", o).CornerRadius = UDim.new(0, 7)

                local checkIco = Instance.new("ImageLabel", o)
                checkIco.Size = UDim2.new(0, 11, 0, 11)
                checkIco.Position = UDim2.new(0, 8, 0.5, -5.5)
                checkIco.BackgroundTransparency = 1
                checkIco.ImageColor3 = WindUI.CurrentTheme.Accent
                checkIco.ImageTransparency = opt == selected and 0 or 1
                checkIco.ScaleType = Enum.ScaleType.Fit
                task.spawn(function() ApplyIcon(checkIco, GetIcon("check")) end)

                local oLbl = Instance.new("TextLabel", o)
                oLbl.Text = opt
                oLbl.Size = UDim2.new(1, -32, 1, 0)
                oLbl.Position = UDim2.new(0, 24, 0, 0)
                oLbl.BackgroundTransparency = 1
                oLbl.TextColor3 = opt == selected and WindUI.CurrentTheme.Text or WindUI.CurrentTheme.SubText
                oLbl.Font = opt == selected and Enum.Font.GothamBold or WindUI.CurrentFont
                oLbl.TextSize = 11
                oLbl.TextXAlignment = Enum.TextXAlignment.Left

                o.MouseEnter:Connect(function()
                    if opt ~= selected then
                        Tween(o, {Time=0.1}, {BackgroundTransparency = 0.88})
                        Tween(oLbl, {Time=0.1}, {TextColor3 = WindUI.CurrentTheme.Text})
                    end
                end)
                o.MouseLeave:Connect(function()
                    if opt ~= selected then
                        Tween(o, {Time=0.1}, {BackgroundTransparency = 1})
                        Tween(oLbl, {Time=0.1}, {TextColor3 = WindUI.CurrentTheme.SubText})
                    end
                end)
                o.MouseButton1Click:Connect(function()
                    for j, btn in ipairs(optButtons) do
                        local prevLbl = btn:FindFirstChildOfClass("TextLabel")
                        local prevIco = btn:FindFirstChildOfClass("ImageLabel")
                        if prevLbl then
                            Tween(prevLbl, {Time=0.12}, {TextColor3 = WindUI.CurrentTheme.SubText})
                            prevLbl.Font = WindUI.CurrentFont
                        end
                        if prevIco then Tween(prevIco, {Time=0.12}, {ImageTransparency = 1}) end
                        Tween(btn, {Time=0.12}, {BackgroundTransparency = 1})
                    end
                    selected = opt
                    selLbl.Text = opt
                    oLbl.Font = Enum.Font.GothamBold
                    Tween(oLbl, {Time=0.12}, {TextColor3 = WindUI.CurrentTheme.Text})
                    Tween(checkIco, {Time=0.12}, {ImageTransparency = 0})
                    Tween(o, {Time=0.12}, {BackgroundTransparency = 0.85})
                    expanded = false
                    searchInput.Text = ""
                    for _, btn in ipairs(optButtons) do btn.Visible = true end
                    optCont.CanvasSize = UDim2.new(0, 0, 0, #options * ITEM_H)
                    Tween(dFrame, {Time = 0.22, Style = Enum.EasingStyle.Quart}, {Size = UDim2.new(0.96, 0, 0, 40)})
                    Tween(arrow, {Time = 0.22}, {Rotation = 0})
                    Tween(dfStroke, {Time=0.15}, {Color = WindUI.CurrentTheme.Border})
                    pcall(callback, opt)
                end)

                optButtons[i] = o
            end

            searchInput:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchInput.Text:lower()
                local count = 0
                for i, btn in ipairs(optButtons) do
                    local match = q == "" or options[i]:lower():find(q, 1, true) ~= nil
                    btn.Visible = match
                    if match then count = count + 1 end
                end
                optCont.CanvasSize = UDim2.new(0, 0, 0, count * ITEM_H)
            end)

            header.MouseEnter:Connect(function()
                if not expanded then Tween(dFrame, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary}) end
            end)
            header.MouseLeave:Connect(function()
                if not expanded then Tween(dFrame, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary}) end
            end)

            header.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    Tween(dFrame, {Time = 0.28, Style = Enum.EasingStyle.Quart}, {Size = UDim2.new(0.96, 0, 0, expandedH), BackgroundColor3 = WindUI.CurrentTheme.Secondary})
                    Tween(dfStroke, {Time=0.2}, {Color = WindUI.CurrentTheme.Accent, Transparency = 0.55})
                    Tween(ddBar, {Time=0.15}, {BackgroundTransparency = 0})
                else
                    Tween(dFrame, {Time = 0.22, Style = Enum.EasingStyle.Quart}, {Size = UDim2.new(0.96, 0, 0, 40)})
                    Tween(dfStroke, {Time=0.15}, {Color = WindUI.CurrentTheme.Border, Transparency = 0})
                    Tween(ddBar, {Time=0.15}, {BackgroundTransparency = 0.3})
                    searchInput.Text = ""
                    for _, btn in ipairs(optButtons) do btn.Visible = true end
                    optCont.CanvasSize = UDim2.new(0, 0, 0, #options * ITEM_H)
                end
                Tween(arrow, {Time = 0.25}, {Rotation = expanded and 180 or 0})
            end)
        end

        function Tab:CreateMultiDropdown(text, options, callback)
            local scroll = self.Scroll
            local selected = {}
            local expanded = false
            local MAX_ROWS = 5
            local ITEM_H   = 34
            local visibleH = math.min(#options, MAX_ROWS) * ITEM_H
            local expandedH = 40 + 1 + 30 + 6 + visibleH + 6

            local dFrame = Instance.new("Frame", scroll)
            dFrame.Size = UDim2.new(0.96, 0, 0, 40)
            dFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            dFrame.ClipsDescendants = true
            Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0, 9)
            local dfStroke = Instance.new("UIStroke", dFrame)
            dfStroke.Color = WindUI.CurrentTheme.Border
            dfStroke.Thickness = 1

            local ddBar = Instance.new("Frame", dFrame)
            ddBar.Size = UDim2.new(0, 3, 0, 22)
            ddBar.Position = UDim2.new(0, 0, 0, 9)
            ddBar.BackgroundColor3 = WindUI.CurrentTheme.Accent
            ddBar.BackgroundTransparency = 0.3
            Instance.new("UICorner", ddBar).CornerRadius = UDim.new(1, 0)

            local header = Instance.new("TextButton", dFrame)
            header.Size = UDim2.new(1, 0, 0, 40)
            header.BackgroundTransparency = 1
            header.Text = ""

            local lbl = Instance.new("TextLabel", header)
            lbl.Text = text
            lbl.Size = UDim2.new(0.45, 0, 1, 0)
            lbl.Position = UDim2.new(0, 14, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = WindUI.CurrentTheme.SubText
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Font = WindUI.CurrentFont
            lbl.TextSize = 11

            local selPill = Instance.new("Frame", header)
            selPill.Size = UDim2.new(0, 0, 0, 22)
            selPill.AutomaticSize = Enum.AutomaticSize.X
            selPill.Position = UDim2.new(0.45, 4, 0.5, -11)
            selPill.BackgroundColor3 = WindUI.CurrentTheme.Accent
            selPill.BackgroundTransparency = 0.78
            Instance.new("UICorner", selPill).CornerRadius = UDim.new(1, 0)
            local selPillPad = Instance.new("UIPadding", selPill)
            selPillPad.PaddingLeft = UDim.new(0, 8)
            selPillPad.PaddingRight = UDim.new(0, 8)
            local selPillStroke = Instance.new("UIStroke", selPill)
            selPillStroke.Color = WindUI.CurrentTheme.Accent
            selPillStroke.Thickness = 1
            selPillStroke.Transparency = 0.5

            local selLbl = Instance.new("TextLabel", selPill)
            selLbl.Text = "0 selected"
            selLbl.Size = UDim2.new(0, 0, 1, 0)
            selLbl.AutomaticSize = Enum.AutomaticSize.X
            selLbl.BackgroundTransparency = 1
            selLbl.TextColor3 = WindUI.CurrentTheme.Accent
            selLbl.Font = Enum.Font.GothamBold
            selLbl.TextSize = 10

            local arrow = Instance.new("ImageLabel", header)
            arrow.Size = UDim2.new(0, 13, 0, 13)
            arrow.Position = UDim2.new(1, -24, 0.5, -6.5)
            arrow.BackgroundTransparency = 1
            arrow.ImageColor3 = WindUI.CurrentTheme.Accent
            arrow.ImageTransparency = 0.4
            arrow.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(arrow, GetIcon("chevron-down")) end)

            local divider = Instance.new("Frame", dFrame)
            divider.Size = UDim2.new(1, -24, 0, 1)
            divider.Position = UDim2.new(0, 12, 0, 40)
            divider.BackgroundColor3 = WindUI.CurrentTheme.Border
            divider.BorderSizePixel = 0

            local searchFrame = Instance.new("Frame", dFrame)
            searchFrame.Size = UDim2.new(1, -16, 0, 26)
            searchFrame.Position = UDim2.new(0, 8, 0, 45)
            searchFrame.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
            local searchStroke = Instance.new("UIStroke", searchFrame)
            searchStroke.Color = WindUI.CurrentTheme.Border
            searchStroke.Thickness = 1

            local searchIco = Instance.new("ImageLabel", searchFrame)
            searchIco.Size = UDim2.new(0, 11, 0, 11)
            searchIco.Position = UDim2.new(0, 8, 0.5, -5.5)
            searchIco.BackgroundTransparency = 1
            searchIco.ImageColor3 = WindUI.CurrentTheme.SubText
            searchIco.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(searchIco, GetIcon("search")) end)

            local searchInput = Instance.new("TextBox", searchFrame)
            searchInput.Size = UDim2.new(1, -28, 1, 0)
            searchInput.Position = UDim2.new(0, 24, 0, 0)
            searchInput.BackgroundTransparency = 1
            searchInput.Font = Enum.Font.Gotham
            searchInput.Text = ""
            searchInput.PlaceholderText = "Search options..."
            searchInput.TextColor3 = WindUI.CurrentTheme.Text
            searchInput.PlaceholderColor3 = WindUI.CurrentTheme.SubText
            searchInput.TextSize = 10
            searchInput.TextXAlignment = Enum.TextXAlignment.Left
            searchInput.ClearTextOnFocus = false

            searchInput.Focused:Connect(function()
                Tween(searchStroke, {Time=0.15}, {Color = WindUI.CurrentTheme.Accent, Transparency = 0.4})
            end)
            searchInput.FocusLost:Connect(function()
                Tween(searchStroke, {Time=0.15}, {Color = WindUI.CurrentTheme.Border, Transparency = 0})
            end)

            local optCont = Instance.new("ScrollingFrame", dFrame)
            optCont.Size = UDim2.new(1, -8, 0, visibleH)
            optCont.Position = UDim2.new(0, 4, 0, 40 + 1 + 30 + 6)
            optCont.BackgroundTransparency = 1
            optCont.ScrollBarThickness = 2
            optCont.ScrollBarImageColor3 = WindUI.CurrentTheme.Accent
            optCont.ScrollBarImageTransparency = 0.5
            optCont.CanvasSize = UDim2.new(0, 0, 0, #options * ITEM_H)
            optCont.ClipsDescendants = true
            local optLayout = Instance.new("UIListLayout", optCont)
            optLayout.Padding = UDim.new(0, 2)
            local optPad = Instance.new("UIPadding", optCont)
            optPad.PaddingLeft = UDim.new(0, 4)
            optPad.PaddingRight = UDim.new(0, 4)

            local optButtons = {}

            local function UpdateBadge()
                local count = 0
                for _ in pairs(selected) do count = count + 1 end
                selLbl.Text = count > 0 and (tostring(count) .. " selected") or "0 selected"
            end

            for i, opt in ipairs(options) do
                local o = Instance.new("TextButton", optCont)
                o.Size = UDim2.new(1, 0, 0, ITEM_H - 2)
                o.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
                o.BackgroundTransparency = 1
                o.Text = ""
                Instance.new("UICorner", o).CornerRadius = UDim.new(0, 7)

                local checkBox = Instance.new("Frame", o)
                checkBox.Size = UDim2.new(0, 14, 0, 14)
                checkBox.Position = UDim2.new(0, 8, 0.5, -7)
                checkBox.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
                Instance.new("UICorner", checkBox).CornerRadius = UDim.new(0, 3)
                local checkBoxStroke = Instance.new("UIStroke", checkBox)
                checkBoxStroke.Color = WindUI.CurrentTheme.Border
                checkBoxStroke.Thickness = 1.2

                local checkIco = Instance.new("ImageLabel", checkBox)
                checkIco.Size = UDim2.new(0, 9, 0, 9)
                checkIco.Position = UDim2.new(0.5, 0, 0.5, 0)
                checkIco.AnchorPoint = Vector2.new(0.5, 0.5)
                checkIco.BackgroundTransparency = 1
                checkIco.ImageColor3 = Color3.fromRGB(255, 255, 255)
                checkIco.ImageTransparency = 1
                checkIco.ScaleType = Enum.ScaleType.Fit
                task.spawn(function() ApplyIcon(checkIco, GetIcon("check")) end)

                local oLbl = Instance.new("TextLabel", o)
                oLbl.Text = opt
                oLbl.Size = UDim2.new(1, -36, 1, 0)
                oLbl.Position = UDim2.new(0, 28, 0, 0)
                oLbl.BackgroundTransparency = 1
                oLbl.TextColor3 = WindUI.CurrentTheme.SubText
                oLbl.Font = WindUI.CurrentFont
                oLbl.TextSize = 11
                oLbl.TextXAlignment = Enum.TextXAlignment.Left

                o.MouseEnter:Connect(function()
                    if not selected[opt] then
                        Tween(o, {Time=0.1}, {BackgroundTransparency = 0.88})
                        Tween(oLbl, {Time=0.1}, {TextColor3 = WindUI.CurrentTheme.Text})
                    end
                end)
                o.MouseLeave:Connect(function()
                    if not selected[opt] then
                        Tween(o, {Time=0.1}, {BackgroundTransparency = 1})
                        Tween(oLbl, {Time=0.1}, {TextColor3 = WindUI.CurrentTheme.SubText})
                    end
                end)
                o.MouseButton1Click:Connect(function()
                    if selected[opt] then
                        selected[opt] = nil
                        Tween(checkBox, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary})
                        Tween(checkBoxStroke, {Time=0.12}, {Color = WindUI.CurrentTheme.Border})
                        Tween(checkIco, {Time=0.12}, {ImageTransparency = 1})
                        Tween(oLbl, {Time=0.12}, {TextColor3 = WindUI.CurrentTheme.SubText})
                        oLbl.Font = WindUI.CurrentFont
                        Tween(o, {Time=0.12}, {BackgroundTransparency = 1})
                    else
                        selected[opt] = true
                        Tween(checkBox, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Accent})
                        Tween(checkBoxStroke, {Time=0.12}, {Color = WindUI.CurrentTheme.Accent})
                        Tween(checkIco, {Time=0.12}, {ImageTransparency = 0})
                        Tween(oLbl, {Time=0.12}, {TextColor3 = WindUI.CurrentTheme.Text})
                        oLbl.Font = Enum.Font.GothamBold
                        Tween(o, {Time=0.12}, {BackgroundTransparency = 0.85})
                    end
                    UpdateBadge()
                    local result = {}
                    for k in pairs(selected) do table.insert(result, k) end
                    pcall(callback, result)
                end)

                optButtons[i] = o
            end

            searchInput:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchInput.Text:lower()
                local count = 0
                for i, btn in ipairs(optButtons) do
                    local match = q == "" or options[i]:lower():find(q, 1, true) ~= nil
                    btn.Visible = match
                    if match then count = count + 1 end
                end
                optCont.CanvasSize = UDim2.new(0, 0, 0, count * ITEM_H)
            end)

            header.MouseEnter:Connect(function()
                if not expanded then Tween(dFrame, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary}) end
            end)
            header.MouseLeave:Connect(function()
                if not expanded then Tween(dFrame, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary}) end
            end)

            header.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    Tween(dFrame, {Time = 0.28, Style = Enum.EasingStyle.Quart}, {Size = UDim2.new(0.96, 0, 0, expandedH), BackgroundColor3 = WindUI.CurrentTheme.Secondary})
                    Tween(dfStroke, {Time=0.2}, {Color = WindUI.CurrentTheme.Accent, Transparency = 0.55})
                    Tween(ddBar, {Time=0.15}, {BackgroundTransparency = 0})
                else
                    Tween(dFrame, {Time = 0.22, Style = Enum.EasingStyle.Quart}, {Size = UDim2.new(0.96, 0, 0, 40)})
                    Tween(dfStroke, {Time=0.15}, {Color = WindUI.CurrentTheme.Border, Transparency = 0})
                    Tween(ddBar, {Time=0.15}, {BackgroundTransparency = 0.3})
                    searchInput.Text = ""
                    for _, btn in ipairs(optButtons) do btn.Visible = true end
                    optCont.CanvasSize = UDim2.new(0, 0, 0, #options * ITEM_H)
                end
                Tween(arrow, {Time = 0.25}, {Rotation = expanded and 180 or 0})
            end)
        end

        function Tab:CreateConfirmButton(text, confirmText, callback, iconName)
            local b = Instance.new("TextButton", scroll)
            b.Size = UDim2.new(0.96, 0, 0, 34)
            b.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            b.Text = ""
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            local bStroke = Instance.new("UIStroke", b)
            bStroke.Color = WindUI.CurrentTheme.Border
            bStroke.Thickness = 1

            local iconImg = Instance.new("ImageLabel", b)
            iconImg.Size = UDim2.new(0, 13, 0, 13)
            iconImg.Position = UDim2.new(0, 12, 0.5, -6.5)
            iconImg.BackgroundTransparency = 1
            iconImg.ImageColor3 = WindUI.CurrentTheme.Accent
            iconImg.ScaleType = Enum.ScaleType.Fit
            iconImg.Visible = false

            local textOffset = 12
            if iconName then
                task.spawn(function()
                    local iconData = GetIcon(iconName)
                    if iconData then ApplyIcon(iconImg, iconData); iconImg.Visible = true end
                end)
                textOffset = 30
            end

            local bLbl = Instance.new("TextLabel", b)
            bLbl.Text = text
            bLbl.Size = UDim2.new(1, -(textOffset + 28), 1, 0)
            bLbl.Position = UDim2.new(0, textOffset, 0, 0)
            bLbl.BackgroundTransparency = 1
            bLbl.Font = WindUI.CurrentFont
            bLbl.TextColor3 = WindUI.CurrentTheme.Text
            bLbl.TextSize = 11
            bLbl.TextXAlignment = Enum.TextXAlignment.Left

            local warnImg = Instance.new("ImageLabel", b)
            warnImg.Size = UDim2.new(0, 11, 0, 11)
            warnImg.Position = UDim2.new(1, -22, 0.5, -5.5)
            warnImg.BackgroundTransparency = 1
            warnImg.ImageColor3 = WindUI.CurrentTheme.Accent
            warnImg.ImageTransparency = 0.5
            warnImg.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(warnImg, GetIcon("alert-triangle")) end)

            b.MouseEnter:Connect(function()
                Tween(b, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary})
                Tween(bStroke, {Time=0.12}, {Color = WindUI.CurrentTheme.Accent, Transparency = 0.5})
                Tween(warnImg, {Time=0.12}, {ImageTransparency = 0})
            end)
            b.MouseLeave:Connect(function()
                Tween(b, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary})
                Tween(bStroke, {Time=0.12}, {Color = WindUI.CurrentTheme.Border, Transparency = 0})
                Tween(warnImg, {Time=0.12}, {ImageTransparency = 0.5})
            end)

            b.MouseButton1Click:Connect(function()
                Tween(b, {Time=0.07}, {BackgroundColor3 = WindUI.CurrentTheme.AccentDark})
                task.delay(0.1, function() Tween(b, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary}) end)
                pcall(callback)
            end)
        end

        function Tab:CreateInput(text, placeholder, callback)
            local iFrame = Instance.new("Frame", scroll)
            iFrame.Size = UDim2.new(0.96, 0, 0, 48)
            iFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            Instance.new("UICorner", iFrame).CornerRadius = UDim.new(0, 8)
            local ifStroke = Instance.new("UIStroke", iFrame)
            ifStroke.Color = WindUI.CurrentTheme.Border
            ifStroke.Thickness = 1

            local bar = Instance.new("Frame", iFrame)
            bar.Size = UDim2.new(0, 3, 0, 26)
            bar.Position = UDim2.new(0, 0, 0.5, -13)
            bar.BackgroundColor3 = WindUI.CurrentTheme.Accent
            bar.BackgroundTransparency = 1
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            local iLbl = Instance.new("TextLabel", iFrame)
            iLbl.Text = text
            iLbl.Size = UDim2.new(1, -20, 0, 18)
            iLbl.Position = UDim2.new(0, 14, 0, 6)
            iLbl.BackgroundTransparency = 1
            iLbl.Font = WindUI.CurrentFont
            iLbl.TextColor3 = WindUI.CurrentTheme.SubText
            iLbl.TextSize = 10
            iLbl.TextXAlignment = Enum.TextXAlignment.Left

            local inputBox = Instance.new("TextBox", iFrame)
            inputBox.Size = UDim2.new(1, -28, 0, 22)
            inputBox.Position = UDim2.new(0, 14, 0, 24)
            inputBox.BackgroundTransparency = 1
            inputBox.Font = WindUI.CurrentFont
            inputBox.Text = ""
            inputBox.PlaceholderText = placeholder or "Type here..."
            inputBox.TextColor3 = WindUI.CurrentTheme.Text
            inputBox.PlaceholderColor3 = WindUI.CurrentTheme.SubText
            inputBox.TextSize = 12
            inputBox.TextXAlignment = Enum.TextXAlignment.Left
            inputBox.ClearTextOnFocus = false

            inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                pcall(callback, inputBox.Text)
            end)
            inputBox.Focused:Connect(function()
                Tween(ifStroke, {Time=0.2}, {Color = WindUI.CurrentTheme.Accent, Transparency = 0.4})
                Tween(bar, {Time=0.2}, {BackgroundTransparency = 0})
            end)
            inputBox.FocusLost:Connect(function()
                Tween(ifStroke, {Time=0.2}, {Color = WindUI.CurrentTheme.Border, Transparency = 0})
                Tween(bar, {Time=0.2}, {BackgroundTransparency = 1})
            end)
        end

        function Tab:CreateKeybind(text, default, callback)
            local currentKey = default or Enum.KeyCode.Unknown
            local binding = false

            local kFrame = Instance.new("TextButton", scroll)
            kFrame.Size = UDim2.new(0.96, 0, 0, 36)
            kFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            kFrame.Text = ""
            Instance.new("UICorner", kFrame).CornerRadius = UDim.new(0, 6)
            local kStroke = Instance.new("UIStroke", kFrame)
            kStroke.Color = WindUI.CurrentTheme.Border
            kStroke.Thickness = 1

            local kIco = Instance.new("ImageLabel", kFrame)
            kIco.Size = UDim2.new(0, 13, 0, 13)
            kIco.Position = UDim2.new(0, 12, 0.5, -6.5)
            kIco.BackgroundTransparency = 1
            kIco.ImageColor3 = WindUI.CurrentTheme.Accent
            kIco.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(kIco, GetIcon("keyboard")) end)

            local kLbl = Instance.new("TextLabel", kFrame)
            kLbl.Text = text
            kLbl.Size = UDim2.new(0.6, 0, 1, 0)
            kLbl.Position = UDim2.new(0, 30, 0, 0)
            kLbl.BackgroundTransparency = 1
            kLbl.Font = WindUI.CurrentFont
            kLbl.TextColor3 = WindUI.CurrentTheme.Text
            kLbl.TextSize = 11
            kLbl.TextXAlignment = Enum.TextXAlignment.Left

            local kBadge = Instance.new("Frame", kFrame)
            kBadge.Size = UDim2.new(0, 68, 0, 20)
            kBadge.Position = UDim2.new(1, -78, 0.5, -10)
            kBadge.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            Instance.new("UICorner", kBadge).CornerRadius = UDim.new(0, 5)
            local kbStroke = Instance.new("UIStroke", kBadge)
            kbStroke.Color = WindUI.CurrentTheme.Accent
            kbStroke.Thickness = 1
            kbStroke.Transparency = 0.5

            local kValLbl = Instance.new("TextLabel", kBadge)
            kValLbl.Size = UDim2.new(1, 0, 1, 0)
            kValLbl.BackgroundTransparency = 1
            kValLbl.Font = Enum.Font.GothamBold
            kValLbl.TextColor3 = WindUI.CurrentTheme.Accent
            kValLbl.TextSize = 9
            kValLbl.Text = tostring(currentKey):gsub("Enum.KeyCode.", "")

            kFrame.MouseEnter:Connect(function() Tween(kFrame, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary}) end)
            kFrame.MouseLeave:Connect(function() Tween(kFrame, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary}) end)

            kFrame.MouseButton1Click:Connect(function()
                if binding then return end
                binding = true
                kValLbl.Text = "· · ·"
                kValLbl.TextColor3 = WindUI.CurrentTheme.SubText
                Tween(kbStroke, {Time=0.15}, {Transparency = 0})

                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        kValLbl.Text = tostring(currentKey):gsub("Enum.KeyCode.", "")
                        kValLbl.TextColor3 = WindUI.CurrentTheme.Accent
                        Tween(kbStroke, {Time=0.15}, {Transparency = 0.5})
                        binding = false
                        conn:Disconnect()
                        pcall(callback, currentKey)
                    end
                end)
            end)
        end

        function Tab:CreateLabel(title, desc)
            local lFrame = Instance.new("Frame", scroll)
            local hasDesc = desc and desc ~= ""
            lFrame.Size = UDim2.new(0.96, 0, 0, hasDesc and 46 or 30)
            lFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            lFrame.BackgroundTransparency = 0
            Instance.new("UICorner", lFrame).CornerRadius = UDim.new(0, 6)
            local lfStroke = Instance.new("UIStroke", lFrame)
            lfStroke.Color = WindUI.CurrentTheme.Border
            lfStroke.Thickness = 1

            local bar = Instance.new("Frame", lFrame)
            bar.Size = UDim2.new(0, 2, 0, hasDesc and 26 or 14)
            bar.Position = UDim2.new(0, 0, 0.5, hasDesc and -13 or -7)
            bar.BackgroundColor3 = WindUI.CurrentTheme.Accent
            bar.BackgroundTransparency = 0.4
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            local tLbl = Instance.new("TextLabel", lFrame)
            tLbl.Text = title
            tLbl.Size = UDim2.new(1, -20, 0, 16)
            tLbl.Position = UDim2.new(0, 10, 0, hasDesc and 7 or 7)
            tLbl.BackgroundTransparency = 1
            tLbl.Font = Enum.Font.GothamBold
            tLbl.TextColor3 = WindUI.CurrentTheme.Text
            tLbl.TextSize = 11
            tLbl.TextXAlignment = Enum.TextXAlignment.Left

            if hasDesc then
                local dLbl = Instance.new("TextLabel", lFrame)
                dLbl.Text = desc
                dLbl.Size = UDim2.new(1, -20, 0, 14)
                dLbl.Position = UDim2.new(0, 10, 0, 25)
                dLbl.BackgroundTransparency = 1
                dLbl.Font = Enum.Font.GothamMedium
                dLbl.TextColor3 = WindUI.CurrentTheme.SubText
                dLbl.TextSize = 9
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.TextWrapped = true
            end
        end

        function Tab:CreateParagraph(title, body)
            local pFrame = Instance.new("Frame", scroll)
            pFrame.Size = UDim2.new(0.95, 0, 0, 0)
            pFrame.AutomaticSize = Enum.AutomaticSize.Y
            pFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            pFrame.BackgroundTransparency = 0.3
            Instance.new("UICorner", pFrame).CornerRadius = UDim.new(0, 8)
            local pStroke = Instance.new("UIStroke", pFrame)
            pStroke.Color = WindUI.CurrentTheme.Border
            pStroke.Thickness = 1
            local pPad = Instance.new("UIPadding", pFrame)
            pPad.PaddingTop = UDim.new(0, 10)
            pPad.PaddingBottom = UDim.new(0, 10)
            pPad.PaddingLeft = UDim.new(0, 7)
            pPad.PaddingRight = UDim.new(0, 7)
            local pLayout = Instance.new("UIListLayout", pFrame)
            pLayout.Padding = UDim.new(0, 4)

            local bar = Instance.new("Frame", pFrame)
            bar.Size = UDim2.new(0, 3, 0, 14)
            bar.BackgroundColor3 = WindUI.CurrentTheme.Accent
            bar.BackgroundTransparency = 0.3
            bar.Position = UDim2.new(0, -14, 0, 10)
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

            local tLbl = Instance.new("TextLabel", pFrame)
            tLbl.Text = title
            tLbl.Size = UDim2.new(1, 0, 0, 0)
            tLbl.AutomaticSize = Enum.AutomaticSize.Y
            tLbl.BackgroundTransparency = 1
            tLbl.Font = Enum.Font.GothamBold
            tLbl.TextColor3 = WindUI.CurrentTheme.Text
            tLbl.TextSize = 12
            tLbl.TextXAlignment = Enum.TextXAlignment.Left
            tLbl.TextWrapped = true

            local bLbl = Instance.new("TextLabel", pFrame)
            bLbl.Text = body
            bLbl.Size = UDim2.new(1, 0, 0, 0)
            bLbl.AutomaticSize = Enum.AutomaticSize.Y
            bLbl.BackgroundTransparency = 1
            bLbl.Font = Enum.Font.GothamMedium
            bLbl.TextColor3 = WindUI.CurrentTheme.SubText
            bLbl.TextSize = 11
            bLbl.TextXAlignment = Enum.TextXAlignment.Left
            bLbl.TextWrapped = true
        end

        function Tab:CreateCheckbox(text, default, callback)
            local state = default or false

            local cBtn = Instance.new("TextButton", scroll)
            cBtn.Size = UDim2.new(0.96, 0, 0, 34)
            cBtn.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            cBtn.Text = ""
            Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)
            local cStroke = Instance.new("UIStroke", cBtn)
            cStroke.Color = WindUI.CurrentTheme.Border
            cStroke.Thickness = 1

            local box = Instance.new("Frame", cBtn)
            box.Size = UDim2.new(0, 16, 0, 16)
            box.Position = UDim2.new(0, 12, 0.5, -8)
            box.BackgroundColor3 = state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Tertiary
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
            local boxStroke = Instance.new("UIStroke", box)
            boxStroke.Color = state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Border
            boxStroke.Thickness = 1.2

            local checkIco = Instance.new("ImageLabel", box)
            checkIco.Size = UDim2.new(0, 10, 0, 10)
            checkIco.Position = UDim2.new(0.5, 0, 0.5, 0)
            checkIco.AnchorPoint = Vector2.new(0.5, 0.5)
            checkIco.BackgroundTransparency = 1
            checkIco.ImageColor3 = Color3.fromRGB(255, 255, 255)
            checkIco.ImageTransparency = state and 0 or 1
            checkIco.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(checkIco, GetIcon("check")) end)

            local cLbl = Instance.new("TextLabel", cBtn)
            cLbl.Text = text
            cLbl.Size = UDim2.new(1, -46, 1, 0)
            cLbl.Position = UDim2.new(0, 34, 0, 0)
            cLbl.BackgroundTransparency = 1
            cLbl.Font = WindUI.CurrentFont
            cLbl.TextColor3 = WindUI.CurrentTheme.Text
            cLbl.TextSize = 11
            cLbl.TextXAlignment = Enum.TextXAlignment.Left

            cBtn.MouseEnter:Connect(function() Tween(cBtn, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Tertiary}) end)
            cBtn.MouseLeave:Connect(function() Tween(cBtn, {Time=0.12}, {BackgroundColor3 = WindUI.CurrentTheme.Secondary}) end)
            cBtn.MouseButton1Click:Connect(function()
                state = not state
                Tween(box, {Time=0.15}, {BackgroundColor3 = state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Tertiary})
                Tween(boxStroke, {Time=0.15}, {Color = state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Border})
                Tween(checkIco, {Time=0.12}, {ImageTransparency = state and 0 or 1})
                pcall(callback, state)
            end)
        end

        function Tab:CreateDivider(label)
            local dWrap = Instance.new("Frame", scroll)
            dWrap.Size = UDim2.new(0.96, 0, 0, 20)
            dWrap.BackgroundTransparency = 1

            local line1 = Instance.new("Frame", dWrap)
            line1.Size = UDim2.new(0.5, -48, 0, 1)
            line1.Position = UDim2.new(0, 0, 0.5, 0)
            line1.BackgroundColor3 = WindUI.CurrentTheme.Border
            line1.BorderSizePixel = 0

            local line2 = Instance.new("Frame", dWrap)
            line2.Size = UDim2.new(0.5, -48, 0, 1)
            line2.Position = UDim2.new(0.5, 48, 0.5, 0)
            line2.BackgroundColor3 = WindUI.CurrentTheme.Border
            line2.BorderSizePixel = 0

            if label and label ~= "" then
                local dLbl = Instance.new("TextLabel", dWrap)
                dLbl.Text = label:upper()
                dLbl.Size = UDim2.new(0, 90, 1, 0)
                dLbl.Position = UDim2.new(0.5, -45, 0, 0)
                dLbl.BackgroundTransparency = 1
                dLbl.Font = Enum.Font.GothamBold
                dLbl.TextColor3 = WindUI.CurrentTheme.SubText
                dLbl.TextSize = 8
                dLbl.TextXAlignment = Enum.TextXAlignment.Center
            else
                local dot = Instance.new("Frame", dWrap)
                dot.Size = UDim2.new(0, 3, 0, 3)
                dot.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
                dot.BackgroundColor3 = WindUI.CurrentTheme.Accent
                dot.BackgroundTransparency = 0.5
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            end
        end

        function Tab:CreateCode(title, code)
            local codeFrame = Instance.new("Frame", scroll)
            codeFrame.Size = UDim2.new(0.95, 0, 0, 0)
            codeFrame.AutomaticSize = Enum.AutomaticSize.Y
            codeFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
            Instance.new("UICorner", codeFrame).CornerRadius = UDim.new(0, 7)
            local cStroke = Instance.new("UIStroke", codeFrame)
            cStroke.Color = WindUI.CurrentTheme.Border
            cStroke.Thickness = 1

            local header = Instance.new("Frame", codeFrame)
            header.Size = UDim2.new(1, 0, 0, 30)
            header.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            header.BackgroundTransparency = 0.5
            Instance.new("UICorner", header).CornerRadius = UDim.new(0, 7)

            local headFill = Instance.new("Frame", header)
            headFill.Size = UDim2.new(1, 0, 0.5, 0)
            headFill.Position = UDim2.new(0, 0, 0.5, 0)
            headFill.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            headFill.BackgroundTransparency = 0.5
            headFill.BorderSizePixel = 0

            local codeIco = Instance.new("ImageLabel", header)
            codeIco.Size = UDim2.new(0, 13, 0, 13)
            codeIco.Position = UDim2.new(0, 10, 0.5, -6.5)
            codeIco.BackgroundTransparency = 1
            codeIco.ImageColor3 = WindUI.CurrentTheme.Accent
            codeIco.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(codeIco, GetIcon("code")) end)

            local titleLbl = Instance.new("TextLabel", header)
            titleLbl.Text = title or "Code"
            titleLbl.Size = UDim2.new(0.6, 0, 1, 0)
            titleLbl.Position = UDim2.new(0, 28, 0, 0)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Font = Enum.Font.GothamBold
            titleLbl.TextColor3 = WindUI.CurrentTheme.SubText
            titleLbl.TextSize = 10
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left

            local copyBtn = Instance.new("TextButton", header)
            copyBtn.Size = UDim2.new(0, 52, 0, 20)
            copyBtn.Position = UDim2.new(1, -60, 0.5, -10)
            copyBtn.BackgroundColor3 = WindUI.CurrentTheme.Accent
            copyBtn.BackgroundTransparency = 0.8
            copyBtn.Text = "Copy"
            copyBtn.Font = Enum.Font.GothamBold
            copyBtn.TextColor3 = WindUI.CurrentTheme.Accent
            copyBtn.TextSize = 9
            Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(1, 0)

            local codePad = Instance.new("UIPadding", codeFrame)
            codePad.PaddingTop = UDim.new(0, 30)
            codePad.PaddingLeft = UDim.new(0, 12)
            codePad.PaddingRight = UDim.new(0, 12)
            codePad.PaddingBottom = UDim.new(0, 10)

            local codeLbl = Instance.new("TextLabel", codeFrame)
            codeLbl.Text = code or ""
            codeLbl.Size = UDim2.new(1, 0, 0, 0)
            codeLbl.AutomaticSize = Enum.AutomaticSize.Y
            codeLbl.BackgroundTransparency = 1
            codeLbl.Font = Enum.Font.Code
            codeLbl.TextColor3 = Color3.fromRGB(180, 220, 180)
            codeLbl.TextSize = 11
            codeLbl.TextXAlignment = Enum.TextXAlignment.Left
            codeLbl.TextYAlignment = Enum.TextYAlignment.Top
            codeLbl.TextWrapped = true
            codeLbl.RichText = false

            copyBtn.MouseButton1Click:Connect(function()
                pcall(function() setclipboard(code) end)
                copyBtn.Text = "✓"
                copyBtn.TextColor3 = Color3.fromRGB(100, 220, 140)
                task.delay(1.5, function()
                    copyBtn.Text = "Copy"
                    copyBtn.TextColor3 = WindUI.CurrentTheme.Accent
                end)
            end)
        end

        function Tab:CreateMultiSection(sectionName, tabs)
            local msFrame = Instance.new("Frame", scroll)
            msFrame.Size = UDim2.new(0.95, 0, 0, 0)
            msFrame.AutomaticSize = Enum.AutomaticSize.Y
            msFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
            msFrame.BackgroundTransparency = 0
            Instance.new("UICorner", msFrame).CornerRadius = UDim.new(0, 10)
            local msStroke = Instance.new("UIStroke", msFrame)
            msStroke.Color = WindUI.CurrentTheme.Border
            msStroke.Thickness = 1

            local msLayout = Instance.new("UIListLayout", msFrame)
            msLayout.Padding = UDim.new(0, 0)

            local msHeader = Instance.new("Frame", msFrame)
            msHeader.Size = UDim2.new(1, 0, 0, 36)
            msHeader.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            msHeader.BackgroundTransparency = 0
            Instance.new("UICorner", msHeader).CornerRadius = UDim.new(0, 10)
            local msHFill = Instance.new("Frame", msHeader)
            msHFill.Size = UDim2.new(1, 0, 0.5, 0)
            msHFill.Position = UDim2.new(0, 0, 0.5, 0)
            msHFill.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            msHFill.BorderSizePixel = 0

            local msHBar = Instance.new("Frame", msHeader)
            msHBar.Size = UDim2.new(0, 3, 0, 16)
            msHBar.Position = UDim2.new(0, 12, 0.5, -8)
            msHBar.BackgroundColor3 = WindUI.CurrentTheme.Accent
            Instance.new("UICorner", msHBar).CornerRadius = UDim.new(1, 0)

            local msHTitle = Instance.new("TextLabel", msHeader)
            msHTitle.Text = sectionName:upper()
            msHTitle.Size = UDim2.new(1, -30, 1, 0)
            msHTitle.Position = UDim2.new(0, 22, 0, 0)
            msHTitle.BackgroundTransparency = 1
            msHTitle.Font = Enum.Font.GothamBold
            msHTitle.TextColor3 = WindUI.CurrentTheme.Text
            msHTitle.TextSize = 10
            msHTitle.TextXAlignment = Enum.TextXAlignment.Left

            local tabBarWrapper = Instance.new("Frame", msFrame)
            tabBarWrapper.Size = UDim2.new(1, 0, 0, 36)
            tabBarWrapper.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
            tabBarWrapper.BackgroundTransparency = 0.5
            tabBarWrapper.BorderSizePixel = 0
            tabBarWrapper.ClipsDescendants = true

            local tabBar = Instance.new("Frame", tabBarWrapper)
            tabBar.Size = UDim2.new(1, -16, 1, -8)
            tabBar.Position = UDim2.new(0, 8, 0, 4)
            tabBar.BackgroundColor3 = WindUI.CurrentTheme.Background
            tabBar.BackgroundTransparency = 0.4
            Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 7)

            local indicatorLayer = Instance.new("Frame", tabBarWrapper)
            indicatorLayer.Size = UDim2.new(1, -16, 1, -8)
            indicatorLayer.Position = UDim2.new(0, 8, 0, 4)
            indicatorLayer.BackgroundTransparency = 1
            indicatorLayer.ZIndex = 2

            local tabIndicator = Instance.new("Frame", indicatorLayer)
            tabIndicator.Size = UDim2.new(1 / #tabs, -4, 1, -4)
            tabIndicator.Position = UDim2.new(0, 2, 0, 2)
            tabIndicator.BackgroundColor3 = WindUI.CurrentTheme.Accent
            tabIndicator.BackgroundTransparency = 0.78
            tabIndicator.ZIndex = 2
            Instance.new("UICorner", tabIndicator).CornerRadius = UDim.new(0, 6)
            local tabIndStroke = Instance.new("UIStroke", tabIndicator)
            tabIndStroke.Color = WindUI.CurrentTheme.Accent
            tabIndStroke.Thickness = 1
            tabIndStroke.Transparency = 0.5

            local tabBtnLayout = Instance.new("UIListLayout", tabBar)
            tabBtnLayout.FillDirection = Enum.FillDirection.Horizontal
            tabBtnLayout.Padding = UDim.new(0, 0)

            local msSep = Instance.new("Frame", msFrame)
            msSep.Size = UDim2.new(1, 0, 0, 1)
            msSep.BackgroundColor3 = WindUI.CurrentTheme.Border
            msSep.BorderSizePixel = 0

            local pageContainer = Instance.new("Frame", msFrame)
            pageContainer.Size = UDim2.new(1, 0, 0, 0)
            pageContainer.AutomaticSize = Enum.AutomaticSize.Y
            pageContainer.BackgroundTransparency = 1
            local pagePad = Instance.new("UIPadding", pageContainer)
            pagePad.PaddingTop = UDim.new(0, 8)
            pagePad.PaddingBottom = UDim.new(0, 8)
            pagePad.PaddingLeft = UDim.new(0, 8)
            pagePad.PaddingRight = UDim.new(0, 8)

            local activeTabBtn = nil
            local activePageFrame = nil
            local tabObjects = {}

            for i, tabDef in ipairs(tabs) do
                local tabName = tabDef.Name or ("Tab " .. i)

                local tBtn = Instance.new("TextButton", tabBar)
                tBtn.Size = UDim2.new(1 / #tabs, 0, 1, 0)
                tBtn.BackgroundTransparency = 1
                tBtn.Text = ""
                tBtn.ZIndex = 5

                local tBtnLbl = Instance.new("TextLabel", tBtn)
                tBtnLbl.Text = tabName
                tBtnLbl.Size = UDim2.new(1, 0, 1, 0)
                tBtnLbl.BackgroundTransparency = 1
                tBtnLbl.Font = i == 1 and Enum.Font.GothamBold or Enum.Font.GothamMedium
                tBtnLbl.TextColor3 = i == 1 and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.SubText
                tBtnLbl.TextSize = 10
                tBtnLbl.ZIndex = 6

                local pageScroll = Instance.new("ScrollingFrame", pageContainer)
                pageScroll.Size = UDim2.new(1, 0, 0, 0)
                pageScroll.AutomaticSize = Enum.AutomaticSize.Y
                pageScroll.BackgroundTransparency = 1
                pageScroll.ScrollBarThickness = 0
                pageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                pageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                pageScroll.Visible = i == 1

                local pageLayout = Instance.new("UIListLayout", pageScroll)
                pageLayout.Padding = UDim.new(0, 6)
                pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

                local pageTab = {Scroll = pageScroll}
                local pScroll = pageScroll

                pageTab.CreateButton = function(self, text, callback, iconName)
                    local b = Instance.new("TextButton", pScroll)
                    b.Size = UDim2.new(0.96, 0, 0, 34)
                    b.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    b.Text = ""
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
                    local bStroke = Instance.new("UIStroke", b)
                    bStroke.Color = WindUI.CurrentTheme.Border
                    bStroke.Thickness = 1
                    local iconImg = Instance.new("ImageLabel", b)
                    iconImg.Size = UDim2.new(0, 13, 0, 13)
                    iconImg.Position = UDim2.new(0, 12, 0.5, -6.5)
                    iconImg.BackgroundTransparency = 1
                    iconImg.ImageColor3 = WindUI.CurrentTheme.Accent
                    iconImg.ScaleType = Enum.ScaleType.Fit
                    iconImg.Visible = false
                    local textOffset = 12
                    if iconName then
                        task.spawn(function()
                            local iconData = GetIcon(iconName)
                            if iconData then ApplyIcon(iconImg, iconData); iconImg.Visible = true end
                        end)
                        textOffset = 30
                    end
                    local bLbl = Instance.new("TextLabel", b)
                    bLbl.Text = text
                    bLbl.Size = UDim2.new(1, -(textOffset + 28), 1, 0)
                    bLbl.Position = UDim2.new(0, textOffset, 0, 0)
                    bLbl.BackgroundTransparency = 1
                    bLbl.Font = WindUI.CurrentFont
                    bLbl.TextColor3 = WindUI.CurrentTheme.Text
                    bLbl.TextSize = 11
                    bLbl.TextXAlignment = Enum.TextXAlignment.Left
                    local arrImg = Instance.new("ImageLabel", b)
                    arrImg.Size = UDim2.new(0, 11, 0, 11)
                    arrImg.Position = UDim2.new(1, -22, 0.5, -5.5)
                    arrImg.BackgroundTransparency = 1
                    arrImg.ImageColor3 = WindUI.CurrentTheme.Accent
                    arrImg.ImageTransparency = 0.6
                    arrImg.ScaleType = Enum.ScaleType.Fit
                    task.spawn(function() ApplyIcon(arrImg, GetIcon("chevron-right")) end)
                    b.MouseEnter:Connect(function() Tween(b,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Tertiary}); Tween(bStroke,{Time=0.12},{Color=WindUI.CurrentTheme.Accent,Transparency=0.5}); Tween(arrImg,{Time=0.12},{ImageTransparency=0}) end)
                    b.MouseLeave:Connect(function() Tween(b,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Secondary}); Tween(bStroke,{Time=0.12},{Color=WindUI.CurrentTheme.Border,Transparency=0}); Tween(arrImg,{Time=0.12},{ImageTransparency=0.6}) end)
                    b.MouseButton1Click:Connect(function() Tween(b,{Time=0.07},{BackgroundColor3=WindUI.CurrentTheme.AccentDark}); task.delay(0.1,function() Tween(b,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Secondary}) end); pcall(callback) end)
                end

                pageTab.CreateToggle = function(self, text, default, callback)
                    local state = default
                    local tBtn = Instance.new("TextButton", pScroll)
                    tBtn.Size = UDim2.new(0.96, 0, 0, 36)
                    tBtn.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    tBtn.Text = ""
                    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
                    local tStroke = Instance.new("UIStroke", tBtn)
                    tStroke.Color = WindUI.CurrentTheme.Border
                    tStroke.Thickness = 1
                    local lbl = Instance.new("TextLabel", tBtn)
                    lbl.Text = text
                    lbl.Size = UDim2.new(1, -64, 1, 0)
                    lbl.Position = UDim2.new(0, 12, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = WindUI.CurrentFont
                    lbl.TextColor3 = WindUI.CurrentTheme.Text
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    local switch = Instance.new("Frame", tBtn)
                    switch.Size = UDim2.new(0, 34, 0, 17)
                    switch.Position = UDim2.new(1, -46, 0.5, -8.5)
                    switch.BackgroundColor3 = state and WindUI.CurrentTheme.Accent or Color3.fromRGB(36, 26, 26)
                    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
                    local knob = Instance.new("Frame", switch)
                    knob.Size = UDim2.new(0, 12, 0, 12)
                    knob.Position = state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
                    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
                    tBtn.MouseEnter:Connect(function() Tween(tBtn,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Tertiary}) end)
                    tBtn.MouseLeave:Connect(function() Tween(tBtn,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Secondary}) end)
                    tBtn.MouseButton1Click:Connect(function()
                        state = not state
                        Tween(switch,{Time=0.2,Style=Enum.EasingStyle.Quart},{BackgroundColor3=state and WindUI.CurrentTheme.Accent or Color3.fromRGB(36,26,26)})
                        Tween(knob,{Time=0.2,Style=Enum.EasingStyle.Back},{Position=state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)})
                        pcall(callback, state)
                    end)
                end

                pageTab.CreateSlider = function(self, text, min, max, default, callback)
                    local sFrame = Instance.new("Frame", pScroll)
                    sFrame.Size = UDim2.new(0.96, 0, 0, 50)
                    sFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 6)
                    local sfStroke = Instance.new("UIStroke", sFrame)
                    sfStroke.Color = WindUI.CurrentTheme.Border
                    sfStroke.Thickness = 1
                    local lbl = Instance.new("TextLabel", sFrame)
                    lbl.Text = text
                    lbl.Size = UDim2.new(0.65, 0, 0, 20)
                    lbl.Position = UDim2.new(0, 12, 0, 6)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = WindUI.CurrentTheme.Text
                    lbl.Font = WindUI.CurrentFont
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    local valLbl = Instance.new("TextLabel", sFrame)
                    valLbl.Text = tostring(default)
                    valLbl.Size = UDim2.new(0.35, -12, 0, 20)
                    valLbl.Position = UDim2.new(0.65, 0, 0, 6)
                    valLbl.BackgroundTransparency = 1
                    valLbl.TextColor3 = WindUI.CurrentTheme.Accent
                    valLbl.Font = Enum.Font.GothamBold
                    valLbl.TextSize = 11
                    valLbl.TextXAlignment = Enum.TextXAlignment.Right
                    local track = Instance.new("Frame", sFrame)
                    track.Size = UDim2.new(1, -24, 0, 4)
                    track.Position = UDim2.new(0, 12, 0, 34)
                    track.BackgroundColor3 = Color3.fromRGB(30,22,22)
                    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
                    local fill = Instance.new("Frame", track)
                    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
                    fill.BackgroundColor3 = WindUI.CurrentTheme.Accent
                    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
                    local knob = Instance.new("TextButton", track)
                    knob.Size = UDim2.new(0, 10, 0, 16)
                    knob.AnchorPoint = Vector2.new(0.5, 0.5)
                    knob.Position = UDim2.new((default-min)/(max-min), 0, 0.5, 0)
                    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                    knob.Text = ""
                    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 3)
                    local dragging = false
                    local function UpdateSlider(input)
                        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
                        local val = math.floor(min + (max-min)*pos)
                        fill.Size = UDim2.new(pos, 0, 1, 0)
                        knob.Position = UDim2.new(pos, 0, 0.5, 0)
                        valLbl.Text = tostring(val)
                        pcall(callback, val)
                    end
                    knob.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
                    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then UpdateSlider(input) end end)
                    UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
                end

                pageTab.CreateDropdown = function(self, text, options, callback)
                    local fakeTab = {Scroll = pScroll}
                    Tab.CreateDropdown(fakeTab, text, options, callback)
                end

                pageTab.CreateMultiDropdown = function(self, text, options, callback)
                    local fakeTab = {Scroll = pScroll}
                    Tab.CreateMultiDropdown(fakeTab, text, options, callback)
                end

                pageTab.CreateInput = function(self, text, placeholder, callback)
                    local iFrame = Instance.new("Frame", pScroll)
                    iFrame.Size = UDim2.new(0.96, 0, 0, 48)
                    iFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    Instance.new("UICorner", iFrame).CornerRadius = UDim.new(0, 8)
                    local ifStroke = Instance.new("UIStroke", iFrame)
                    ifStroke.Color = WindUI.CurrentTheme.Border
                    ifStroke.Thickness = 1
                    local bar = Instance.new("Frame", iFrame)
                    bar.Size = UDim2.new(0, 3, 0, 26)
                    bar.Position = UDim2.new(0, 0, 0.5, -13)
                    bar.BackgroundColor3 = WindUI.CurrentTheme.Accent
                    bar.BackgroundTransparency = 1
                    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
                    local iLbl = Instance.new("TextLabel", iFrame)
                    iLbl.Text = text
                    iLbl.Size = UDim2.new(1, -20, 0, 18)
                    iLbl.Position = UDim2.new(0, 14, 0, 6)
                    iLbl.BackgroundTransparency = 1
                    iLbl.Font = WindUI.CurrentFont
                    iLbl.TextColor3 = WindUI.CurrentTheme.SubText
                    iLbl.TextSize = 10
                    iLbl.TextXAlignment = Enum.TextXAlignment.Left
                    local inputBox = Instance.new("TextBox", iFrame)
                    inputBox.Size = UDim2.new(1, -28, 0, 22)
                    inputBox.Position = UDim2.new(0, 14, 0, 24)
                    inputBox.BackgroundTransparency = 1
                    inputBox.Font = WindUI.CurrentFont
                    inputBox.Text = ""
                    inputBox.PlaceholderText = placeholder or "Type here..."
                    inputBox.TextColor3 = WindUI.CurrentTheme.Text
                    inputBox.PlaceholderColor3 = WindUI.CurrentTheme.SubText
                    inputBox.TextSize = 12
                    inputBox.TextXAlignment = Enum.TextXAlignment.Left
                    inputBox.ClearTextOnFocus = false
                    inputBox:GetPropertyChangedSignal("Text"):Connect(function() pcall(callback, inputBox.Text) end)
                    inputBox.Focused:Connect(function() Tween(ifStroke,{Time=0.2},{Color=WindUI.CurrentTheme.Accent,Transparency=0.4}); Tween(bar,{Time=0.2},{BackgroundTransparency=0}) end)
                    inputBox.FocusLost:Connect(function() Tween(ifStroke,{Time=0.2},{Color=WindUI.CurrentTheme.Border,Transparency=0}); Tween(bar,{Time=0.2},{BackgroundTransparency=1}) end)
                end

                pageTab.CreateKeybind = function(self, text, default, callback)
                    local currentKey = default or Enum.KeyCode.Unknown
                    local binding = false
                    local kFrame = Instance.new("TextButton", pScroll)
                    kFrame.Size = UDim2.new(0.96, 0, 0, 36)
                    kFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    kFrame.Text = ""
                    Instance.new("UICorner", kFrame).CornerRadius = UDim.new(0, 6)
                    local kStroke = Instance.new("UIStroke", kFrame)
                    kStroke.Color = WindUI.CurrentTheme.Border
                    kStroke.Thickness = 1
                    local kIco = Instance.new("ImageLabel", kFrame)
                    kIco.Size = UDim2.new(0, 13, 0, 13)
                    kIco.Position = UDim2.new(0, 12, 0.5, -6.5)
                    kIco.BackgroundTransparency = 1
                    kIco.ImageColor3 = WindUI.CurrentTheme.Accent
                    kIco.ScaleType = Enum.ScaleType.Fit
                    task.spawn(function() ApplyIcon(kIco, GetIcon("keyboard")) end)
                    local kLbl = Instance.new("TextLabel", kFrame)
                    kLbl.Text = text
                    kLbl.Size = UDim2.new(0.6, 0, 1, 0)
                    kLbl.Position = UDim2.new(0, 30, 0, 0)
                    kLbl.BackgroundTransparency = 1
                    kLbl.Font = WindUI.CurrentFont
                    kLbl.TextColor3 = WindUI.CurrentTheme.Text
                    kLbl.TextSize = 11
                    kLbl.TextXAlignment = Enum.TextXAlignment.Left
                    local kBadge = Instance.new("Frame", kFrame)
                    kBadge.Size = UDim2.new(0, 68, 0, 20)
                    kBadge.Position = UDim2.new(1, -78, 0.5, -10)
                    kBadge.BackgroundColor3 = WindUI.CurrentTheme.Tertiary
                    Instance.new("UICorner", kBadge).CornerRadius = UDim.new(0, 5)
                    local kbStroke = Instance.new("UIStroke", kBadge)
                    kbStroke.Color = WindUI.CurrentTheme.Accent
                    kbStroke.Thickness = 1
                    kbStroke.Transparency = 0.5
                    local kValLbl = Instance.new("TextLabel", kBadge)
                    kValLbl.Size = UDim2.new(1, 0, 1, 0)
                    kValLbl.BackgroundTransparency = 1
                    kValLbl.Font = Enum.Font.GothamBold
                    kValLbl.TextColor3 = WindUI.CurrentTheme.Accent
                    kValLbl.TextSize = 9
                    kValLbl.Text = tostring(currentKey):gsub("Enum.KeyCode.", "")
                    kFrame.MouseEnter:Connect(function() Tween(kFrame,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Tertiary}) end)
                    kFrame.MouseLeave:Connect(function() Tween(kFrame,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Secondary}) end)
                    kFrame.MouseButton1Click:Connect(function()
                        if binding then return end
                        binding = true
                        kValLbl.Text = "· · ·"
                        kValLbl.TextColor3 = WindUI.CurrentTheme.SubText
                        Tween(kbStroke,{Time=0.15},{Transparency=0})
                        local conn
                        conn = UserInputService.InputBegan:Connect(function(input, gpe)
                            if gpe then return end
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                currentKey = input.KeyCode
                                kValLbl.Text = tostring(currentKey):gsub("Enum.KeyCode.","")
                                kValLbl.TextColor3 = WindUI.CurrentTheme.Accent
                                Tween(kbStroke,{Time=0.15},{Transparency=0.5})
                                binding = false
                                conn:Disconnect()
                                pcall(callback, currentKey)
                            end
                        end)
                    end)
                end

                pageTab.CreateLabel = function(self, title, desc)
                    local lFrame = Instance.new("Frame", pScroll)
                    local hasDesc = desc and desc ~= ""
                    lFrame.Size = UDim2.new(0.96, 0, 0, hasDesc and 46 or 30)
                    lFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    Instance.new("UICorner", lFrame).CornerRadius = UDim.new(0, 6)
                    local lfStroke = Instance.new("UIStroke", lFrame)
                    lfStroke.Color = WindUI.CurrentTheme.Border
                    lfStroke.Thickness = 1
                    local bar = Instance.new("Frame", lFrame)
                    bar.Size = UDim2.new(0, 2, 0, hasDesc and 26 or 14)
                    bar.Position = UDim2.new(0, 0, 0.5, hasDesc and -13 or -7)
                    bar.BackgroundColor3 = WindUI.CurrentTheme.Accent
                    bar.BackgroundTransparency = 0.4
                    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
                    local tLbl = Instance.new("TextLabel", lFrame)
                    tLbl.Text = title
                    tLbl.Size = UDim2.new(1, -20, 0, 16)
                    tLbl.Position = UDim2.new(0, 10, 0, 7)
                    tLbl.BackgroundTransparency = 1
                    tLbl.Font = Enum.Font.GothamBold
                    tLbl.TextColor3 = WindUI.CurrentTheme.Text
                    tLbl.TextSize = 11
                    tLbl.TextXAlignment = Enum.TextXAlignment.Left
                    if hasDesc then
                        local dLbl = Instance.new("TextLabel", lFrame)
                        dLbl.Text = desc
                        dLbl.Size = UDim2.new(1, -20, 0, 14)
                        dLbl.Position = UDim2.new(0, 10, 0, 25)
                        dLbl.BackgroundTransparency = 1
                        dLbl.Font = Enum.Font.GothamMedium
                        dLbl.TextColor3 = WindUI.CurrentTheme.SubText
                        dLbl.TextSize = 9
                        dLbl.TextXAlignment = Enum.TextXAlignment.Left
                        dLbl.TextWrapped = true
                    end
                end

                pageTab.CreateCheckbox = function(self, text, default, callback)
                    local state = default or false
                    local cBtn = Instance.new("TextButton", pScroll)
                    cBtn.Size = UDim2.new(0.96, 0, 0, 34)
                    cBtn.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    cBtn.Text = ""
                    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)
                    local cStroke = Instance.new("UIStroke", cBtn)
                    cStroke.Color = WindUI.CurrentTheme.Border
                    cStroke.Thickness = 1
                    local box = Instance.new("Frame", cBtn)
                    box.Size = UDim2.new(0, 16, 0, 16)
                    box.Position = UDim2.new(0, 12, 0.5, -8)
                    box.BackgroundColor3 = state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Tertiary
                    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
                    local boxStroke = Instance.new("UIStroke", box)
                    boxStroke.Color = state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Border
                    boxStroke.Thickness = 1.2
                    local checkIco = Instance.new("ImageLabel", box)
                    checkIco.Size = UDim2.new(0, 10, 0, 10)
                    checkIco.Position = UDim2.new(0.5, 0, 0.5, 0)
                    checkIco.AnchorPoint = Vector2.new(0.5, 0.5)
                    checkIco.BackgroundTransparency = 1
                    checkIco.ImageColor3 = Color3.fromRGB(255,255,255)
                    checkIco.ImageTransparency = state and 0 or 1
                    checkIco.ScaleType = Enum.ScaleType.Fit
                    task.spawn(function() ApplyIcon(checkIco, GetIcon("check")) end)
                    local cLbl = Instance.new("TextLabel", cBtn)
                    cLbl.Text = text
                    cLbl.Size = UDim2.new(1, -46, 1, 0)
                    cLbl.Position = UDim2.new(0, 34, 0, 0)
                    cLbl.BackgroundTransparency = 1
                    cLbl.Font = WindUI.CurrentFont
                    cLbl.TextColor3 = WindUI.CurrentTheme.Text
                    cLbl.TextSize = 11
                    cLbl.TextXAlignment = Enum.TextXAlignment.Left
                    cBtn.MouseEnter:Connect(function() Tween(cBtn,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Tertiary}) end)
                    cBtn.MouseLeave:Connect(function() Tween(cBtn,{Time=0.12},{BackgroundColor3=WindUI.CurrentTheme.Secondary}) end)
                    cBtn.MouseButton1Click:Connect(function()
                        state = not state
                        Tween(box,{Time=0.15},{BackgroundColor3=state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Tertiary})
                        Tween(boxStroke,{Time=0.15},{Color=state and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.Border})
                        Tween(checkIco,{Time=0.12},{ImageTransparency=state and 0 or 1})
                        pcall(callback, state)
                    end)
                end

                pageTab.CreateDivider = function(self, label)
                    local dWrap = Instance.new("Frame", pScroll)
                    dWrap.Size = UDim2.new(0.96, 0, 0, 20)
                    dWrap.BackgroundTransparency = 1
                    local line1 = Instance.new("Frame", dWrap)
                    line1.Size = UDim2.new(0.5, -48, 0, 1)
                    line1.Position = UDim2.new(0, 0, 0.5, 0)
                    line1.BackgroundColor3 = WindUI.CurrentTheme.Border
                    line1.BorderSizePixel = 0
                    local line2 = Instance.new("Frame", dWrap)
                    line2.Size = UDim2.new(0.5, -48, 0, 1)
                    line2.Position = UDim2.new(0.5, 48, 0.5, 0)
                    line2.BackgroundColor3 = WindUI.CurrentTheme.Border
                    line2.BorderSizePixel = 0
                    if label and label ~= "" then
                        local dLbl = Instance.new("TextLabel", dWrap)
                        dLbl.Text = label:upper()
                        dLbl.Size = UDim2.new(0, 90, 1, 0)
                        dLbl.Position = UDim2.new(0.5, -45, 0, 0)
                        dLbl.BackgroundTransparency = 1
                        dLbl.Font = Enum.Font.GothamBold
                        dLbl.TextColor3 = WindUI.CurrentTheme.SubText
                        dLbl.TextSize = 8
                        dLbl.TextXAlignment = Enum.TextXAlignment.Center
                    else
                        local dot = Instance.new("Frame", dWrap)
                        dot.Size = UDim2.new(0, 3, 0, 3)
                        dot.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
                        dot.BackgroundColor3 = WindUI.CurrentTheme.Accent
                        dot.BackgroundTransparency = 0.5
                        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                    end
                end

                pageTab.CreateParagraph = function(self, title, body)
                    local pFrame = Instance.new("Frame", pScroll)
                    pFrame.Size = UDim2.new(0.95, 0, 0, 0)
                    pFrame.AutomaticSize = Enum.AutomaticSize.Y
                    pFrame.BackgroundColor3 = WindUI.CurrentTheme.Secondary
                    pFrame.BackgroundTransparency = 0.3
                    Instance.new("UICorner", pFrame).CornerRadius = UDim.new(0, 8)
                    local pStroke = Instance.new("UIStroke", pFrame)
                    pStroke.Color = WindUI.CurrentTheme.Border
                    pStroke.Thickness = 1
                    local pPad = Instance.new("UIPadding", pFrame)
                    pPad.PaddingTop = UDim.new(0, 10)
                    pPad.PaddingBottom = UDim.new(0, 10)
                    pPad.PaddingLeft = UDim.new(0, 7)
                    pPad.PaddingRight = UDim.new(0, 7)
                    local pLayout = Instance.new("UIListLayout", pFrame)
                    pLayout.Padding = UDim.new(0, 4)
                    local bar = Instance.new("Frame", pFrame)
                    bar.Size = UDim2.new(0, 3, 0, 14)
                    bar.BackgroundColor3 = WindUI.CurrentTheme.Accent
                    bar.BackgroundTransparency = 0.3
                    bar.Position = UDim2.new(0, -14, 0, 10)
                    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
                    local tLbl = Instance.new("TextLabel", pFrame)
                    tLbl.Text = title
                    tLbl.Size = UDim2.new(1, 0, 0, 0)
                    tLbl.AutomaticSize = Enum.AutomaticSize.Y
                    tLbl.BackgroundTransparency = 1
                    tLbl.Font = Enum.Font.GothamBold
                    tLbl.TextColor3 = WindUI.CurrentTheme.Text
                    tLbl.TextSize = 12
                    tLbl.TextXAlignment = Enum.TextXAlignment.Left
                    tLbl.TextWrapped = true
                    local bLbl = Instance.new("TextLabel", pFrame)
                    bLbl.Text = body
                    bLbl.Size = UDim2.new(1, 0, 0, 0)
                    bLbl.AutomaticSize = Enum.AutomaticSize.Y
                    bLbl.BackgroundTransparency = 1
                    bLbl.Font = Enum.Font.GothamMedium
                    bLbl.TextColor3 = WindUI.CurrentTheme.SubText
                    bLbl.TextSize = 11
                    bLbl.TextXAlignment = Enum.TextXAlignment.Left
                    bLbl.TextWrapped = true
                end

                table.insert(tabObjects, {btn=tBtn, lbl=tBtnLbl, page=pageScroll, index=i})

                if i == 1 then activeTabBtn = tBtn; activePageFrame = pageScroll end

                tBtn.MouseButton1Click:Connect(function()
                    local prevIndex = 1
                    local prevPage = nil
                    for _, obj in ipairs(tabObjects) do
                        if obj.page.Visible then
                            prevIndex = obj.index
                            prevPage = obj.page
                            break
                        end
                    end
                    if prevIndex == i then return end

                    local targetX = (i - 1) / #tabs
                    Tween(tabIndicator, {Time=0.25, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.Out},
                        {Position=UDim2.new(targetX, 2, 0, 2)})

                    for _, obj in ipairs(tabObjects) do
                        local isActive = obj.index == i
                        Tween(obj.lbl, {Time=0.2}, {
                            TextColor3 = isActive and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.SubText
                        })
                        obj.lbl.Font = isActive and Enum.Font.GothamBold or Enum.Font.GothamMedium
                    end

                    local origPos = msFrame.Position
                    Tween(msFrame, {Time=0.1, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.Out},
                        {BackgroundTransparency=0.15})
                    task.delay(0.1, function()
                        Tween(msFrame, {Time=0.15, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.Out},
                            {BackgroundTransparency=0})
                    end)

                    if prevPage then
                        prevPage.Visible = false
                    end
                    pageScroll.Visible = true
                end)

                if tabDef.Build then
                    tabDef.Build(pageTab)
                end
            end

            return tabObjects
        end

        function Tab:CreateTabDropdown(name, subNames, iconName)
            local resolvedSubIcon = iconName or "layers"
            local subExpanded = false
            local SUBBTN_H = 32
            local subH = #subNames * SUBBTN_H + (#subNames - 1) * 3

            local wrapFrame = Instance.new("Frame", tabContainer)
            wrapFrame.Size = UDim2.new(1, 0, 0, 34)
            wrapFrame.BackgroundTransparency = 1
            wrapFrame.ClipsDescendants = false
            Instance.new("UICorner", wrapFrame).CornerRadius = UDim.new(0, 7)

            local dropBtn = Instance.new("TextButton", wrapFrame)
            dropBtn.Size = UDim2.new(1, 0, 0, 34)
            dropBtn.BackgroundColor3 = WindUI.CurrentTheme.Accent
            dropBtn.BackgroundTransparency = 0.94
            dropBtn.Text = ""
            Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 7)
            local dropBtnStroke = Instance.new("UIStroke", dropBtn)
            dropBtnStroke.Color = WindUI.CurrentTheme.Accent
            dropBtnStroke.Thickness = 1
            dropBtnStroke.Transparency = 0.7

            local dropIcon = Instance.new("ImageLabel", dropBtn)
            dropIcon.Size = UDim2.new(0, 13, 0, 13)
            dropIcon.Position = UDim2.new(0, 14, 0.5, -6.5)
            dropIcon.BackgroundTransparency = 1
            dropIcon.ImageColor3 = WindUI.CurrentTheme.SubText
            dropIcon.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(dropIcon, GetIcon(resolvedSubIcon)) end)

            local dropLbl = Instance.new("TextLabel", dropBtn)
            dropLbl.Text = name
            dropLbl.Size = UDim2.new(1, -50, 1, 0)
            dropLbl.Position = UDim2.new(0, 32, 0, 0)
            dropLbl.BackgroundTransparency = 1
            dropLbl.Font = WindUI.CurrentFont
            dropLbl.TextColor3 = WindUI.CurrentTheme.SubText
            dropLbl.TextSize = 11
            dropLbl.TextXAlignment = Enum.TextXAlignment.Left

            local dropArrow = Instance.new("ImageLabel", dropBtn)
            dropArrow.Size = UDim2.new(0, 10, 0, 10)
            dropArrow.Position = UDim2.new(1, -18, 0.5, -5)
            dropArrow.BackgroundTransparency = 1
            dropArrow.ImageColor3 = WindUI.CurrentTheme.SubText
            dropArrow.ImageTransparency = 0.3
            dropArrow.ScaleType = Enum.ScaleType.Fit
            task.spawn(function() ApplyIcon(dropArrow, GetIcon("chevron-down")) end)

            local subContainer = Instance.new("Frame", wrapFrame)
            subContainer.Size = UDim2.new(1, -10, 0, 0)
            subContainer.Position = UDim2.new(0, 10, 0, 36)
            subContainer.BackgroundTransparency = 1
            subContainer.ClipsDescendants = true
            local subLayout = Instance.new("UIListLayout", subContainer)
            subLayout.Padding = UDim.new(0, 3)

            local subTabs = {}
            for si, subName in ipairs(subNames) do
                local subBtn = Instance.new("TextButton", subContainer)
                subBtn.Size = UDim2.new(1, 0, 0, SUBBTN_H)
                subBtn.BackgroundColor3 = WindUI.CurrentTheme.Accent
                subBtn.BackgroundTransparency = 1
                subBtn.Text = ""
                Instance.new("UICorner", subBtn).CornerRadius = UDim.new(0, 8)
                subBtn.ZIndex = 2

                local subLbl = Instance.new("TextLabel", subBtn)
                subLbl.Text = subName
                subLbl.Size = UDim2.new(1, -24, 1, 0)
                subLbl.Position = UDim2.new(0, 18, 0, 0)
                subLbl.BackgroundTransparency = 1
                subLbl.Font = WindUI.CurrentFont
                subLbl.TextColor3 = WindUI.CurrentTheme.SubText
                subLbl.TextSize = 10
                subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.ZIndex = 3

                local subContainer_tab = Instance.new("CanvasGroup", contentArea)
                subContainer_tab.Size = UDim2.new(1, 0, 1, 0)
                subContainer_tab.BackgroundTransparency = 1
                subContainer_tab.Visible = false

                local subScroll = Instance.new("ScrollingFrame", subContainer_tab)
                subScroll.Size = UDim2.new(1, 0, 1, 0)
                subScroll.BackgroundTransparency = 1
                subScroll.ScrollBarThickness = 2
                subScroll.ScrollBarImageColor3 = WindUI.CurrentTheme.Accent
                subScroll.ScrollBarImageTransparency = 0.7
                subScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                subScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                local subScrollLayout = Instance.new("UIListLayout", subScroll)
                subScrollLayout.Padding = UDim.new(0, 8)
                subScrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                local subScrollPad = Instance.new("UIPadding", subScroll)
                subScrollPad.PaddingTop = UDim.new(0, 8)
                subScrollPad.PaddingBottom = UDim.new(0, 8)

                local SubTab = { Container = subContainer_tab, Scroll = subScroll, Button = subBtn }

                local function ActivateSub()
                    if Window.CurrentTab == SubTab then return end
                    local prev = Window.CurrentTab
                    if prev and prev.Container then
                        local prevC = prev.Container
                        Tween(prevC, {Time=0.18, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.In},
                            {Position=UDim2.new(0,0,0,-10), GroupTransparency=1})
                        task.delay(0.19, function()
                            if prevC and prevC.Parent then
                                prevC.Visible = false
                                prevC.Position = UDim2.new(0,0,0,0)
                                prevC.GroupTransparency = 1
                            end
                        end)
                    end
                    for _, t in pairs(Window.Tabs) do
                        Tween(t.Button, {Time = 0.2}, {BackgroundTransparency = 1})
                        local ind = t.Button:FindFirstChild("Frame")
                        if ind then Tween(ind, {Time = 0.3}, {Size = UDim2.new(0, 3, 0, 0)}) end
                        local lbl2 = t.Button:FindFirstChildOfClass("TextLabel")
                        if lbl2 then Tween(lbl2, {Time = 0.2}, {TextColor3 = WindUI.CurrentTheme.SubText}) end
                        local ico2 = t.Button:FindFirstChildOfClass("ImageLabel")
                        if ico2 then Tween(ico2, {Time = 0.2}, {ImageColor3 = WindUI.CurrentTheme.SubText}) end
                        t.Container.Visible = false
                    end
                    Window.CurrentTab = SubTab
                    subContainer_tab.Position = UDim2.new(0, 0, 0, 14)
                    subContainer_tab.GroupTransparency = 1
                    subContainer_tab.Visible = true
                    Tween(subContainer_tab, {Time=0.28, Style=Enum.EasingStyle.Quart, Dir=Enum.EasingDirection.Out},
                        {Position=UDim2.new(0,0,0,0), GroupTransparency=0})
                    Tween(subBtn, {Time = 0.2}, {BackgroundTransparency = 0.84})
                    Tween(subLbl, {Time = 0.2}, {TextColor3 = WindUI.CurrentTheme.Accent})
                    subLbl.Font = Enum.Font.GothamBold
                    Tween(dropLbl, {Time=0.15}, {TextColor3 = WindUI.CurrentTheme.Text})
                    Tween(dropIcon, {Time=0.15}, {ImageColor3 = WindUI.CurrentTheme.Accent})
                end

                subBtn.MouseEnter:Connect(function()
                    if Window.CurrentTab ~= SubTab then
                        Tween(subBtn, {Time = 0.15}, {BackgroundTransparency = 0.93})
                        Tween(subLbl, {Time=0.12}, {TextColor3 = WindUI.CurrentTheme.Text})
                    end
                end)
                subBtn.MouseLeave:Connect(function()
                    if Window.CurrentTab ~= SubTab then
                        Tween(subBtn, {Time = 0.15}, {BackgroundTransparency = 1})
                        Tween(subLbl, {Time=0.12}, {TextColor3 = WindUI.CurrentTheme.SubText})
                    end
                end)
                subBtn.MouseButton1Click:Connect(ActivateSub)

                SubTab.CreateButton = Tab.CreateButton
                SubTab.CreateToggle = Tab.CreateToggle
                SubTab.CreateSlider = Tab.CreateSlider
                SubTab.CreateDropdown = Tab.CreateDropdown
                SubTab.CreateSection = Tab.CreateSection
                SubTab.CreateInput = Tab.CreateInput
                SubTab.CreateKeybind = Tab.CreateKeybind
                SubTab.CreateLabel = Tab.CreateLabel
                SubTab.CreateParagraph = Tab.CreateParagraph
                SubTab.CreateCheckbox = Tab.CreateCheckbox
                SubTab.CreateDivider = Tab.CreateDivider
                SubTab.CreateCode = Tab.CreateCode
                SubTab.CreateMultiSection = Tab.CreateMultiSection
                SubTab.CreateMultiDropdown = Tab.CreateMultiDropdown

                table.insert(Window.Tabs, SubTab)
                table.insert(subTabs, SubTab)
            end

            dropBtn.MouseEnter:Connect(function()
                Tween(dropBtn, {Time = 0.15}, {BackgroundTransparency = 0.88})
                Tween(dropIcon, {Time = 0.15}, {ImageColor3 = WindUI.CurrentTheme.Text})
                Tween(dropBtnStroke, {Time=0.15}, {Transparency = 0.5})
            end)
            dropBtn.MouseLeave:Connect(function()
                if not subExpanded then
                    Tween(dropBtn, {Time = 0.15}, {BackgroundTransparency = 0.94})
                    Tween(dropIcon, {Time = 0.15}, {ImageColor3 = WindUI.CurrentTheme.SubText})
                    Tween(dropBtnStroke, {Time=0.15}, {Transparency = 0.7})
                end
            end)

            dropBtn.MouseButton1Click:Connect(function()
                subExpanded = not subExpanded
                local targetH = subExpanded and (34 + subH + 2) or 34
                Tween(wrapFrame, {Time = 0.28, Style = Enum.EasingStyle.Quart}, {Size = UDim2.new(1, 0, 0, targetH)})
                Tween(subContainer, {Time = 0.28, Style = Enum.EasingStyle.Quart}, {Size = UDim2.new(1, -10, 0, subExpanded and subH or 0)})
                Tween(dropArrow, {Time = 0.25}, {Rotation = subExpanded and 180 or 0})
                Tween(dropLbl, {Time = 0.15}, {TextColor3 = subExpanded and WindUI.CurrentTheme.Text or WindUI.CurrentTheme.SubText})
                Tween(dropIcon, {Time = 0.15}, {ImageColor3 = subExpanded and WindUI.CurrentTheme.Accent or WindUI.CurrentTheme.SubText})
                Tween(dropBtn, {Time = 0.15}, {BackgroundTransparency = subExpanded and 0.82 or 0.94})
                Tween(dropBtnStroke, {Time=0.15}, {Transparency = subExpanded and 0.4 or 0.7})
            end)

            return subTabs
        end

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Activate() end
        return Tab
    end

    function Window:Unload()
        for _, conn in pairs(WindUI.Connections) do conn:Disconnect() end
        WindUI.ScreenGui:Destroy()
        if WindUI.NotifyGui then WindUI.NotifyGui:Destroy() end
    end

    return Window
end

function WindUI:SetLayoutStyle(style)
    self._layoutStyle = style
    local configs = {
        ["Compact"]  = {padding=3,  padTop=4,  padBot=4,  itemH=-4},
        ["Default"]  = {padding=6,  padTop=8,  padBot=8,  itemH=0},
        ["Cozy"]     = {padding=10, padTop=12, padBot=12, itemH=6},
    }
    local cfg = configs[style] or configs["Default"]
    for _, tab in ipairs(self._allTabs) do
        if tab._scrollLayout and tab._scrollLayout.Parent then
            tab._scrollLayout.Padding = UDim.new(0, cfg.padding)
        end
        if tab._scrollPad and tab._scrollPad.Parent then
            tab._scrollPad.PaddingTop    = UDim.new(0, cfg.padTop)
            tab._scrollPad.PaddingBottom = UDim.new(0, cfg.padBot)
        end
        if cfg.itemH ~= 0 then
            for _, child in ipairs(tab.Scroll:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") then
                    local base = child:GetAttribute("BaseHeight")
                    if not base then
                        base = child.Size.Y.Offset
                        child:SetAttribute("BaseHeight", base)
                    end
                    if base and base > 0 then
                        child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, base + cfg.itemH)
                    end
                end
            end
        else
            for _, child in ipairs(tab.Scroll:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") then
                    local base = child:GetAttribute("BaseHeight")
                    if base and base > 0 then
                        child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, base)
                    end
                end
            end
        end
    end
    self:Notify("Layout", style .. " layout applied.", 2)
end

function WindUI:SetSidebarStyle(style)
    self._sidebarStyle = style
    for _, entry in ipairs(self._allBtns) do
        local btn = entry.btn
        local icon = entry.icon
        local lbl = entry.lbl
        if not (btn and btn.Parent) then continue end
        if style == "Icon Only" then
            btn.Size = UDim2.new(1, 0, 0, 32)
            if lbl then lbl.Visible = false end
            if icon then
                icon.Position = UDim2.new(0.5, -6.5, 0.5, -6.5)
                icon.Size = UDim2.new(0, 13, 0, 13)
            end
        elseif style == "Icon + Text" then
            btn.Size = UDim2.new(1, 0, 0, 32)
            if lbl then lbl.Visible = true end
            if icon then
                icon.Position = UDim2.new(0, 14, 0.5, -6.5)
                icon.Size = UDim2.new(0, 13, 0, 13)
            end
        elseif style == "Text Only" then
            btn.Size = UDim2.new(1, 0, 0, 32)
            if lbl then
                lbl.Visible = true
                lbl.Position = UDim2.new(0, 12, 0, 0)
                lbl.Size = UDim2.new(1, -16, 1, 0)
            end
            if icon then icon.Visible = false end
        elseif style == "Large" then
            btn.Size = UDim2.new(1, 0, 0, 44)
            if lbl then
                lbl.Visible = true
                lbl.TextSize = 12
            end
            if icon then
                icon.Size = UDim2.new(0, 16, 0, 16)
                icon.Position = UDim2.new(0, 14, 0.5, -8)
            end
        end
    end
    self:Notify("Sidebar", style .. " style applied.", 2)
end

return WindUI
