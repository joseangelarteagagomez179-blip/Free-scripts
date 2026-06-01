--[[
    Script para "Kick a Lucky Block" - by JoseAngel_Blox
    Funciona con cualquier ejecutor (Synapse, Krnl, etc.)
    Coloca este script en un LocalScript dentro de StarterGui o ejecútalo directamente.
]]

-- Cargar servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

-- Variables de estado
local autoKickEnabled = false
local autoWeightEnabled = false
local autoClickX2Enabled = false
local autoFarmEnabled = false
local autoCollectEnabled = false
local flyEnabled = false
local invisibleEnabled = false
local godModeEnabled = false
local fpsVisible = false

local flySpeed = 50
local walkSpeed = 16
local farmSpeed = 50
local farmDistance = 10
local autoKickInterval = 0.5
local autoClickX2Interval = 0.25

-- Conexiones de loops
local autoKickCoroutine = nil
local autoWeightCoroutine = nil
local autoClickX2Coroutine = nil
local autoFarmCoroutine = nil
local autoCollectCoroutine = nil
local flyCoroutine = nil
local godCoroutine = nil
local fpsCoroutine = nil

-- Funciones de utilidad
local function findRemote(nameHint)
    -- Busca un RemoteEvent que contenga el nombre sugerido
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local function search(container)
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("RemoteEvent") and string.find(string.lower(obj.Name), nameHint:lower()) then
                return obj
            end
            if obj:IsA("Folder") or obj:IsA("Model") then
                local result = search(obj)
                if result then return result end
            end
        end
    end
    return search(replicatedStorage) or search(game:GetService("Workspace"))
end

local kickRemote = findRemote("kick") or findRemote("hit") or findRemote("main") -- Ajusta según el juego
local moneyRemote = findRemote("collect") or findRemote("money") -- Para recoger dinero

-- Simular un clic (si no hay remote)
local function simulateClick()
    local mouse = player:GetMouse()
    if mouse then
        mouse1click()
    end
end

-- Función para hacer kick
local function doKick()
    if kickRemote then
        kickRemote:FireServer()
    else
        simulateClick()
    end
end

-- Auto Kick
local function autoKickLoop()
    while autoKickEnabled do
        doKick()
        task.wait(autoKickInterval)
    end
end

-- Auto Weight (equipar pesa)
local function autoWeightLoop()
    while autoWeightEnabled do
        if not char then break end
        local tool = player.Backpack:FindFirstChild("Pesa") or player.Backpack:FindFirstChild("Weight") or player.Backpack:FindFirstChild("Peso")
        if tool and not char:FindFirstChild(tool.Name) then
            hum:EquipTool(tool)
        end
        task.wait(1)
    end
end

-- Auto Click x2
local function autoClickX2Loop()
    while autoClickX2Enabled do
        doKick()
        task.wait(autoClickX2Interval)
    end
end

-- Auto Farm (patear y regresar automáticamente)
local function autoFarmLoop()
    local startPos = char and char:GetPivot().Position
    if not startPos then return end
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.WalkSpeed = farmSpeed
    while autoFarmEnabled and char and humanoid.Health > 0 do
        -- Avanzar
        local forwardDir = char:GetPivot().LookVector * Vector3.new(1,0,1)
        local targetPos = char:GetPivot().Position + forwardDir.Unit * farmDistance
        humanoid:MoveTo(targetPos)
        humanoid.MoveToFinished:Wait()
        doKick()
        task.wait(0.2)
        -- Regresar
        humanoid:MoveTo(startPos)
        humanoid.MoveToFinished:Wait()
        task.wait(0.1)
    end
end

-- Auto Collect Money
local function autoCollectLoop()
    while autoCollectEnabled do
        if not char or not hum or hum.Health <= 0 then task.wait(1) continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then task.wait(1) continue end
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and (string.find(string.lower(part.Name), "coin") or
                string.find(string.lower(part.Name), "money") or
                string.find(string.lower(part.Name), "cash") or
                string.find(string.lower(part.Name), "bill")) then
                if (root.Position - part.Position).Magnitude < 50 then
                    if moneyRemote then
                        moneyRemote:FireServer(part)
                    else
                        firetouchinterest(root, part, 0)
                        firetouchinterest(root, part, 1)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- Fly
local function flyLoop()
    local bg = Instance.new("BodyGyro")
    local bv = Instance.new("BodyVelocity")
    bg.P = 9e4
    bg.Parent = char:WaitForChild("HumanoidRootPart")
    bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
    bv.Velocity = Vector3.new()
    bv.Parent = char.HumanoidRootPart
    hum.PlatformStand = true
    while flyEnabled and char and char.HumanoidRootPart do
        local moveDirection = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection += workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection -= workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection -= workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection += workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection += Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection -= Vector3.new(0, 1, 0)
        end
        bv.Velocity = moveDirection * flySpeed
        task.wait()
    end
    bg:Destroy()
    bv:Destroy()
    hum.PlatformStand = false
end

-- Invisible
local function setInvisible(state)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = state and 1 or 0
        end
    end
end

-- God Mode
local function godLoop()
    while godModeEnabled and char and hum do
        if hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
        task.wait(0.1)
    end
end

-- FPS
local function fpsLoop(label)
    local frameCount = 0
    local lastTime = tick()
    while fpsVisible do
        frameCount += 1
        if tick() - lastTime >= 1 then
            local fps = frameCount
            frameCount = 0
            lastTime = tick()
            label.Text = "FPS: " .. fps
        end
        RunService.RenderStepped:Wait()
    end
    label.Text = ""
end

-- Optimización
local function applyOptimization()
    -- Reducir calidad gráfica
    if Lighting then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e5
        Lighting.Brightness = 1
    end
    if workspace:FindFirstChild("Terrain") then
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 0
    end
    settings().Rendering.QualityLevel = 1
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Material == Enum.Material.Neon then
            part.Material = Enum.Material.SmoothPlastic
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part:Destroy()
        end
    end
end

-- Construcción del GUI
local gui = Instance.new("ScreenGui")
gui.Name = "JoseAngel_BloxHub"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Marco principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

-- Título con nombre del creador
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.Text = "JoseAngel_Blox Script | v1.0"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextScaled = true
title.Parent = mainFrame

-- Botones de pestañas
local tabs = {}
local tabButtons = {}
local function createTab(name, positionX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 30)
    btn.Position = UDim2.new(positionX, 0, 0, 40)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = mainFrame
    table.insert(tabButtons, btn)
    return btn
end

local mainTab = createTab("Main", 0)
local playerTab = createTab("Player", 0.333)
local configTab = createTab("Config", 0.666)

-- Contenedor de páginas
local pages = {}
local function createPage(visible)
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, -10, 1, -80)
    page.Position = UDim2.new(0, 5, 0, 75)
    page.BackgroundTransparency = 1
    page.Visible = visible
    page.Parent = mainFrame
    return page
end

local mainPage = createPage(true)
local playerPage = createPage(false)
local configPage = createPage(false)

-- Función para cambiar pestaña
local function switchTab(tab)
    for i, btn in ipairs(tabButtons) do
        btn.BackgroundColor3 = btn == tab and Color3.fromRGB(100,100,100) or Color3.fromRGB(70,70,70)
    end
    mainPage.Visible = tab == mainTab
    playerPage.Visible = tab == playerTab
    configPage.Visible = tab == configTab
end

mainTab.MouseButton1Click:Connect(function() switchTab(mainTab) end)
playerTab.MouseButton1Click:Connect(function() switchTab(playerTab) end)
configTab.MouseButton1Click:Connect(function() switchTab(configTab) end)

-- Utilidades para crear elementos
local function createToggle(parent, text, posY, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.Position = UDim2.new(0, 5, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 20, 0, 20)
    button.Position = UDim2.new(0, 0, 0, 5)
    button.Text = ""
    button.BackgroundColor3 = Color3.fromRGB(200,50,50)
    button.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Parent = frame

    local toggled = false
    button.MouseButton1Click:Connect(function()
        toggled = not toggled
        button.BackgroundColor3 = toggled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
        callback(toggled)
    end)
    return frame
end

local function createSlider(parent, text, posY, minVal, maxVal, default, callback)
    -- Simplificado: usamos un TextBox para ingresar valor
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.Position = UDim2.new(0, 5, 0, posY)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ":"
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -130, 0, 25)
    box.Position = UDim2.new(0, 130, 0, 10)
    box.Text = tostring(default)
    box.BackgroundColor3 = Color3.fromRGB(50,50,50)
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.Parent = frame

    local apply = Instance.new("TextButton")
    apply.Size = UDim2.new(0, 50, 0, 25)
    apply.Position = UDim2.new(1, -60, 0, 10)
    apply.Text = "Set"
    apply.BackgroundColor3 = Color3.fromRGB(100,100,100)
    apply.TextColor3 = Color3.fromRGB(255,255,255)
    apply.Parent = frame

    apply.MouseButton1Click:Connect(function()
        local num = tonumber(box.Text)
        if num and num >= minVal and num <= maxVal then
            callback(num)
        end
    end)
    return frame
end

-- Pestaña Main
createToggle(mainPage, "Auto Kick (ON/OFF)", 10, function(state)
    autoKickEnabled = state
    if state then
        autoKickCoroutine = task.spawn(autoKickLoop)
    else
        autoKickCoroutine = nil
    end
end)
createToggle(mainPage, "Auto Weight (equipar pesa)", 50, function(state)
    autoWeightEnabled = state
    if state then
        autoWeightCoroutine = task.spawn(autoWeightLoop)
    else
        autoWeightCoroutine = nil
    end
end)
createToggle(mainPage, "Auto Click x2", 90, function(state)
    autoClickX2Enabled = state
    if state then
        autoClickX2Coroutine = task.spawn(autoClickX2Loop)
    else
        autoClickX2Coroutine = nil
    end
end)
createToggle(mainPage, "Auto Farm (patear/regresar)", 130, function(state)
    autoFarmEnabled = state
    if state then
        if not char then return end
        autoFarmCoroutine = task.spawn(autoFarmLoop)
    else
        autoFarmCoroutine = nil
        if char and hum then hum.WalkSpeed = 16 end
    end
end)
createSlider(mainPage, "Farm Walkspeed", 170, 16, 500, 50, function(val)
    farmSpeed = val
    if autoFarmEnabled and hum then hum.WalkSpeed = val end
end)
createSlider(mainPage, "Farm Distance", 210, 5, 100, 10, function(val)
    farmDistance = val
end)
createToggle(mainPage, "Auto Collect Money", 250, function(state)
    autoCollectEnabled = state
    if state then
        autoCollectCoroutine = task.spawn(autoCollectLoop)
    else
        autoCollectCoroutine = nil
    end
end)

-- Pestaña Player
createToggle(playerPage, "Fly (Volar)", 10, function(state)
    flyEnabled = state
    if state then
        flyCoroutine = task.spawn(flyLoop)
    else
        flyCoroutine = nil
    end
end)
createSlider(playerPage, "Fly Speed", 50, 20, 500, 50, function(val)
    flySpeed = val
end)
createSlider(playerPage, "WalkSpeed", 90, 16, 500, 16, function(val)
    walkSpeed = val
    if hum then hum.WalkSpeed = val end
end)
createToggle(playerPage, "Invisible (Local)", 130, function(state)
    invisibleEnabled = state
    setInvisible(state)
end)
createToggle(playerPage, "God Mode (Inmortal)", 170, function(state)
    godModeEnabled = state
    if state then
        godCoroutine = task.spawn(godLoop)
    else
        godCoroutine = nil
    end
end)

-- Pestaña Config
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, -10, 0, 30)
fpsLabel.Position = UDim2.new(0, 5, 0, 10)
fpsLabel.BackgroundColor3 = Color3.fromRGB(40,40,40)
fpsLabel.TextColor3 = Color3.fromRGB(255,255,255)
fpsLabel.Text = ""
fpsLabel.Parent = configPage

createToggle(configPage, "Mostrar FPS", 50, function(state)
    fpsVisible = state
    if state then
        fpsCoroutine = task.spawn(fpsLoop, fpsLabel)
    else
        fpsCoroutine = nil
    end
end)

local optimizeBtn = Instance.new("TextButton")
optimizeBtn.Size = UDim2.new(1, -10, 0, 40)
optimizeBtn.Position = UDim2.new(0, 5, 0, 100)
optimizeBtn.Text = "Aplicar Optimización"
optimizeBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
optimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
optimizeBtn.Parent = configPage
optimizeBtn.MouseButton1Click:Connect(applyOptimization)

-- Mantener las referencias del personaje actualizadas
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hum = newChar:WaitForChild("Humanoid")
    if invisibleEnabled then setInvisible(true) end
    if godModeEnabled then
        godCoroutine = task.spawn(godLoop)
    end
end)

-- Crédito extra en consola
print("Script de JoseAngel_Blox cargado correctamente!")
