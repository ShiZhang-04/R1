-- src/shared/VoxelManager.lua
local VoxelManager = {}

local SECTOR_SIZE = 64   -- adjust to your sector size
local HEIGHT = 32        -- max voxel height

-- Greedy meshing function (simplified)
function VoxelManager.meshSector(voxelData, sectorFolder)
    -- voxelData = 3D table [x][y][z] = Color3 or nil
    for x = 1, SECTOR_SIZE do
        for z = 1, SECTOR_SIZE do
            for y = 1, HEIGHT do
                local color = voxelData[x][y][z]
                if color then
                    local w, d, h = 1, 1, 1

                    -- greedy X
                    while x + w <= SECTOR_SIZE and voxelData[x+w][y][z] == color do w = w + 1 end
                    -- greedy Z
                    while z + d <= SECTOR_SIZE do
                        local ok = true
                        for dx = 0, w-1 do
                            if voxelData[x+dx][y][z+d] ~= color then ok = false break end
                        end
                        if not ok then break end
                        d = d + 1
                    end
                    -- greedy Y
                    while y + h <= HEIGHT do
                        local ok = true
                        for dx = 0, w-1 do
                            for dz = 0, d-1 do
                                if voxelData[x+dx][y+h][z+dz] ~= color then ok = false break end
                            end
                        end
                        if not ok then break end
                        h = h + 1
                    end

                    -- Create combined part
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(w, h, d)
                    part.Position = Vector3.new(
                        (x + w/2 - 0.5) * 4,   -- scale voxels to 4x4x4 studs if you want bigger
                        (y + h/2 - 0.5) * 4,
                        (z + d/2 - 0.5) * 4
                    )
                    part.Color = color
                    part.Anchored = true
                    part.Material = Enum.Material.Sand  -- or whatever
                    part.Parent = sectorFolder

                    -- Mark processed (skip inner voxels)
                    for dx = 0, w-1 do
                        for dy = 0, h-1 do
                            for dz = 0, d-1 do
                                voxelData[x+dx][y+dy][z+dz] = nil  -- optional: clear to avoid double-meshing
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Load sector from DataStore (example)
function VoxelManager.loadSector(player, sectorID)
    if not player or not player:IsA("Player") then
        warn("loadSector called with invalid player: " .. tostring(player))
        return
    end

    local key = player.UserId .. "_" .. sectorID
    local success, data = pcall(function()
        return ds:GetAsync(key)
    end)

    if success and data then
        local folder = workspace.Sectors:FindFirstChild(sectorID) or Instance.new("Folder")
        folder.Name = sectorID
        folder.Parent = workspace.Sectors or Instance.new("Folder", workspace)

        VoxelManager.meshSector(data, folder)
        print("Loaded sector " .. sectorID .. " for " .. player.Name)
    else
        print("No data or error for " .. sectorID)
    end
end

return VoxelManager