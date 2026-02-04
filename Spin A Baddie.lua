local PlaceId = 79305036070450
if game.PlaceId ~= PlaceId then
    warn("You are not in 'Spin a Baddie' (ID: " .. PlaceId .. "). Script might not work!")
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local TweenService = game:GetService("TweenService") 
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

-- 1. Create Folder
if not isfolder("ArchemaraHub") then makefolder("ArchemaraHub") end

-- 2. Global Table for Save System
local Elements = {}

local Window = Rayfield:CreateWindow({
    Name = "Spin a Baddie Script",
    LoadingTitle = "Archemara Hub",
    LoadingSubtitle = "Shop Clearer Edition",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false, Invite = "", RememberJoins = true },
    KeySystem = false
})

-- ==========================================
--  ORGANIZED TABS (NO ICONS)
-- ==========================================
local FarmingTab = Window:CreateTab("💸 Farming", nil)
local DiceTab    = Window:CreateTab("🎲 Dice Manager", nil)
local RewardsTab = Window:CreateTab("🎁 Rewards", nil)
local SettingsTab= Window:CreateTab("⚙️ Settings", nil)

-- Variables
local AutoBuyEnabled = false
local AutoSelectEnabled = false 
local AutoWalkSlotsEnabled = false
local AutoTweenSlotsEnabled = false
local AutoEquipBaddiesEnabled = false
local HideNotificationsEnabled = false 
local ShowSlotESP = false 
local CurrentSpeed = 50 
local HoverHeight = 3 
local MyLockedPlot = nil 
local NoclipConnection = nil 

-- Default List
local TargetSlotsString = "1, 3, 5, 7, 9, 11, 2, 4, 6, 8, 10, 12, 13, 15, 17, 19, 21, 23, 14, 16, 18, 20, 22, 24" 

-- Priority List
local DiceRankings = {
    ["Basic"] = 1, ["Silver"] = 2, ["Golden"] = 3, 
    ["Aureline"] = 4, ["Crystallum"] = 5, ["Diamond"] = 6, 
    ["Nebulite"] = 7, ["Galaxion"] = 8, ["Quantum"] = 9, 
    ["Devil"] = 10, ["Heaven"] = 11, ["Nebula"] = 12, 
    ["Singularity"] = 13, ["Aqua"] = 14, ["Lucky"] = 15, 
    ["Void"] = 16, ["Ethereal"] = 17, ["Celestial"] = 18, 
    ["Solar"] = 19, ["Abyssal"] = 20, ["Hell"] = 21,
    ["Infinity"] = 23, ["Blackhole"] = 24, ["Death"] = 25,
    ["Paradox"] = 26, ["Soul"] = 27, ["Joker"] = 28,
    ["Reality"] = 29, ["Kraken"] = 29, ["Seraphim"] = 30,
    ["Galactic"] = 31, ["Eldritch"] = 32, ["Emperor"] = 33,
    ["Anihilation"] = 34, ["Disaster"] = 35, ["Impossible"] = 36,
    ["Limbo"] = 37 
}

local DiceList = {}
for k,_ in pairs(DiceRankings) do table.insert(DiceList, k .. " Dice") end
table.sort(DiceList)

-- Labels
local PlotStatusLabel = nil 
local SelectStatusLabel = nil

-- =========================================================================
--  CORE FUNCTIONS
-- =========================================================================

local function forceSelectAndClick(button)
    if not button then return end
    GuiService.SelectedObject = button
    task.wait(0.15) 
    
    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    local center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2)
    local inset = GuiService:GetGuiInset()
    local clickX = center.X
    local clickY = center.Y + inset.Y

    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
end

-- =========================================================================
--  SHOP STOCK READER (NEW)
-- =========================================================================

local function getShopStock(diceName)
    local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return 0 end
    
    -- Target: Main.Restock.ScrollingFrame[DiceName].stock
    if pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("Restock") then
        local scroll = pGui.Main.Restock:FindFirstChild("ScrollingFrame")
        if scroll then
            local diceFrame = scroll:FindFirstChild(diceName)
            if diceFrame then
                local stockLabel = diceFrame:FindFirstChild("stock") -- Case sensitive check
                if stockLabel and stockLabel:IsA("TextLabel") then
                    local text = stockLabel.Text
                    
                    -- CHECK 1: "NO STOCK"
                    if text:upper():find("NO STOCK") then
                        return 0
                    end
                    
                    -- CHECK 2: "x999" -> 999
                    local num = tonumber(text:match("%d+"))
                    if num then
                        return num
                    end
                end
            end
        end
    end
    return 0 -- Default to 0 if UI not found
end

-- =========================================================================
--  POTION STOCK READER
-- =========================================================================

local function getPotionStock(potionName)
    local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return 0 end
    
    -- Target: Main.Potions.ScrollingFrame[PotionName].stock
    if pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("Potions") then
        local scroll = pGui.Main.Potions:FindFirstChild("ScrollingFrame")
        if scroll then
            local potionFrame = scroll:FindFirstChild(potionName)
            if potionFrame then
                -- Check for 'stock' label (Assuming same naming convention as Dice)
                local stockLabel = potionFrame:FindFirstChild("stock") 
                if stockLabel and stockLabel:IsA("TextLabel") then
                    local text = stockLabel.Text
                    
                    -- CHECK 1: "NO STOCK"
                    if text:upper():find("NO STOCK") then
                        return 0
                    end
                    
                    -- CHECK 2: Extract Number
                    local num = tonumber(text:match("%d+"))
                    if num then
                        return num
                    end
                end
            end
        end
    end
    return 0 
end

-- =========================================================================
--  INVENTORY FINDERS
-- =========================================================================

local function findDiceContainer()
    local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return nil end
    if pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("Dice") and pGui.Main.Dice:FindFirstChild("Container") then
        return pGui.Main.Dice.Container
    end
    -- Fallback
    if pGui:FindFirstChild("Main") then
        for _, v in pairs(pGui.Main:GetDescendants()) do
            if v.Name == "Container" and v:FindFirstChildOfClass("ImageButton") then
                return v
            end
        end
    end
    return nil
end

local function getCurrentDiceName()
    local container = findDiceContainer()
    if container and container.Parent then
        local title = container.Parent:FindFirstChild("title")
        if title and title:IsA("TextLabel") then return title.Text end
    end
    return "None"
end

local function getDiceRank(name)
    for key, rank in pairs(DiceRankings) do
        if name:find(key) then return rank end
    end
    return 0
end

local function getContainerDiceStock(frame)
    for _, v in pairs(frame:GetDescendants()) do
        if v:IsA("TextLabel") then
            local txt = v.Text:gsub("x", ""):gsub("%s+", ""):gsub(",", "")
            if tonumber(txt) then return tonumber(txt) end
        end
    end
    return 1 
end

-- =========================================================================
--  SYSTEM FUNCTIONS
-- =========================================================================

local NotifConnection = nil
local function toggleNotificationBlocker(enable)
    if enable then
        if NotifConnection then NotifConnection:Disconnect() end
        local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            local botNot = pGui:FindFirstChild("bot_not")
            if botNot then
                local targetFrame = botNot:FindFirstChild("Frame")
                if targetFrame then
                    for _, child in pairs(targetFrame:GetChildren()) do
                        if child.Name == "ActiveNotification" then child:Destroy() end
                    end
                    NotifConnection = targetFrame.ChildAdded:Connect(function(child)
                        if child.Name == "ActiveNotification" then
                            task.wait() 
                            child:Destroy()
                        end
                    end)
                end
            end
        end
    else
        if NotifConnection then
            NotifConnection:Disconnect()
            NotifConnection = nil
        end
    end
end

local function parseSlotString(str)
    local list = {}
    for s in string.gmatch(str, "([^,]+)") do
        local n = tonumber(s)
        if n then table.insert(list, n) end
    end
    return list
end

local function toggleNoclip(state)
    if state then
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                local char = Players.LocalPlayer.Character
                if char then
                    for _, v in pairs(char:GetDescendants()) do
                        if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                    end
                end
            end)
        end
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
    end
end

local function findAndLockPlot()
    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local closestPlot = nil
    local shortestDistance = math.huge
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Plots") then
        for _, plot in pairs(workspace.Map.Plots:GetChildren()) do
            local zone = plot:FindFirstChild("Zone")
            if zone then
                local distance = (root.Position - zone.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlot = plot
                end
            end
        end
    end
    if closestPlot then
        MyLockedPlot = closestPlot
        if PlotStatusLabel then PlotStatusLabel:Set("Locked Plot: " .. closestPlot.Name) end
        Rayfield:Notify({Title = "Plot Found", Content = "Locked to " .. closestPlot.Name, Duration = 3})
    else
        Rayfield:Notify({Title = "Error", Content = "Could not find any nearby plot!", Duration = 3})
    end
end

local function updateSlotESP(enabled)
    if MyLockedPlot then
        for _, obj in pairs(MyLockedPlot:GetDescendants()) do
            if obj.Name == "GeminiSlotESP" then obj:Destroy() end
        end
    end
    if enabled and MyLockedPlot and MyLockedPlot:FindFirstChild("Slots") then
        for _, slot in pairs(MyLockedPlot.Slots:GetChildren()) do
            if slot:FindFirstChild("Collect") and slot.Collect:FindFirstChild("Touch") then
                local part = slot.Collect.Touch
                local bg = Instance.new("BillboardGui")
                bg.Name = "GeminiSlotESP"
                bg.Adornee = part
                bg.Size = UDim2.new(0, 100, 0, 50)
                bg.StudsOffset = Vector3.new(0, 5, 0)
                bg.AlwaysOnTop = true
                local label = Instance.new("TextLabel")
                label.Parent = bg
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = "Slot " .. slot.Name
                label.TextColor3 = Color3.new(0, 1, 0)
                label.TextStrokeTransparency = 0
                label.TextScaled = true
                bg.Parent = part
            end
        end
    end
end

-- ==========================================
-- 🌾 FARMING TAB
-- ==========================================
FarmingTab:CreateSection("Location Setup")

PlotStatusLabel = FarmingTab:CreateLabel("Locked Plot: None")

FarmingTab:CreateButton({
    Name = "Set Current Location as My Plot",
    Callback = function()
        findAndLockPlot()
    end,
})

local SlotESPElement = FarmingTab:CreateToggle({
    Name = "Show Slot Numbers (ESP)",
    CurrentValue = false,
    Flag = "SlotESPToggle",
    Callback = function(Value)
        ShowSlotESP = Value
        if not MyLockedPlot then findAndLockPlot() end
        updateSlotESP(Value)
    end,
})
Elements["SlotESPToggle"] = SlotESPElement

FarmingTab:CreateSection("Auto-Farming")

local SlotInputElement = FarmingTab:CreateInput({
    Name = "Custom Slot List",
    PlaceholderText = "1, 3... 24",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomSlotList",
    Callback = function(Text)
        TargetSlotsString = Text
    end,
})
Elements["CustomSlotList"] = SlotInputElement

local AutoWalkElement = FarmingTab:CreateToggle({
    Name = "Auto Claim Money (Walk - Smart Hop)",
    CurrentValue = false,
    Flag = "AutoWalkSlots",
    Callback = function(Value)
        AutoWalkSlotsEnabled = Value
        if Value and AutoTweenSlotsEnabled then
            Rayfield:Notify({Title = "Conflict", Content = "Disable Tween Mode first!", Duration = 3})
            AutoWalkSlotsEnabled = false
            Elements["AutoWalkSlots"]:Set(false)
            return
        end
        if Value then
            if not MyLockedPlot then findAndLockPlot() end
            task.spawn(function()
                while AutoWalkSlotsEnabled do
                    local char = Players.LocalPlayer.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if char and hum and root and hum.Health > 0 and MyLockedPlot then
                        hum.WalkSpeed = CurrentSpeed
                        local currentPath = parseSlotString(TargetSlotsString)
                        for _, slotNum in ipairs(currentPath) do
                            if not AutoWalkSlotsEnabled then break end
                            local slot = MyLockedPlot.Slots:FindFirstChild(tostring(slotNum))
                            if slot and slot:FindFirstChild("Collect") and slot.Collect:FindFirstChild("Touch") then
                                local targetPart = slot.Collect.Touch
                                local heightDiff = math.abs(targetPart.Position.Y - root.Position.Y)
                                if heightDiff > 8 then
                                    root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                                    task.wait(0.15)
                                else
                                    hum:MoveTo(targetPart.Position)
                                    hum.MoveToFinished:Wait()
                                end
                            end
                            task.wait(0.1)
                        end
                    elseif not MyLockedPlot then
                        Rayfield:Notify({Title = "Error", Content = "Click 'Set Current Location' first!", Duration = 3})
                        task.wait(3)
                        AutoWalkSlotsEnabled = false
                        Elements["AutoWalkSlots"]:Set(false)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})
Elements["AutoWalkSlots"] = AutoWalkElement

local AutoTweenElement = FarmingTab:CreateToggle({
    Name = "Auto Claim Money (Tween - Fast)",
    CurrentValue = false,
    Flag = "AutoTweenSlots",
    Callback = function(Value)
        AutoTweenSlotsEnabled = Value
        toggleNoclip(Value) 
        if Value and AutoWalkSlotsEnabled then
            Rayfield:Notify({Title = "Conflict", Content = "Disable Walk Mode first!", Duration = 3})
            AutoTweenSlotsEnabled = false
            Elements["AutoTweenSlots"]:Set(false)
            return
        end
        if Value then
            if not MyLockedPlot then findAndLockPlot() end
            task.spawn(function()
                while AutoTweenSlotsEnabled do
                    local char = Players.LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if char and root and MyLockedPlot then
                        local currentPath = parseSlotString(TargetSlotsString)
                        for _, slotNum in ipairs(currentPath) do
                            if not AutoTweenSlotsEnabled then break end
                            local slot = MyLockedPlot.Slots:FindFirstChild(tostring(slotNum))
                            if slot and slot:FindFirstChild("Collect") and slot.Collect:FindFirstChild("Touch") then
                                local targetPos = slot.Collect.Touch.Position + Vector3.new(0, HoverHeight, 0)
                                local distance = (root.Position - targetPos).Magnitude
                                local tweenTime = distance / CurrentSpeed
                                local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                                local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
                                tween:Play()
                                tween.Completed:Wait()
                            end
                        end
                    elseif not MyLockedPlot then
                         Rayfield:Notify({Title = "Error", Content = "Click 'Set Current Location' first!", Duration = 3})
                         task.wait(3)
                         AutoTweenSlotsEnabled = false
                         Elements["AutoTweenSlots"]:Set(false)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})
Elements["AutoTweenSlots"] = AutoTweenElement

local TweenSpeedElement = FarmingTab:CreateSlider({
    Name = "Tween Speed",
    Range = {16, 300},
    Increment = 10,
    Suffix = "Studs/Sec",
    CurrentValue = 50,
    Flag = "SpeedSlider",
    Callback = function(Value)
        CurrentSpeed = Value
    end,
})
Elements["SpeedSlider"] = TweenSpeedElement

-- ==========================================
-- 🎲 DICE MANAGER TAB
-- ==========================================
DiceTab:CreateSection("Auto-Selector")

SelectStatusLabel = DiceTab:CreateLabel("Status: Idle")

local AutoSelectElement = DiceTab:CreateToggle({
    Name = "Auto Select Best Dice (Hybrid Lock)",
    CurrentValue = false,
    Flag = "AutoSelectToggle",
    Callback = function(Value)
        AutoSelectEnabled = Value
        if Value then
            task.spawn(function()
                while AutoSelectEnabled do
                    pcall(function() -- ERROR PROTECTION
                        local container = findDiceContainer()
                        if container then
                            local currentName = getCurrentDiceName()
                            local currentRank = getDiceRank(currentName)
                            local bestUpgradeName = nil
                            local bestUpgradeRank = -1
                            local bestUpgradeClicker = nil
                            
                            for _, frame in pairs(container:GetChildren()) do
                                if frame:IsA("Frame") or frame:IsA("ImageButton") then
                                    local dName = frame.Name
                                    local rank = getDiceRank(dName)
                                    if rank > 0 then
                                        local cStock = getContainerDiceStock(frame)
                                        if cStock > 0 then
                                            if rank > bestUpgradeRank then
                                                bestUpgradeRank = rank
                                                bestUpgradeName = dName
                                                bestUpgradeClicker = frame:FindFirstChild("Click") or frame
                                            end
                                        end
                                    end
                                end
                            end
                            
                            if bestUpgradeName and bestUpgradeRank > currentRank then
                                SelectStatusLabel:Set("Locking on: " .. bestUpgradeName)
                                if bestUpgradeClicker then
                                    forceSelectAndClick(bestUpgradeClicker)
                                    task.wait(1) 
                                end
                            else
                                SelectStatusLabel:Set("Holding: " .. currentName)
                            end
                        else
                            SelectStatusLabel:Set("Status: Menu Not Found")
                        end
                    end)
                    task.wait(1) 
                end
                SelectStatusLabel:Set("Status: Idle")
            end)
        end
    end,
})
Elements["AutoSelectToggle"] = AutoSelectElement

DiceTab:CreateSection("Auto-Buy")

local AutoBuyStatus = DiceTab:CreateLabel("Status: Idle")

local AutoBuyElement = DiceTab:CreateToggle({
    Name = "Auto Clear Shop (Buy Available Stock)",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(Value)
        AutoBuyEnabled = Value
        if Value then
            task.spawn(function()
                while AutoBuyEnabled do
                    for k, v in pairs(DiceRankings) do
                        if not AutoBuyEnabled then break end
                        
                        -- NEW LOGIC: Check Shop Stock for this specific Dice
                        local diceFullName = k .. " Dice"
                        local stockAvailable = getShopStock(diceFullName)
                        
                        if stockAvailable > 0 then
                            task.spawn(function()
                                pcall(function()
                                    -- Buy EXACTLY the amount available in the shop
                                    ReplicatedStorage.Events.buy:InvokeServer(diceFullName, stockAvailable)
                                end)
                            end)
                        end
                    end
                    
                    AutoBuyStatus:Set("Status: Clearing Stock...")
                    task.wait(5) -- Fast check loop
                end
                AutoBuyStatus:Set("Status: Idle")
            end)
        end
    end,
})
Elements["AutoBuyToggle"] = AutoBuyElement

DiceTab:CreateSection("Potions Manager")

local AutoBuyPotionsEnabled = false
local PotionStatusLabel = DiceTab:CreateLabel("Status: Idle")

local AutoBuyPotionsElement = DiceTab:CreateToggle({
    Name = "Auto Clear Potions (Safe Buy)",
    CurrentValue = false,
    Flag = "AutoBuyPotionsToggle",
    Callback = function(Value)
        AutoBuyPotionsEnabled = Value
        if Value then
            task.spawn(function()
                while AutoBuyPotionsEnabled do
                    local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
                    if pGui and pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("Potions") then
                        local scroll = pGui.Main.Potions:FindFirstChild("ScrollingFrame")
                        
                        if scroll then
                            PotionStatusLabel:Set("Status: Scanning Shop...")
                            
                            for _, child in pairs(scroll:GetChildren()) do
                                if not AutoBuyPotionsEnabled then break end
                                
                                -- Ensure it is a valid Potion Frame
                                if (child:IsA("Frame") or child:IsA("ImageButton")) and child.Name ~= "UIListLayout" then 
                                    local stock = getPotionStock(child.Name)
                                    
                                    if stock > 0 then
                                        PotionStatusLabel:Set("Buying: " .. child.Name .. " ("..stock..")")
                                        
                                        -- SAFE BUY: Strictly uses the standard 'buy' remote
                                        pcall(function()
                                            -- Using child.Name (e.g., "PrismaticPotion") and Stock amount
                                            ReplicatedStorage.Events.buy:InvokeServer(child.Name, stock)
                                        end)
                                        
                                        task.wait(0.25) -- 0.25s delay to be safe and avoid transaction errors
                                    end
                                end
                            end
                        else
                            PotionStatusLabel:Set("Status: UI Not Found")
                        end
                    end
                    
                    if AutoBuyPotionsEnabled then
                        PotionStatusLabel:Set("Status: Waiting for Restock...")
                        task.wait(3) -- Longer wait to look natural
                    end
                end
                PotionStatusLabel:Set("Status: Idle")
            end)
        end
    end,
})
Elements["AutoBuyPotionsToggle"] = AutoBuyPotionsElement

DiceTab:CreateSection("Baddies")

local AutoEquipElement = DiceTab:CreateToggle({
    Name = "Equip Best Baddies (Every 1m)",
    CurrentValue = false,
    Flag = "AutoEquipBaddies",
    Callback = function(Value)
        AutoEquipBaddiesEnabled = Value
        if Value then
            task.spawn(function()
                while AutoEquipBaddiesEnabled do
                    ReplicatedStorage.Events.PlaceBestBaddies:InvokeServer()
                    Rayfield:Notify({Title = "Equip Best", Content = "Baddies Updated!", Duration = 2})
                    task.wait(60) 
                end
            end)
        end
    end,
})
Elements["AutoEquipBaddies"] = AutoEquipElement

-- ==========================================
-- 🎁 REWARDS TAB
-- ==========================================
RewardsTab:CreateSection("Automation")

local AutoIndexElement = RewardsTab:CreateToggle({
    Name = "Auto Index Rewards",
    CurrentValue = false,
    Flag = "AutoIndexRewards",
    Callback = function(Value)
        AutoIndexRewardsEnabled = Value
        if Value then
            task.spawn(function()
                while AutoIndexRewardsEnabled do
                    ReplicatedStorage.Events.claimAll:InvokeServer()
                    task.wait(5)
                end
            end)
        end
    end,
})
Elements["AutoIndexRewards"] = AutoIndexElement

local AutoRebirthElement = RewardsTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(Value)
        AutoRebirthEnabled = Value
        if Value then
            task.spawn(function()
                while AutoRebirthEnabled do
                    ReplicatedStorage.Events.rebirth:InvokeServer()
                    task.wait(10)
                end
            end)
        end
    end,
})
Elements["AutoRebirth"] = AutoRebirthElement

RewardsTab:CreateSection("System")

local HideNotifsElement = RewardsTab:CreateToggle({
    Name = "Destroy Notifications",
    CurrentValue = false,
    Flag = "HideNotifs",
    Callback = function(Value)
        HideNotificationsEnabled = Value
        toggleNotificationBlocker(Value)
    end,
})
Elements["HideNotifs"] = HideNotifsElement

local AntiAFKElement = RewardsTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(Value)
        if Value then
            local vu = game:GetService("VirtualUser")
            game:GetService("Players").LocalPlayer.Idled:Connect(function()
                vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                wait(1)
                vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            end)
        end
    end,
})
Elements["AntiAFK"] = AntiAFKElement

-- ==========================================
-- ⚙️ SETTINGS TAB
-- ==========================================
SettingsTab:CreateSection("Configuration Manager")

local ConfigNameInput = ""
local SelectedConfig = nil

local function SaveConfig(name)
    local data = {}
    for flag, element in pairs(Elements) do
        if element.CurrentValue ~= nil then 
            data[flag] = element.CurrentValue 
        elseif element.CurrentOption then
             data[flag] = element.CurrentOption
        end
    end
    writefile("ArchemaraHub/" .. name .. ".json", HttpService:JSONEncode(data))
end

local function LoadConfig(name)
    if isfile("ArchemaraHub/" .. name .. ".json") then
        local content = readfile("ArchemaraHub/" .. name .. ".json")
        local data = HttpService:JSONDecode(content)
        for flag, value in pairs(data) do
            if Elements[flag] then 
                Elements[flag]:Set(value) 
            end
        end
    end
end

local function GetConfigList()
    local files = {}
    if isfolder("ArchemaraHub") then
        for _, file in pairs(listfiles("ArchemaraHub")) do
            if file:sub(-5) == ".json" and not file:find("autoload.txt") then
                table.insert(files, file:match("ArchemaraHub/(.*).json"))
            end
        end
    end
    return files
end

SettingsTab:CreateInput({
   Name = "Config Name",
   PlaceholderText = "Input Name",
   Callback = function(Text) ConfigNameInput = Text end,
})

local ConfigDropdown
ConfigDropdown = SettingsTab:CreateDropdown({
   Name = "Select Config",
   Options = GetConfigList(),
   CurrentOption = "",
   MultipleOptions = false,
   Flag = "ConfigDropdown",
   Callback = function(Option)
      if Option and Option[1] then SelectedConfig = Option[1] end
   end,
})

SettingsTab:CreateButton({
   Name = "Save / Overwrite Config",
   Callback = function()
      if ConfigNameInput ~= "" then
         SaveConfig(ConfigNameInput)
         Rayfield:Notify({Title = "Saved", Content = ConfigNameInput, Duration = 2})
         ConfigDropdown:Refresh(GetConfigList(), true)
      elseif SelectedConfig then
         SaveConfig(SelectedConfig)
         Rayfield:Notify({Title = "Overwritten", Content = SelectedConfig, Duration = 2})
      end
   end,
})

SettingsTab:CreateButton({
   Name = "Load Selected Config",
   Callback = function()
      if SelectedConfig then
         LoadConfig(SelectedConfig)
         Rayfield:Notify({Title = "Loaded", Content = SelectedConfig, Duration = 2})
      end
   end,
})

SettingsTab:CreateSection("Autostart")

local AutoloadToggle = SettingsTab:CreateToggle({
   Name = "Autoload Selected Config",
   CurrentValue = false,
   Flag = "AutoloadToggle",
   Callback = function(Value)
      if Value and SelectedConfig then
         writefile("ArchemaraHub/autoload.txt", SelectedConfig)
      elseif not Value then
         if isfile("ArchemaraHub/autoload.txt") then delfile("ArchemaraHub/autoload.txt") end
      end
   end,
})

-- // AUTO LOAD LOGIC // --
task.spawn(function()
    if isfile("ArchemaraHub/autoload.txt") then
        local autoConfig = readfile("ArchemaraHub/autoload.txt")
        if isfile("ArchemaraHub/" .. autoConfig .. ".json") then
            task.wait(1)
            LoadConfig(autoConfig)
            Rayfield:Notify({Title = "Autoload", Content = "Loaded " .. autoConfig, Duration = 3})
            SelectedConfig = autoConfig
            ConfigDropdown:Set({autoConfig})
            AutoloadToggle:Set(true)
        end
    end
end)

task.spawn(function()
    task.wait(2)
    findAndLockPlot()
end)
