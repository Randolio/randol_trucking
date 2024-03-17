if GetResourceState('es_extended') ~= 'started' then return end
local ox_inv = GetResourceState('ox_inventory') == 'started'

local ESX = exports['es_extended']:getSharedObject()

function GetPlayer(id)
    return ESX.GetPlayerFromId(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('esx:showNotification', src, text, nType)
end

function GetPlyIdentifier(xPlayer)
    return xPlayer.identifier
end

function GetSourceFromIdentifier(cid)
    local xPlayer = ESX.GetPlayerFromIdentifier(cid)
    return xPlayer and xPlayer.source or false
end

function GetCharacterName(xPlayer)
    return xPlayer.getName()
end

function AddItem(xPlayer, item, amount)
    if ox_inv then
        exports.ox_inventory:AddItem(xPlayer.source, item, amount)
    end
end

function RemoveItem(xPlayer, item, amount)
    if ox_inv then
        exports.ox_inventory:RemoveItem(xPlayer.source, item, amount)
    end
end

function AddMoney(xPlayer, moneyType, amount)
    local account = moneyType == 'cash' and 'money' or moneyType
    xPlayer.addAccountMoney(account, amount)
end

function itemCount(xPlayer, item)
    if not ox_inv then return 0 end

    local count = exports.ox_inventory:GetItemCount(xPlayer.source, item)
    return count
end

function itemLabel(item)
    return exports.ox_inventory:Items()[item].label
end

AddEventHandler('esx:playerLogout', function(playerId)
    OnPlayerUnload(playerId)
end)

AddEventHandler('esx:playerLoaded', function(source)
    OnPlayerLoaded(source)
end)
