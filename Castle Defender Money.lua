local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local WaveVal = LocalPlayer:WaitForChild("WaveVal")
local ProgressVal = WaveVal:WaitForChild("Progress")
local ToggleWave = ReplicatedStorage.Events.Remotes.ToggleWave

-- [[ CONFIGURATION ]]
local TargetWave = 102
local MaxEnemies = 60
local AutoFarmEnabled = true -- CHANGED TO TRUE (Starts automatically)

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local InputBox = Instance.new("TextBox")
local ToggleButton = Instance.new("TextButton")

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.Position = UDim2.new(0.02, 0, 0.5, 0)
Frame.Size = UDim2.new(0, 200, 0, 160)
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).Parent = Frame

Title.Parent = Frame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 5)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Font = Enum.Font.GothamBold
Title.Text = "MATH FARMER (AUTO)"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.TextSize = 16

StatusLabel.Parent = Frame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 25)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Status: Starting..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12

InputBox.Parent = Frame
InputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
InputBox.Position = UDim2.new(0.1, 0, 0.35, 0)
InputBox.Size = UDim2.new(0.8, 0, 0, 35)
InputBox.Font = Enum.Font.Gotham
InputBox.PlaceholderText = "Target Wave"
InputBox.Text = tostring(TargetWave)
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.TextSize = 16

ToggleButton.Parent = Frame
ToggleButton.Position = UDim2.new(0.1, 0, 0.65, 0)
ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 16
Instance.new("UICorner", ToggleButton).Parent = ToggleButton

-- Set Initial Button State
if AutoFarmEnabled then
	ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
	ToggleButton.Text = "Auto Farm: ON"
	StatusLabel.Text = "Status: Auto Started"
else
	ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	ToggleButton.Text = "Auto Farm: OFF"
	StatusLabel.Text = "Status: Idle"
end

-- Events
InputBox.FocusLost:Connect(function()
	local num = tonumber(InputBox.Text)
	if num then TargetWave = num else InputBox.Text = tostring(TargetWave) end
end)

ToggleButton.MouseButton1Click:Connect(function()
	AutoFarmEnabled = not AutoFarmEnabled
	if AutoFarmEnabled then
		ToggleButton.Text = "Auto Farm: ON"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
		StatusLabel.Text = "Status: Resumed"
	else
		ToggleButton.Text = "Auto Farm: OFF"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		StatusLabel.Text = "Status: Paused"
	end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- Main Loop
local StuckTimer = tick()
local LastProgress = -1

task.spawn(function()
	while task.wait(0.1) do
		if AutoFarmEnabled then
			local CurrentProgress = ProgressVal.Value
			local EnemiesLeft = MaxEnemies - CurrentProgress
			
			if EnemiesLeft <= 0 then
				StatusLabel.Text = "Status: RESETTING..."
				
				ToggleWave:FireServer(false)
				ToggleWave:FireServer("Stop")
				ToggleWave:FireServer(true)
				ToggleWave:FireServer("Start")
				
				StatusLabel.Text = "Status: Waiting for Reset..."
				local Timeout = tick()
				repeat 
					task.wait(0.1)
				until ProgressVal.Value < MaxEnemies or (tick() - Timeout) > 3
				
				StuckTimer = tick() 
				
			elseif WaveVal.Value >= TargetWave then
				StatusLabel.Text = "Status: OVER TARGET"
				ToggleWave:FireServer(false)
				ToggleWave:FireServer("Stop")
				
			else
				StatusLabel.Text = "Enemies Left: " .. tostring(EnemiesLeft)
				
				if CurrentProgress == LastProgress then
					if (tick() - StuckTimer) > 5 then
						StatusLabel.Text = "Status: KICKSTARTING..."
						ToggleWave:FireServer(true)
						ToggleWave:FireServer("Start")
						StuckTimer = tick()
					end
				else
					LastProgress = CurrentProgress
					StuckTimer = tick()
				end
			end
		end
	end
end)
