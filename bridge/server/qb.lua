if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()
local ox_inv = GetResourceState('ox_inventory') == 'started'

function GetPlayer(id)
    return QBCore.Functions.GetPlayer(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('QBCore:Notify', src, text, nType)
end

function GetPlyIdentifier(Player)
    return Player.PlayerData.citizenid
end

function GetSourceFromIdentifier(cid)
    local Player = QBCore.Functions.GetPlayerByCitizenId(cid)
    return Player and Player.PlayerData.source or false
end

function GetCharacterName(Player)
    return Player.PlayerData.charinfo.firstname.. ' ' ..Player.PlayerData.charinfo.lastname
end

function AddItem(Player, item, amount)
    if ox_inv then
        exports.ox_inventory:AddItem(Player.PlayerData.source, item, amount)
    else
        Player.Functions.AddItem(item, amount, false)
        TriggerClientEvent("inventory:client:ItemBox", Player.PlayerData.source, QBCore.Shared.Items[item], "add", amount)
    end
end

function RemoveItem(Player, item, amount)
    if ox_inv then
        exports.ox_inventory:RemoveItem(Player.PlayerData.source, item, amount)
    else
        Player.Functions.RemoveItem(item, amount)
        TriggerClientEvent("inventory:client:ItemBox", Player.PlayerData.source, QBCore.Shared.Items[item], "remove", amount)
    end
end

function AddMoney(Player, moneyType, amount)
    Player.Functions.AddMoney(moneyType, amount)
end

function itemCount(Player, item)
    local count = 0
    if ox_inv then 
        count = exports.ox_inventory:GetItemCount(Player.PlayerData.source, item)
    else
        for _, data in pairs(Player.PlayerData.items) do -- Apparently qb only counts the amount from the first slot so I gotta do this.
            if data.name == item then
                count += data.amount
            end
        end
    end
    return count
end

function itemLabel(item)
    local label = ox_inv and exports.ox_inventory:Items()[item].label or QBCore.Shared.Items[item].label
    return label
end

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(source)
    OnPlayerUnload(source)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    OnPlayerLoaded(source)
end)