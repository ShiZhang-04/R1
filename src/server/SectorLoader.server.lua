-- src/server/SectorLoader.server.lua (new file)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local VoxelManager = require(ReplicatedStorage.Modules.VoxelManager)

local ds = DataStoreService:GetDataStore("PlayerSectors")

Players.PlayerAdded:Connect(function(player)
    -- Load default sector when player joins
    local sectorID = "1A"  -- example, replace with your logic (random free, owned, etc.)
    VoxelManager.loadSector(player, sectorID)
end)