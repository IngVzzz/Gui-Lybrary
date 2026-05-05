local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/IngVzzz/Gui-Lybrary/refs/heads/main/Lybrary%20Sendiri%20test"))()

local window = Library:Init("VIOLENCE DISTRICT [VIP]", "Depeloper-X | IngVzz")

-- ==================== GLOBAL VARIABLES ====================
_G.DisableSkillCheck = false
_G.ESP_Player = false
_G.Moonwalk = false
_G.Croushair = false
_G.BypassZoom = false
_G.Aimbot = false
_G.Hitbox = false
_G.Walkspeed = false
_G.WalkspeedValue = 50
_G.Noclip = false
_G.Fullbright = false

-- ==================== DISABLE SKILLCHECK SCRIPT ====================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local isSkillCheckActive = false
local skillCheckConnections = {}

local function clearSkillCheckConnections()
    for _, conn in pairs(skillCheckConnections) do
        pcall(function() conn:Disconnect() end)
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

-- ==================== ESP PLAYER SCRIPT ====================
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

-- ==================== MOONWALK SCRIPT ====================
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

-- ==================== CROUSHAIR SCRIPT ====================
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
    dot.Position = UDim2.new(0.5, 0, 0.51, 0)
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

-- ==================== BYPASS ZOOM SCRIPT ====================
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

-- ==================== AIMBOT SCRIPT (FIXED) ====================
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
    aimbotButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 80, 80)
    aimbotButton.BackgroundTransparency = aimbotEnabled and 0.3 or 0.15
    aimbotButton.Image = "rbxassetid://3926305904"
    aimbotButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
    aimbotButton.ImageTransparency = 0.2
    aimbotButton.Parent = aimbotScreenGui

    local cornerAimbot = Instance.new("UICorner", aimbotButton)
    cornerAimbot.CornerRadius = UDim.new(1, 0)
    
    strokeAimbot = Instance.new("UIStroke", aimbotButton)
    strokeAimbot.Color = aimbotEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
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
        
        -- Update global variable biar sinkron
        _G.Aimbot = aimbotEnabled
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
    
    -- JANGAN nyalain aimbotEnabled dulu
    aimbotEnabled = false  -- <-- INI PENTING: DEFAULT OFF
    aimbotCamera = workspace.CurrentCamera
    CreateAimbotGUI()  -- GUI dibuat dengan status OFF (merah)
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

-- ==================== HITBOX SCRIPT ====================
local hitboxActive = false
local HITBOX_Size = 30
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

-- ==================== WALKSPEED SCRIPT ====================
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

-- ==================== NOCLIP SCRIPT ====================
local noClipActive = false
local noClipChar = nil

local function updateNoclip()
    noClipChar = LocalPlayer.Character
    if not noClipChar then return end
    
    if noClipActive then
        for _, part in ipairs(noClipChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    else
        for _, part in ipairs(noClipChar:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

local function enableNoClip()
    if noClipActive then return end
    noClipActive = true
    updateNoclip()
end

local function disableNoClip()
    if not noClipActive then return end
    noClipActive = false
    updateNoclip()
end

local function onCharacterAddedNoClip()
    task.wait(0.3)
    updateNoclip()
end

LocalPlayer.CharacterAdded:Connect(onCharacterAddedNoClip)

-- ==================== FULLBRIGHT SCRIPT ====================
local isFullbrightActive = false
local originalBrightness = Lighting.Brightness
local originalTimeOfDay = Lighting.TimeOfDay
local originalClockTime = Lighting.ClockTime
local originalAmbient = Lighting.Ambient
local originalFogEnd = Lighting.FogEnd
local originalGlobalShadows = Lighting.GlobalShadows

local function enableFullbright()
    if isFullbrightActive then return end
    isFullbrightActive = true
    
    if originalBrightness == Lighting.Brightness then
        originalBrightness = Lighting.Brightness
        originalTimeOfDay = Lighting.TimeOfDay
        originalClockTime = Lighting.ClockTime
        originalAmbient = Lighting.Ambient
        originalFogEnd = Lighting.FogEnd
        originalGlobalShadows = Lighting.GlobalShadows
    end
    
    Lighting.Brightness = 2
    Lighting.TimeOfDay = "12:00:00"
    Lighting.ClockTime = 12
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
end

local function disableFullbright()
    if not isFullbrightActive then return end
    isFullbrightActive = false
    
    Lighting.Brightness = originalBrightness
    Lighting.TimeOfDay = originalTimeOfDay
    Lighting.ClockTime = originalClockTime
    Lighting.Ambient = originalAmbient
    Lighting.FogEnd = originalFogEnd
    Lighting.GlobalShadows = originalGlobalShadows
end

-- ==================== CHARACTER ADDED HANDLER ====================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    if isEspActive then enableESP() end
    if walkSpeedActive then applySpeed() end
    if noClipActive then updateNoclip() end
end)

-- ==================== TAB SURVIVOR ====================
local survivorTab = window:CreateTab("SURVIVOR")
survivorTab:AddDivider("SURVIVOR MODS")

survivorTab:AddToggle("⚡ DISABLE SKILLCHECK", false, function(v)
    _G.DisableSkillCheck = v
    if v then StartSkillCheck() else StopSkillCheck() end
end)

survivorTab:AddToggle("👁️ ESP PLAYER", false, function(v)
    _G.ESP_Player = v
    if v then enableESP() else disableESP() end
end)

survivorTab:AddToggle("🌙 MOONWALK", false, function(v)
    _G.Moonwalk = v
    if v then StartMoonwalkSystem() else StopMoonwalkSystem() end
end)

survivorTab:AddToggle("🎯 CROUSHAIR", false, function(v)
    _G.Croushair = v
    if v then StartCroushair() else StopCroushair() end
end)

survivorTab:AddToggle("🔍 BYPASS ZOOM", false, function(v)
    _G.BypassZoom = v
    if v then StartZoom() else StopZoom() end
end)

-- ==================== TAB KILLER ====================
local killerTab = window:CreateTab("KILLER")
killerTab:AddDivider("KILLER MODS")

killerTab:AddToggle("🎯 AIMBOT", false, function(v)
    _G.Aimbot = v
    if v then StartAimbot() else StopAimbot() end
end)

killerTab:AddToggle("📦 HITBOX", false, function(v)
    _G.Hitbox = v
    if v then StartHitbox() else StopHitbox() end
end)

-- ==================== TAB MODS ====================
local modsTab = window:CreateTab("MODS")
modsTab:AddDivider("MODS")

modsTab:AddToggle("🏃 WALKSPEED", false, function(v)
    _G.Walkspeed = v
    if v then enableWalkSpeed() else disableWalkSpeed() end
end)

modsTab:AddSlider("🏃 WALKSPEED VALUE", 16, 100, 50, function(v)
    _G.WalkspeedValue = v
    updateWalkSpeed(v)
end)

modsTab:AddToggle("🌀 NOCLIP", false, function(v)
    _G.Noclip = v
    if v then enableNoClip() else disableNoClip() end
end)

-- ==================== TAB MISC ====================
local miscTab = window:CreateTab("MISC")
miscTab:AddDivider("MISC MODS")

miscTab:AddToggle("☀️ FULLBRIGHT", false, function(v)
    _G.Fullbright = v
    if v then enableFullbright() else disableFullbright() end
end)

-- ==================== TAB INFO ====================
local infoTab = window:CreateTab("INFO")
infoTab:AddDivider("INFORMATION")
infoTab:AddLabel("VIOLENCE DISTRICT [VIP]")
infoTab:AddLabel("CREATED BY: INGVZZ")
infoTab:AddLabel("DEVELOPER-X | INGVZZ")
infoTab:AddLabel("")
infoTab:AddLabel("✅ FITUR AKTIF:")
infoTab:AddLabel("🛡️ SURVIVOR: Skillcheck, ESP, Moonwalk, Croushair, Bypass Zoom")
infoTab:AddLabel("🔪 KILLER: Aimbot, Hitbox")
infoTab:AddLabel("🛠️ MODS: WalkSpeed + Slider, NoClip")
infoTab:AddLabel("🎲 MISC: Fullbright")
infoTab:AddLabel("")
infoTab:AddLabel("ALL FEATURES ARE FOR EDUCATIONAL")
infoTab:AddLabel("PURPOSES ONLY.")

window:Start()
