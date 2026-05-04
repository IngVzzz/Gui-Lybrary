udah gua modifikasi+ganti raw Lybrary
local DrRayLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IngVzzz/Gui-Lybrary/refs/heads/main/DrayLybrary"))()

local Window = DrRayLibrary:Load("😈VIOLENCE DISTRICT [VIP]😈", "rbxassetid://13047715178")

-- ==================== GLOBAL VARIABLES ====================
_G.DisableSkillCheck = false
_G.ESP_Player = false
_G.Moonwalk = false
_G.Croushair = false
_G.BypassZoom = false
_G.Aimbot = false
_G.Hitbox = false
_G.Noclip = false

-- ==================== DISABLE SKILLCHECK ====================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local isSkillCheckActive = false
local skillCheckConnections = {}

local function clearSkillCheckConnections()
    for _, conn in pairs(skillCheckConnections) do pcall(function() conn:Disconnect() end) end
    skillCheckConnections = {}
end

local function DestroyAllSkillChecks()
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not Remotes then return end
    for _, folderName in pairs({"Healing", "Generator"}) do
        local folder = Remotes:FindFirstChild(folderName)
        if folder then
            local skillCheck = folder:FindFirstChild("SkillCheckEvent")
            if skillCheck then pcall(function() skillCheck:Destroy() end) end
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
                    if child.Name == "SkillCheckEvent" and isSkillCheckActive then pcall(function() child:Destroy() end) end
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

-- ==================== ESP PLAYER ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local isEspActive = false
local espConnections = {}

local function RemoveHighlight(char)
    if not char then return end
    local h = char:FindFirstChild("ESP_Highlight")
    if h then h:Destroy() end
end

local function ApplyHighlight(char, color)
    if not char or not color then return end
    local existing = char:FindFirstChild("ESP_Highlight")
    if existing then existing:Destroy() end
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
    if not isEspActive or player == LocalPlayer or not player.Character or not player.Team then return end
    local teamName = player.Team.Name
    local color = teamName == "Killer" and Color3.fromRGB(255, 0, 0) or (teamName == "Survivors" and Color3.fromRGB(0, 255, 255))
    if color then ApplyHighlight(player.Character, color) else RemoveHighlight(player.Character) end
end

local function enableESP()
    if isEspActive then return end
    isEspActive = true
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        task.wait(0.2)
        if isEspActive then UpdateSinglePlayer(player) end
    end)
    table.insert(espConnections, playerAddedConn)
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        if player.Character then RemoveHighlight(player.Character) end
    end)
    table.insert(espConnections, playerRemovingConn)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then UpdateSinglePlayer(p) end
    end
end

local function disableESP()
    if not isEspActive then return end
    isEspActive = false
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then RemoveHighlight(p.Character) end
    end
    for _, conn in pairs(espConnections) do
        pcall(function() conn:Disconnect() end)
    end
    espConnections = {}
end

-- ==================== MOONWALK ====================
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local moonwalkActive = false
local moonwalkChar, moonwalkHumanoid, moonwalkRootPart = nil, nil, nil
local moonwalkTurningLeft, moonwalkTurningRight = false, false
local moonwalkBaseYaw, moonwalkCurrentYaw = 0, 0
local moonwalkMaxTurn, moonwalkTurnSpeed, moonwalkReturnSpeed = 40, 850, 800
local moonwalkGui, moonwalkButton = nil, nil
local moonwalkConnections, moonwalkButtonConnections = {}, {}

local function updateMoonwalkRefs(newChar)
    moonwalkChar = newChar or LocalPlayer.Character
    if not moonwalkChar then return false end
    moonwalkHumanoid = moonwalkChar:FindFirstChild("Humanoid")
    moonwalkRootPart = moonwalkChar:FindFirstChild("HumanoidRootPart")
    return (moonwalkHumanoid and moonwalkRootPart)
end

local function getYaw(cf) local _, y, _ = cf:ToEulerAnglesYXZ() return math.deg(y) end
local function setYaw(cf, yaw) return CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(yaw), 0) end

local function clearMoonwalkButtonEvents()
    for _, conn in pairs(moonwalkButtonConnections) do pcall(function() conn:Disconnect() end) end
    moonwalkButtonConnections = {}
end

local function enableMoonwalk()
    if not updateMoonwalkRefs() or moonwalkActive then return end
    moonwalkActive = true
    moonwalkHumanoid.AutoRotate = false
    moonwalkBaseYaw = getYaw(moonwalkRootPart.CFrame)
    moonwalkCurrentYaw = moonwalkBaseYaw
    if moonwalkButton then pcall(function() moonwalkButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255) end) end
end

local function disableMoonwalk()
    if not moonwalkActive then return end
    moonwalkActive = false
    if moonwalkHumanoid then moonwalkHumanoid.AutoRotate = true end
    if moonwalkButton then pcall(function() moonwalkButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end) end
    moonwalkTurningLeft, moonwalkTurningRight = false, false
end

local function destroyMoonwalkGUI()
    if moonwalkGui then pcall(function() moonwalkGui:Destroy() end) moonwalkGui, moonwalkButton = nil, nil end
end

local function createMoonwalkGUI()
    if moonwalkGui then destroyMoonwalkGUI() end
    clearMoonwalkButtonEvents()
    moonwalkGui = Instance.new("ScreenGui")
    moonwalkGui.Name = "MoonwalkController"
    moonwalkGui.IgnoreGuiInset = true
    moonwalkGui.ResetOnSpawn = false
    moonwalkGui.Parent = CoreGui
    moonwalkButton = Instance.new("TextButton")
    moonwalkButton.Size = UDim2.new(0, 45, 0, 45)
    moonwalkButton.Position = UDim2.new(1, -50, 1, -110)
    moonwalkButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    moonwalkButton.Text = "R"
    moonwalkButton.TextColor3 = Color3.new(1, 1, 1)
    moonwalkButton.TextScaled = true
    moonwalkButton.BorderSizePixel = 0
    moonwalkButton.Parent = moonwalkGui
    table.insert(moonwalkButtonConnections, moonwalkButton.MouseButton1Down:Connect(enableMoonwalk))
    table.insert(moonwalkButtonConnections, moonwalkButton.MouseButton1Up:Connect(disableMoonwalk))
    table.insert(moonwalkButtonConnections, moonwalkButton.TouchBegan:Connect(enableMoonwalk))
    table.insert(moonwalkButtonConnections, moonwalkButton.TouchEnded:Connect(disableMoonwalk))
end

local function StartMoonwalk()
    if moonwalkActive then return end
    for _, conn in ipairs(moonwalkConnections) do pcall(function() conn:Disconnect() end) end
    moonwalkConnections = {}
    table.insert(moonwalkConnections, UIS.TouchMoved:Connect(function(input)
        if not moonwalkActive then return end
        if math.abs(input.Delta.X) > 3 then
            if input.Delta.X > 0 then moonwalkTurningRight, moonwalkTurningLeft = true, false else moonwalkTurningLeft, moonwalkTurningRight = true, false end
        end
    end))
    table.insert(moonwalkConnections, UIS.TouchEnded:Connect(function() moonwalkTurningLeft, moonwalkTurningRight = false, false end))
    table.insert(moonwalkConnections, RunService.RenderStepped:Connect(function(dt)
        if not moonwalkActive or not updateMoonwalkRefs() or not moonwalkRootPart then return end
        if moonwalkTurningLeft then
            moonwalkCurrentYaw = math.clamp(moonwalkCurrentYaw - moonwalkTurnSpeed * dt, moonwalkBaseYaw - moonwalkMaxTurn, moonwalkBaseYaw + moonwalkMaxTurn)
        elseif moonwalkTurningRight then
            moonwalkCurrentYaw = math.clamp(moonwalkCurrentYaw + moonwalkTurnSpeed * dt, moonwalkBaseYaw - moonwalkMaxTurn, moonwalkBaseYaw + moonwalkMaxTurn)
        else
            if moonwalkCurrentYaw < moonwalkBaseYaw then
                moonwalkCurrentYaw = math.min(moonwalkCurrentYaw + moonwalkReturnSpeed * dt, moonwalkBaseYaw)
            elseif moonwalkCurrentYaw > moonwalkBaseYaw then
                moonwalkCurrentYaw = math.max(moonwalkCurrentYaw - moonwalkReturnSpeed * dt, moonwalkBaseYaw)
            end
        end
        if moonwalkRootPart and moonwalkRootPart.Parent then moonwalkRootPart.CFrame = setYaw(CFrame.new(moonwalkRootPart.CFrame.Position), moonwalkCurrentYaw) end
    end))
    table.insert(moonwalkConnections, LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.2)
        updateMoonwalkRefs(newChar)
        if moonwalkActive then
            disableMoonwalk()
            task.wait(0.1)
            enableMoonwalk()
        end
    end))
    updateMoonwalkRefs()
    createMoonwalkGUI()
end

local function StopMoonwalk()
    destroyMoonwalkGUI()
    if moonwalkActive then disableMoonwalk() end
    for _, conn in ipairs(moonwalkConnections) do pcall(function() conn:Disconnect() end) end
    moonwalkConnections = {}
end

-- ==================== CROUSHAIR ====================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local crosshairGui = nil

local function CreateCroushair()
    if crosshairGui then return end
    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "CustomCrosshair"
    crosshairGui.ResetOnSpawn = false
    crosshairGui.IgnoreGuiInset = true
    crosshairGui.Parent = playerGui
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 5, 0, 5)
    dot.Position = UDim2.new(0.49, 0, 0.53, 0)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = crosshairGui
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)
end

local function RemoveCroushair()
    if crosshairGui then crosshairGui:Destroy() crosshairGui = nil end
end

-- ==================== BYPASS ZOOM ====================
local UserInputService = game:GetService("UserInputService")
local zoomActive = false
local zoomLevel = 50
local zoomSpeed = 3
local DEFAULT_FOV = 70
local zoomRenderConn, zoomInputConn, zoomMaxConn = nil, nil, nil
local CameraZoom = workspace.CurrentCamera

local function disableZoom()
    if not zoomActive then return end
    zoomActive = false
    if CameraZoom then pcall(function() CameraZoom.FieldOfView = DEFAULT_FOV end) end
    pcall(function() LocalPlayer.CameraMaxZoomDistance = 40 LocalPlayer.CameraMinZoomDistance = 1 end)
    if zoomRenderConn then zoomRenderConn:Disconnect() zoomRenderConn = nil end
    if zoomInputConn then zoomInputConn:Disconnect() zoomInputConn = nil end
    if zoomMaxConn then zoomMaxConn:Disconnect() zoomMaxConn = nil end
end

local function enableZoom()
    if zoomActive then return end
    if workspace and workspace.CurrentCamera then CameraZoom = workspace.CurrentCamera end
    if not CameraZoom then return end
    zoomActive = true
    zoomLevel = CameraZoom.FieldOfView
    DEFAULT_FOV = CameraZoom.FieldOfView
    pcall(function() LocalPlayer.CameraMaxZoomDistance = 50 LocalPlayer.CameraMinZoomDistance = 8 end)
    zoomMaxConn = LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
        if zoomActive and LocalPlayer.CameraMaxZoomDistance < 50 then pcall(function() LocalPlayer.CameraMaxZoomDistance = 50 end) end
    end)
    zoomInputConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not zoomActive or not CameraZoom or input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
        zoomLevel = math.clamp(zoomLevel - (input.Position.Z * zoomSpeed), 20, 120)
        pcall(function() CameraZoom.FieldOfView = zoomLevel end)
    end)
    zoomRenderConn = RunService.RenderStepped:Connect(function()
        if not zoomActive or not CameraZoom then return end
        pcall(function()
            if CameraZoom.FieldOfView ~= zoomLevel then CameraZoom.FieldOfView = zoomLevel end
            if LocalPlayer.CameraMaxZoomDistance ~= 50 then LocalPlayer.CameraMaxZoomDistance = 50 end
        end)
    end)
end

-- ==================== AIMBOT ====================
local aimbotEnabled = false
local currentTarget = nil
local maxLockDistance = 35
local SMOOTHNESS = 0.85
local aimbotConnections = {}
local aimbotUI = {}
local aimbotButton = nil
local aimbotScreenGui = nil
local lastTargetUpdate = 0
local aimbotRenderConn = nil
local aimbotCamera = workspace.CurrentCamera

local function cleanAimbotUI()
    for _, conn in pairs(aimbotUI) do pcall(function() conn:Disconnect() end) end
    aimbotUI = {}
end

local function cleanAimbotEvents()
    for _, conn in pairs(aimbotConnections) do pcall(function() conn:Disconnect() end) end
    aimbotConnections = {}
    cleanAimbotUI()
    if aimbotRenderConn then pcall(function() aimbotRenderConn:Disconnect() end) aimbotRenderConn = nil end
end

local function lockMouse() pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter UserInputService.MouseIconEnabled = false end) end
local function unlockMouse() pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default UserInputService.MouseIconEnabled = true end) end

local function getClosestTarget()
    if not aimbotCamera then return nil end
    local closest, shortestDist = nil, math.huge
    local center = aimbotCamera.ViewportSize / 2
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if root and hum and hum.Health > 0 and (myRoot.Position - root.Position).Magnitude <= maxLockDistance then
                    local screenPoint, onScreen = aimbotCamera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                        if screenDist < shortestDist then closest, shortestDist = p, screenDist end
                    end
                end
            end
        end
    end
    return closest
end

local function UpdateAimbotButtonUI()
    if not aimbotButton then return end
    pcall(function()
        aimbotButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 80, 80)
        aimbotButton.BackgroundTransparency = aimbotEnabled and 0.3 or 0.15
    end)
end

local function CreateAimbotGUI()
    cleanAimbotUI()
    local existing = CoreGui:FindFirstChild("SimpleAimbot")
    if existing then existing:Destroy() end
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
    Instance.new("UICorner", aimbotButton).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", aimbotButton)
    stroke.Color = Color3.fromRGB(255, 100, 100)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    local dragging, dragStart, startPos = false, nil, nil
    table.insert(aimbotUI, aimbotButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging, dragStart, startPos = true, input.Position, aimbotButton.Position end
    end))
    table.insert(aimbotUI, aimbotButton.InputEnded:Connect(function() dragging = false end))
    table.insert(aimbotUI, aimbotButton.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            aimbotButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    table.insert(aimbotUI, aimbotButton.MouseButton1Click:Connect(function()
        if dragging then dragging = false return end
        aimbotEnabled = not aimbotEnabled
        if aimbotEnabled then lockMouse() currentTarget = getClosestTarget() else unlockMouse() currentTarget = nil end
        UpdateAimbotButtonUI()
    end))
end

local function StartAimbot()
    if aimbotEnabled then return end
    if aimbotScreenGui then aimbotScreenGui:Destroy() end
    cleanAimbotEvents()
    aimbotEnabled = true
    aimbotCamera = workspace.CurrentCamera
    CreateAimbotGUI()
    aimbotRenderConn = RunService.RenderStepped:Connect(function()
        if not aimbotEnabled or not aimbotCamera then return end
        local now = tick()
        if now - lastTargetUpdate >= 0.1 then
            lastTargetUpdate = now
            if not currentTarget then currentTarget = getClosestTarget()
            elseif currentTarget and (not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart")) then currentTarget = getClosestTarget() end
        end
        if currentTarget and currentTarget.Character then
            local root = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local lookAt = CFrame.new(aimbotCamera.CFrame.Position, root.Position)
                aimbotCamera.CFrame = aimbotCamera.CFrame:Lerp(lookAt, SMOOTHNESS)
            else currentTarget = nil end
        else currentTarget = nil end
    end)
    table.insert(aimbotConnections, aimbotRenderConn)
    local cameraConn = workspace.Changed:Connect(function()
        if workspace.CurrentCamera then aimbotCamera = workspace.CurrentCamera end
    end)
    table.insert(aimbotConnections, cameraConn)
end

local function StopAimbot()
    if aimbotEnabled then
        aimbotEnabled = false
        unlockMouse()
        currentTarget = nil
    end
    if aimbotScreenGui then pcall(function() aimbotScreenGui:Destroy() end) aimbotScreenGui = nil end
    aimbotButton = nil
    cleanAimbotEvents()
end

-- ==================== HITBOX (NO SLIDER) ====================
local HITBOX_Size = 35
local OriginalHitboxSizes = {}
local isHitboxActive = false
local hitboxConnections = {}

local function clearHitboxConnections()
    for _, conn in pairs(hitboxConnections) do pcall(function() conn:Disconnect() end) end
    hitboxConnections = {}
end

local function ResetHitbox(player)
    if not player then return end
    local orig = OriginalHitboxSizes[player]
    if orig and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then pcall(function() root.Size = orig root.CanCollide = true end) end
    end
    OriginalHitboxSizes[player] = nil
end

local function ResetAllHitboxes()
    for p, origSize in pairs(OriginalHitboxSizes) do
        if p and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then pcall(function() root.Size = origSize root.CanCollide = true end) end
        end
    end
    OriginalHitboxSizes = {}
end

local function ExpandHitbox(player)
    if not isHitboxActive then return end
    if not player or player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then ResetHitbox(player) return end
    if not OriginalHitboxSizes[player] then
        OriginalHitboxSizes[player] = root.Size
        pcall(function() root.Size = Vector3.new(HITBOX_Size, HITBOX_Size, HITBOX_Size) root.CanCollide = false end)
    end
end

local function UpdateAllHitboxes()
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ExpandHitbox(p) end end
end

local function StartHitbox()
    if isHitboxActive then return end
    isHitboxActive = true
    local renderConn = RunService.RenderStepped:Connect(function()
        if not isHitboxActive then return end
        UpdateAllHitboxes()
    end)
    table.insert(hitboxConnections, renderConn)
    local playerAddedConn = Players.PlayerAdded:Connect(ExpandHitbox)
    table.insert(hitboxConnections, playerAddedConn)
    local playerRemovingConn = Players.PlayerRemoving:Connect(ResetHitbox)
    table.insert(hitboxConnections, playerRemovingConn)
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then ExpandHitbox(p) end end
end

local function StopHitbox()
    if not isHitboxActive then return end
    isHitboxActive = false
    ResetAllHitboxes()
    clearHitboxConnections()
end

-- ==================== NOCLIP ====================
local noClipActive = false
local noClipChar, noClipRootPart = nil, nil

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
            if part:IsA("BasePart") then part.CanCollide = false end
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
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end)
end

local function onCharacterAddedNC(newChar)
    noClipChar = newChar
    task.wait(0.3)
    getNoClipCharacter()
    if noClipActive then enableNoClip() end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAddedNC)
getNoClipCharacter()

-- ==================== SURVIVOR TAB ====================
local SurvivorTab = DrRayLibrary.newTab("SURVIVOR", "rbxassetid://3926305904")

SurvivorTab.newToggle("DISABLE SKILLCHECK", "Mematikan skillcheck survivor", false, function(state)
    _G.DisableSkillCheck = state
    if state then StartSkillCheck() else StopSkillCheck() end
end)

SurvivorTab.newToggle("ESP PLAYER", "Melihat highlight player (Killer Merah, Survivor Biru)", false, function(state)
    _G.ESP_Player = state
    if state then enableESP() else disableESP() end
end)

SurvivorTab.newToggle("MOONWALK", "Moonwalk + kontrol geser layar (Tekan R di pojok)", false, function(state)
    _G.Moonwalk = state
    if state then StartMoonwalk() else StopMoonwalk() end
end)

SurvivorTab.newToggle("CROUSHAIR", "Crosshair titik putih di tengah layar", false, function(state)
    _G.Croushair = state
    if state then CreateCroushair() else RemoveCroushair() end
end)

SurvivorTab.newToggle("BYPASS ZOOM", "Zoom bebas pakai scroll mouse", false, function(state)
    _G.BypassZoom = state
    if state then enableZoom() else disableZoom() end
end)

-- ==================== KILLER TAB ====================
local KillerTab = DrRayLibrary.newTab("KILLER", "rbxassetid://3926305904")

KillerTab.newToggle("AIMBOT", "Auto aim ke target terdekat (Tekan tombol aimbot di pojok)", false, function(state)
    _G.Aimbot = state
    if state then StartAimbot() else StopAimbot() end
end)

KillerTab.newToggle("HITBOX", "Memperbesar hitbox survivor (ukuran 30 studs)", false, function(state)
    _G.Hitbox = state
    if state then StartHitbox() else StopHitbox() end
end)

-- ==================== MODS TAB ====================
local ModsTab = DrRayLibrary.newTab("MODS", "rbxassetid://3926305904")

ModsTab.newToggle("NOCLIP", "Tembus dinding", false, function(state)
    _G.Noclip = state
    if state then enableNoClip() else disableNoClip() end
end)

-- ==================== INFO TAB ====================
local InfoTab = DrRayLibrary.newTab("INFO", "rbxassetid://3926305904")
InfoTab.newLabel("👑 VIOLENCE DISTRICT [VIP] 👑")
InfoTab.newLabel("🔥 CREATED BY: IngVzz")
InfoTab.newLabel("😍🔥 BANTU SUPPORT 🔥😍")