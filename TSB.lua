local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KirikGodHubV25"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

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
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 0, 0)

-- ПЕРЕМЕЩЕНИЕ ОКНА
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
game:GetService("UserInputService").InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, 0)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "KIRIK HUB V25"
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
local RetreatBtn = CreateButton("SMART ESCAPE", UDim2.new(0.05, 0, 0, 215), Color3.fromRGB(200, 150, 0))
local CrushBtn = CreateButton("THROW TRASH", UDim2.new(0.05, 0, 0, 245), Color3.fromRGB(200, 0, 0))
local ResetBtn = CreateButton("RESET CAMERA", UDim2.new(0.05, 0, 0, 275), Color3.fromRGB(0, 50, 150))
local CloseBtn = CreateButton("CLOSE HUB", UDim2.new(0.05, 0, 0, 315), Color3.fromRGB(30, 30, 30))

-- ФУНКЦИЯ ОСТАНОВКИ ИНЕРЦИИ (чтобы не улетать после ТП)
local function stopVelocity(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("LinearVelocity") then
            v:Destroy()
        end
    end
end

-- ЛОГИКА ПОИСКА ПОЛА (RAYCAST V2)
local function findSafePoint(targetPos)
    local rayOrigin = Vector3.new(targetPos.X, 1000, targetPos.Z)
    local rayDirection = Vector3.new(0, -2000, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, workspace:FindFirstChild("Visuals")}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.RespectCanCollide = true -- Игнорируем невидимые триггеры!

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if result and result.Instance then
        return result.Position + Vector3.new(0, 4, 0)
    end
    return nil
end

-- SMART ESCAPE
RetreatBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Ищем точки по краям мира и вокруг игрока
    local checkRadii = {550, 400, 250, 100}
    local angles = {
        Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1),
        Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1),
        Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)
    }
    
    local bestPoint = nil
    local maxDist = 0
    
    for _, radius in ipairs(checkRadii) do
        for _, dir in ipairs(angles) do
            local testPos = dir * radius
            local safePos = findSafePoint(testPos)
            
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
        stopVelocity(char) -- Замираем
        hrp.CFrame = CFrame.new(bestPoint)
    else
        -- Если края не найдены, пробуем прыжок назад относительно игрока
        local backPos = findSafePoint(hrp.Position - (hrp.CFrame.LookVector * 150))
        if backPos then
            stopVelocity(char)
            hrp.CFrame = CFrame.new(backPos)
        else
            RetreatBtn.Text = "FLOOR ERROR!"
            task.wait(1)
            RetreatBtn.Text = "SMART ESCAPE"
        end
    end
end)

-- ОСТАЛЬНЫЕ ФУНКЦИИ (ESP, UN ATTACKED, TRASH)
local unattackedActive = false
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
                hrp.CFrame = hrp.CFrame * CFrame.new(math.random(-8, 8), 0, math.random(-8, 8))
            end
        end
        task.wait(0.06)
    end
end)

local selectedPlayer = nil
CrushBtn.MouseButton1Click:Connect(function()
    if not selectedPlayer or not selectedPlayer.Character then return end
    local targetHrp = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if targetHrp and myHrp then
        local oldPos = myHrp.CFrame
        local count = 0
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Anchored then
                local n = v.Name:lower()
                if n:find("trash") or n:find("bin") or n:find("can") or n:find("dump") then
                    count = count + 1
                    myHrp.CFrame = v.CFrame * CFrame.new(0, 3, 0)
                    task.wait(0.12)
                    v.CFrame = targetHrp.CFrame * CFrame.new(0, 50, 0)
                    v.AssemblyLinearVelocity = Vector3.new(0, -1800, 0)
                    task.wait(0.05)
                end
            end
            if count >= 8 then break end
        end
        myHrp.CFrame = oldPos
    end
end)

local espActive = false
EspBtn.MouseButton1Click:Connect(function()
    espActive = not espActive
    EspBtn.Text = "ESP: " .. (espActive and "ON" or "OFF")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if espActive then
                local hl = p.Character:FindFirstChild("HL") or Instance.new("Highlight", p.Character)
                hl.Name = "HL"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
            elseif p.Character:FindFirstChild("HL") then p.Character.HL:Destroy() end
        end
    end
end)

local listMode = "TP"
local function updateList()
    for _, child in pairs(PlayerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -5, 0, 20)
            btn.Text = player.DisplayName
            btn.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Parent = PlayerList
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                CrushBtn.Text = "THROW AT: " .. player.Name
                if listMode == "TP" and player.Character then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                elseif listMode == "VIEW" and player.Character then
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

ResetBtn.MouseButton1Click:Connect(function() if LocalPlayer.Character then workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid end end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)
updateList()
