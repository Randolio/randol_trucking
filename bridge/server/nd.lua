if not lib.checkDependency('ND_Core', '2.0.0') then return end

NDCore = {}

lib.load('@ND_Core.init')

function GetPlayer(id)
    return NDCore.getPlayer(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('ox_lib:notify', src, { type = nType, description = text })
end

function GetPlyIdentifier(Player)
    return Player.identifier
end

function GetCharacterName(Player)
    return Player.fullname
end

function GetSourceFromIdentifier(cid)
    local Player = NDCore.Functions.GetPlayerByCharacterId(cid)
    return Player and Player.source or false
end

function AddItem(Player, item, amount)
    exports.ox_inventory:AddItem(Player.source, item, amount)
end

function RemoveItem(Player, item, amount)
    exports.ox_inventory:RemoveItem(Player.source, item, amount)
end

function AddMoney(Player, moneyType, amount)
    Player.addMoney(moneyType, amount)
end

function itemCount(Player, item)
    local count = exports.ox_inventory:GetItemCount(Player.source, item)
    return count
end

function itemLabel(item)
    return exports.ox_inventory:Items()[item].label
end

AddEventHandler("ND:characterLoaded", function(character)
    if not character then return end
    OnPlayerLoaded(character.source)
end)

AddEventHandler("ND:characterUnloaded", function(src, character)
    OnPlayerUnload(src)
end)