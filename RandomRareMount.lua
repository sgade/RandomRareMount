--[[
--  RandomRareMount.lua
--
--  Copyright (c) 2023 Sören Gade
]]--

---@class AceAddon
local RandomRareMountAddon = LibStub:GetLibrary("AceAddon-3.0"):NewAddon("RandomRareMount", "AceConsole-3.0", "AceEvent-3.0")
if not RandomRareMountAddon then return end

---@class MountsRarity: { GetData: function, GetRarityByID: function }
local libMountsRarity = LibStub:GetLibrary("MountsRarity-2.0", true)
if not libMountsRarity then
    RandomRareMountAddon:Print("ERROR: Required library MountsRarity not found.")
    return
end

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
        local rarity = libMountsRarity:GetRarityByID(mountInfo.mountId)

        if (rarity ~= nil) then
            table.insert(favoriteMountsWithRarities, {
                mountInfo = mountInfo,
                rarity = rarity,
                invertedRarity = ( 1 / rarity )
            })
        else
            self:Print("WARN: No mount data for " .. mountInfo.name)
        end
    end

    local randomIndex = RandomRareMountAddon:WeightedRandomSelect(favoriteMountsWithRarities)
    if (randomIndex == nil) then
        return nil
    end

    return favoriteMountsWithRarities[randomIndex]
end

function RandomRareMountAddon:SummonRandomFavoriteMount()
    if ( libMountsRarity == nil or libMountsRarity.GetData() == nil ) then
        self:Print("MountsRarity addon not loaded.")
        return nil
    end

    local mount = RandomRareMountAddon:DetermineRandomFavoriteMount()
    if (mount == nil) then
        self:Print("Could not determine random mount.")
        return
    end

    self:Print("Mount " .. mount.mountInfo.name .. " is owned by " .. string.format("%.02f", mount.rarity) .. "% of players.")
    C_MountJournal.SummonByID(mount.mountInfo.mountId)
end

function RandomRareMountAddon:SlashCommands(args)
    local arg1 = self:GetArgs(args, 1)

    if arg1 and string.upper(arg1) == "FAVORITES" then
        self:SummonRandomFavoriteMount()
    else
        -- TODO: implement
        self:Print("Random across all mounts is not yet implemented.")
    end
end

-- Lifecycle events

function RandomRareMountAddon:OnInitialize()
    -- stub
end

function RandomRareMountAddon:OnEnable()
    self:RegisterChatCommand("randomraremount", "SlashCommands")
    self:RegisterChatCommand("rrm", "SlashCommands")
end

function RandomRareMountAddon:OnDisable()
    self:UnregisterChatCommand("randomraremount")
    self:UnregisterChatCommand("rrm")
end
