local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KirikGodHub"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local TweenService = game:GetService("TweenService")

-- ГЛАВНОЕ ОКНО (TSB STYLE)
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -75, 0.5, -165)
MainFrame.Size = UDim2.new(0, 160, 0, 350) -- Увеличил под новую кнопку
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 2

-- ДРАГ (ПЕРЕМЕЩЕНИЕ)
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, 0)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "KIRIK TSB V21"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Parent = Content

local function CreateButton(text, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 25)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.Parent = Content
    Instance.new("UICorner", btn)
    return btn
end

-- КНОПКИ
local EspBtn = CreateButton("ESP: OFF", UDim2.new(0.05, 0, 0, 45), Color3.fromRGB(40, 40, 40))
local ModeBtn = CreateButton("MODE: TP", UDim2.new(0.05, 0, 0, 75), Color3.fromRGB(80, 0, 0))

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(0.9, 0, 0, 70)
PlayerList.Position = UDim2.new(0.05, 0, 0, 105)
PlayerList.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.ScrollBarThickness = 2
PlayerList.Parent = Content
Instance.new("UIListLayout", PlayerList).Padding = UDim.new(0, 3)

local UnattackedBtn = CreateButton("UN ATTACKED: OFF", UDim2.new(0.05, 0, 0, 185), Color3.fromRGB(0, 100, 0))
local RetreatBtn = CreateButton("FAST RETREAT (ESCAPE)", UDim2.new(0.05, 0, 0, 215), Color3.fromRGB(200, 150, 0))
local CrushBtn = CreateButton("THROW TRASH", UDim2.new(0.05, 0, 0, 245), Color3.fromRGB(200, 0, 0))
local ResetBtn = CreateButton("RESET CAMERA", UDim2.new(0.05, 0, 0, 275), Color3.fromRGB(0, 50, 150))
local CloseBtn = CreateButton("CLOSE HUB", UDim2.new(0.05, 0, 0, 310), Color3.fromRGB(30, 30, 30))

-- ЛОГИКА ТЕЛЕПОРТА И ВЫБОРА
local listMode = "TP"
local selectedPlayer = nil
local unattackedActive = false

local function updateList()
    for _, child in pairs(PlayerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -5, 0, 20)
            btn.Text = player.DisplayName
            btn.BackgroundColor3 = Color3.fromRGB(35, 10, 10)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 10
            btn.Parent = PlayerList
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                CrushBtn.Text = "THROW AT: " .. player.Name
                if listMode == "TP" then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                else
                    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
                end
            end)
        end
    end
end

-- БЫСТРОЕ ОСТУПЛЕНИЕ
RetreatBtn.MouseButton1Click:Connect(function()
    local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Точки по краям карты (примерные для большинства карт TSB)
    local mapEdges = {
        Vector3.new(900, 50, 900),
        Vector3.new(-900, 50, 900),
        Vector3.new(900, 50, -900),
        Vector3.new(-900, 50, -900)
    }
    
    local furthestPoint = mapEdges[1]
    local maxDist = 0
    
    -- Ищем точку, которая ДАЛЬШЕ всего от нас сейчас
    for _, point in pairs(mapEdges) do
        local dist = (hrp.Position - point).Magnitude
        if dist > maxDist then
            maxDist = dist
            furthestPoint = point
        end
    end
    
    hrp.CFrame = CFrame.new(furthestPoint)
end)

-- UN ATTACKED (УВОРОТЫ)
task.spawn(function()
    while true do
        if unattackedActive then
            local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-7, 7), 0, math.random(-7, 7))
            end
        end
        task.wait(0.06)
    end
end)

UnattackedBtn.MouseButton1Click:Connect(function()
    unattackedActive = not unattackedActive
    UnattackedBtn.Text = "UN ATTACKED: " .. (unattackedActive and "ON" or "OFF")
    UnattackedBtn.BackgroundColor3 = unattackedActive and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(0, 100, 0)
end)

-- THROW TRASH
CrushBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer or not selectedPlayer.Character then return end
    local targetHrp = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if targetHrp and myHrp then
        local oldPos = myHrp.CFrame
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Anchored and (v.Name:lower():find("trash") or v.Name:lower():find("bin")) then
                myHrp.CFrame = v.CFrame * CFrame.new(0, 3, 0)
                task.wait(0.1)
                v.CFrame = targetHrp.CFrame * CFrame.new(0, 40, 0)
                v.AssemblyLinearVelocity = Vector3.new(0, -1000, 0)
                task.wait(0.05)
            end
        end
        myHrp.CFrame = oldPos
    end
end)

-- ESP
local espActive = false
EspBtn.MouseButton1Click:Connect(function()
    espActive = not espActive
    EspBtn.Text = "ESP: " .. (espActive and "ON" or "OFF")
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character then
            if espActive then
                local hl = p.Character:FindFirstChild("HL") or Instance.new("Highlight", p.Character)
                hl.Name = "HL"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
            elseif p.Character:FindFirstChild("HL") then p.Character.HL:Destroy() end
        end
    end
end)

ModeBtn.MouseButton1Click:Connect(function()
    listMode = (listMode == "TP") and "VIEW" or "TP"
    ModeBtn.Text = "MODE: " .. listMode
end)

ResetBtn.MouseButton1Click:Connect(function() workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
game.Players.PlayerAdded:Connect(updateList)
game.Players.PlayerRemoving:Connect(updateList)
updateList()
