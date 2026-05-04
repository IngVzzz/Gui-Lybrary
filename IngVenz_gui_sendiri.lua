local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BitwiseHub"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

-- ==================== STATE TOGGLE (TETAP INGAT POSISINYA) ====================
_G.ToggleStates = {
    -- SURVIVOR
    DisableSkillCheck = false,
    ESP_Player = false,
    Moonwalk = false,
    Croushair = false,
    BypassZoom = false,
    -- KILLER
    Aimbot = false,
    Hitbox = false,
    -- MODS
    Walkspeed = false,
    WalkspeedValue = 50,
    Noclip = false,
}

-- ==================== TOMBOL KOTAK ====================
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 45, 0, 45)
toggleButton.Position = UDim2.new(1, -80, 0.5, -50)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
toggleButton.Text = "▶"
toggleButton.TextColor3 = Color3.fromRGB(219, 15, 15)
toggleButton.TextSize = 23
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleButton

-- Drag toggle button
local dragging = false
local dragStart = nil
local startPos = nil
local isDragging = false

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        isDragging = false
        dragStart = input.Position
        startPos = toggleButton.Position
    end
end)

toggleButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            isDragging = true
        end
        toggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

toggleButton.InputEnded:Connect(function()
    dragging = false
    task.wait(0.05)
    isDragging = false
end)

-- ==================== ESP PLAYER ====================
local Hook = {
    Players = {
        ["Killer"] = {Color = Color3.fromRGB(255, 0, 0), On = true},
        ["Survivor"] = {Color = Color3.fromRGB(0, 255, 255), On = true}
    }
}

local isEspActive = false
local espConnections = {}
local playerConnections = {}
local espRenderConn = nil

local function safeDisconnect(conn)
    if conn and conn.Disconnect then
        pcall(function() conn:Disconnect() end)
    end
end

local function clearAllESPConnections()
    for _, conn in pairs(espConnections) do
        safeDisconnect(conn)
    end
    espConnections = {}
    
    for player, conn in pairs(playerConnections) do
        safeDisconnect(conn)
    end
    playerConnections = {}
    
    if espRenderConn then
        safeDisconnect(espRenderConn)
        espRenderConn = nil
    end
end

local function RemoveHighlight(char)
    if not char then return end
    local h = char:FindFirstChild("ESP_Highlight")
    if h then
        h:Destroy()
    end
end

local function ApplyHighlight(char, color)
    if not char or not color then return end
    
    local existing = char:FindFirstChild("ESP_Highlight")
    if existing and existing.FillColor == color then
        return
    end
    
    if existing then
        existing:Destroy()
    end
    
    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.85
    h.OutlineTransparency = 0.3
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
end

local function UpdateSinglePlayer(player)
    if not isEspActive then return end
    if player == LocalPlayer then return end
    if not player.Character or not player.Team then return end
    
    local teamName = player.Team.Name
    local color = nil
    
    if teamName == "Killer" and Hook.Players["Killer"].On then
        color = Hook.Players["Killer"].Color
    elseif teamName == "Survivors" and Hook.Players["Survivor"].On then
        color = Hook.Players["Survivor"].Color
    end
    
    if color then
        ApplyHighlight(player.Character, color)
    else
        RemoveHighlight(player.Character)
    end
end

local function UpdateAllHighlights()
    if not isEspActive then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            UpdateSinglePlayer(p)
        end
    end
end

local function BindPlayerEvents(player)
    if player == LocalPlayer then return end
    
    if playerConnections[player] then
        safeDisconnect(playerConnections[player])
        playerConnections[player] = nil
    end
    
    local conn = player.CharacterAdded:Connect(function()
        task.wait(0.3)
        if isEspActive then
            UpdateSinglePlayer(player)
        end
    end)
    playerConnections[player] = conn
    table.insert(espConnections, conn)
end

local function enableESP()
    if isEspActive then return end
    isEspActive = true
    espConnections = {}
    playerConnections = {}
    
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        BindPlayerEvents(player)
        task.wait(0.2)
        if isEspActive then
            UpdateSinglePlayer(player)
        end
    end)
    table.insert(espConnections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            RemoveHighlight(player.Character)
        end
        if playerConnections[player] then
            safeDisconnect(playerConnections[player])
            playerConnections[player] = nil
        end
    end)
    table.insert(espConnections, playerRemovingConn)
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            BindPlayerEvents(p)
        end
    end
    
    espRenderConn = RunService.RenderStepped:Connect(UpdateAllHighlights)
end

local function disableESP()
    if not isEspActive then return end
    isEspActive = false
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            RemoveHighlight(p.Character)
        end
    end
    clearAllESPConnections()
end

-- ==================== MOONWALK ASLI ====================
local PlayersMW = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayerMW = PlayersMW.LocalPlayer
local char = nil
local humanoid = nil
local rootPart = nil

local currentGui = nil
local moonwalkButton = nil
local moonwalkActive = false
local turningLeft = false
local turningRight = false

local baseYaw = 0
local currentYaw = 0
local maxTurn = 40
local turnSpeed = 850
local returnSpeed = 800

local moonwalkConnections = {}
local buttonConnections = {}
local lastCharCheck = 0
local charValid = false

local function updateCharacterRefs(newChar)
    char = newChar or LocalPlayerMW.Character
    if not char then 
        charValid = false
        return false 
    end
    humanoid = char:FindFirstChild("Humanoid")
    rootPart = char:FindFirstChild("HumanoidRootPart")
    charValid = (humanoid and rootPart and rootPart.Parent ~= nil)
    return charValid
end

local function getYaw(cf)
    local _, y, _ = cf:ToEulerAnglesYXZ()
    return math.deg(y)
end

local function setYaw(cf, yaw)
    return CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(yaw), 0)
end

local function clearButtonEvents()
    for _, conn in pairs(buttonConnections) do
        pcall(function() conn:Disconnect() end)
    end
    buttonConnections = {}
end

local function enableMoonwalk()
    if not charValid then 
        if not updateCharacterRefs() then return end
    end
    if not rootPart or not humanoid then return end
    if moonwalkActive then return end
    moonwalkActive = true
    humanoid.AutoRotate = false
    baseYaw = getYaw(rootPart.CFrame)
    currentYaw = baseYaw
    if moonwalkButton then
        pcall(function()
            moonwalkButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        end)
    end
end

local function disableMoonwalk()
    if not moonwalkActive then return end
    moonwalkActive = false
    if charValid and humanoid then
        humanoid.AutoRotate = true
    end
    if moonwalkButton then
        pcall(function()
            moonwalkButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        end)
    end
    turningLeft = false
    turningRight = false
end

local function destroyMoonwalkGUI()
    if currentGui then
        pcall(function() currentGui:Destroy() end)
        currentGui = nil
        moonwalkButton = nil
    end
end

local function createMoonwalkGUI()
    if currentGui then
        destroyMoonwalkGUI()
    end
    
    clearButtonEvents()
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "MoonwalkController"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    currentGui = gui
    
    moonwalkButton = Instance.new("TextButton")
    moonwalkButton.Size = UDim2.new(0, 45, 0, 45)
    moonwalkButton.Position = UDim2.new(1, -50, 1, -110)
    moonwalkButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    moonwalkButton.Text = "R"
    moonwalkButton.TextColor3 = Color3.new(1, 1, 1)
    moonwalkButton.TextScaled = true
    moonwalkButton.BorderSizePixel = 0
    moonwalkButton.Parent = gui
    
    local mouseDownConn = moonwalkButton.MouseButton1Down:Connect(enableMoonwalk)
    table.insert(buttonConnections, mouseDownConn)
    
    local mouseUpConn = moonwalkButton.MouseButton1Up:Connect(disableMoonwalk)
    table.insert(buttonConnections, mouseUpConn)
    
    local touchBeganConn = moonwalkButton.TouchBegan:Connect(enableMoonwalk)
    table.insert(buttonConnections, touchBeganConn)
    
    local touchEndedConn = moonwalkButton.TouchEnded:Connect(disableMoonwalk)
    table.insert(buttonConnections, touchEndedConn)
end

local function clearAllMoonwalkEvents()
    for _, conn in ipairs(moonwalkConnections) do
        pcall(function() conn:Disconnect() end)
    end
    moonwalkConnections = {}
    clearButtonEvents()
end

function StartMoonwalkSystem()
    if moonwalkActive then return end
    clearAllMoonwalkEvents()
    moonwalkConnections = {}
    
    local touchMovedConn = UIS.TouchMoved:Connect(function(input)
        if not moonwalkActive then return end
        if math.abs(input.Delta.X) > 3 then
            if input.Delta.X > 0 then
                turningRight = true
                turningLeft = false
            else
                turningLeft = true
                turningRight = false
            end
        end
    end)
    table.insert(moonwalkConnections, touchMovedConn)
    
    local touchEndedConn = UIS.TouchEnded:Connect(function()
        turningLeft = false
        turningRight = false
    end)
    table.insert(moonwalkConnections, touchEndedConn)
    
    local renderConn = RunService.RenderStepped:Connect(function(dt)
        if not moonwalkActive then return end
        
        local now = tick()
        if now - lastCharCheck >= 0.5 then
            lastCharCheck = now
            if not charValid then
                if not updateCharacterRefs() then return end
            end
        end
        
        if not rootPart or not humanoid or not rootPart.Parent then 
            charValid = false
            return 
        end
        
        if turningLeft then
            currentYaw = math.clamp(currentYaw - turnSpeed * dt, baseYaw - maxTurn, baseYaw + maxTurn)
        elseif turningRight then
            currentYaw = math.clamp(currentYaw + turnSpeed * dt, baseYaw - maxTurn, baseYaw + maxTurn)
        else
            if currentYaw < baseYaw then
                currentYaw = math.min(currentYaw + returnSpeed * dt, baseYaw)
            elseif currentYaw > baseYaw then
                currentYaw = math.max(currentYaw - returnSpeed * dt, baseYaw)
            end
        end
        
        if rootPart and rootPart.Parent then
            rootPart.CFrame = setYaw(CFrame.new(rootPart.CFrame.Position), currentYaw)
        end
    end)
    table.insert(moonwalkConnections, renderConn)
    
    local charAddedConn = LocalPlayerMW.CharacterAdded:Connect(function(newChar)
        task.wait(0.2)
        updateCharacterRefs(newChar)
        if moonwalkActive then
            disableMoonwalk()
            task.wait(0.1)
            enableMoonwalk()
        end
    end)
    table.insert(moonwalkConnections, charAddedConn)
    
    updateCharacterRefs()
    createMoonwalkGUI()
end

function StopMoonwalkSystem()
    destroyMoonwalkGUI()
    if moonwalkActive then
        disableMoonwalk()
    end
    clearAllMoonwalkEvents()
end

-- ==================== CROUSHAIR ====================
local croudhairActive = false
local crosshairGui = nil
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local function CreateCroushair()
    if crosshairGui then return end
    
    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "CustomCrosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.IgnoreGuiInset = true
    crosshairGui.Parent = playerGui
    
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 5, 0, 5)
    dot.Position = UDim2.new(0.49, 0, 0.53, 0)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.ZIndex = 100
    dot.Parent = crosshairGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = dot
end

local function RemoveCroushair()
    if crosshairGui then
        crosshairGui:Destroy()
        crosshairGui = nil
    end
end

local function StartCroushair()
    if croudhairActive then return end
    croudhairActive = true
    CreateCroushair()
end

local function StopCroushair()
    croudhairActive = false
    RemoveCroushair()
end

-- ==================== BYPASS ZOOM ====================
local zoomActive = false
local zoomLevel = 50
local zoomSpeed = 3
local DEFAULT_FOV = 70
local zoomRenderConn = nil
local zoomInputConn = nil
local zoomMaxConn = nil
local CameraZoom = workspace.CurrentCamera

local function getCameraZoom()
    if workspace and workspace.CurrentCamera then
        CameraZoom = workspace.CurrentCamera
        return true
    end
    return false
end

local function disableZoom()
    if not zoomActive then return end
    zoomActive = false
    
    if CameraZoom then
        pcall(function()
            CameraZoom.FieldOfView = DEFAULT_FOV
        end)
    end
    
    pcall(function()
        LocalPlayer.CameraMaxZoomDistance = 40
        LocalPlayer.CameraMinZoomDistance = 1
    end)
    
    if zoomRenderConn then zoomRenderConn:Disconnect() zoomRenderConn = nil end
    if zoomInputConn then zoomInputConn:Disconnect() zoomInputConn = nil end
    if zoomMaxConn then zoomMaxConn:Disconnect() zoomMaxConn = nil end
end

local function enableZoom()
    if zoomActive then return end
    
    if not getCameraZoom() then
        task.wait(0.3)
        if not CameraZoom then return end
    end
    
    zoomActive = true
    zoomLevel = CameraZoom.FieldOfView
    DEFAULT_FOV = CameraZoom.FieldOfView
    
    pcall(function()
        LocalPlayer.CameraMaxZoomDistance = 50
        LocalPlayer.CameraMinZoomDistance = 8
    end)
    
    zoomMaxConn = LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
        if zoomActive and LocalPlayer.CameraMaxZoomDistance < 50 then
            pcall(function() LocalPlayer.CameraMaxZoomDistance = 50 end)
        end
    end)
    
    zoomInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not zoomActive then return end
        if not CameraZoom then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            zoomLevel = zoomLevel - (input.Position.Z * zoomSpeed)
            zoomLevel = math.clamp(zoomLevel, 20, 120)
            pcall(function() CameraZoom.FieldOfView = zoomLevel end)
        end
    end)
    
    zoomRenderConn = RunService.RenderStepped:Connect(function()
        if not zoomActive then return end
        if not CameraZoom then return end
        pcall(function()
            if CameraZoom.FieldOfView ~= zoomLevel then
                CameraZoom.FieldOfView = zoomLevel
            end
            if LocalPlayer.CameraMaxZoomDistance ~= 50 then
                LocalPlayer.CameraMaxZoomDistance = 50
            end
        end)
    end)
end

local function StartZoom()
    enableZoom()
end

local function StopZoom()
    disableZoom()
end

-- ==================== DISABLE SKILLCHECK ====================
local isSkillCheckActive = false
local skillCheckConnections = {}

local function clearSkillCheckConnections()
    for _, conn in pairs(skillCheckConnections) do
        safeDisconnect(conn)
    end
    skillCheckConnections = {}
end

local function DestroyAllSkillChecks()
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not Remotes then return end
    
    for _, folderName in pairs({"Healing", "Generator"}) do
        local folder = Remotes:FindFirstChild(folderName)
        if folder then
            local skillCheck = folder:FindFirstChild("SkillCheckEvent")
            if skillCheck then
                pcall(function() skillCheck:Destroy() end)
            end
        end
    end
end

local function StartSkillCheck()
    if isSkillCheckActive then return end
    isSkillCheckActive = true
    DestroyAllSkillChecks()
    
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        for _, folderName in pairs({"Healing", "Generator"}) do
            local folder = remotes:FindFirstChild(folderName)
            if folder then
                local conn = folder.ChildAdded:Connect(function(child)
                    if child.Name == "SkillCheckEvent" and isSkillCheckActive then
                        pcall(function() child:Destroy() end)
                    end
                end)
                table.insert(skillCheckConnections, conn)
            end
        end
    end
end

local function StopSkillCheck()
    if not isSkillCheckActive then return end
    isSkillCheckActive = false
    clearSkillCheckConnections()
end

-- ==================== AIMBOT ====================
local aimbotEnabled = false
local currentTarget = nil
local maxLockDistance = 35
local SMOOTHNESS = 0.85
local aimbotConnections = {}
local uiConnections = {}
local aimbotButton = nil
local strokeAimbot = nil
local aimbotScreenGui = nil
local lastTargetUpdate = 0
local aimbotRenderConn = nil
local aimbotCamera = workspace.CurrentCamera

local function cleanUIEventsAimbot()
    for _, conn in pairs(uiConnections) do
        pcall(function() conn:Disconnect() end)
    end
    uiConnections = {}
end

local function cleanAllEventsAimbot()
    for _, conn in pairs(aimbotConnections) do
        pcall(function() conn:Disconnect() end)
    end
    aimbotConnections = {}
    
    cleanUIEventsAimbot()
    
    if aimbotRenderConn then
        pcall(function() aimbotRenderConn:Disconnect() end)
        aimbotRenderConn = nil
    end
end

local function lockMouse()
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end)
end

local function unlockMouse()
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

local function getClosestTargetAimbot()
    if not aimbotCamera then return nil end
    local closest = nil
    local shortestDist = math.huge
    local center = aimbotCamera.ViewportSize / 2
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if root and hum and hum.Health > 0 then
                    local dist3D = (myRoot.Position - root.Position).Magnitude
                    if dist3D <= maxLockDistance then
                        local screenPoint, onScreen = aimbotCamera:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local screenDist = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                            if screenDist < shortestDist then
                                closest = p
                                shortestDist = screenDist
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function UpdateButtonUIAimbot()
    if not aimbotButton then return end
    pcall(function()
        if aimbotEnabled then
            aimbotButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            aimbotButton.BackgroundTransparency = 0.3
            if strokeAimbot then strokeAimbot.Color = Color3.fromRGB(100, 255, 100) end
        else
            aimbotButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            aimbotButton.BackgroundTransparency = 0.15
            if strokeAimbot then strokeAimbot.Color = Color3.fromRGB(255, 100, 100) end
        end
    end)
end

local function CreateAimbotGUI()
    cleanUIEventsAimbot()
    
    local existingGui = CoreGui:FindFirstChild("SimpleAimbot")
    if existingGui then
        pcall(function() existingGui:Destroy() end)
    end
    
    aimbotScreenGui = Instance.new("ScreenGui")
    aimbotScreenGui.Name = "SimpleAimbot"
    aimbotScreenGui.Parent = CoreGui

    aimbotButton = Instance.new("ImageButton")
    aimbotButton.Size = UDim2.new(0, 50, 0, 50)
    aimbotButton.Position = UDim2.new(1, -210, 1, -420)
    aimbotButton.AnchorPoint = Vector2.new(1, 1)
    aimbotButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    aimbotButton.BackgroundTransparency = 0.15
    aimbotButton.Image = "rbxassetid://3926305904"
    aimbotButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
    aimbotButton.ImageTransparency = 0.2
    aimbotButton.Parent = aimbotScreenGui

    local cornerAimbot = Instance.new("UICorner", aimbotButton)
    cornerAimbot.CornerRadius = UDim.new(1, 0)
    
    strokeAimbot = Instance.new("UIStroke", aimbotButton)
    strokeAimbot.Color = Color3.fromRGB(255, 100, 100)
    strokeAimbot.Thickness = 2
    strokeAimbot.Transparency = 0.5

    local draggingBtn = false
    local dragStartBtn = nil
    local startPosBtn = nil

    local beganConn = aimbotButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingBtn = true
            dragStartBtn = input.Position
            startPosBtn = aimbotButton.Position
        end
    end)
    table.insert(uiConnections, beganConn)

    local endedConn = aimbotButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingBtn = false
        end
    end)
    table.insert(uiConnections, endedConn)

    local changedConn = aimbotButton.InputChanged:Connect(function(input)
        if draggingBtn and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartBtn
            aimbotButton.Position = UDim2.new(
                startPosBtn.X.Scale, 
                startPosBtn.X.Offset + delta.X,
                startPosBtn.Y.Scale,
                startPosBtn.Y.Offset + delta.Y
            )
        end
    end)
    table.insert(uiConnections, changedConn)

    local clickConn = aimbotButton.MouseButton1Click:Connect(function()
        if draggingBtn then
            draggingBtn = false
            return
        end
        
        aimbotEnabled = not aimbotEnabled
        if aimbotEnabled then
            lockMouse()
            currentTarget = getClosestTargetAimbot()
        else
            unlockMouse()
            currentTarget = nil
        end
        UpdateButtonUIAimbot()
    end)
    table.insert(uiConnections, clickConn)
end

local function setupRenderSteppedAimbot()
    if aimbotRenderConn then
        pcall(function() aimbotRenderConn:Disconnect() end)
        aimbotRenderConn = nil
    end
    
    aimbotRenderConn = RunService.RenderStepped:Connect(function()
        if not aimbotEnabled then return end
        if not aimbotCamera then return end
        
        local now = tick()
        if now - lastTargetUpdate >= 0.1 then
            lastTargetUpdate = now
            if not currentTarget then
                currentTarget = getClosestTargetAimbot()
            elseif currentTarget and (not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart")) then
                currentTarget = getClosestTargetAimbot()
            end
        end
        
        if currentTarget and currentTarget.Character then
            local root = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local lookAt = CFrame.new(aimbotCamera.CFrame.Position, root.Position)
                aimbotCamera.CFrame = aimbotCamera.CFrame:Lerp(lookAt, SMOOTHNESS)
            else
                currentTarget = nil
            end
        else
            currentTarget = nil
        end
    end)
    table.insert(aimbotConnections, aimbotRenderConn)
end

local function setupCameraHandlerAimbot()
    local cameraConn = workspace.Changed:Connect(function()
        if workspace.CurrentCamera then
            aimbotCamera = workspace.CurrentCamera
        end
    end)
    table.insert(aimbotConnections, cameraConn)
end

local function StartAimbot()
    if aimbotEnabled then return end
    
    if aimbotScreenGui then
        pcall(function() aimbotScreenGui:Destroy() end)
        aimbotScreenGui = nil
    end
    cleanAllEventsAimbot()
    
    aimbotEnabled = true
    aimbotCamera = workspace.CurrentCamera
    CreateAimbotGUI()
    setupRenderSteppedAimbot()
    setupCameraHandlerAimbot()
    if aimbotScreenGui then
        aimbotScreenGui.Enabled = true
    end
end

local function StopAimbot()
    if aimbotEnabled then
        aimbotEnabled = false
        unlockMouse()
        currentTarget = nil
    end
    
    if aimbotScreenGui then
        pcall(function() aimbotScreenGui:Destroy() end)
        aimbotScreenGui = nil
    end
    
    aimbotButton = nil
    strokeAimbot = nil
    cleanAllEventsAimbot()
end

-- ==================== HITBOX (TOGGLE ONLY, NO SLIDER) ====================
local hitboxActive = false
local HITBOX_Size = 35
local OriginalHitboxSizes = {}
local hitboxConnections = {}
local hitboxPlayerConns = {}

local function safeDisconnectHitbox(conn)
    pcall(function() if conn then conn:Disconnect() end end)
end

local function clearAllHitboxPlayerConns()
    for player, conn in pairs(hitboxPlayerConns) do
        safeDisconnectHitbox(conn)
    end
    hitboxPlayerConns = {}
end

local function clearHitboxConnections()
    for _, conn in pairs(hitboxConnections) do
        safeDisconnectHitbox(conn)
    end
    hitboxConnections = {}
    clearAllHitboxPlayerConns()
end

local function ResetHitbox(player)
    if not player then return end
    local orig = OriginalHitboxSizes[player]
    if player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            pcall(function()
                if orig then root.Size = orig end
                root.CanCollide = true
            end)
        end
    end
    OriginalHitboxSizes[player] = nil
end

local function ResetAllHitboxes()
    for p, origSize in pairs(OriginalHitboxSizes) do
        if p and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(function()
                    root.Size = origSize
                    root.CanCollide = true
                end)
            end
        end
    end
    OriginalHitboxSizes = {}
end

local function ExpandHitbox(player)
    if not hitboxActive then return end
    if not player or player == LocalPlayer then return end
    
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        ResetHitbox(player)
        return
    end
    
    if not OriginalHitboxSizes[player] then
        OriginalHitboxSizes[player] = root.Size
        pcall(function()
            root.Size = Vector3.new(HITBOX_Size, HITBOX_Size, HITBOX_Size)
            root.CanCollide = false
        end)
    end
end

local function UpdateAllHitboxes()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            ExpandHitbox(p)
        end
    end
end

local function BindHitboxPlayerEvents(player)
    if player == LocalPlayer then return end
    
    if hitboxPlayerConns[player] then
        safeDisconnectHitbox(hitboxPlayerConns[player])
        hitboxPlayerConns[player] = nil
    end
    
    local conn = player.CharacterAdded:Connect(function()
        task.wait(0.3)
        if hitboxActive then
            ExpandHitbox(player)
        end
    end)
    hitboxPlayerConns[player] = conn
    table.insert(hitboxConnections, conn)
end

local function BindAllExistingHitboxPlayers()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            ExpandHitbox(p)
            BindHitboxPlayerEvents(p)
            task.wait(0.05)
        end
    end
end

local function StartHitbox()
    if hitboxActive then return end
    hitboxActive = true
    hitboxConnections = {}
    hitboxPlayerConns = {}
    
    local renderConn = RunService.RenderStepped:Connect(function()
        if not hitboxActive then return end
        UpdateAllHitboxes()
    end)
    table.insert(hitboxConnections, renderConn)
    
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        if hitboxActive then
            BindHitboxPlayerEvents(player)
        end
    end)
    table.insert(hitboxConnections, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        ResetHitbox(player)
        if hitboxPlayerConns[player] then
            safeDisconnectHitbox(hitboxPlayerConns[player])
            hitboxPlayerConns[player] = nil
        end
    end)
    table.insert(hitboxConnections, playerRemovingConn)
    
    BindAllExistingHitboxPlayers()
end

local function StopHitbox()
    hitboxActive = false
    ResetAllHitboxes()
    clearHitboxConnections()
end

-- ==================== WALKSPEED ====================
local walkSpeedActive = false
local targetSpeed = 50
local walkSpeedConn = nil

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("Humanoid")
end

local function applySpeed()
    if not walkSpeedActive then return end
    local hum = getHumanoid()
    if hum and hum.WalkSpeed ~= targetSpeed then
        pcall(function()
            hum.WalkSpeed = targetSpeed
        end)
    end
end

local function enableWalkSpeed()
    if walkSpeedActive then return end
    walkSpeedActive = true
    applySpeed()
    
    if not walkSpeedConn then
        walkSpeedConn = RunService.Heartbeat:Connect(function()
            applySpeed()
        end)
    end
end

local function disableWalkSpeed()
    if not walkSpeedActive then return end
    walkSpeedActive = false
    
    if walkSpeedConn then
        walkSpeedConn:Disconnect()
        walkSpeedConn = nil
    end
    
    local hum = getHumanoid()
    if hum then
        pcall(function()
            hum.WalkSpeed = 16
        end)
    end
end

local function updateWalkSpeed(speed)
    targetSpeed = speed
    if walkSpeedActive then
        applySpeed()
    end
end

local function onCharacterAddedWalkSpeed()
    task.wait(0.3)
    if walkSpeedActive then
        applySpeed()
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAddedWalkSpeed)

-- ==================== NOCLIP ====================
local noClipActive = false
local noClipChar = nil
local noClipRootPart = nil

local function getNoClipCharacter()
    noClipChar = LocalPlayer.Character
    if not noClipChar then return false end
    noClipRootPart = noClipChar:FindFirstChild("HumanoidRootPart")
    return (noClipRootPart ~= nil)
end

local function enableNoClip()
    if noClipActive then return end
    if not getNoClipCharacter() then return end
    
    noClipActive = true
    
    pcall(function()
        noClipRootPart.CanCollide = false
        for _, part in pairs(noClipChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoClip()
    if not noClipActive then return end
    if not getNoClipCharacter() then return end
    
    noClipActive = false
    
    pcall(function()
        noClipRootPart.CanCollide = true
        for _, part in pairs(noClipChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end)
end

local function onCharacterAddedNoClip(newChar)
    noClipChar = newChar
    task.wait(0.3)
    getNoClipCharacter()
    if noClipActive then
        enableNoClip()
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAddedNoClip)
getNoClipCharacter()

-- ==================== FRAME UTAMA ====================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 450)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 50, 100)
stroke.Thickness = 2
stroke.Transparency = 0.5
stroke.Parent = mainFrame

-- ==================== HEADER ====================
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, 0, 0, 45)
headerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
headerFrame.BackgroundTransparency = 0.3
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = headerFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "👑Violence District V.2.0 [VIP]👑"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 10, 0, 0)
title.Parent = headerFrame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Position = UDim2.new(0, 10, 0, 24)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Dev:IngVzz"
subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = headerFrame

-- Drag frame
local draggingFrame = false
local dragFrameStart = nil
local frameStartPos = nil

headerFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = true
        dragFrameStart = input.Position
        frameStartPos = mainFrame.Position
    end
end)

headerFrame.InputEnded:Connect(function()
    draggingFrame = false
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFrame and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragFrameStart
        mainFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
    end
end)

-- ==================== TAB MENU KIRI ====================
local leftMenu = Instance.new("Frame")
leftMenu.Size = UDim2.new(0, 100, 1, -45)
leftMenu.Position = UDim2.new(0, 0, 0, 45)
leftMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
leftMenu.BackgroundTransparency = 0.5
leftMenu.BorderSizePixel = 0
leftMenu.Parent = mainFrame

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 0)
menuCorner.Parent = leftMenu

-- Daftar tab (TANPA CREDIT)
local tabs = {"SURVIVOR", "KILLER", "MODS", "INFO"}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Position = UDim2.new(0, 0, 0, (i-1) * 38)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.BackgroundTransparency = 0.3
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = leftMenu
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 0)
    btnCorner.Parent = btn
    
    tabButtons[tabName] = btn
end

-- ==================== KONTEN KANAN ====================
local rightContent = Instance.new("Frame")
rightContent.Size = UDim2.new(1, -110, 1, -45)
rightContent.Position = UDim2.new(0, 110, 0, 45)
rightContent.BackgroundTransparency = 1
rightContent.Parent = mainFrame

-- Helper functions
local function createToggle(parent, yPos, text, defaultValue, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 32)
    toggleFrame.Position = UDim2.new(0, 10, 0, yPos)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 45, 0, 22)
    toggleBtn.Position = UDim2.new(1, -55, 0.5, -11)
    toggleBtn.BackgroundColor3 = defaultValue and Color3.fromRGB(255, 50, 100) or Color3.fromRGB(60, 60, 70)
    toggleBtn.Text = defaultValue and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 10
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = toggleFrame
    
    local toggleCornerBtn = Instance.new("UICorner")
    toggleCornerBtn.CornerRadius = UDim.new(1, 0)
    toggleCornerBtn.Parent = toggleBtn
    
    local state = defaultValue
    
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            toggleBtn.Text = "ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)  -- HIJAU
            label.TextColor3 = Color3.fromRGB(100, 255, 100)  -- HIJAU
        else
            toggleBtn.Text = "OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        if callback then callback(state) end
    end)
    
    return toggleBtn
end

local function createSlider(parent, yPos, text, minVal, maxVal, defaultValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 45)
    sliderFrame.Position = UDim2.new(0, 10, 0, yPos)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. defaultValue
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -60, 0, 3)
    sliderBg.Position = UDim2.new(0, 0, 0, 22)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = sliderFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 2)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    local percent = (defaultValue - minVal) / (maxVal - minVal)
    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 50, 100)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 14, 0, 14)
    sliderButton.Position = UDim2.new(percent, -7, 0, -5.5)
    sliderButton.BackgroundColor3 = Color3.fromRGB(255, 50, 100)
    sliderButton.Text = ""
    sliderButton.BorderSizePixel = 0
    sliderButton.AutoButtonColor = false
    sliderButton.Parent = sliderBg
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = sliderButton
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 45, 0, 20)
    valueLabel.Position = UDim2.new(1, -50, 0, 15)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(255, 50, 100)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    local currentValue = defaultValue
    local dragActive = false
    
    local function updateSlider(input)
        local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        sliderButton.Position = UDim2.new(relativeX, -7, 0, -5.5)
        local value = minVal + (relativeX * (maxVal - minVal))
        currentValue = math.floor(value + 0.5)
        valueLabel.Text = tostring(currentValue)
        label.Text = text .. ": " .. currentValue
        if callback then callback(currentValue) end
    end
    
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragActive = true
            updateSlider(input)
        end
    end)
    
    sliderButton.InputChanged:Connect(function(input)
        if dragActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    sliderButton.InputEnded:Connect(function()
        dragActive = false
    end)
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
        end
    end)
    
    return sliderButton
end

local function switchContent(tab)
    for _, child in pairs(rightContent:GetChildren()) do
        child:Destroy()
    end
    
    if tab == "SURVIVOR" then
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -20, 0, 35)
        header.Position = UDim2.new(0, 10, 0, 10)
        header.BackgroundTransparency = 1
        header.Text = "SURVIVOR MODS"
        header.TextColor3 = Color3.fromRGB(255, 50, 100)
        header.Font = Enum.Font.GothamBold
        header.TextSize = 14
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = rightContent
        
        createToggle(rightContent, 55, "DISABLE SKILLCHECK", _G.ToggleStates.DisableSkillCheck, function(state)
            _G.ToggleStates.DisableSkillCheck = state
            if state then StartSkillCheck() else StopSkillCheck() end
        end)
        
        createToggle(rightContent, 95, "ESP PLAYER", _G.ToggleStates.ESP_Player, function(state)
            _G.ToggleStates.ESP_Player = state
            if state then enableESP() else disableESP() end
        end)
        
        createToggle(rightContent, 135, "MOONWALK", _G.ToggleStates.Moonwalk, function(state)
            _G.ToggleStates.Moonwalk = state
            if state then StartMoonwalkSystem() else StopMoonwalkSystem() end
        end)
        
        createToggle(rightContent, 175, "CROUSHAIR", _G.ToggleStates.Croushair, function(state)
            _G.ToggleStates.Croushair = state
            if state then StartCroushair() else StopCroushair() end
        end)
        
        createToggle(rightContent, 215, "BYPASS ZOOM", _G.ToggleStates.BypassZoom, function(state)
            _G.ToggleStates.BypassZoom = state
            if state then StartZoom() else StopZoom() end
        end)
        
    elseif tab == "KILLER" then
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -20, 0, 35)
        header.Position = UDim2.new(0, 10, 0, 10)
        header.BackgroundTransparency = 1
        header.Text = "KILLER MODS"
        header.TextColor3 = Color3.fromRGB(255, 50, 100)
        header.Font = Enum.Font.GothamBold
        header.TextSize = 14
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = rightContent
        
        createToggle(rightContent, 55, "AIMBOT", _G.ToggleStates.Aimbot, function(state)
            _G.ToggleStates.Aimbot = state
            if state then StartAimbot() else StopAimbot() end
        end)
        
        createToggle(rightContent, 95, "HITBOX", _G.ToggleStates.Hitbox, function(state)
            _G.ToggleStates.Hitbox = state
            if state then StartHitbox() else StopHitbox() end
        end)
        
    elseif tab == "MODS" then
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -20, 0, 35)
        header.Position = UDim2.new(0, 10, 0, 10)
        header.BackgroundTransparency = 1
        header.Text = "MODS"
        header.TextColor3 = Color3.fromRGB(255, 50, 100)
        header.Font = Enum.Font.GothamBold
        header.TextSize = 14
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = rightContent
        
        createToggle(rightContent, 55, "WALKSPEED", _G.ToggleStates.Walkspeed, function(state)
            _G.ToggleStates.Walkspeed = state
            if state then enableWalkSpeed() else disableWalkSpeed() end
        end)
        
        createSlider(rightContent, 100, "WALKSPEED VALUE", 16, 100, _G.ToggleStates.WalkspeedValue, function(value)
            _G.ToggleStates.WalkspeedValue = value
            updateWalkSpeed(value)
        end)
        
        createToggle(rightContent, 155, "NOCLIP", _G.ToggleStates.Noclip, function(state)
            _G.ToggleStates.Noclip = state
            if state then enableNoClip() else disableNoClip() end
        end)
        
    elseif tab == "INFO" then
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -20, 0, 35)
        header.Position = UDim2.new(0, 10, 0, 10)
        header.BackgroundTransparency = 1
        header.Text = "INFORMATION"
        header.TextColor3 = Color3.fromRGB(255, 50, 100)
        header.Font = Enum.Font.GothamBold
        header.TextSize = 14
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = rightContent
        
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -20, 0, 160)
        info.Position = UDim2.new(0, 10, 0, 55)
        info.BackgroundTransparency = 1
        info.Text = "BITWISE HUB V.2.0 [VIP]\nCREATED BY: DYVILLE XZ\nNODE-X | DELTA LITE\n\n✅ FITUR AKTIF:\n\n🛡️ SURVIVOR:\n• Disable Skillcheck\n• ESP Player (Killer: Merah, Survivor: Biru)\n• Moonwalk (Tekan tombol R di pojok kanan bawah)\n• Croushair (Crosshair putih di tengah layar)\n• Bypass Zoom (Scroll mouse untuk zoom bebas)\n\n🔪 KILLER:\n• Aimbot (Tekan tombol aimbot di pojok kanan bawah)\n• Hitbox (Perbesar hitbox survivor ukuran 35 studs)\n\n⭐ MODS:\n• WalkSpeed (Atur kecepatan jalan 16-100)\n• NoClip (Tembus dinding)"
        info.TextColor3 = Color3.fromRGB(150, 150, 150)
        info.Font = Enum.Font.Gotham
        info.TextSize = 11
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.Parent = rightContent
    end
end

for tabName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for _, b in pairs(tabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            b.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        btn.BackgroundColor3 = Color3.fromRGB(255, 50, 100)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        switchContent(tabName)
    end)
end

tabButtons["SURVIVOR"].BackgroundColor3 = Color3.fromRGB(255, 50, 100)
tabButtons["SURVIVOR"].TextColor3 = Color3.fromRGB(255, 255, 255)
switchContent("SURVIVOR")

-- ==================== OPEN/CLOSE FRAME ====================
local guiVisible = false

toggleButton.MouseButton1Click:Connect(function()
    if isDragging then
        return
    end
    
    guiVisible = not guiVisible
    mainFrame.Visible = guiVisible
    
    if guiVisible then
        toggleButton.Text = "✕"
        toggleButton.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
    else
        toggleButton.Text = "▶"
        toggleButton.BackgroundColor3 = Color3.fromRGB(30, 144, 255)
    end
end)