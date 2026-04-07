local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KirikGodHubV22"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ГЛАВНОЕ ОКНО
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -80, 0.5, -180)
MainFrame.Size = UDim2.new(0, 165, 0, 365)
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(255, 0, 0)
Stroke.Thickness = 2

-- ПЕРЕМЕЩЕНИЕ ОКНА (DRAG)
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
Title.Text = "KIRIK GOD HUB"
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
PlayerList.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.ScrollBarThickness = 2
PlayerList.Parent = Content
Instance.new("UIListLayout", PlayerList).Padding = UDim.new(0, 3)

local UnattackedBtn = CreateButton("UN ATTACKED: OFF", UDim2.new(0.05, 0, 0, 185), Color3.fromRGB(0, 100, 0))
local RetreatBtn = CreateButton("SAFE RETREAT (ESCAPE)", UDim2.new(0.05, 0, 0, 215), Color3.fromRGB(200, 150, 0))
local CrushBtn = CreateButton("THROW TRASH", UDim2.new(0.05, 0, 0, 245), Color3.fromRGB(200, 0, 0))
local ResetBtn = CreateButton("RESET CAMERA", UDim2.new(0.05, 0, 0, 275), Color3.fromRGB(0, 50, 150))
local CloseBtn = CreateButton("CLOSE HUB", UDim2.new(0.05, 0, 0, 315), Color3.fromRGB(30, 30, 30))

-- ЛОГИКА
local listMode = "TP"
local selectedPlayer = nil
local unattackedActive = false
local espActive = false

-- ФУНКЦИЯ ПРОВЕРКИ ПОЛА (RAYCAST)
local function findSafePoint(targetPos)
    local rayOrigin = targetPos + Vector3.new(0, 150, 0)
    local rayDirection = Vector3.new(0, -300, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace.Debris}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result and result.Instance.CanCollide then
        return result.Position + Vector3.new(0, 3, 0)
    end
    return nil
end

-- ОБНОВЛЕНИЕ СПИСКА ИГРОКОВ
local function updateList()
    for _, child in pairs(PlayerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -5, 0, 20)
            btn.Text = player.DisplayName
            btn.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 10
            btn.Parent = PlayerList
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                CrushBtn.Text = "THROW AT: " .. player.Name
                if listMode == "TP" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                elseif listMode == "VIEW" and player.Character and player.Character:FindFirstChild("Humanoid") then
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

-- БЫСТРОЕ ОТСТУПЛЕНИЕ С ПРОВЕРКОЙ ПОЛА
RetreatBtn.MouseButton1Click:Connect(function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local escapePoints = {
        Vector3.new(450, 10, 450), Vector3.new(-450, 10, 450),
        Vector3.new(450, 10, -450), Vector3.new(-450, 10, -450),
        Vector3.new(0, 10, 500), Vector3.new(0, 10, -500)
    }
    
    local bestPoint = nil
    local maxDist = 0
    
    for _, point in pairs(escapePoints) do
        local safePos = findSafePoint(point)
        if safePos then
            local distance = (hrp.Position - safePos).Magnitude
            if distance > maxDist then
                maxDist = distance
                bestPoint = safePos
            end
        end
    end
    
    if bestPoint then
        hrp.CFrame = CFrame.new(bestPoint)
    end
end)

-- UN ATTACKED (УКЛОНЕНИЕ)
UnattackedBtn.MouseButton1Click:Connect(function()
    unattackedActive = not unattackedActive
    UnattackedBtn.Text = "UN ATTACKED: " .. (unattackedActive and "ON" or "OFF")
    UnattackedBtn.BackgroundColor3 = unattackedActive and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(0, 100, 0)
end)

task.spawn(function()
    while true do
        if unattackedActive then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local randomOffset = Vector3.new(math.random(-7, 7), 0, math.random(-7, 7))
                hrp.CFrame = hrp.CFrame * CFrame.new(randomOffset)
            end
        end
        task.wait(0.06)
    end
end)

-- THROW TRASH (МЕТАНИЕ МУСОРОК)
CrushBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer or not selectedPlayer.Character then return end
    local targetHrp = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if targetHrp and myHrp then
        local oldPos = myHrp.CFrame
        local trashFound = 0
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Anchored then
                local name = v.Name:lower()
                if name:find("trash") or name:find("bin") or name:find("dumpster") or name:find("can") then
                    trashFound = trashFound + 1
                    myHrp.CFrame = v.CFrame * CFrame.new(0, 3, 0)
                    task.wait(0.12)
                    if targetHrp.Parent then
                        v.CFrame = targetHrp.CFrame * CFrame.new(0, 45, 0)
                        v.AssemblyLinearVelocity = Vector3.new(0, -1200, 0)
                    end
                    task.wait(0.05)
                end
            end
            if trashFound >= 6 then break end
        end
        myHrp.CFrame = oldPos
    end
end)

-- ESP
EspBtn.MouseButton1Click:Connect(function()
    espActive = not espActive
    EspBtn.Text = "ESP: " .. (espActive and "ON" or "OFF")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if espActive then
                local hl = p.Character:FindFirstChild("Highlight") or Instance.new("Highlight", p.Character)
                hl.FillColor = Color3.fromRGB(255, 0, 0)
            elseif p.Character:FindFirstChild("Highlight") then
                p.Character.Highlight:Destroy()
            end
        end
    end
end)

ResetBtn.MouseButton1Click:Connect(function() 
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid 
    end
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)
updateList()
