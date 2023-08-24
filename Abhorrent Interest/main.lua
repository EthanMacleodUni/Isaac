-- Register Mod
local mod = RegisterMod("Abhorrent Interest", 1)

------------ CONSTANTS ------------
local ABHORRENT_INTEREST_ID = Isaac.GetItemIdByName("Abhorrent Interest") -- Item ID
local INITIAL_DAMAGE = 0.2                                                -- Starting point of damage up
local MAX_DAMAGE = 3000;                                                  -- Most damage before U_I stops spawning
-----------------------------------

-- Initialise spawn chance
local spawnChance = 0.15
local spawnChanceIncrease = 0.05

-- Number of current AI's
local pickedUpAI = 0

local newFloor = false


-- Add to External Item Descriptions
EID:addCollectible(ABHORRENT_INTEREST_ID,
    "↑ {{Damage}} Damage up#Damage increases for every Abhorrent Interest owned#Will appear more often once picked up",
    "Abhorrent Interest")

------------ Adds damage to Player ------------
--@param player - Player object
--@param cacheFlags - player stats cache
function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(ABHORRENT_INTEREST_ID) -- Gets number of items
        local damageToAdd = INITIAL_DAMAGE *
            (2 ^ itemCount)                                               -- Adds exponential damage to player cache (i*2^n)
        player.Damage = player.Damage + damageToAdd                       -- Adds damage to player cache
    end
end

-----------------------------------------------

------------ Controls spawning of Abhorrent Interest ------------
function mod:UISpawning()
    local entities = Isaac.GetRoomEntities()
    local player = Isaac.GetPlayer(0)

    for _, entity in ipairs(entities) do
        if mod:CanSpawn(entity, player) then
            local pos = entity.Position
            entity:Remove()
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, ABHORRENT_INTEREST_ID, pos,
                Vector(0, 0),
                nil)
            spawnChance = spawnChance + spawnChanceIncrease
        end
    end
end

-------------------------------------------------------------

------------ Checks spawn conditions ------------
-- @param entity - an entity in the room (eg. pedestal)
-- @param player - player object
-- @returns: true if UI can spawn. false if UI cannot spawn
function mod:CanSpawn(entity, player)
    local room = Game():GetRoom()
    local rng = player:GetCollectibleRNG(ABHORRENT_INTEREST_ID)

    if room:IsFirstVisit() and mod:HasAI(player) then
        if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and (rng:RandomFloat() < spawnChance) and (player.Damage < MAX_DAMAGE) then
            return true
        end
    end
    return false
end

-------------------------------------------------

------------ Check if player has the Abhorrent Interest collectible ------------
-- @param player - player object
-- @returns: true if player has AI. false if player doesnt have AI
function mod:HasAI(player)
    if player:HasCollectible(ABHORRENT_INTEREST_ID, true) then
        return true
    end
    return false
end

-----------------------------------------------------------------------------

------------ Checks and applies "Interest" ------------
function mod:HandleInterest()
    local player = Isaac.GetPlayer(0)

    if mod:HasAI(player) then
        local numAI = player:GetCollectibleNum(ABHORRENT_INTEREST_ID)

        if (numAI - pickedUpAI) == 0 then
            Game():AddPixelation(0)
            Game():GetHUD():ShowFortuneText("Pay the interest", "Or pay the price")
            player:AnimateSad()
            local currentCoins = player:GetNumCoins()

            if (currentCoins < numAI) and player:GetName() ~= "Keeper" then
                player:AddCoins(-currentCoins)
                player:TakeDamage((numAI - currentCoins), DamageFlag.DAMAGE_RED_HEARTS, EntityRef(player), 0)
            else
                player:AddCoins(-numAI)
            end
        end
        pickedUpAI = numAI
    end
end

------------------------------------------------------

------------ Add callbacks ------------
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.UISpawning)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.HandleInterest)
---------------------------------------
