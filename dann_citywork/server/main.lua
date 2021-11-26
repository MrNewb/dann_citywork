ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


ESX.RegisterServerCallback('dann_citywork:ServerSpawnVehicle', function(source, callback, model, coords, heading)
    if type(model) == 'string' then model = GetHashKey(model) end
    CreateThread(function()
        entity = CreateVehicle(model, coords, heading, true, false)
        while not DoesEntityExist(entity) do Wait(20) end
        netid = NetworkGetNetworkIdFromEntity(entity)
        callback(netid)
    end)
end)

RegisterNetEvent('dann_citywork:Payout', function(type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if type == 'short' then
        xPlayer.addMoney(math.random(Config.SmallAmount-50, Config.SmallAmount+50))
    elseif type == 'long' then
        xPlayer.addMoney(math.random(Config.LargeAmount-50, Config.LargeAmount+50))
    else
        print("This is being triggered without a var 🤷‍♂️")
    end
end)