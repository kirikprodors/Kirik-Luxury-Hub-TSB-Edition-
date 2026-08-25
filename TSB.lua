-- [[ KIRIK TSB HUB • V26 CLEAN LUXURY EDITION ]] --
-- Fully Optimized for The Strongest Battlegrounds (PC & Mobile)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Защита от дубликатов
if CoreGui:FindFirstChild("KirikTSB_V26") then
    CoreGui.KirikTSB_V26:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KirikTSB_V26"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ==================== ПЕРЕМЕННЫЕ И СОСТОЯНИЯ ==================== --
local State = {
    Esp = false,
    Noclip = false,
    WalkSpeed = 16,
    SpeedEnabled = false,
    Unattacked = false,
    Fullbright = false,
    SelectedTarget = nil, -- Может быть Player или Dummy
    Fov = 70,
    GuiScale = 1.0
}

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

-- ==================== ТЕМА ОФОРМЛЕНИЯ ==================== --
local Theme = {
    Background = Color3.fromRGB(14, 14, 18),
    Sidebar = Color3.fromRGB(20, 20, 26),
    Card = Color3.fromRGB(25, 25, 34),
    InputBg = Color3.fromRGB(16, 16, 22),
    Accent = Color3.fromRGB(255, 45, 85),
    AccentDummy = Color3.fromRGB(0, 210, 255),
    AccentGradient = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 45, 85)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))
    },
    Text = Color3.fromRGB(245, 245, 255),
    TextDim = Color3.fromRGB(145, 145, 165),
    Success = Color3.fromRGB(46, 213, 115),
    Danger = Color3.fromRGB(255, 71, 87)
}

-- ==================== СИСТЕМА УВЕДОМЛЕНИЙ ==================== --
local NotifContainer = Instance.new("Frame")
NotifContainer.Size = UDim2.new(0, 240, 1, -20)
NotifContainer.Position = UDim2.new(1, -250, 0, 10)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = ScreenGui

local function SendNotification(title, desc, duration, color)
    color = color or Theme.Accent
    duration = duration or 2.5

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 52)
    NotifFrame.BackgroundColor3 = Theme.Card
    NotifFrame.Position = UDim2.new(1.3, 0, 1, -60)
    NotifFrame.Parent = NotifContainer
    Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 8)

    local Stroke = Instance.new("UIStroke", NotifFrame)
    Stroke.Color = color
    Stroke.Thickness = 1.2

    local Line = Instance.new("Frame", NotifFrame)
    Line.Size = UDim2.new(0, 4, 1, -12)
    Line.Position = UDim2.new(0, 6, 0, 6)
    Line.BackgroundColor3 = color
    Instance.new("UICorner", Line).CornerRadius = UDim.new(0, 4)

    local Ttl = Instance.new("TextLabel", NotifFrame)
    Ttl.Text = title
    Ttl.Size = UDim2.new(1, -20, 0, 16)
    Ttl.Position = UDim2.new(0, 16, 0, 8)
    Ttl.TextColor3 = Theme.Text
    Ttl.Font = Enum.Font.GothamBold
    Ttl.TextSize = 12
    Ttl.TextXAlignment = Enum.TextXAlignment.Left
    Ttl.BackgroundTransparency = 1

    local Msg = Instance.new("TextLabel", NotifFrame)
    Msg.Text = desc
    Msg.Size = UDim2.new(1, -20, 0, 16)
    Msg.Position = UDim2.new(0, 16, 0, 26)
    Msg.TextColor3 = Theme.TextDim
    Msg.Font = Enum.Font.Gotham
    Msg.TextSize = 10
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.BackgroundTransparency = 1

    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 1, -60)
    }):Play()

    task.delay(duration, function()
        local tw = TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1.3, 0, 1, -60)
        })
        tw:Play()
        tw.Completed:Connect(function() NotifFrame:Destroy() end)
    end)
end

-- ==================== ГЛАВНОЕ ОКНО ==================== --
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 330)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainScale = Instance.new("UIScale", MainFrame)
MainScale.Scale = State.GuiScale

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 1.6
MainStroke.Color = Theme.Accent

local StrokeGradient = Instance.new("UIGradient", MainStroke)
StrokeGradient.Color = Theme.AccentGradient
StrokeGradient.Rotation = 45

-- ==================== DRAG ЛОГИКА С УЧЕТОМ SCALE ==================== --
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + (delta.X / MainScale.Scale),
            startPos.Y.Scale,
            startPos.Y.Offset + (delta.Y / MainScale.Scale)
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==================== САЙДБАР ==================== --
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0

local TitleBox = Instance.new("Frame", Sidebar)
TitleBox.Size = UDim2.new(1, 0, 0, 50)
TitleBox.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TitleBox)
Title.Text = "KIRIK TSB"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 15
Title.TextColor3 = Theme.Text
Title.Size = UDim2.new(1, -12, 0, 20)
Title.Position = UDim2.new(0, 12, 0, 10)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

local SubTitle = Instance.new("TextLabel", TitleBox)
SubTitle.Text = "V26 LUXURY • TSB"
SubTitle.Font = Enum.Font.GothamBold
SubTitle.TextSize = 8
SubTitle.TextColor3 = Theme.Accent
SubTitle.Size = UDim2.new(1, -12, 0, 14)
SubTitle.Position = UDim2.new(0, 12, 0, 28)
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.BackgroundTransparency = 1

local TabButtonHolder = Instance.new("Frame", Sidebar)
TabButtonHolder.Size = UDim2.new(1, -14, 1, -55)
TabButtonHolder.Position = UDim2.new(0, 7, 0, 52)
TabButtonHolder.BackgroundTransparency = 1

local TabListLayout = Instance.new("UIListLayout", TabButtonHolder)
TabListLayout.Padding = UDim.new(0, 4)
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local PagesHolder = Instance.new("Frame", MainFrame)
PagesHolder.Size = UDim2.new(1, -150, 1, -12)
PagesHolder.Position = UDim2.new(0, 145, 0, 6)
PagesHolder.BackgroundTransparency = 1

local CloseIcon = Instance.new("TextButton", MainFrame)
CloseIcon.Size = UDim2.new(0, 24, 0, 24)
CloseIcon.Position = UDim2.new(1, -30, 0, 8)
CloseIcon.Text = "✕"
CloseIcon.TextColor3 = Theme.TextDim
CloseIcon.BackgroundColor3 = Theme.Card
CloseIcon.Font = Enum.Font.GothamBold
CloseIcon.TextSize = 12
CloseIcon.ZIndex = 10
Instance.new("UICorner", CloseIcon).CornerRadius = UDim.new(0, 6)
CloseIcon.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- ==================== МЕНЕДЖЕР ВКЛАДОК ==================== --
local Tabs = {}
local function CreateTab(name, icon, order)
    local TabBtn = Instance.new("TextButton", TabButtonHolder)
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.BackgroundColor3 = Theme.Card
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = ""
    TabBtn.LayoutOrder = order
    TabBtn.AutoButtonColor = false
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

    local TabLabel = Instance.new("TextLabel", TabBtn)
    TabLabel.Size = UDim2.new(1, -10, 1, 0)
    TabLabel.Position = UDim2.new(0, 10, 0, 0)
    TabLabel.Text = icon .. " " .. name
    TabLabel.Font = Enum.Font.GothamMedium
    TabLabel.TextSize = 11
    TabLabel.TextColor3 = Theme.TextDim
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.BackgroundTransparency = 1

    local Page = Instance.new("ScrollingFrame", PagesHolder)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.Visible = false
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)

    local PageLayout = Instance.new("UIListLayout", Page)
    PageLayout.Padding = UDim.new(0, 6)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local PagePad = Instance.new("UIPadding", Page)
    PagePad.PaddingTop = UDim.new(0, 24)
    PagePad.PaddingRight = UDim.new(0, 8)

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            TweenService:Create(t.Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(t.Label, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim}):Play()
            t.Page.Visible = false
        end
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(TabLabel, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
        Page.Visible = true
    end)

    Tabs[name] = {Btn = TabBtn, Label = TabLabel, Page = Page}
    return Page
end

-- ==================== UI КОМПОНЕНТЫ ==================== --

local function CreateActionButton(page, title, desc, btnText, callback)
    local Card = Instance.new("Frame", page)
    Card.Size = UDim2.new(1, 0, 0, 44)
    Card.BackgroundColor3 = Theme.Card
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

    local TitleLbl = Instance.new("TextLabel", Card)
    TitleLbl.Text = title
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 11
    TitleLbl.TextColor3 = Theme.Text
    TitleLbl.Size = UDim2.new(0.62, 0, 0, 15)
    TitleLbl.Position = UDim2.new(0, 10, 0, 6)
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.BackgroundTransparency = 1

    local DescLbl = Instance.new("TextLabel", Card)
    DescLbl.Text = desc
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.TextSize = 9
    DescLbl.TextColor3 = Theme.TextDim
    DescLbl.Size = UDim2.new(0.62, 0, 0, 14)
    DescLbl.Position = UDim2.new(0, 10, 0, 22)
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    DescLbl.BackgroundTransparency = 1

    local ActionBtn = Instance.new("TextButton", Card)
    ActionBtn.Size = UDim2.new(0, 85, 0, 26)
    ActionBtn.Position = UDim2.new(1, -95, 0.5, -13)
    ActionBtn.BackgroundColor3 = Theme.Sidebar
    ActionBtn.Text = btnText
    ActionBtn.TextColor3 = Theme.Text
    ActionBtn.Font = Enum.Font.GothamMedium
    ActionBtn.TextSize = 10
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 6)
    
    local Stroke = Instance.new("UIStroke", ActionBtn)
    Stroke.Color = Theme.Accent
    Stroke.Thickness = 1

    ActionBtn.MouseButton1Click:Connect(function()
        TweenService:Create(ActionBtn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Accent}):Play()
        task.wait(0.1)
        TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play()
        callback()
    end)
end

local function CreateToggle(page, title, desc, default, callback)
    local Card = Instance.new("Frame", page)
    Card.Size = UDim2.new(1, 0, 0, 44)
    Card.BackgroundColor3 = Theme.Card
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

    local TitleLbl = Instance.new("TextLabel", Card)
    TitleLbl.Text = title
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 11
    TitleLbl.TextColor3 = Theme.Text
    TitleLbl.Size = UDim2.new(0.7, 0, 0, 15)
    TitleLbl.Position = UDim2.new(0, 10, 0, 6)
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.BackgroundTransparency = 1

    local DescLbl = Instance.new("TextLabel", Card)
    DescLbl.Text = desc
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.TextSize = 9
    DescLbl.TextColor3 = Theme.TextDim
    DescLbl.Size = UDim2.new(0.7, 0, 0, 14)
    DescLbl.Position = UDim2.new(0, 10, 0, 22)
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    DescLbl.BackgroundTransparency = 1

    local Switch = Instance.new("TextButton", Card)
    Switch.Size = UDim2.new(0, 42, 0, 22)
    Switch.Position = UDim2.new(1, -52, 0.5, -11)
    Switch.BackgroundColor3 = default and Theme.Success or Theme.Sidebar
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame", Switch)
    Dot.Size = UDim2.new(0, 16, 0, 16)
    Dot.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local state = default
    Switch.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Switch, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.Success or Theme.Sidebar
        }):Play()
        TweenService:Create(Dot, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        callback(state)
    end)
end

local function CreateNumberInput(page, title, desc, default, min, max, callback)
    local Card = Instance.new("Frame", page)
    Card.Size = UDim2.new(1, 0, 0, 44)
    Card.BackgroundColor3 = Theme.Card
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

    local TitleLbl = Instance.new("TextLabel", Card)
    TitleLbl.Text = title
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 11
    TitleLbl.TextColor3 = Theme.Text
    TitleLbl.Size = UDim2.new(0.65, 0, 0, 15)
    TitleLbl.Position = UDim2.new(0, 10, 0, 6)
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.BackgroundTransparency = 1

    local DescLbl = Instance.new("TextLabel", Card)
    DescLbl.Text = desc .. " (" .. tostring(min) .. " - " .. tostring(max) .. ")"
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.TextSize = 9
    DescLbl.TextColor3 = Theme.TextDim
    DescLbl.Size = UDim2.new(0.65, 0, 0, 14)
    DescLbl.Position = UDim2.new(0, 10, 0, 22)
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    DescLbl.BackgroundTransparency = 1

    local InputBox = Instance.new("TextBox", Card)
    InputBox.Size = UDim2.new(0, 60, 0, 26)
    InputBox.Position = UDim2.new(1, -70, 0.5, -13)
    InputBox.BackgroundColor3 = Theme.InputBg
    InputBox.Text = tostring(default)
    InputBox.TextColor3 = Theme.Accent
    InputBox.Font = Enum.Font.GothamBold
    InputBox.TextSize = 11
    InputBox.ClearTextOnFocus = false
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)

    local BoxStroke = Instance.new("UIStroke", InputBox)
    BoxStroke.Color = Color3.fromRGB(60, 60, 80)
    BoxStroke.Thickness = 1

    InputBox.Focused:Connect(function()
        TweenService:Create(BoxStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
    end)

    local currentVal = default
    InputBox.FocusLost:Connect(function()
        TweenService:Create(BoxStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 60, 80)}):Play()
        local num = tonumber(InputBox.Text)
        if num then
            if min and num < min then num = min end
            if max and num > max then num = max end
            currentVal = num
            InputBox.Text = tostring(num)
            callback(num)
        else
            InputBox.Text = tostring(currentVal)
        end
    end)
    return InputBox
end

-- ==================== СТРАНИЦЫ ==================== --
local CombatPage   = CreateTab("Бой", "⚔️", 1)
local MovePage     = CreateTab("Персонаж", "⚡", 2)
local VisualsPage  = CreateTab("Визуалы", "👁️", 3)
local TargetPage   = CreateTab("Таргет", "👥", 4)
local SettingsPage = CreateTab("Опции", "⚙️", 5)

-- ==================== ЛОГИКА DUMMY И ЭНТИТИ ==================== --

-- Поиск всех Weakest Dummy и манекенов в workspace
local function GetDummies()
    local dummies = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if not Players:GetPlayerFromCharacter(obj) and obj ~= LocalPlayer.Character then
                local n = obj.Name:lower()
                if n:find("dummy") or n:find("weakest") or (obj.Parent and obj.Parent.Name:lower():find("dummy")) then
                    table.insert(dummies, obj)
                end
            end
        end
    end
    return dummies
end

-- Остановка инерции (Safe Stop)
local function StopVelocity(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("LinearVelocity") then
            v:Destroy()
        end
    end
end

-- Безопасный поиск пола
local function FindSafePoint(targetPos)
    local rayOrigin = Vector3.new(targetPos.X, 1000, targetPos.Z)
    local rayDirection = Vector3.new(0, -2000, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace:FindFirstChild("Visuals")}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.RespectCanCollide = true

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result and result.Instance then
        return result.Position + Vector3.new(0, 4, 0)
    end
    return nil
end

-- ==================== ВКЛАДКА ⚔️ БОЙ ==================== --

CreateToggle(CombatPage, "Unattacked / Jitter", "Быстрый рассинхрон позиции (анти-лок)", false, function(v)
    State.Unattacked = v
    SendNotification("Unattacked", v and "Активирован" or "Отключен", 2)
end)

task.spawn(function()
    while true do
        if State.Unattacked then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-7, 7), 0, math.random(-7, 7))
            end
        end
        task.wait(0.06)
    end
end)

CreateActionButton(CombatPage, "Smart Escape", "Умный сейв из комбо с поиском пола", "ПОБЕГ", function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local checkRadii = {550, 400, 250, 100}
    local angles = {
        Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1),
        Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1),
        Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
    }

    local bestPoint, maxDist = nil, 0
    for _, radius in ipairs(checkRadii) do
        for _, dir in ipairs(angles) do
            local safePos = FindSafePoint(dir * radius)
            if safePos then
                local d = (hrp.Position - safePos).Magnitude
                if d > maxDist then
                    maxDist = d
                    bestPoint = safePos
                end
            end
        end
        if bestPoint and maxDist > 100 then break end
    end

    if bestPoint then
        StopVelocity(char)
        hrp.CFrame = CFrame.new(bestPoint)
        SendNotification("Smart Escape", "Успешный телепорт в безопасность!", 2, Theme.Success)
    else
        local backPos = FindSafePoint(hrp.Position - (hrp.CFrame.LookVector * 150))
        if backPos then
            StopVelocity(char)
            hrp.CFrame = CFrame.new(backPos)
            SendNotification("Smart Escape", "Отскок назад", 2, Theme.Success)
        end
    end
end)

CreateActionButton(CombatPage, "Throw Trash / Props", "Бросить мусор в выбранную цель/Дами", "БРОСОК", function()
    if not State.SelectedTarget or not State.SelectedTarget.Character then
        SendNotification("Ошибка", "Сначала выберите Игрока или Dummy во вкладке [Таргет]!", 3, Theme.Danger)
        return
    end

    local targetHrp = State.SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not (targetHrp and myHrp) then return end

    local oldPos = myHrp.CFrame
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Anchored then
            local n = v.Name:lower()
            if n:find("trash") or n:find("bin") or n:find("can") or n:find("dump") or n:find("prop") or n:find("rock") then
                count = count + 1
                myHrp.CFrame = v.CFrame * CFrame.new(0, 3, 0)
                task.wait(0.09)
                v.CFrame = targetHrp.CFrame * CFrame.new(0, 45, 0)
                v.AssemblyLinearVelocity = Vector3.new(0, -2200, 0)
                task.wait(0.03)
            end
        end
        if count >= 10 then break end
    end
    myHrp.CFrame = oldPos
    SendNotification("Trash Attack", "Запущено " .. count .. " объектов в цель!", 2, Theme.Success)
end)

-- ==================== ВКЛАДКА ⚡ ПЕРСОНАЖ ==================== --

CreateToggle(MovePage, "Noclip", "Проход сквозь любые стены", false, function(v)
    State.Noclip = v
    SendNotification("Noclip", v and "Включен" or "Выключен", 2)
end)

RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

CreateToggle(MovePage, "Speed Modifier", "Включить кастомную скорость", false, function(v)
    State.SpeedEnabled = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
    SendNotification("Speed", v and "Скорость изменена" or "Скорость сброшена", 2)
end)

CreateNumberInput(MovePage, "Значение скорости", "WalkSpeed", State.WalkSpeed, 16, 250, function(val)
    State.WalkSpeed = val
end)

RunService.RenderStepped:Connect(function()
    if State.SpeedEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = State.WalkSpeed
        end
    end
end)

-- ==================== ВКЛАДКА 👁️ ВИЗУАЛЫ ==================== --

local function ApplyHighlight(model, isDummy)
    if not model or model == LocalPlayer.Character then return end
    local hl = model:FindFirstChild("TSB_Highlight") or Instance.new("Highlight")
    hl.Name = "TSB_Highlight"
    hl.FillColor = isDummy and Theme.AccentDummy or Theme.Accent
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = State.Esp
    hl.Parent = model
end

-- Обработка реальных игроков
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        if p.Character then ApplyHighlight(p.Character, false) end
        p.CharacterAdded:Connect(function(char) ApplyHighlight(char, false) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char) ApplyHighlight(char, false) end)
end)

-- Периодическая проверка и подсветка Weakest Dummy
task.spawn(function()
    while true do
        if State.Esp then
            for _, dummy in pairs(GetDummies()) do
                ApplyHighlight(dummy, true)
            end
        end
        task.wait(2)
    end
end)

CreateToggle(VisualsPage, "Chams ESP (Игроки + Дами)", "Подсветка игроков и Weakest Dummy", false, function(v)
    State.Esp = v
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("TSB_Highlight") then
            p.Character.TSB_Highlight.Enabled = v
        end
    end
    for _, dummy in pairs(GetDummies()) do
        if dummy:FindFirstChild("TSB_Highlight") then
            dummy.TSB_Highlight.Enabled = v
        else
            if v then ApplyHighlight(dummy, true) end
        end
    end
    SendNotification("ESP", v and "ESP активен (Игроки + Дами)" or "ESP выключен", 2)
end)

CreateToggle(VisualsPage, "Fullbright", "Максимальная яркость карты", false, function(v)
    State.Fullbright = v
    if v then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.Ambient = OriginalLighting.Ambient
    end
end)

CreateNumberInput(VisualsPage, "Field of View", "Угол обзора камеры", State.Fov, 60, 120, function(val)
    State.Fov = val
    Camera.FieldOfView = val
end)

CreateActionButton(VisualsPage, "Сбросить камеру", "Вернуть фокус на себя", "СБРОС", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        SendNotification("Камера", "Фокус возвращен персонажу", 2)
    end
end)

-- ==================== ВКЛАДКА 👥 ТАРГЕТ & ДАМИ ==================== --

local TargetBox = Instance.new("Frame", TargetPage)
TargetBox.Size = UDim2.new(1, 0, 0, 56)
TargetBox.BackgroundColor3 = Theme.Sidebar
Instance.new("UICorner", TargetBox).CornerRadius = UDim.new(0, 8)

local TargetAvatar = Instance.new("ImageLabel", TargetBox)
TargetAvatar.Size = UDim2.new(0, 42, 0, 42)
TargetAvatar.Position = UDim2.new(0, 7, 0, 7)
TargetAvatar.BackgroundColor3 = Theme.Card
TargetAvatar.Image = "rbxassetid://6031075938"
TargetAvatar.ImageColor3 = Theme.Accent
Instance.new("UICorner", TargetAvatar).CornerRadius = UDim.new(0, 6)

local TargetName = Instance.new("TextLabel", TargetBox)
TargetName.Text = "Цель не выбрана"
TargetName.Font = Enum.Font.GothamBold
TargetName.TextSize = 12
TargetName.TextColor3 = Theme.Text
TargetName.Size = UDim2.new(1, -60, 0, 16)
TargetName.Position = UDim2.new(0, 56, 0, 10)
TargetName.TextXAlignment = Enum.TextXAlignment.Left
TargetName.BackgroundTransparency = 1

local TargetSub = Instance.new("TextLabel", TargetBox)
TargetSub.Text = "Нажмите на игрока или Dummy в списке"
TargetSub.Font = Enum.Font.Gotham
TargetSub.TextSize = 9
TargetSub.TextColor3 = Theme.TextDim
TargetSub.Size = UDim2.new(1, -60, 0, 14)
TargetSub.Position = UDim2.new(0, 56, 0, 28)
TargetSub.TextXAlignment = Enum.TextXAlignment.Left
TargetSub.BackgroundTransparency = 1

local ActionsContainer = Instance.new("Frame", TargetPage)
ActionsContainer.Size = UDim2.new(1, 0, 0, 30)
ActionsContainer.BackgroundTransparency = 1

local TpToBtn = Instance.new("TextButton", ActionsContainer)
TpToBtn.Size = UDim2.new(0.48, 0, 1, 0)
TpToBtn.BackgroundColor3 = Theme.Card
TpToBtn.Text = "🚀 Телепорт"
TpToBtn.TextColor3 = Theme.Text
TpToBtn.Font = Enum.Font.GothamBold
TpToBtn.TextSize = 10
Instance.new("UICorner", TpToBtn).CornerRadius = UDim.new(0, 6)

local ViewBtn = Instance.new("TextButton", ActionsContainer)
ViewBtn.Size = UDim2.new(0.48, 0, 1, 0)
ViewBtn.Position = UDim2.new(0.52, 0, 0, 0)
ViewBtn.BackgroundColor3 = Theme.Card
ViewBtn.Text = "👁️ Слежка"
ViewBtn.TextColor3 = Theme.Text
ViewBtn.Font = Enum.Font.GothamBold
ViewBtn.TextSize = 10
Instance.new("UICorner", ViewBtn).CornerRadius = UDim.new(0, 6)

TpToBtn.MouseButton1Click:Connect(function()
    if State.SelectedTarget and State.SelectedTarget.Character and State.SelectedTarget.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = State.SelectedTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            SendNotification("Телепорт", "Перемещен к " .. State.SelectedTarget.Name, 2, Theme.Success)
        end
    end
end)

ViewBtn.MouseButton1Click:Connect(function()
    if State.SelectedTarget and State.SelectedTarget.Character and State.SelectedTarget.Character:FindFirstChildOfClass("Humanoid") then
        Camera.CameraSubject = State.SelectedTarget.Character:FindFirstChildOfClass("Humanoid")
        SendNotification("Слежка", "Камера направлена на " .. State.SelectedTarget.Name, 2)
    end
end)

local TargetListFrame = Instance.new("Frame", TargetPage)
TargetListFrame.Size = UDim2.new(1, 0, 0, 120)
TargetListFrame.BackgroundColor3 = Theme.Sidebar
Instance.new("UICorner", TargetListFrame).CornerRadius = UDim.new(0, 8)

local PScroll = Instance.new("ScrollingFrame", TargetListFrame)
PScroll.Size = UDim2.new(1, -8, 1, -8)
PScroll.Position = UDim2.new(0, 4, 0, 4)
PScroll.BackgroundTransparency = 1
PScroll.ScrollBarThickness = 2
PScroll.ScrollBarImageColor3 = Theme.Accent
PScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local PLayout = Instance.new("UIListLayout", PScroll)
PLayout.Padding = UDim.new(0, 4)

local function UpdateTargetList()
    for _, ch in pairs(PScroll:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end

    -- 1. Добавляем Weakest Dummy
    for idx, dummy in pairs(GetDummies()) do
        local dBtn = Instance.new("TextButton", PScroll)
        dBtn.Size = UDim2.new(1, -4, 0, 24)
        dBtn.BackgroundColor3 = Color3.fromRGB(15, 30, 45)
        dBtn.Text = "  🤖 [BOT] " .. dummy.Name .. " #" .. idx
        dBtn.TextColor3 = Theme.AccentDummy
        dBtn.Font = Enum.Font.GothamBold
        dBtn.TextSize = 10
        dBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", dBtn).CornerRadius = UDim.new(0, 5)

        dBtn.MouseButton1Click:Connect(function()
            State.SelectedTarget = {Name = dummy.Name .. " #" .. idx, Character = dummy, IsNPC = true}
            TargetName.Text = dummy.Name
            TargetSub.Text = "[TSB NPC Training Dummy]"
            TargetAvatar.Image = "rbxassetid://6031075938"
            TargetAvatar.ImageColor3 = Theme.AccentDummy
        end)
    end

    -- 2. Добавляем Реальных игроков
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local Btn = Instance.new("TextButton", PScroll)
            Btn.Size = UDim2.new(1, -4, 0, 24)
            Btn.BackgroundColor3 = Theme.Card
            Btn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")"
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.GothamMedium
            Btn.TextSize = 10
            Btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)

            Btn.MouseButton1Click:Connect(function()
                State.SelectedTarget = {Name = p.DisplayName, Character = p.Character, IsNPC = false}
                TargetName.Text = p.DisplayName
                TargetSub.Text = "@" .. p.Name
                task.spawn(function()
                    TargetAvatar.ImageColor3 = Color3.new(1, 1, 1)
                    TargetAvatar.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
            end)
        end
    end
end

Players.PlayerAdded:Connect(UpdateTargetList)
Players.PlayerRemoving:Connect(UpdateTargetList)
UpdateTargetList()

-- ==================== ВКЛАДКА ⚙️ ОПЦИИ / НАСТРОЙКИ (UISCALE) ==================== --

local ScaleCard = Instance.new("Frame", SettingsPage)
ScaleCard.Size = UDim2.new(1, 0, 0, 78)
ScaleCard.BackgroundColor3 = Theme.Card
Instance.new("UICorner", ScaleCard).CornerRadius = UDim.new(0, 8)

local ScaleTitle = Instance.new("TextLabel", ScaleCard)
ScaleTitle.Text = "Размер интерфейса (UIScale)"
ScaleTitle.Font = Enum.Font.GothamBold
ScaleTitle.TextSize = 11
ScaleTitle.TextColor3 = Theme.Text
ScaleTitle.Size = UDim2.new(0.6, 0, 0, 15)
ScaleTitle.Position = UDim2.new(0, 10, 0, 6)
ScaleTitle.TextXAlignment = Enum.TextXAlignment.Left
ScaleTitle.BackgroundTransparency = 1

local ScaleDesc = Instance.new("TextLabel", ScaleCard)
ScaleDesc.Text = "0.8 - меньше, 1.0 - стандарт, 1.2 - больше"
ScaleDesc.Font = Enum.Font.Gotham
ScaleDesc.TextSize = 9
ScaleDesc.TextColor3 = Theme.TextDim
ScaleDesc.Size = UDim2.new(0.6, 0, 0, 14)
ScaleDesc.Position = UDim2.new(0, 10, 0, 22)
ScaleDesc.TextXAlignment = Enum.TextXAlignment.Left
ScaleDesc.BackgroundTransparency = 1

local ScaleInput = Instance.new("TextBox", ScaleCard)
ScaleInput.Size = UDim2.new(0, 60, 0, 24)
ScaleInput.Position = UDim2.new(1, -70, 0, 8)
ScaleInput.BackgroundColor3 = Theme.InputBg
ScaleInput.Text = tostring(State.GuiScale)
ScaleInput.TextColor3 = Theme.Accent
ScaleInput.Font = Enum.Font.GothamBold
ScaleInput.TextSize = 11
Instance.new("UICorner", ScaleInput).CornerRadius = UDim.new(0, 6)
local SStroke = Instance.new("UIStroke", ScaleInput)
SStroke.Color = Color3.fromRGB(60, 60, 80)
SStroke.Thickness = 1

local function SetScale(val)
    val = math.clamp(val, 0.6, 1.6)
    State.GuiScale = val
    ScaleInput.Text = string.format("%.2f", val)
    TweenService:Create(MainScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Scale = val
    }):Play()
end

ScaleInput.FocusLost:Connect(function()
    local num = tonumber(ScaleInput.Text)
    if num then SetScale(num) else ScaleInput.Text = tostring(State.GuiScale) end
end)

local PresetsHolder = Instance.new("Frame", ScaleCard)
PresetsHolder.Size = UDim2.new(1, -20, 0, 24)
PresetsHolder.Position = UDim2.new(0, 10, 0, 46)
PresetsHolder.BackgroundTransparency = 1

local presetLayout = Instance.new("UIListLayout", PresetsHolder)
presetLayout.FillDirection = Enum.FillDirection.Horizontal
presetLayout.Padding = UDim.new(0, 6)

local presets = {0.8, 0.9, 1.0, 1.1, 1.2}
for _, pVal in ipairs(presets) do
    local pBtn = Instance.new("TextButton", PresetsHolder)
    pBtn.Size = UDim2.new(0, 46, 1, 0)
    pBtn.BackgroundColor3 = Theme.Sidebar
    pBtn.Text = tostring(pVal) .. "x"
    pBtn.TextColor3 = Theme.Text
    pBtn.Font = Enum.Font.GothamMedium
    pBtn.TextSize = 10
    Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 5)
    pBtn.MouseButton1Click:Connect(function() SetScale(pVal) end)
end

CreateActionButton(SettingsPage, "Rejoin Server", "Перезайти на этот же сервер", "REJOIN", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

CreateActionButton(SettingsPage, "Закрыть GUI", "Полная выгрузка скрипта", "ЗАКРЫТЬ", function()
    ScreenGui:Destroy()
end)

-- ==================== ПЛАВАЮЩАЯ КНОПКА (ДЛЯ ТЕЛЕФОНОВ) ==================== --
local ToggleBtn = Instance.new("ImageButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 42, 0, 42)
ToggleBtn.Position = UDim2.new(0, 15, 0.45, 0)
ToggleBtn.BackgroundColor3 = Theme.Card
ToggleBtn.Image = "rbxassetid://6031075938"
ToggleBtn.ImageColor3 = Theme.Accent
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Theme.Accent
ToggleStroke.Thickness = 1.5

local draggingBtn, bStart, bPos
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBtn = true
        bStart = input.Position
        bPos = ToggleBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - bStart
        ToggleBtn.Position = UDim2.new(bPos.X.Scale, bPos.X.Offset + delta.X, bPos.Y.Scale, bPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function() draggingBtn = false end)

local isOpened = true
local function ToggleHub()
    isOpened = not isOpened
    if isOpened then
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
    else
        local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0.5, 0, 1.4, 0)
        })
        tw:Play()
        tw.Completed:Connect(function()
            if not isOpened then MainFrame.Visible = false end
        end)
    end
end

ToggleBtn.MouseButton1Click:Connect(ToggleHub)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert) then
        ToggleHub()
    end
end)

-- Инициализация первой страницы
Tabs["Бой"].Btn.BackgroundTransparency = 0
Tabs["Бой"].Label.TextColor3 = Theme.Text
Tabs["Бой"].Page.Visible = true

SendNotification("💎 KIRIK TSB HUB", "V26 Clean Edition загружен!", 3.5, Theme.Accent)
