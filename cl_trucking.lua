local Config = lib.require('config')
local DropOffZone, activeTrailer, pickupZone, PICKUP_BLIP, DELIVERY_BLIP
local activeRoute = {}
local droppingOff = false
local delay = false

local TruckerWork = AddBlipForCoord(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
SetBlipSprite(TruckerWork, 479)
SetBlipDisplay(TruckerWork, 4)
SetBlipScale(TruckerWork, 0.8)
SetBlipAsShortRange(TruckerWork, true)
SetBlipColour(TruckerWork, 56)
BeginTextCommandSetBlipName('STRING')
AddTextComponentSubstringPlayerName('Trucking Work')
EndTextCommandSetBlipName(TruckerWork)

local function cleanupShit()
    if DropOffZone then DropOffZone:remove() DropOffZone = nil end
    if pickupZone then pickupZone:remove() pickupZone = nil end
    if DoesBlipExist(PICKUP_BLIP) then RemoveBlip(PICKUP_BLIP) end
    if DoesBlipExist(DELIVERY_BLIP) then RemoveBlip(DELIVERY_BLIP) end

    activeTrailer, PICKUP_BLIP, DELIVERY_BLIP = nil
    table.wipe(activeRoute)
    delay = false
    droppingOff = false
end

local function getStreetandZone(coords)
    local currentStreetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
    return currentStreetName
end

local function createRouteBlip(coords, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 479)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, 3)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function viewRoutes()
    local context = {}

    local routes = lib.callback.await('randol_trucking:server:getRoutes', false)
    if not next(routes) then
        return DoNotification('You do not have any routes currently.', 'error')
    end

    for index, data in pairs(routes) do
        local isDisabled = activeRoute.index == index
        local info = ('Route: %s \nPayment: $%s'):format(getStreetandZone(data.deliver.xyz), data.payment)
        context[#context + 1] = {
            title = ('%s'):format(getStreetandZone(data.pickup.xyz)),
            description = info,
            icon = 'fa-solid fa-location-dot',
            disabled = isDisabled,
            onSelect = function()
                local choice = lib.callback.await('randol_trucking:server:chooseRoute', false, index)
                if choice and type(choice) == 'table' then
                    activeRoute = choice
                    activeRoute.index = index
                    SetRoute()
                end
            end,
        }
    end

    lib.registerContext({ id = 'view_work_routes', title = 'Work Routes', options = context })
    lib.showContext('view_work_routes')
end

local function nearZone(point)
    DrawMarker(1, point.coords.x, point.coords.y, point.coords.z - 1, 0, 0, 0, 0, 0, 0, 6.0, 6.0, 1.5, 79, 194, 247, 165, 0, 0, 0,0)
    
    if point.isClosest and point.currentDistance <= 4 then
        if not showText then
            showText = true
            lib.showTextUI('**E** - Deliver Trailer', {position = 'left-center'})
        end
        if next(activeRoute) and cache.vehicle and IsEntityAttachedToEntity(cache.vehicle, activeTrailer) then
            if IsControlJustPressed(0, 38) and not droppingOff then
                droppingOff = true
                FreezeEntityPosition(cache.vehicle, true)
                lib.hideTextUI()
                if lib.progressCircle({
                    duration = 5000,
                    position = 'bottom',
                    label = 'Dropping trailer..',
                    useWhileDead = false,
                    canCancel = false,
                    disable = { move = true, car = true, mouse = false, combat = true, },
                }) then
                    DetachEntity(activeTrailer, true, true)
                    NetworkFadeOutEntity(activeTrailer, 0, 1)
                    Wait(500)
                    lib.callback.await('randol_trucking:server:updateRoute', false, NetworkGetNetworkIdFromEntity(activeTrailer), activeRoute)
                    FreezeEntityPosition(cache.vehicle, false)
                    cleanupShit()
                end
            end
        end
    elseif showText then
        showText = false
        lib.hideTextUI()
    end
end

local function createDropoff()
    RemoveBlip(PICKUP_BLIP)
    pickupZone:remove()
    DropOffZone = lib.points.new({ coords = vec3(activeRoute.deliver.x, activeRoute.deliver.y, activeRoute.deliver.z), distance = 20, nearby = nearZone })
    DELIVERY_BLIP = createRouteBlip(activeRoute.deliver.xyz, 'Delivery Point')
    SetNewWaypoint(activeRoute.deliver.x, activeRoute.deliver.y)
    DoNotification('Your delivery route has been marked.', 'success')
    Wait(1000)
    delay = false
end

function SetRoute()
    PICKUP_BLIP = createRouteBlip(activeRoute.pickup.xyz, 'Pickup Point')
    DoNotification('Head to the pick up point and collect your trailer.')
    pickupZone = lib.points.new({ 
        coords = vec3(activeRoute.pickup.x, activeRoute.pickup.y, activeRoute.pickup.z), 
        distance = 70, 
        onEnter = function()
            if not activeTrailer then
                local success, netid = lib.callback.await('randol_trucking:server:spawnTrailer', false)
                if success and netid then
                    activeTrailer = lib.waitFor(function()
                        if NetworkDoesEntityExistWithNetworkId(netid) then
                            return NetToVeh(netid)
                        end
                    end, 'Could not load entity in time.', 3000)
                end
            end
        end,
        nearby = function()
            DrawMarker(1, activeRoute.pickup.x, activeRoute.pickup.y, activeRoute.pickup.z - 1, 0, 0, 0, 0, 0, 0, 6.0, 6.0, 1.5, 79, 194, 247, 165, 0, 0, 0,0)
            
            if cache.vehicle and IsEntityAttachedToEntity(cache.vehicle, activeTrailer) and not delay then
                delay = true
                createDropoff()
            end
        end,
    })
end

local function removePedSpawned()
    exports['qb-target']:RemoveTargetEntity(truckerPed, {'Clock In', 'Clock Out', 'View Routes', 'Pull Out Vehicle', 'Abort Route'})
    DeleteEntity(truckerPed)
    truckerPed = nil
end

local function spawnPed()
    if DoesEntityExist(truckerPed) then return end

    lib.requestModel(Config.BossModel, 2000)
    truckerPed = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
    SetEntityAsMissionEntity(truckerPed, true, true)
    SetPedFleeAttributes(truckerPed, 0, 0)
    SetBlockingOfNonTemporaryEvents(truckerPed, true)
    SetEntityInvincible(truckerPed, true)
    FreezeEntityPosition(truckerPed, true)

    exports['qb-target']:AddTargetEntity(truckerPed, { 
        options = {
            { 
                num = 1,
                icon = 'fa-solid fa-clipboard-check',
                label = 'Clock In',
                canInteract = function()
                    return not LocalPlayer.state.truckDuty
                end,
                action = function()
                    lib.callback.await('randol_trucking:server:clockIn', false)
                end,
            },
            { 
                num = 2,
                icon = 'fa-solid fa-clipboard-check',
                label = 'Clock Out',
                canInteract = function() return LocalPlayer.state.truckDuty end,
                action = function()
                    lib.callback.await('randol_trucking:server:clockOut', false)
                end,
            },
            {
                num = 3,
                icon = 'fa-solid fa-clipboard-check',
                label = 'View Routes',
                canInteract = function() return LocalPlayer.state.truckDuty end,
                action = function()
                    viewRoutes()
                end,
            },
            {
                num = 4,
                icon = 'fa-solid fa-truck',
                label = 'Pull Out Vehicle',
                canInteract = function() return LocalPlayer.state.truckDuty end,
                action = function()
                    if IsAnyVehicleNearPoint(Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, 15.0) then 
                        return DoNotification('A vehicle is blocking the spawn.', 'error') 
                    end

                    local success, coords = lib.callback.await('randol_trucking:server:spawnTruck', false)
                    if not success and coords then
                        SetNewWaypoint(coords.x, coords.y)
                        DoNotification('Your work truck is already out. It has been located on your GPS.')
                    end
                end,
            },
            {
                num = 5,
                icon = 'fa-solid fa-xmark',
                label = 'Abort Route',
                canInteract = function() return LocalPlayer.state.truckDuty and next(activeRoute) end,
                action = function()
                    local success = lib.callback.await('randol_trucking:server:abortRoute', false, activeRoute.index)
                    if success then
                        DoNotification('You aborted your current route.', 'error')
                    end
                end,
            },
        }, 
        distance = 1.5, 
    })
end

RegisterNetEvent('randol_trucking:client:clearRoutes', function()
    if GetInvokingResource() then return end
    cleanupShit()
end)

RegisterNetEvent('randol_trucking:server:spawnTruck', function(netid)
    if GetInvokingResource() or not netid then return end
    local MY_VEH = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netid) then
            return NetToVeh(netid)
        end
    end, 'Could not load entity in time.', 3000)
    
    handleVehicleKeys(MY_VEH)
    if Config.Fuel.enable then
        exports[Config.Fuel.script]:SetFuel(MY_VEH, 100.0)
    else
        Entity(MY_VEH).state.fuel = 100
    end
end)

local function createTruckingStart()
    truckingPedZone = lib.points.new({
        coords = Config.BossCoords.xyz,
        distance = 60,
        onEnter = spawnPed,
        onExit = removePedSpawned,
    })
end

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName and hasPlyLoaded() then
        OnPlayerUnload()
    end 
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource and hasPlyLoaded() then
        createTruckingStart()
    end
end)

function OnPlayerLoaded()
    createTruckingStart()
end

function OnPlayerUnload()
    if truckingPedZone then truckingPedZone:remove() truckingPedZone = nil end
    removePedSpawned()
    cleanupShit()
end
