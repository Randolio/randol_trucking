if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()
local ox_inv = GetResourceState('ox_inventory') == 'started'

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    OnPlayerLoaded()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    OnPlayerUnload()
end)

function hasPlyLoaded()
    return LocalPlayer.state.isLoggedIn
end

function hasItem(item)
    if ox_inv then
        local count = exports.ox_inventory:Search('count', item)
        return count and count > 0
    else
        return QBCore.Functions.HasItem(item)
    end
end

function DoNotification(text, nType)
    QBCore.Functions.Notify(text, nType)
end

function handleVehicleKeys(veh)
    local plate = GetVehicleNumberPlateText(veh)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
end