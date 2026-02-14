-- MainGameSystems.server.lua
-- Core game logic: thirst, tanks, drips, plants, shop, placement

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

print("Server starting - MainGameSystems loading...")

-- Leaderstats + Thirst
Players.PlayerAdded:Connect(function(player)
    print(player.Name .. " joined - setting up leaderstats")

    player.CharacterAdded:Connect(function(character)
        local ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player

        local water = Instance.new("NumberValue")
        water.Name = "Water"
        water.Value = 2
        water.Parent = ls

        local money = Instance.new("IntValue")
        money.Name = "Money"
        money.Value = 0
        money.Parent = ls

        local seeds = Instance.new("IntValue")
        seeds.Name = "Seeds"
        seeds.Value = 0
        seeds.Parent = ls

        print(player.Name .. " leaderstats created")

        -- Thirst drain: 0.01 L/s, lethal when 0
        task.spawn(function()
            while character.Parent do
                task.wait(1)
                if player.leaderstats then
                    local w = player.leaderstats.Water
                    if w.Value > 0 then
                        w.Value = math.max(0, w.Value - 0.01)
                    else
                        local hum = character:FindFirstChild("Humanoid")
                        if hum then
                            hum.Health = math.max(0, hum.Health - 5)
                            print(player.Name .. " dehydrated - health draining")
                        end
                    end
                end
            end
        end)
    end)
end)

-- Helper: Update WaterLevel visual (grows upward from bottom origin)
local function updateWaterLevelVisual(tank, current, max)
    local wl = tank:FindFirstChild("WaterLevel")
    if not wl then
        warn("No WaterLevel in tank: " .. tank.Name)
        return
    end

    local ratio = current / max
    local fillHeight = max * ratio

    wl.Size = Vector3.new(wl.Size.X, fillHeight, wl.Size.Z)

    -- Bottom fixed at original position
    local originalBottomY = wl.Position.Y - (wl.Size.Y / 2)  -- initial bottom
    local newCenterY = originalBottomY + (fillHeight / 2)
    wl.Position = Vector3.new(wl.Position.X, newCenterY, wl.Position.Z)

    local lbl = tank:FindFirstChild("Label", true)
    if lbl then
        lbl.Text = string.format("%.3f / %.0f L", current, max)
    end
end

-- Tank setup (claim + collect)
local function setupTank(model)
    if model:GetAttribute("Setup") then return end
    model:SetAttribute("Setup", true)

    print("Setting up tank: " .. model.Name)

    local body = model:FindFirstChild("TankBody")
    local wl = model:FindFirstChild("WaterLevel")
    local ghost = model:FindFirstChild("GhostWater")

    if not body or not wl or not ghost then
        warn("Tank incomplete: " .. model.Name .. " (missing TankBody, WaterLevel or GhostWater)")
        return
    end

    local maxWater = ghost.Size.Y
    model:SetAttribute("MaxWater", maxWater)
    model:SetAttribute("CurrentWater", 0)

    local owner = nil

    -- Collect prompt (must be manually added)
    local prompt = body:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        warn("No ProximityPrompt on TankBody in " .. model.Name .. " - add manually")
    else
        prompt.Triggered:Connect(function(plr)
            if plr == owner then
                local current = model:GetAttribute("CurrentWater") or 0
                if current > 0 then
                    plr.leaderstats.Water.Value += current
                    model:SetAttribute("CurrentWater", 0)
                    updateWaterLevelVisual(model, 0, maxWater)
                    print(plr.Name .. " collected " .. string.format("%.3f L", current) .. " from " .. model.Name)
                end
            end
        end)
    end

    -- Claim on touch
    body.Touched:Connect(function(hit)
        local plr = Players:GetPlayerFromCharacter(hit.Parent)
        if plr and not owner then
            owner = plr
            print(plr.Name .. " claimed " .. model.Name)
        end
    end)

    -- Initial visual
    updateWaterLevelVisual(model, 0, maxWater)
end

-- WaterSource setup (drips fill any tank via GhostWater)
local function setupWaterSource(sourceModel)
    if sourceModel:GetAttribute("Setup") then return end
    sourceModel:SetAttribute("Setup", true)

    print("Setting up WaterSource: " .. sourceModel.Name)

    local dripPoint = sourceModel:FindFirstChild("DripPoint")
    if not dripPoint then
        warn("WaterSource missing DripPoint: " .. sourceModel.Name)
        return
    end

    local dripRate = 1
    local dripAmount = 0.001

    -- Optional visual drip
    local emitter = dripPoint:FindFirstChildOfClass("ParticleEmitter")
    if emitter then
        emitter.Rate = dripRate
        emitter.Lifetime = NumberRange.new(2, 2)
        emitter.Speed = NumberRange.new(5, 5)
        emitter.Direction = Vector3.new(0, -1, 0)
    end

    task.spawn(function()
        while sourceModel.Parent do
            task.wait(1 / dripRate)

            local rayDirection = Vector3.new(0, -30, 0)
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {sourceModel}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local result = workspace:Raycast(dripPoint.WorldPosition, rayDirection, rayParams)

            if result and result.Instance and result.Instance.Name == "GhostWater" then
                local tank = result.Instance.Parent
                if tank and tank:IsA("Model") and tank.Name == "Tank" then
                    local current = tank:GetAttribute("CurrentWater") or 0
                    local maxWater = tank:GetAttribute("MaxWater") or 40

                    if current < maxWater then
                        local newCurrent = math.min(current + dripAmount, maxWater)
                        tank:SetAttribute("CurrentWater", newCurrent)
                        updateWaterLevelVisual(tank, newCurrent, maxWater)
                        print("Drip filled tank " .. tank.Name .. ": " .. string.format("%.3f L", newCurrent))
                    end
                end
            end
        end
    end)
end

-- Plant system
PlantEvent.OnServerEvent:Connect(function(player, plot)
    if not player.leaderstats then return end
    if plot:GetAttribute("Growing") then return end
    if player.leaderstats.Water.Value < 0.2 or player.leaderstats.Seeds.Value < 1 then
        print(player.Name .. " - not enough water or seeds")
        return
    end

    local plant = plot:FindFirstChild("Plant")
    local soil = plot:FindFirstChild("Soil")
    local prompt = soil and soil:FindFirstChildOfClass("ProximityPrompt")
    if not plant or not soil or not prompt then
        warn("Invalid plot for " .. player.Name)
        return
    end

    prompt.Enabled = false
    plot:SetAttribute("Growing", true)
    player.leaderstats.Water.Value -= 0.2
    player.leaderstats.Seeds.Value -= 1

    plant.Transparency = 0
    plant.Orientation = Vector3.new(0, 0, 0)
    local tween = TweenService:Create(plant, TweenInfo.new(30), {Size = Vector3.new(4, 8, 4)})
    tween:Play()

    local heartbeatConn = RunService.Heartbeat:Connect(function()
        if tween.PlaybackState ~= Enum.PlaybackState.Playing then
            heartbeatConn:Disconnect()
            return
        end
        plant.Orientation = Vector3.new(0, 0, 0)
        local halfHeight = plant.Size.Y / 2
        plant.Position = soil.Position + Vector3.new(0, soil.Size.Y/2 + halfHeight, 0)
    end)

    tween.Completed:Connect(function()
        if player.leaderstats then
            player.leaderstats.Money.Value += 50
            print(player.Name .. " harvested a plant")
        end
        plant.Transparency = 1
        plant.Size = Vector3.new(0.5, 0.5, 0.5)
        plant.Orientation = Vector3.new(0, 0, 0)
        plant.Position = soil.Position + Vector3.new(0, soil.Size.Y/2 + 0.25, 0)
        plot:SetAttribute("Growing", false)
        prompt.Enabled = true
        heartbeatConn:Disconnect()
    end)
end)

-- Shop buys
BuyItemEvent.OnServerEvent:Connect(function(player, itemType)
    if not player.leaderstats then return end
    local money = player.leaderstats.Money
    local cost = 0
    local item = nil

    if itemType == "Tank" then
        cost = 100
        item = Instance.new("Tool")
        item.Name = "TankPlacer"
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1,1,1)
        handle.Parent = item
    elseif itemType == "Plot" then
        cost = 50
        item = Instance.new("Tool")
        item.Name = "PlotPlacer"
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1,1,1)
        handle.Parent = item
    elseif itemType == "Seed" then
        cost = 10
    end

    if money.Value >= cost then
        money.Value -= cost
        if itemType == "Seed" then
            player.leaderstats.Seeds.Value += 1
        else
            item.Parent = player.Backpack
        end
        print(player.Name .. " bought " .. itemType)
    else
        print(player.Name .. " - not enough money for " .. itemType)
    end
end)

-- Placement
PlaceItemEvent.OnServerEvent:Connect(function(player, itemType, position)
    local model = nil
    if itemType == "Tank" then
        model = Instance.new("Model")
        model.Name = "Tank"
        local body = Instance.new("Part")
        body.Name = "TankBody"
        body.Size = Vector3.new(6,8,6)
        body.Anchored = true
        body.Position = position
        body.Parent = model
        -- Add your real Tank model here if you want (clone from ReplicatedStorage.Assets.Tank)
    elseif itemType == "Plot" then
        model = Instance.new("Model")
        model.Name = "PlantPlot"
        local soil = Instance.new("Part")
        soil.Name = "Soil"
        soil.Size = Vector3.new(4,0.5,4)
        soil.Anchored = true
        soil.Position = position
        soil.Parent = model
        local plant = Instance.new("Part")
        plant.Name = "Plant"
        plant.Size = Vector3.new(0.5,0.5,0.5)
        plant.Anchored = true
        plant.Position = soil.Position + Vector3.new(0, soil.Size.Y/2 + 0.25, 0)
        plant.Parent = model
    end

    if model then
        model.Parent = workspace
        if itemType == "Tank" then
            setupTank(model)
        end
        print(player.Name .. " placed " .. itemType .. " at " .. tostring(position))
    end
end)

-- Auto-setup existing Tanks / WaterSources
for _, obj in workspace:GetChildren() do
    if obj:IsA("Model") then
        if obj.Name == "Tank" then task.spawn(setupTank, obj)
        elseif obj.Name == "WaterSource" then task.spawn(setupWaterSource, obj)
        end
    end
end

workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        if child.Name == "Tank" then task.spawn(setupTank, child)
        elseif child.Name == "WaterSource" then task.spawn(setupWaterSource, child)
        end
    end
end)

print("Water Tycoon server fully loaded - ready")