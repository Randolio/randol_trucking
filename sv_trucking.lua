local Server = lib.require('sv_config')
local Config = lib.require('config')
local storedRoutes = {}
local queue = {}
local spawnedTrailers = {}

local function removeFromQueue(cid)
    for i, cids in ipairs(queue) do
        if cids == cid then
            table.remove(queue, i)
            break
        end
    end
end

local function createTruckingVehicle(source, model, warp, coords)
    if not coords then coords = Config.VehicleSpawn end

    -- CreateVehicleServerSetter can be funky and I cba, especially for a temp vehicle. Cry about it. I just need the entity handle.
    local vehicle = CreateVehicle(joaat(model), coords.x, coords.y, coords.z, coords.w, true, true)
    local ped = GetPlayerPed(source)

    while not DoesEntityExist(vehicle) do Wait(0) end 

    if warp then
        while GetVehiclePedIsIn(ped, false) ~= vehicle do
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
            Wait(100)
        end
    end

    return vehicle
end

local function resetEverything()
    local players = GetPlayers()
    if #players > 0 then
        for i = 1, #players do
            local src = tonumber(players[i])
            local player = GetPlayer(src)

            if player then
                if Player(src).state.truckDuty then
                    Player(src).state:set('truckDuty', false, true)
                end
                local cid = GetPlyIdentifier(player)
                if storedRoutes[cid] and storedRoutes[cid].vehicle and DoesEntityExist(storedRoutes[cid].vehicle) then
                    DeleteEntity(storedRoutes[cid].vehicle)
                end
            end

            if spawnedTrailers[src] and DoesEntityExist(spawnedTrailers[src]) then
                DeleteEntity(spawnedTrailers[src])
            end
        end
    end
end

local function generateRoute(cid)
    local data = {}
    data.pickup = Server.Pickups[math.random(#Server.Pickups)] 
    data.payment = math.random(Server.Payment.min, Server.Payment.max)
    repeat
        data.deliver = Server.Deliveries[math.random(#Server.Deliveries)]

        local found = false
        for _, route in ipairs(storedRoutes[cid].routes) do
            if route.deliver == data.deliver then
                found = true
                break
            end
        end

        if not found then break end
    until false

    return data
end

lib.callback.register('randol_trucking:server:clockIn', function(source)
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)

    if storedRoutes[cid] then
        DoNotification(src, 'You have already clocked in. Check your routes.')
        return false
    end

    queue[#queue+1] = cid
    storedRoutes[cid] = { routes = {}, vehicle = 0, }
    Player(src).state:set('truckDuty', true, true)

    DoNotification(src, 'You have clocked in for trucking work. Look out for job notifications or check your current routes.', 'success', 7000)
    return true
end)

lib.callback.register('randol_trucking:server:clockOut', function(source) 
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)

    if not storedRoutes[cid] or not Player(src).state.truckDuty then
        DoNotification(src, 'You are not clocked in to the trucking job.', 'error')
        return false
    end

    local workTruck = storedRoutes[cid].vehicle
    local workTrailer = spawnedTrailers[src]

    if workTruck and DoesEntityExist(workTruck) then DeleteEntity(workTruck) end
    if workTrailer and DoesEntityExist(workTrailer) then DeleteEntity(workTrailer) end

    removeFromQueue(cid)
    storedRoutes[cid] = nil
    Player(src).state:set('truckDuty', false, true)
    TriggerClientEvent('randol_trucking:client:clearRoutes', src)
    DoNotification(src, 'You have clocked out and cleared all your routes.', 'success')
    return true
end)

lib.callback.register('randol_trucking:server:spawnTruck', function(source) 
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)

    if not storedRoutes[cid] or not Player(src).state.truckDuty then
        DoNotification(src, 'You are not clocked in to the trucking job.', 'error')
        return false
    end

    local workTruck = storedRoutes[cid].vehicle

    if DoesEntityExist(workTruck) then
        local coords = GetEntityCoords(workTruck)
        return false, coords
    end

    local model = Server.Trucks[math.random(#Server.Trucks)]
    local vehicle = createTruckingVehicle(src, model, true)

    storedRoutes[cid].vehicle = vehicle
    DoNotification(src, 'You have pulled out your work truck. Check out your current routes or wait for one to come through.', 'success')
    TriggerClientEvent('randol_trucking:server:spawnTruck', src, NetworkGetNetworkIdFromEntity(vehicle))
    return true
end)

lib.callback.register('randol_trucking:server:spawnTrailer', function(source) 
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)

    if not storedRoutes[cid] or not Player(src).state.truckDuty then return false end

    local model = Server.Trailers[math.random(#Server.Trailers)]
    local coords = storedRoutes[cid].currentRoute.pickup
    local trailer = createTruckingVehicle(src, model, false, coords)

    spawnedTrailers[src] = trailer
    return true, NetworkGetNetworkIdFromEntity(trailer)
end)

lib.callback.register('randol_trucking:server:chooseRoute', function(source, index) 
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)

    if not storedRoutes[cid] or not Player(src).state.truckDuty then return false end

    if spawnedTrailers[src] or storedRoutes[cid].currentRoute then
        DoNotification(src, 'You already have an active route to complete.', 'success')
        return false 
    end

    storedRoutes[cid].currentRoute = storedRoutes[cid].routes[index]
    storedRoutes[cid].currentRoute.index = index

    return storedRoutes[cid].currentRoute
end)

lib.callback.register('randol_trucking:server:getRoutes', function(source) 
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)

    if not storedRoutes[cid] or not Player(src).state.truckDuty then return false end

    return storedRoutes[cid].routes
end)

lib.callback.register('randol_trucking:server:updateRoute', function(source, netid, route)
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)
    local pos = GetEntityCoords(GetPlayerPed(src))
    local entity = NetworkGetEntityFromNetworkId(netid)
    local coords = GetEntityCoords(entity)
    local data = storedRoutes[cid]

    if not data or not DoesEntityExist(entity) or #(coords - data.currentRoute.deliver.xyz) > 15.0 or #(pos - data.currentRoute.deliver.xyz) > 15.0 then 
        return false 
    end

    if spawnedTrailers[src] == entity and route.index == data.currentRoute.index then
        AddMoney(player, 'cash', data.currentRoute.payment)
        DoNotification(src, ('You finished the route and received $%s'):format(data.currentRoute.payment), 'success', 7000)
        DeleteEntity(entity)
        spawnedTrailers[src] = nil
        data.currentRoute = nil
        table.remove(data.routes, route.index)
    end
end)

lib.callback.register('randol_trucking:server:abortRoute', function(source, index)
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)

    if not storedRoutes[cid] or not Player(src).state.truckDuty then return false end

    local data = storedRoutes[cid]

    if data.currentRoute and data.currentRoute.index == index then
        if spawnedTrailers[src] and DoesEntityExist(spawnedTrailers[src]) then
            DeleteEntity(spawnedTrailers[src])
            spawnedTrailers[src] = nil
        end
        data.currentRoute = nil
        table.remove(data.routes, index)
        TriggerClientEvent('randol_trucking:client:clearRoutes', src)
        return true
    end

    return false
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    resetEverything()
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Player(src).state.truckDuty then
        Player(src).state:set('truckDuty', false, true)
        if spawnedTrailers[src] and DoesEntityExist(spawnedTrailers[src]) then
            DeleteEntity(spawnedTrailers[src])
        end
    end
end)

function OnPlayerLoaded(source)
    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)
    
    if storedRoutes[cid] then
        Player(src).state:set('truckDuty', true, true)
    end
end

function OnPlayerUnload(source)
    local src = source
    if Player(src).state.truckDuty then
        Player(src).state:set('truckDuty', false, true)
        if spawnedTrailers[src] and DoesEntityExist(spawnedTrailers[src]) then
            DeleteEntity(spawnedTrailers[src])
        end
    end
end

local function initQueue()
    if #queue == 0 then return end

    for i = 1, #queue do
        local cid = queue[i]
        local src = GetSourceFromIdentifier(cid)
        local player = GetPlayer(src)
        if player and Player(src).state.truckDuty then
            if #storedRoutes[cid].routes < 5 then
                storedRoutes[cid].routes[#storedRoutes[cid].routes + 1] = generateRoute(cid)
                DoNotification(src, 'A new route has been added to your current routes.')
            end
        end
    end
end

SetInterval(initQueue, Server.QueueTimer * 60000)