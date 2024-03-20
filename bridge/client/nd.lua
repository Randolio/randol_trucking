if not lib.checkDependency('ND_Core', '2.0.0') then return end

NDCore = {}

lib.load('@ND_Core.init')

RegisterNetEvent('ND:characterUnloaded', function()
    LocalPlayer.state.isLoggedIn = false
    OnPlayerUnload()
end)

RegisterNetEvent('ND:characterLoaded', function(character)
    LocalPlayer.state.isLoggedIn = true
    OnPlayerLoaded()
end)

function hasPlyLoaded()
    return LocalPlayer.state.isLoggedIn
end

function hasItem(item)
    local count = exports.ox_inventory:Search('count', item)
    return count and count > 0
end

function DoNotification(text, nType)
    lib.notify({ title = "Notification", description = text, type = nType, })
end

function handleVehicleKeys(veh)
    -- ?
end