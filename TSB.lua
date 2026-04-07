local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KirikTSBHub"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ГЛАВНОЕ ОКНО (TSB STYLE)
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 5, 5) -- Темно-красный оттенок
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -75, 0.5, -130)
MainFrame.Size = UDim2.new(0, 150, 0, 280)
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 1.5

local DragHandle = Instance.new("Frame")
DragHandle.Size = UDim2.new(1, 0, 0, 30)
DragHandle.BackgroundTransparency = 1
DragHandle.Parent = MainFrame

-- ЛОГИКА ПЕРЕМЕЩЕНИЯ (Драг)
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
Title.Text = "KIRIK HUB: TSB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Parent = Content

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "×"
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -28, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn)

-- КНОПКИ УПРАВЛЕНИЯ
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

local EspBtn = CreateButton("ESP: OFF", UDim2.new(0.05, 0, 0, 35), Color3.fromRGB(40, 40, 40))
local ModeBtn = CreateButton("MODE: TP", UDim2.new(0.05, 0, 0, 65), Color3.fromRGB(100, 0, 0))

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(0.9, 0, 0, 80)
PlayerList.Position = UDim2.new(0.05, 0, 0, 95)
PlayerList.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.ScrollBarThickness = 2
PlayerList.Parent = Content
Instance.new("UIListLayout", PlayerList).Padding = UDim.new(0, 3)

local StabBtn = CreateButton("FIX POS (STAB)", UDim2.new(0.05, 0, 0, 180), Color3.fromRGB(150, 0, 0))
local CrushBtn = CreateButton("TSB CRUSH (SELECT)", UDim2.new(0.05, 0, 0, 210), Color3.fromRGB(200, 0, 0))
local UnviewBtn = CreateButton("RESET CAMERA", UDim2.new(0.05, 0, 0, 240), Color3.fromRGB(0, 50, 100))

-- ЛОГИКА TSB
local listMode = "TP"
local selectedPlayer = nil

ModeBtn.MouseButton1Click:Connect(function()
    listMode = (listMode == "TP") and "VIEW" or "TP"
    ModeBtn.Text = "MODE: " .. listMode
end)

local function updateList()
    for _, child in pairs(PlayerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -5, 0, 20)
            btn.Text = player.DisplayName
            btn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 10
            btn.Parent = PlayerList
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                CrushBtn.Text = "CRUSH: " .. player.Name
                if listMode == "TP" then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                else
                    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
                end
            end)
        end
    end
end

-- КРАШ-ЛОГИКА ПОД TSB (Ищем обломки)
CrushBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer or not selectedPlayer.Character then return end
    local targetHrp = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if targetHrp and myHrp then
        local originalCFrame = myHrp.CFrame
        local objects = {}
        
        -- В TSB обломки часто лежат в папках 'Debris' или просто в Workspace
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Anchored and v.CanCollide then
                if v.Size.Magnitude > 3 and not v:IsDescendantOf(game.Players.LocalPlayer.Character) then
                    table.insert(objects, v)
                end
            end
            if #objects >= 8 then break end 
        end
        
        for _, obj in pairs(objects) do
            myHrp.CFrame = obj.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.1)
            if targetHrp.Parent then
                obj.CFrame = targetHrp.CFrame * CFrame.new(0, 40, 0)
                obj.AssemblyLinearVelocity = Vector3.new(0, -1000, 0)
            end
            task.wait(0.05)
        end
        myHrp.CFrame = originalCFrame
    end
end)

-- ESP
local espActive = false
local function applyESP(char)
    if espActive and char then
        local hl = char:FindFirstChild("TsbHighlight") or Instance.new("Highlight", char)
        hl.Name = "TsbHighlight"
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

EspBtn.MouseButton1Click:Connect(function()
    espActive = not espActive
    EspBtn.Text = "ESP: " .. (espActive and "ON" or "OFF")
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character then
            if espActive then applyESP(p.Character)
            elseif p.Character:FindFirstChild("TsbHighlight") then p.Character.TsbHighlight:Destroy() end
        end
    end
end)

-- Фикс позиции (чтобы не улетать от ударов)
StabBtn.MouseButton1Click:Connect(function()
    local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
    hrp.Anchored = true
    task.wait(0.3)
    hrp.Anchored = false
end)

game.Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(applyESP) updateList() end)
game.Players.PlayerRemoving:Connect(updateList)
UnviewBtn.MouseButton1Click:Connect(function() workspace.CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

updateList()
