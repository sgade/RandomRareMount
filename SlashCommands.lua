--[[
--  SlashCommands.lua
--
--  Copyright (c) 2023 Sören Gade
]]--

SLASH_RANDOMRAREMOUNT1 = "/rrm"
SLASH_RANDOMRAREMOUNT2 = "/randomraremount"

SlashCmdList["RANDOMRAREMOUNT"] = function(msg)
    RandomRareMountAddon:SummonRandomFavoriteMount()
end
