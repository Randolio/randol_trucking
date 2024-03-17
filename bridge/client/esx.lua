if GetResourceState('es_extended') ~= 'started' then return end
local ox_inv = GetResourceState('ox_inventory') == 'started'

local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerLoaded = true
    OnPlayerLoaded()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    OnPlayerUnload()
end)

function hasPlyLoaded()
    return ESX.PlayerLoaded
end

function hasItem(item)
    if not ox_inv then return 0 end
    local count = exports.ox_inventory:Search('count', item)
    return count and count > 0
end

function DoNotification(text, nType)
    ESX.ShowNotification(text, nType)
end

function handleVehicleKeys(veh)
    -- ?
end