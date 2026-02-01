local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser") -- Used for Anti-AFK

local player = Players.LocalPlayer

-------------------------------------------------------------------------
-- 1. DATA CONFIGURATION
-------------------------------------------------------------------------
local GameData = {
    {
        MapName = "Pirate Island",
        Mobs = {"Cobe", "Bogge", "Roby Lucy", "Kome", "Gerp"}
    },
    {
        MapName = "Nameko City",
        Mobs = {"Gurldo", "Borter", "Giniu", "Recorme", "Freeza"}
    },
    {
        MapName = "Demon Village",
        Mobs = {"Roi", "Gyutoru", "Acaza", "Touma", "Muzon"}
    },
    {
        MapName = "Ninja Village",
        Mobs = {"Sabusa", "Obeto", "Zasuke", "Tachi", "Pani"}
    }
}

-- CONFIGURATION
local MOVEMENT_SPEED = 200 
local ATTACK_DISTANCE = 6 
local STUCK_TIMEOUT = 1 

-- STATE
local isFarming = false 
local currentMapIndex = 1 
local targetName = nil 
local currentTarget = nil
local nextTarget = nil
local targetStartTime = 0
local deadBodies = {} 
local scriptRunning = true 

-------------------------------------------------------------------------
-- 2. UI SETUP
-------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local HeaderFrame = Instance.new("Frame") 
local TitleLabel = Instance.new("TextLabel")
local CloseBtn = Instance.new("TextButton")
local MinBtn = Instance.new("TextButton")
local OpenBtn = Instance.new("TextButton") 
local ConfirmFrame = Instance.new("Frame") 
local ConfirmText = Instance.new("TextLabel")
local YesBtn = Instance.new("TextButton")
local NoBtn = Instance.new("TextButton")

local MapControlFrame = Instance.new("Frame")
local MapNameLabel = Instance.new("TextLabel")
local PrevMapBtn = Instance.new("TextButton")
local NextMapBtn = Instance.new("TextButton")
local MobListFrame = Instance.new("ScrollingFrame")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

pcall(function() ScreenGui.Parent = CoreGui end) 
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

ScreenGui.Name = "AnimeEnergyUI"
ScreenGui.ResetOnSpawn = false

-- --- MAIN FRAME ---
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.Position = UDim2.new(0.5, -110, 0.3, 0) 
MainFrame.Size = UDim2.new(0, 220, 0, 350)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- --- HEADER ---
HeaderFrame.Parent = MainFrame
HeaderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
HeaderFrame.Size = UDim2.new(1, 0, 0, 30)
HeaderFrame.BorderSizePixel = 0
Instance.new("UICorner", HeaderFrame).CornerRadius = UDim.new(0, 10)

local HeaderFix = Instance.new("Frame")
HeaderFix.Parent = HeaderFrame
HeaderFix.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BorderSizePixel = 0

TitleLabel.Parent = HeaderFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "ANIME ENERGY"
TitleLabel.TextColor3 = Color3.fromRGB(255, 170, 0) 
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

CloseBtn.Parent = HeaderFrame
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Font = Enum.Font.GothamBold

MinBtn.Parent = HeaderFrame
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.BackgroundTransparency = 1
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Position = UDim2.new(1, -60, 0, 0)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20

-- --- OPEN BUTTON ---
OpenBtn.Parent = ScreenGui
OpenBtn.Visible = false
OpenBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
OpenBtn.Size = UDim2.new(0, 120, 0, 40)
OpenBtn.Position = UDim2.new(0, 20, 0.9, -20)
OpenBtn.Text = "OPEN MENU"
OpenBtn.TextColor3 = Color3.fromRGB(255, 170, 0)
OpenBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 8)

-- --- CONFIRMATION ---
ConfirmFrame.Parent = MainFrame
ConfirmFrame.Visible = false
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ConfirmFrame.Size = UDim2.new(1, 0, 1, 0) 
ConfirmFrame.ZIndex = 10
Instance.new("UICorner", ConfirmFrame).CornerRadius = UDim.new(0, 10)

ConfirmText.Parent = ConfirmFrame
ConfirmText.Text = "Kill Script?"
ConfirmText.TextColor3 = Color3.new(1,1,1)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Size = UDim2.new(1, 0, 0.4, 0)
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.TextSize = 18
ConfirmText.ZIndex = 11

YesBtn.Parent = ConfirmFrame
YesBtn.Text = "YES"
YesBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
YesBtn.TextColor3 = Color3.new(1,1,1)
YesBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
YesBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
YesBtn.Font = Enum.Font.GothamBold
YesBtn.ZIndex = 11
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 6)

NoBtn.Parent = ConfirmFrame
NoBtn.Text = "NO"
NoBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
NoBtn.TextColor3 = Color3.new(1,1,1)
NoBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
NoBtn.Position = UDim2.new(0.55, 0, 0.5, 0)
NoBtn.Font = Enum.Font.GothamBold
NoBtn.ZIndex = 11
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 6)

-- --- MAP CONTROLS ---
MapControlFrame.Parent = MainFrame
MapControlFrame.BackgroundTransparency = 1
MapControlFrame.Position = UDim2.new(0, 0, 0.12, 0)
MapControlFrame.Size = UDim2.new(1, 0, 0, 30)

PrevMapBtn.Parent = MapControlFrame
PrevMapBtn.Text = "<"
PrevMapBtn.Size = UDim2.new(0, 25, 1, 0)
PrevMapBtn.Position = UDim2.new(0, 10, 0, 0)
PrevMapBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PrevMapBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", PrevMapBtn).CornerRadius = UDim.new(0,5)

NextMapBtn.Parent = MapControlFrame
NextMapBtn.Text = ">"
NextMapBtn.Size = UDim2.new(0, 25, 1, 0)
NextMapBtn.Position = UDim2.new(1, -35, 0, 0)
NextMapBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
NextMapBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", NextMapBtn).CornerRadius = UDim.new(0,5)

MapNameLabel.Parent = MapControlFrame
MapNameLabel.Text = GameData[currentMapIndex].MapName
MapNameLabel.Size = UDim2.new(1, -80, 1, 0)
MapNameLabel.Position = UDim2.new(0, 40, 0, 0)
MapNameLabel.BackgroundTransparency = 1
MapNameLabel.TextColor3 = Color3.fromRGB(255, 200, 50) 
MapNameLabel.Font = Enum.Font.GothamBold
MapNameLabel.TextSize = 14
MapNameLabel.TextScaled = true 

-- --- MOB LIST ---
MobListFrame.Parent = MainFrame
MobListFrame.BackgroundTransparency = 1
MobListFrame.Position = UDim2.new(0, 10, 0.24, 0)
MobListFrame.Size = UDim2.new(1, -20, 0.58, 0)
MobListFrame.CanvasSize = UDim2.new(0, 0, 0, 0) 
MobListFrame.ScrollBarThickness = 3
MobListFrame.BorderSizePixel = 0

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = MobListFrame
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- --- START BUTTON ---
ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60) 
ToggleButton.Position = UDim2.new(0, 10, 0.86, 0) 
ToggleButton.Size = UDim2.new(1, -20, 0.11, 0)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "START FARMING"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 16
UICorner.Parent = ToggleButton
UICorner.CornerRadius = UDim.new(0, 6)


-------------------------------------------------------------------------
-- 3. UTILITIES (Anti-AFK & Drag)
-------------------------------------------------------------------------
-- ANTI-AFK: Prevents disconnection
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

-- Drag Logic
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X, 
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

HeaderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

HeaderFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)


-------------------------------------------------------------------------
-- 4. BUTTON LOGIC (Close, Min, Maps)
-------------------------------------------------------------------------
CloseBtn.MouseButton1Click:Connect(function() ConfirmFrame.Visible = true end)
NoBtn.MouseButton1Click:Connect(function() ConfirmFrame.Visible = false end)

YesBtn.MouseButton1Click:Connect(function()
    isFarming = false
    scriptRunning = false
    ScreenGui:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

local mobButtons = {}

function refreshMobList()
    for _, btn in pairs(mobButtons) do btn:Destroy() end
    mobButtons = {}
    
    local data = GameData[currentMapIndex]
    MapNameLabel.Text = data.MapName
    
    for i, mobName in ipairs(data.Mobs) do
        local btn = Instance.new("TextButton")
        btn.Parent = MobListFrame
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.new(0.8,0.8,0.8)
        btn.Text = mobName
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            targetName = mobName
            for _, b in pairs(mobButtons) do 
                b.BackgroundColor3 = Color3.fromRGB(50, 50, 50) 
                b.TextColor3 = Color3.new(0.8,0.8,0.8)
            end
            btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0) 
            btn.TextColor3 = Color3.new(0,0,0)
        end)
        
        table.insert(mobButtons, btn)
    end
    MobListFrame.CanvasSize = UDim2.new(0, 0, 0, #data.Mobs * 35)
end

PrevMapBtn.MouseButton1Click:Connect(function()
    currentMapIndex = currentMapIndex - 1
    if currentMapIndex < 1 then currentMapIndex = #GameData end
    refreshMobList()
end)

NextMapBtn.MouseButton1Click:Connect(function()
    currentMapIndex = currentMapIndex + 1
    if currentMapIndex > #GameData then currentMapIndex = 1 end
    refreshMobList()
end)

refreshMobList()

-------------------------------------------------------------------------
-- 5. FARM LOGIC
-------------------------------------------------------------------------
function isMobValid(model)
    if not model or not model.Parent then return false end
    if deadBodies[model] then return false end
    
    local human = model:FindFirstChild("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    
    if not human or not root then return false end
    if human.Health <= 0 then return false end
    if root.Position.Magnitude < 50 then return false end
    
    return true
end

function findNext(excludedMob)
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetName then return nil end 

    local closest = nil
    local shortestDist = math.huge

    for _, child in pairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child ~= excludedMob and string.find(child.Name, targetName) then
            if isMobValid(child) then
                local dist = (myRoot.Position - child.HumanoidRootPart.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = child
                end
            end
        end
    end
    return closest
end

RunService.Heartbeat:Connect(function(deltaTime)
    if not scriptRunning then return end 
    if not isFarming then return end
    if not targetName then return end 
    
    local character = player.Character
    if not character then return end
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    if currentTarget then
        if (tick() - targetStartTime) > STUCK_TIMEOUT then
            deadBodies[currentTarget] = true 
            currentTarget = nil
        elseif not isMobValid(currentTarget) then
            deadBodies[currentTarget] = true 
            currentTarget = nil
        end
    end

    if not currentTarget then
        if nextTarget and isMobValid(nextTarget) then
            currentTarget = nextTarget
            nextTarget = nil 
            targetStartTime = tick()
        else
            currentTarget = findNext(nil)
            if currentTarget then targetStartTime = tick() end
        end
    end

    if currentTarget and not nextTarget then
        task.spawn(function()
            nextTarget = findNext(currentTarget)
        end)
    end
    
    local moveTarget = currentTarget or nextTarget 
    if moveTarget then
        local targetRoot = moveTarget:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local currentPos = myRoot.Position
            local targetPos = targetRoot.Position
            local lookAtCFrame = CFrame.lookAt(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
            
            local dist = (targetPos - currentPos).Magnitude
            if dist > ATTACK_DISTANCE then
                local alpha = (MOVEMENT_SPEED * deltaTime) / dist
                if alpha > 1 then alpha = 1 end
                local newPos = currentPos:Lerp(targetPos, alpha)
                myRoot.CFrame = CFrame.new(newPos) * lookAtCFrame.Rotation
            else
                myRoot.CFrame = CFrame.new(currentPos) * lookAtCFrame.Rotation
            end
        end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

task.spawn(function()
    while scriptRunning do
        task.wait(2)
        if isFarming then deadBodies = {} end
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    if not targetName then
        ToggleButton.Text = "SELECT MOB FIRST!"
        task.wait(1)
        ToggleButton.Text = "START FARMING"
        return
    end

    isFarming = not isFarming 
    
    if isFarming then
        ToggleButton.Text = "STOP FARMING"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 255, 60) 
        deadBodies = {}
        currentTarget = nil
        nextTarget = nil
    else
        ToggleButton.Text = "START FARMING"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60) 
        currentTarget = nil
        nextTarget = nil
    end
end)
