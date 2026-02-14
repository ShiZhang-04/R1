local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 1. Setup Remotes automatically
local folder = ReplicatedStorage:FindFirstChild("DevEvents") or Instance.new("Folder", ReplicatedStorage)
folder.Name = "DevEvents"

local remote = folder:FindFirstChild("DevAction") or Instance.new("RemoteEvent", folder)
remote.Name = "DevAction"

-- 2. Handle Commands
remote.OnServerEvent:Connect(function(player, action)
	local ls = player:FindFirstChild("leaderstats")
	local char = player.Character
	
	if action == "AddMoney" then
		if ls and ls:FindFirstChild("Money") then
			ls.Money.Value += 1000
			print(player.Name .. " cheated in $1000")
		end

	elseif action == "FillWater" then
		if ls and ls:FindFirstChild("Water") then
			ls.Water.Value = 10 -- Or whatever your max is
			print(player.Name .. " refilled water")
		end

	elseif action == "Heal" then
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.Health = char.Humanoid.MaxHealth
		end

	elseif action == "ToggleDebug" then
		-- Toggle visual beams on WaterSources (Helps see if raycasts are working)
		for _, source in pairs(workspace:GetDescendants()) do
			if source.Name == "WaterSource" and source:FindFirstChild("DripPoint") then
				local point = source.DripPoint
				local beam = point:FindFirstChild("DebugBeam")
				
				if beam then
					beam:Destroy()
				else
					-- Create a visual ray to show where it's dripping
					local att0 = Instance.new("Attachment", point)
					local att1 = Instance.new("Attachment", point)
					att1.Position = Vector3.new(0, -15, 0) -- Show drip length
					
					local b = Instance.new("Beam", point)
					b.Name = "DebugBeam"
					b.Attachment0 = att0
					b.Attachment1 = att1
					b.Color = ColorSequence.new(Color3.new(1,0,0))
					b.Width0 = 0.1
					b.Width1 = 0.1
				end
			end
		end
	end
end)