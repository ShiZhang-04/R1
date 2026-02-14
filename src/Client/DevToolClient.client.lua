local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tool = script.Parent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get the RemoteEvent (Wait for server to create it)
local DevEvents = ReplicatedStorage:WaitForChild("DevEvents", 10)
local DevActionRemote = DevEvents and DevEvents:WaitForChild("DevAction", 10)

-- GUI Storage variable
local createdGui = nil

local function createDevGui()
	if createdGui then return createdGui end

	-- 1. Create ScreenGui
	local sg = Instance.new("ScreenGui")
	sg.Name = "DevConsoleGui"
	sg.ResetOnSpawn = false
	
	-- 2. Create Main Frame
	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0, 200, 0, 300)
	frame.Position = UDim2.new(0.02, 0, 0.5, -150) -- Left side of screen
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 2
	frame.Parent = sg

	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "DEV CONSOLE"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.Parent = frame

	-- Layout List
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = frame

	-- Padding for Title vs Buttons
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 50)
	pad.Parent = frame

	-- Helper to make buttons
	local function makeButton(text, actionName, color)
		local btn = Instance.new("TextButton")
		btn.Text = text
		btn.Size = UDim2.new(0.9, 0, 0, 40)
		btn.BackgroundColor3 = color or Color3.fromRGB(80, 80, 80)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.GothamSemibold
		btn.Parent = frame
		
		btn.MouseButton1Click:Connect(function()
			if DevActionRemote then
				DevActionRemote:FireServer(actionName)
				print("Dev Tool: Sent " .. actionName)
			end
		end)
	end

	-- 3. Add Buttons
	makeButton("Add $1000", "AddMoney", Color3.fromRGB(0, 150, 0))
	makeButton("Refill Water", "FillWater", Color3.fromRGB(0, 100, 200))
	makeButton("Heal Player", "Heal", Color3.fromRGB(200, 50, 50))
	makeButton("Toggle Drip Debug", "ToggleDebug", Color3.fromRGB(150, 0, 150))
	
	createdGui = sg
	return sg
end

-- Tool Events
Tool.Equipped:Connect(function()
	local gui = createDevGui()
	gui.Parent = playerGui
	gui.Enabled = true
end)

Tool.Unequipped:Connect(function()
	if createdGui then
		createdGui.Enabled = false
	end
end)