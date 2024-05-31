local QBCore = exports['qb-core']:GetCoreObject()
local Guard = nil

function UnloadBodyguard()
    DeletePed(Guard)
    exports['qb-target']:RemoveSpawnedPed(Guard)
    Guard = nil
end

function GetClosestPed()
    local playerPed = GetPlayerPed(-1)
    local playerCoords = GetEntityCoords(playerPed)
    local closestPed = nil
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= playerPed and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distancia = GetDistanceBetweenCoords(playerCoords, pedCoords, true)
            if distancia <= 3 then
                closestPed = ped
                break
            end
        end
    end
    return closestPed
end

local function RotationToDirection(rotation)
	local ajustarRotacion =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direccion =
	{
		x = -math.sin(ajustarRotacion.z) * math.abs(math.cos(ajustarRotacion.x)),
		y = math.cos(ajustarRotacion.z) * math.abs(math.cos(ajustarRotacion.x)),
		z = math.sin(ajustarRotacion.x)
	}
	return direccion
end

local function RayCastGamePlayCamera(distancia)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direccion = RotationToDirection(cameraRotation)
	local destino =
	{
		x = cameraCoord.x + direccion.x * distancia,
		y = cameraCoord.y + direccion.y * distancia,
		z = cameraCoord.z + direccion.z * distancia
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destino.x, destino.y, destino.z, -1, PlayerPedId(), 0))
	return b, c, e
end

function Laser()
    local color = {r = 2, g = 241, b = 181, a = 200}
    local hit, coords = RayCastGamePlayCamera(20.0)

    if hit then
        local position = GetEntityCoords(PlayerPedId())
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)
    end

    return hit, coords
end

function Colocar(coords, ped)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskGoStraightToCoord(ped, coords, 15.0, -1, 0.0, 0.0)
    TaskGoStraightToCoord(ped, coords, 15.0, -1, 0.0, 0.0)
end

RegisterNetEvent('qb-npccontrol:client:guardaespaldasColocar', function(data)
    rayoLaser = not rayoLaser

    if rayoLaser then
        CreateThread(function()
            while rayoLaser do
                local hit, coords = Laser()
                if IsControlJustReleased(0, 38) then
                    rayoLaser = false
                    if hit then
                       Colocar(coords, data.ped)
                    else
                        QBCore.Functions.Notify("No se puede colocar ahí", "error")
                    end
                elseif IsControlJustReleased(0, 47) then
                    rayoLaser = false
                end
                Wait(0)
            end
        end)
    end
end)

RegisterNetEvent('qb-npccontrol:client:guardaespaldasGirar', function(data)
    ClearPedTasks(data.ped)
    SetBlockingOfNonTemporaryEvents(data.ped, true)
    SetEntityHeading(data.ped, GetEntityHeading(PlayerPedId()))
    FreezeEntityPosition(data.ped, true)
    Wait(1000)
    TaskStartScenarioInPlace(data.ped, "WORLD_HUMAN_GUARD_STAND", 0, false)
end)


RegisterNetEvent('qb-npccontrol:client:guardaespaldasseguir', function(data)
    TaskGoToEntity(data.ped, PlayerPedId(), -1, 2.0, 2.0 , 1073741824, 0)
    TaskFollowToOffsetOfEntity(data.ped, PlayerPedId(), 0.0, -2.0, 0.0, 2.0, -1, 0.0, true)
    SetPedKeepTask(data.ped, true)
    FreezeEntityPosition(data.ped, false)
end)

RegisterNetEvent('qb-npccontrol:client:guardaespaldasechar', function(data)
    exports['qb-target']:RemoveSpawnedPed(data.ped)
    Guard = nil
end)

RegisterNetEvent('qb-npccontrol:client:establecerguardia', function(data)
    FreezeEntityPosition(data.ped, true)
    SetPedCanPlayAmbientAnims(data.ped, true)
    SetBlockingOfNonTemporaryEvents(data.ped, true)
    TaskStartScenarioInPlace(data.ped, "WORLD_HUMAN_GUARD_STAND", 0, false)
end)

RegisterNetEvent('qb-npccontrol:client:dararma', function(data)
    SetCanPedEquipWeapon(data.ped, GetHashKey(Guadaespaldas.Arma), true)
    GiveWeaponToPed(data.ped, GetHashKey(Guadaespaldas.Arma),250, false, true)
    SetPedCurrentWeaponVisible(data.ped, true, false, 0, 0)
    SetBlockingOfNonTemporaryEvents(data.ped, true)
    TaskStartScenarioInPlace(data.ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
end)


RegisterNetEvent('qb-npccontrol:client:enGuardia', function(data)
    SetBlockingOfNonTemporaryEvents(data.ped, false)
    ClearPedTasks(data.ped)
end)

RegisterNetEvent('qb-npccontrol:client:quitararma', function(data)
    SetCanPedEquipWeapon(data.ped, GetHashKey('weapon_unarmed'), false)
    GiveWeaponToPed(data.ped, GetHashKey('weapon_unarmed'),250, false, false)
    SetPedCurrentWeaponVisible(data.ped, false, true, 0, 0)
    ClearPedTasks(data.ped)
    SetBlockingOfNonTemporaryEvents(data.ped, true)
    TaskStartScenarioInPlace(data.ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
end)

RegisterNetEvent('ds-npccontrol:menu:guardaespaldas', function(targetPed)
    local MenuGuardaespaldas = {
        {
            header = "npccontrol",
            isMenuHeader = true
        },
        {
            header = "Seguir",
            txt =  "Hacer que te siga",
            icon = "",
            params = {
                event = "qb-npccontrol:client:guardaespaldasseguir",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Mover",
            txt =  "Colocar en un punto",
            icon = "",
            params = {
                event = "qb-npccontrol:client:guardaespaldasColocar",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Girar",
            txt =  "Hacer que mire en tu dirección",
            icon = "",
            params = {
                event = "qb-npccontrol:client:guardaespaldasGirar",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Guardia",
            txt =  "Poner en posición de guardia (Pasivo)",
            icon = "",
            params = {
                event = "qb-npccontrol:client:establecerguardia",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "En alerta",
            txt =  "Establecer en modo alerta",
            icon = "",
            params = {
                event = "qb-npccontrol:client:enGuardia",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Dar Arma",
            txt =  "Dale un arma al guardaspaldas",
            icon = "",
            params = {
                event = "qb-npccontrol:client:dararma",
                args = {
                    ped = targetPed
                }
            }
        },  
        {
            header = "Quitar arma",
            txt =  "Quitar arma larga",
            icon = "",
            params = {
                event = "qb-npccontrol:client:quitararma",
                args = {
                    ped = targetPed
                }
            }
        },
        {
            header = "Despedir",
            txt =  "Hacer que se vaya",
            icon = "",
            params = {
                event = "qb-npccontrol:client:guardaespaldasechar",
                args = {
                    ped = targetPed
                }
            }
        },
    }
    exports['qb-menu']:openMenu(MenuGuardaespaldas)
end)

RegisterCommand("guardaespaldas", function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerPed = PlayerPedId()
    local posicionPlayer = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)
    local heading = GetEntityHeading(PlayerPedId())
    if Guadaespaldas.Gang[PlayerData.gang.name] then
        Guard = exports['qb-target']:SpawnPed({
            spawnNow = true,
            name = "Guardaespaldas",
            model = Guadaespaldas.GuardSkin,
            networked = true,
            coords = vector4(posicionPlayer.x, posicionPlayer.y, posicionPlayer.z, GetEntityHeading(PlayerPedId())),
            minusOne = true,
            freeze = true,
            invincible = false,
            blockevents = false,
            scenario = 'WORLD_HUMAN_GUARD_STAND',
            flag = 1,
            target = {
                useModel = false,
                options = {
                    {
                        type = "client",
                        label = 'Ordenar',
                        gang = Guadaespaldas.Gang,
                        job = Guadaespaldas.Job,
                        action = function(entity)
                            TriggerEvent('ds-npccontrol:menu:guardaespaldas', entity)
                        end,
                    }
                },
                distancia = 2.5,
            },
        })
        SetEntityHeading(Guard, heading)
    end
end, false)