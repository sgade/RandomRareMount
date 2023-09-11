--[[
--  RandomRareMount.lua
--
--  Copyright (c) 2023 Sören Gade
]]--

RandomRareMountAddon = {}

---@alias ShortMountInfo { name: string, mountId: number, spellId: number }

---Returns the player's favorite mounts from the mount journal.
---@return ShortMountInfo[]
function RandomRareMountAddon:GetFavoriteMounts()
    ---@type ShortMountInfo[]
    local favoriteMounts = {}

    local mountIds = C_MountJournal.GetMountIDs();
    for i, mountId in ipairs(mountIds) do
        local name, spellId, _, _, isUsable, _, isFavorite, _, _, shouldHideOnChar, isCollected, _, _ = C_MountJournal.GetMountInfoByID(mountId);

        if ( isCollected and shouldHideOnChar ~= true and isUsable and isFavorite ) then
            ---@type ShortMountInfo
            local mountInfo = {}
            mountInfo.name = name
            mountInfo.mountId = mountId
            mountInfo.spellId = spellId
            table.insert(favoriteMounts, mountInfo)
        end
    end

    return favoriteMounts
end

---Returns a mount's rarity value.
---@param mountId number
---@return number | nil
function RandomRareMountAddon:GetMountRarityByID(mountId)
    if ( MountsRarityAddon == nil or MountsRarityAddon.MountsRarity == nil ) then
        return nil
    end

    return MountsRarityAddon.MountsRarity[tostring(mountId)]
end

---Calculates a weighted random index for the given array.
---@param favoriteMountsWithRarities { mountInfo: ShortMountInfo, rarity: number, invertedRarity: number }[]
---@return integer | nil
function RandomRareMountAddon:WeightedRandomSelect(favoriteMountsWithRarities)
    -- based on https://gist.github.com/TeoTwawki/87d5dab7e4515f4a2981df7ea8e0a798
    -- thanks @ncg for the help in fine-tuning this!
    ---@type number
    local totalWeight = 0

    for _, mountWithRarity in ipairs(favoriteMountsWithRarities) do
        totalWeight = totalWeight + mountWithRarity.invertedRarity
    end

    local selectedWeight = math.random() * totalWeight

    local searchWeight = 0
    for i, mountWithRarity in ipairs(favoriteMountsWithRarities) do
        searchWeight = searchWeight + mountWithRarity.invertedRarity
        if (selectedWeight < searchWeight) then
            return i
        end
    end

    return nil
end

function RandomRareMountAddon:DetermineRandomFavoriteMount()
    local favoriteMounts = RandomRareMountAddon:GetFavoriteMounts()

    ---@type { mountInfo: ShortMountInfo, rarity: number, invertedRarity: number }[]
    local favoriteMountsWithRarities = {}

    for i, mountInfo in ipairs(favoriteMounts) do
        local rarity = RandomRareMountAddon:GetMountRarityByID(mountInfo.mountId)

        if (rarity ~= nil) then
            table.insert(favoriteMountsWithRarities, {
                mountInfo = mountInfo,
                rarity = rarity,
                invertedRarity = ( 1 / rarity )
            })
        else
            print("WARN: No mount data for " .. mountInfo.name)
        end
    end

    local randomIndex = RandomRareMountAddon:WeightedRandomSelect(favoriteMountsWithRarities)
    if (randomIndex == nil) then
        return nil
    end

    return favoriteMountsWithRarities[randomIndex]
end

function RandomRareMountAddon:SummonRandomFavoriteMount()
    if ( MountsRarityAddon == nil or MountsRarityAddon.MountsRarity == nil ) then
        print("RandomRareMount: MountsRarity addon not loaded.")
        return nil
    end

    local mount = RandomRareMountAddon:DetermineRandomFavoriteMount()
    if (mount == nil) then
        print("Could not determine random mount.")
        return
    end

    print("Mount " .. mount.mountInfo.name .. " is owned by " .. string.format("%.02f", mount.rarity) .. "% of players.")
    C_MountJournal.SummonByID(mount.mountInfo.mountId)
end
