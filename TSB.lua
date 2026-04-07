local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KirikUltraHub"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ГЛАВНОЕ ОКНО
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -75, 0.5, -150)
MainFrame.Size = UDim2.new(0, 160, 0, 320) -- Немного увеличил высоту для новой кнопки
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 2

local DragHandle = Instance.new("Frame")
DragHandle.Size = UDim2.new(1, 0, 0, 30)
DragHandle.BackgroundTransparency = 1
DragHandle.Parent = MainFrame

-- ДРАГ-СИСТЕМА
local dragging, dragStart, startPos
DragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
    end
end)
DragHandle.InputChanged:Connect(function(input)
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
Title.Text = "KIRIK TSB V20"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Size = UDim2.new(1, 0, 0, 35)
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
local EspBtn = CreateButton("ESP: OFF", UDim2.new(0.05, 0, 0, 40), Color3.fromRGB(40, 40, 40))
local ModeBtn = CreateButton("MODE: TP", UDim2.new(0.05, 0, 0, 70), Color3.fromRGB(80, 0, 0))

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(0.9, 0, 0, 70)
PlayerList.Position = UDim2.new(0.05, 0, 0, 100)
PlayerList.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.ScrollBarThickness = 2
PlayerList.Parent = Content
Instance.new("UIListLayout", PlayerList).Padding = UDim.new(0, 3)

local UnattackedBtn = CreateButton("UN ATTACKED: OFF", UDim2.new(0.05, 0, 0, 180), Color3.fromRGB(0, 100, 0))
local CrushBtn = CreateButton("THROW TRASH (SELECT)", UDim2.new(0.05, 0, 0, 210), Color3.fromRGB(200, 0, 0))
local ResetCamBtn = CreateButton("RESET CAMERA", UDim2.new(0.05, 0, 0, 240), Color3.fromRGB(0, 50, 100))
local CloseBtn = CreateButton("CLOSE HUB", UDim2.new(0.05, 0, 0, 275), Color3.fromRGB(50, 50, 50))

-- ПЕРЕМЕННЫЕ
local listMode = "TP"
local selectedPlayer = nil
local unattackedActive = false

-- ЛОГИКА ВЫБОРА ИГРОКА
local function updateList()
    for _, child in pairs(PlayerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -5, 0, 20)
            btn.Text = player.DisplayName
            btn.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 10
            btn.Parent = PlayerList
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                CrushBtn.Text = "TARGET: " .. player.Name
                if listMode == "TP" then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                else
                    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
                end
            end)
        end
    end
end

ModeBtn.MouseButton1Click:Connect(function()
    listMode = (listMode == "TP") and "VIEW" or "TP"
    ModeBtn.Text = "MODE: " .. listMode
end)

-- ЛОГИКА CRUSH (КИДАЕМ МУСОРКИ)
CrushBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer or not selectedPlayer.Character then return end
    local targetHrp = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if targetHrp and myHrp then
        local originalCFrame = myHrp.CFrame
        local trashItems = {}
        
        -- Ищем именно мусорки по названию
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Anchored then
                local name = v.Name:lower()
                if name:find("trash") or name:find("bin") or name:find("garbage") then
                    table.insert(trashItems, v)
                end
            end
            if #trashItems >= 5 then break end 
        end
        
        if #trashItems == 0 then
            CrushBtn.Text = "NO TRASH FOUND!"
            task.wait(1)
            CrushBtn.Text = "THROW TRASH (SELECT)"
            return
        end

        for _, item in pairs(trashItems) do
            -- ТП к мусорке чтобы "захватить" её
            myHrp.CFrame = item.CFrame * CFrame.new(0, 3, 0)
            task.wait(0.15)
            
            -- Кидаем в цель
            if targetHrp.Parent then
                item.CFrame = targetHrp.CFrame * CFrame.new(0, 50, 0)
                item.AssemblyLinearVelocity = Vector3.new(0, -1200, 0)
            end
            task.wait(0.1)
        end
        myHrp.CFrame = originalCFrame
    end
end)

-- ЛОГИКА UN ATTACKED (УВОРОТЫ)
UnattackedBtn.MouseButton1Click:Connect(function()
    unattackedActive = not unattackedActive
    UnattackedBtn.Text = "UN ATTACKED: " .. (unattackedActive and "ON" or "OFF")
    UnattackedBtn.BackgroundColor3 = unattackedActive and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(0, 100, 0)
end)

task.spawn(function()
    while true do
        if unattackedActive then
            local char = game.Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Рандомно перемещаем игрока в стороны на 5-7 студов
                local randomOffset = Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
                hrp.CFrame = hrp.CFrame * CFrame.new(randomOffset)
                task.wait(0.05) -- Скорость перемещения
            end
        end
        task.wait(0.01)
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
                local hl = p.Character:FindFirstChild("UltraHighlight") or Instance.new("Highlight", p.Character)
                hl.Name = "UltraHighlight"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
            elseif p.Character:FindFirstChild("UltraHighlight") then
                p.Character.UltraHighlight:Destroy()
            end
        end
    end
end)

ResetCamBtn.MouseButton1Click:Connect(function() workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

game.Players.PlayerAdded:Connect(updateList)
game.Players.PlayerRemoving:Connect(updateList)
updateList()
