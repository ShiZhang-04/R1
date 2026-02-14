-- src/client/PlantPrompts.client.lua
-- No auto-creation anymore - only binds to prompts you manually placed

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local PlantEvent     = ReplicatedStorage:WaitForChild("PlantEvent", 10)
local OpenShopEvent  = ReplicatedStorage:WaitForChild("OpenShopEvent", 10)
local BuyItemEvent   = ReplicatedStorage:WaitForChild("BuyItemEvent", 10)
local PlaceItemEvent = ReplicatedStorage:WaitForChild("PlaceItemEvent", 10)

-- Bind existing prompts (manual only)
local function bindPrompt(prompt)
    if prompt.Parent and prompt.Parent.Name == "Soil" then
        prompt.Triggered:Connect(function()
            local plot = prompt.Parent.Parent  -- Soil → PlantPlot
            PlantEvent:FireServer(plot)
        end)
    end
end

-- Initial scan
for _, desc in workspace:GetDescendants() do
    if desc:IsA("ProximityPrompt") then
        bindPrompt(desc)
    end
end

-- New prompts added later
workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("ProximityPrompt") then
        bindPrompt(desc)
    end
end)

-- Shop GUI handling
OpenShopEvent.OnClientEvent:Connect(function()
    local gui = player.PlayerGui:FindFirstChild("ShopGui")
    if gui then
        gui.Enabled = true
    end
end)

-- Connect shop buttons (manual names)
task.spawn(function()
    local gui = player.PlayerGui:WaitForChild("ShopGui", 15)
    if not gui then return end

    local frame = gui:FindFirstChild("Frame") or gui  -- adjust if no Frame
    local buyTankBtn = frame:FindFirstChild("BuyTank")
    local buyPlotBtn = frame:FindFirstChild("BuyPlot")
    local buySeedBtn = frame:FindFirstChild("BuySeed")
    local closeBtn   = frame:FindFirstChild("Close")

    if buyTankBtn then
        buyTankBtn.MouseButton1Click:Connect(function()
            BuyItemEvent:FireServer("Tank")
        end)
    end
    if buyPlotBtn then
        buyPlotBtn.MouseButton1Click:Connect(function()
            BuyItemEvent:FireServer("Plot")
        end)
    end
    if buySeedBtn then
        buySeedBtn.MouseButton1Click:Connect(function()
            BuyItemEvent:FireServer("Seed")
        end)
    end
    if closeBtn then
        closeBtn.MouseButton1Click:Connect(function()
            gui.Enabled = false
        end)
    end
end)

-- Placement tool logic
task.spawn(function()
    player:WaitForChild("Backpack", 10)

    player.Backpack.ChildAdded:Connect(function(tool)
        if tool:IsA("Tool") and (tool.Name == "TankPlacer" or tool.Name == "PlotPlacer") then
            tool.Activated:Connect(function()
                local target = player:GetMouse().Target
                if target then
                    PlaceItemEvent:FireServer(tool.Name:gsub("Placer", ""), player:GetMouse().Hit.Position)
                    tool:Destroy()
                end
            end)
        end
    end)
end)

print("PlantPrompts loaded - only binding existing prompts")