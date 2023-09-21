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
---@alias MountFilter fun(name: string, spellID: number, isActive: boolean, sourceType: number, isFavorite: boolean, isFactionSpecific: boolean, faction: number?, isForDragonriding: boolean): boolean

---@param filter MountFilter
function RandomRareMountAddon:GetMounts(filter)
    ---@type ShortMountInfo[]
    local selectedMounts = {}
    if type(filter) ~= "function" then
        return selectedMounts
    end
    local journal = C_MountJournal

    local mountIDs = journal.GetMountIDs()

    for _, mountID in ipairs(mountIDs) do
        local name, spellID, _, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, _, isForDragonriding = journal.GetMountInfoByID(mountID)

        if isUsable and shouldHideOnChar ~= true and isCollected then
            local couldSelect = filter(name, spellID, isActive, sourceType, isFavorite, isFactionSpecific, faction, isForDragonriding)

            if couldSelect then
                ---@type ShortMountInfo
                local mountInfo = {}
                mountInfo.name = name
                mountInfo.mountId = mountID
                mountInfo.spellId = spellID
                table.insert(selectedMounts, mountInfo)
            end
        end
    end

    return selectedMounts
end

function RandomRareMountAddon:GetAllMounts()
    ---@type MountFilter
    local filter = function (_, _, isActive, _, _, _, _, _)
        return isActive ~= true
    end

    return self:GetMounts(filter)
end

---Returns the player's favorite mounts from the mount journal.
function RandomRareMountAddon:GetFavoriteMounts()
    ---@type MountFilter
    local filter = function (_, _, isActive, _, isFavorite, _, _, _)
        return isActive ~= true and isFavorite
    end

    return self:GetMounts(filter)
end

---Calculates a weighted random index for the given array.
---@param favoriteMountsWithRarities { mountInfo: ShortMountInfo, rarity: number, invertedRarity: number }[]
---@return integer | nil, number|nil
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
            return i, (mountWithRarity.invertedRarity / totalWeight)
        end
    end

    return nil, nil
end

---@param mountList ShortMountInfo[]
function RandomRareMountAddon:DetermineRandomMount(mountList)
    ---@type { mountInfo: ShortMountInfo, rarity: number, invertedRarity: number }[]
    local mountsWithRarities = {}

    for i, mountInfo in ipairs(mountList) do
        local rarity = libMountsRarity:GetRarityByID(mountInfo.mountId)

        if (rarity ~= nil) then
            table.insert(mountsWithRarities, {
                mountInfo = mountInfo,
                rarity = rarity,
                invertedRarity = ( 1 / rarity )
            })
        else
            self:Print("WARN: No mount data for " .. mountInfo.name)
        end
    end

    local randomIndex, chance = self:WeightedRandomSelect(mountsWithRarities)
    if (randomIndex == nil) then
        return nil, nil
    end

    return mountsWithRarities[randomIndex], chance
end

---@type ShortMountInfo[]
function RandomRareMountAddon:SummonRandomMount(mountList)
    local mount, chance = self:DetermineRandomMount(mountList)
    if (mount == nil) then
        self:Print("Could not determine random mount.")
        return
    end

    local owningPercentage = string.format("%.02f", mount.rarity)
    local chancePercentage = string.format("%.02f", chance * 100)
    self:Print(mount.mountInfo.name .. " owned by " .. owningPercentage .. "%. Chance to summon: " .. chancePercentage .. "%.")

    C_MountJournal.SummonByID(mount.mountInfo.mountId)
end

function RandomRareMountAddon:SlashCommands(args)
    local arg1 = self:GetArgs(args, 1)

    ---@type ShortMountInfo[]
    local potentialMounts = {}
    if arg1 and string.upper(arg1) == "FAVORITE" then
        potentialMounts = self:GetFavoriteMounts()
    else
        potentialMounts = self:GetAllMounts()
    end
    self:SummonRandomMount(potentialMounts)
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
