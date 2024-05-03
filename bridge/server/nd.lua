if not lib.checkDependency('ND_Core', '2.0.0') then return end

local NDCore = exports["ND_Core"]

function GetPlayer(id)
    return NDCore:getPlayer(id)
end

function DoNotification(src, text, nType)
    local player = NDCore:getPlayer(src)
    return player and player.notify({ type = nType, description = text })
end

function GetPlyIdentifier(player)
    return player?.id
end

function GetSourceFromIdentifier(cid)
    local players = NDCore:getPlayers()
    for _, info in pairs(players) do
        if info.id == cid then
            return info.source
        end
    end
    return false
end

function GetCharacterName(Player)
    return player?.fullname
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
    return exports.ox_inventory:Items(item).label
end

AddEventHandler("ND:characterLoaded", function(character)
    if not character then return end
    OnPlayerLoaded(character.source)
end)

AddEventHandler("ND:characterUnloaded", function(src, character)
    OnPlayerUnload(src)
end)
