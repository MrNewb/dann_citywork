local ESX = exports['es_extended']:getSharedObject()
local Status = nil
local SetBlips = {}
local hasInspected = false
local JobType = ''
local fetchingPart = false
local boxville = nil
local partCollected = false
local attachedProp = 0

-- NPC Handling --

local coords = {
    {Config.NPC.x,Config.NPC.y,Config.NPC.z,"",Config.NPC.h,0xEE75A00F,"s_m_y_garbage"},
}

CreateThread(function()
    for _,v in pairs(coords) do
      RequestModel(GetHashKey(v[7]))
      while not HasModelLoaded(GetHashKey(v[7])) do
        Wait(1)
      end
      ped = CreatePed(4, v[6],v[1],v[2],v[3], 3374176, false, true)
      SetEntityHeading(ped, v[5])
      FreezeEntityPosition(ped, true)
      SetEntityInvincible(ped, true)
      SetBlockingOfNonTemporaryEvents(ped, true)
    end
end)

-- Default Stuff

exports.qtarget:AddBoxZone("cityworks", vector3(927.2202, -1560.2773, 30.9384), 1.0, 1.0, {
	name="cityworks",
	heading=92.0,
	debugPoly=false,
	minZ=29.9384,
	maxZ=31.9384,
	}, {
		options = {
			{
				event = "dann_citywork:StartJob",
				icon = "fas fa-bolt",
				label = "Start Job",
                job = 'cityworks',
                canInteract = function(entity)
                    if Status == nil then
                        return true
                    end
                end
			},
            {
				event = "dann_citywork:CancelJob",
				icon = "fas fa-window-close",
				label = "End Job",
                job = 'cityworks',
                canInteract = function(entity)
                    if Status ~= nil then
                        return true
                    end
                end
			},
		},
	distance = 2.0
})


AddEventHandler('dann_citywork:StartJob', function()
    Status = 1
    ESX.TriggerServerCallback('dann_citywork:ServerSpawnVehicle', function(vehicle)

        while not NetworkDoesEntityExistWithNetworkId(vehicle) do Wait(25) end
                    
        vehicle = NetToVeh(vehicle)
        TriggerEvent('dann_citywork:setVehicle', vehicle)
    end,'boxville', vector3(922.3655, -1563.7789, 30.7371), 89.8603)
end)

AddEventHandler('dann_citywork:CancelJob', function(data)
    Status = nil
    exports['mythic_notify']:SendAlert('error', 'Job has been cancelled')
    ESX.Game.DeleteVehicle(boxville)
    RemoveAllBlips()
end)

AddEventHandler('dann_citywork:setVehicle', function(vehicle)
    boxville = vehicle

    CreateThread(function()
		exports['mythic_notify']:SendAlert('inform', 'Collect your Utility Van!')
		while (Status == 1) do
			local vehPos = GetEntityCoords(vehicle)
			local Veh = GetVehiclePedIsIn(PlayerPedId(), false)
            local sentModel = 'boxville'
			if Veh == boxville then
				TriggerEvent('dann_citywork:requestLocation')
				break
			end
			Wait(0)
		end
	end)
end)

AddEventHandler('dann_citywork:requestLocation', function()
    JobType = ''
    hasInspected = false
    if Status == 1 then
        Status = 2
        location = Config.WorkLocations[math.random(1, #Config.WorkLocations)]
        exports['mythic_notify']:SendAlert('inform', 'Go to '..location.Display..' Refinery, Marked on your GPS!', 5000)
        CreateBlip(location.Waypoint,354,0.8,28,'Work Location',workLocation)
        CreateThread(function()
            while Status == 2 do
                local dist = #(GetEntityCoords(PlayerPedId()) - location.Waypoint)
                if dist < 40 then
                    exports.mythic_notify:SendAlert('inform', "Hey! You're getting close to the area. Get over there an fix some shit!", 5000)
                    TriggerEvent('dann_citywork:WorkArea')
                    break
                end
                Wait(0)
            end
        end)
    end
end)


AddEventHandler('dann_citywork:WorkArea', function()
    Status = 3
    print(location.Area)
    CreateThread(function()
        while true do
            local dist = #(GetEntityCoords(PlayerPedId()) - location.Area)
            if dist < 2 then
                if Status == 3 and not hasInspected then
                    TriggerEvent('luke_textui:ShowUI', '[E] Inspect Part', 'IndianRed')
                    JobType = 'inspect'
                else
                    TriggerEvent('luke_textui:ShowUI', '[E] Attempt Fix', 'LightSalmon')
                    JobType = 'attempt'
                end
                if IsControlJustPressed(0, 38) then
                    if JobType == 'inspect' then
                        TriggerEvent('dann_citywork:Inspect')
                        TriggerEvent('luke_textui:HideUI')
                        hasInspected = true
                        break
                    elseif JobType == 'attempt' then
                        TriggerEvent('dann_citywork:AttempFix')
                        TriggerEvent('luke_textui:HideUI')
                        break
                    end
                end
            else
                TriggerEvent('luke_textui:HideUI')
            end
            Wait(5)
        end
    end)
end)

AddEventHandler('dann_citywork:Inspect', function()
    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 25000,
        label = "Inspecting Part",
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = false,
        },
        animation = {
            animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
            anim = "machinic_loop_mechandplayer",
        },
    })
    Wait(25000)
    ClearPedTasks(PlayerPedId())
    TriggerEvent('dann_citywork:GetResults')
end)

AddEventHandler('dann_citywork:GetResults', function()
    Wait(500)
    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 15000,
        label = "Getting Results",
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = false,
        },
        animation = {
            animDict = "missfam4",
            anim = "base",
        },
        prop = {
            model = "p_amb_clipboard_01",
        }
    })
    Wait(15000)
    ClearPedTasks(PlayerPedId())

    RandEff = math.random(1, 100)

	local menu = {}
    table.insert(menu, {
        id = 0,
        header = "LS Water & Power Clipboard",
        txt = ""
    })

    if RandEff <= 75 then
        table.insert(menu, {
			id = 1,
			header = 'Effeciency : '..RandEff..'%',
			txt = 'Result : Repair Required',
		})
        TriggerEvent('nh-context:sendMenu', menu)
        Wait(5000)
        TriggerEvent('dann_citywork:WorkArea')
        JobType = 'attempt'
    else
        table.insert(menu, {
			id = 1,
			header = 'Effeciency : '..RandEff..'%',
			txt = 'Result : No repairs required',
		})
        exports.mythic_notify:SendAlert('inform', 'This unit doesn\'t require repairs')
        JobStatus = 1
        RemoveAllBlips()
        TriggerEvent('dann_citywork:requestLocation')
    end
    
end)

AddEventHandler('dann_citywork:AttempFix', function()
    if partCollected then
        TriggerEvent('dann_citywork:CancelAnim')
    end
    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 30000,
        label = "Fixing Part",
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = false,
        },
        animation = {
            animDict = "mini@repair",
            anim = "fixing_a_ped",
        },
    })
    Wait(30000)
    ClearPedTasks(PlayerPedId())
    if not partCollected then
        chance = math.random(1, 10)
        print(chance)
        if chance > 2 then
            fetchingPart = true
            exports.mythic_notify:SendAlert('error', 'Shit, looks like you broke a piece off. Get a spare from the van and fix it')
        else
            JobType = ''
            RemoveAllBlips()
            TriggerEvent('luke_textui:ShowUI', 'Status : Part Fixed', 'SeaGreen')
            TriggerServerEvent('dann_citywork:Payout', 'short')
            Wait(5000)
            TriggerEvent('luke_textui:HideUI')
            Status = 1
            TriggerEvent('dann_citywork:requestLocation')
        end
    else
        partCollected = false
        JobType = ''
        RemoveAllBlips()
        TriggerServerEvent('dann_citywork:Payout', 'long')
        TriggerEvent('luke_textui:ShowUI', 'Status : Part Fixed', 'SeaGreen')
        Wait(5000)
        TriggerEvent('luke_textui:HideUI')
        Status = 1
        TriggerEvent('dann_citywork:requestLocation')
    end
end)

AddEventHandler('dann_citywork:CollectSpare', function()
    fetchingPart = false
    TriggerEvent("mythic_progbar:client:progress", {
        name = "unique_action_name",
        duration = 12500,
        label = "Finding Spare Part",
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = false,
        },
        animation = {
            animDict = "mini@repair",
            anim = "fixing_a_ped",
        },
    })
    Wait(12500)
    ClearPedTasks(PlayerPedId())
    exports.mythic_notify:SendAlert('inform', 'Part Collected')
    partCollected = true
    TriggerEvent('dann_citywork:WorkArea')
    Wait(1000)
    TriggerEvent('dann_citywork:SparePartAnim')
end)

exports.qtarget:AddTargetBone({"seat_pside_r","seat_dside_r"}, {
	options = {
		{
			event = "dann_citywork:CollectSpare",
			icon = "fas fa-toolbox",
			label = "Collect Spare Part",
			canInteract = function(entity)
                if entity == boxville and fetchingPart then
                    return true
                end
            end
		},
	},
	distance = 2
})


-- Job Animation --


AddEventHandler('dann_citywork:CancelAnim', function()
    FreezeEntityPosition(PlayerPedId(),false)
    removeAttachedProp()
    ClearPedTasks(PlayerPedId())
end)

AddEventHandler('dann_citywork:SparePartAnim', function()
    local coords = GetEntityCoords(GetPlayerPed(-1))
	local animDict = "anim@heists@box_carry@"
	local animation = "idle"

    attachAProp("prop_champ_box_01", 60309, 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, 0.0, false, false, false, false, 2, true)

    loadAnimDict(animDict)
	local animLength = GetAnimDuration(animDict, animation)
	TaskPlayAnim(PlayerPedId(), animDict, animation, 1.0, 4.0, animLength, 51, 0, 0, 0, 0)
end)

function attachAProp(attachModelSent,boneNumberSent,x,y,z,xR,yR,zR)
	removeAttachedProp()
	attachModel = GetHashKey(attachModelSent)
	boneNumber = boneNumberSent 
	local bone = GetPedBoneIndex(PlayerPedId(), boneNumberSent)
	RequestModel(attachModel)
	while not HasModelLoaded(attachModel) do
		Citizen.Wait(100)
	end
	attachedProp = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
	AttachEntityToEntity(attachedProp, PlayerPedId(), bone, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
	SetModelAsNoLongerNeeded(attachModel)
end

function removeAttachedProp()
	DeleteEntity(attachedProp)
	attachedProp = 0
end

function loadModel(modelName)
    RequestModel(GetHashKey(modelName))
    while not HasModelLoaded(GetHashKey(modelName)) do
        RequestModel(GetHashKey(modelName))
        Citizen.Wait(1)
    end
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end



-- Blip Functions

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    if job ~= nil then
        if PlayerData == nil then
            PlayerData = ESX.GetPlayerData()
        end
    end

    PlayerData.job = job

    if PlayerData.job.name == 'cityworks' then
        CWBlip()
    else
        RemoveBlip(lockerBlip)
        return
    end
end)

CreateThread(function()
    if ESX ~= nil then
        PlayerData = ESX.GetPlayerData()
        if PlayerData.job ~= nil and PlayerData.job.name == 'cityworks' then
            CWBlip()
        end
    end
end)

function CWBlip()
    if DoesBlipExist(lockerBlip) then
        return
    else
        lockerblip = AddBlipForCoord(vector3(927.2202, -1560.2773, 30.9384))

        SetBlipSprite(lockerblip, 351)
        SetBlipScale(lockerblip, 0.9)
        SetBlipColour(lockerblip, 28)
        SetBlipAsShortRange(lockerblip, true)
    
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('City Works Locker')
        EndTextCommandSetBlipName(lockerblip)
    end
end

function CreateBlip(coords,sprite,scale,colour,name,uid)
    uid = AddBlipForCoord(coords)

    SetBlipSprite(uid, sprite)
    SetBlipScale(uid, scale)
    SetBlipColour(uid, colour)
    SetBlipAsShortRange(uid, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(uid)
    
    table.insert(SetBlips, uid)
end

function RemoveAllBlips()
	if #SetBlips ~= 0 then
		for i=1, #SetBlips do
			local blip = SetBlips[i]
			if DoesBlipExist(blip) then
				RemoveBlip(blip)
			end
		end
	end
	SetBlips = {}
end