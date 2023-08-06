local ESX = not UseOx and exports.es_extended.getSharedObject() --[[@as table]]
if UseOx then
	assert(load(LoadResourceFile("ox_core", "imports/server.lua"), "@@ox_core/imports/server.lua"))()
end

local routingBuckets = {}
local jailed = {}

---@param tbl table: The table to search.
---@param value any: The value to look for in the table.
---@return boolean: Returns true if the value is found in the table, false otherwise.
local function hasOne(tbl, value)
	for _, v in pairs(tbl) do
		if v == value then
			return true
		end
	end
	return false
end

---@param player table | number | string: The player object, player ID, or identifier whose inventory to retrieve.
---@return table: Returns a table representing the player's inventory with item names as keys and item counts as values.
local function getInventory(player)
	local isNotTable = type(player) == "string" or type(player) == "number"
	player = isNotTable and (UseOx and Ox.GetPlayer(tonumber(player)) or not UseOx and ESX.GetPlayerFromId(source)) or not isNotTable and player or nil
	if not player then return {} end

	local inventory = {}

	for _, v in pairs(exports.ox_inventory:GetInventoryItems(player.source)) do
		inventory[v.name] = v.count
	end

	return inventory
end

---@param source number: The source of the command (player ID).
---@param args table: The command arguments passed to the function.
RegisterCommand("ajail", function(source, args)
	local id = args[1]
	local time = tonumber(args[2])
	if not id or id == "" or not time then return end

	time = time > 0 and time or 1

	local ply = UseOx and Ox.GetPlayer(tonumber(source)) or not UseOx and ESX.GetPlayerFromId(source)
	if not ply then return end

	if not UseAces then
		if UseOx and not ply.hasGroup(AllowedGroup) or not UseOx and not hasOne(AllowedGroup, ply.getGroup()) then
			TriggerClientEvent("chat:addMessage", source, {
				template = "^1[ ! ] ^0You don\'t have permission to use this command",
			})
			return
		end
	end

	local targetPly = UseOx and Ox.GetPlayer(tonumber(id)) or not UseOx and ESX.GetPlayerFromId(id)
	if not targetPly then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not online",
			args = { id },
		})
		return
	end

	local identifier = UseOx and targetPly.charid or targetPly.identifier

	if jailed[identifier] then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is already jailed",
			args = { id },
		})
		return
	end

	local newBucket = math.random(1, 999999)
	while routingBuckets[newBucket] do
		Wait(0)
		newBucket = math.random(1, 999999)
	end
	routingBuckets[newBucket] = identifier

	local playerPed = GetPlayerPed(id)
	local closest = JailedState
	local jail = Jails[closest]
	local inventory = getInventory(targetPly)

	jailed[identifier] = {
		jail = closest,
		time = time,
		inventory = inventory,
		active = true,
		type = "admin",
	}

	for k, v in pairs(inventory) do
		if not jail.blacklistedItems[k] then
			exports.ox_inventory:RemoveItem(targetPly.source, k, v)
		end
	end

	for k, v in pairs(jail.items) do
		exports.ox_inventory:AddItem(targetPly.source, k, v)
	end

	SetPlayerRoutingBucket(id, newBucket)
	SetEntityCoords(playerPed, jail.insideCoords.x, jail.insideCoords.y, jail.insideCoords.z, true, false, false, false)
	Player(id).state:set("jailed", true, true)

	local reasonTbl = {}
	for i = 3, #args do
		reasonTbl[#reasonTbl + 1] = args[i]
	end

	local reason = table.concat(reasonTbl, " ")
	TriggerClientEvent("chat:addMessage", -1, {
		template = "^1AdmCmd {0} has been admin jailed by {1} for {2} minute(s), reason: {3}",
		args = {
			UseOx and targetPly.firstname .. " " .. targetPly.lastname or targetPly.getName(),
			UseOx and ply.firstname .. " " .. ply.lastname or ply.getName(),
			time,
			reason == "" and "Not provided." or reason,
		},
	})
end, UseAces)

---@param source number: The source of the command (player ID).
---@param args table: The command arguments passed to the function.
RegisterCommand("ajailrelease", function(source, args)
	local id = args[1]
	local ply = UseOx and Ox.GetPlayer(tonumber(source)) or not UseOx and ESX.GetPlayerFromId(source)
	if not ply then return end

	if not UseAces then
		if UseOx and not ply.hasGroup(AllowedGroup) or not UseOx and not hasOne(AllowedGroup, ply.getGroup()) then
			TriggerClientEvent("chat:addMessage", source, {
				template = "^1[ ! ] ^0You don\'t have permission to use this command",
			})
			return
		end
	end

	local targetPly = UseOx and Ox.GetPlayer(tonumber(id)) or not UseOx and ESX.GetPlayerFromId(id)
	if not targetPly then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not online",
			args = { id },
		})
		return
	end

	local identifier = UseOx and targetPly.charid or targetPly.identifier

	local jailData = jailed[identifier]
	if not jailData then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not jailed",
			args = { id },
		})
		return
	end

	if not jailData.active then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not logged in",
			args = { id },
		})
		return
	end

	local jail = Jails[jailData.jail]

	SetEntityCoords(GetPlayerPed(id), jail.outsideCoords.x, jail.outsideCoords.y, jail.outsideCoords.z, true, false, false, false)

	SetPlayerRoutingBucket(id, 0)
	Player(id).state:set("jailed", false, true)

	local inventory = getInventory(targetPly)
	for k, v in pairs(inventory) do
		exports.ox_inventory:RemoveItem(targetPly.source, k, v)
	end

	for k, v in pairs(jailData.inventory) do
		exports.ox_inventory:AddItem(targetPly.source, k, v)
	end

	for k, v in pairs(routingBuckets) do
		if v == identifier then routingBuckets[k] = nil end
	end

	jailed[identifier] = nil
	MySQL.query("DELETE FROM jail WHERE identifier = ?", { identifier })

	TriggerClientEvent("chat:addMessage", -1, {
		template = "^1AdmCmd {0} has been released from admin jail by {1}.",
		args = {
			UseOx and targetPly.firstname .. " " .. targetPly.lastname or targetPly.getName(),
			UseOx and ply.firstname .. " " .. ply.lastname or ply.getName(),
		},
	})
end, UseAces)

---@param source number: The source of the command (player ID).
---@param args table: The command arguments passed to the function.
RegisterCommand("ajailtime", function(source, args)
	local id = args[1]
	local ply = UseOx and Ox.GetPlayer(tonumber(source)) or not UseOx and ESX.GetPlayerFromId(source)
	if not ply then return end

	if not UseAces then
		if UseOx and not ply.hasGroup(AllowedGroup) or not UseOx and not hasOne(AllowedGroup, ply.getGroup()) then
			TriggerClientEvent("chat:addMessage", source, {
				template = "^1[ ! ] ^0You don\'t have permission to use this command",
			})
			return
		end
	end

	local targetPly = UseOx and Ox.GetPlayer(tonumber(id)) or not UseOx and ESX.GetPlayerFromId(id)
	if not targetPly then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not online",
			args = { id },
		})
		return
	end

	local jailData = jailed[UseOx and targetPly.charid or targetPly.identifier]
	if not jailData then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not jailed",
			args = { id },
		})
		return
	end

	TriggerClientEvent("chat:addMessage", source, {
		template = "^1[ ! ] ^0Player ^3{0} ^0has ^3{1} ^0minute(s) of jailtime left",
		args = { id, jailData.time },
	})
end, UseAces)

---@param id number: The player ID of the loaded player.
RegisterNetEvent("esx:playerLoaded", function(id)
	local ply = ESX.GetPlayerFromId(id)
	local jailData = jailed[ply.identifier]
	if not jailData then return end

	local bucket = 1
	for k, v in pairs(routingBuckets) do
		if v == ply.identifier then bucket = k end
	end

	local jail = Jails[jailData.jail]
	SetPlayerRoutingBucket(id, bucket)

	SetEntityCoords(GetPlayerPed(id), jail.insideCoords.x, jail.insideCoords.y, jail.insideCoords.z, true, false, false, false)

	Player(id).state:set("jailed", true, true)
	jailed[ply.identifier].active = true
end)

---@param id number: The player ID of the loaded player.
AddEventHandler("esx:playerLogout", function(id)
	local ply = ESX.GetPlayerFromId(id)
	if not ply then return end

	if not jailed[ply.identifier] then return end

	SetPlayerRoutingBucket(id, 0)
	Player(id).state:set("jailed", false, true)

	jailed[ply.identifier].active = false
end)

---@param id number: The player ID of the loaded player.
RegisterNetEvent("esx:playerDropped", function(id)
	local ply = ESX.GetPlayerFromId(id)
	if not ply then return end

	if not jailed[ply.identifier] then return end
	jailed[ply.identifier].active = false
end)

---@param id number: The player ID of the loaded player.
---@param _ any: This parameter is unused in this event handler.
---@param charid string | number: The character identifier of the loaded player.
AddEventHandler("ox:playerLoaded", function(id, _, charid)
	local jailData = jailed[charid]
	if not jailData then return end

	local bucket = 1
	for k, v in pairs(routingBuckets) do
		if v == charid then bucket = k end
	end

	local jail = Jails[jailData.jail]
	SetPlayerRoutingBucket(id, bucket)

	SetEntityCoords(GetPlayerPed(id), jail.insideCoords.x, jail.insideCoords.y, jail.insideCoords.z, true, false, false, false)

	Player(id).state:set("jailed", true, true)
	jailed[charid].active = true
end)

---@param id number: The player ID of the loaded player.
---@param _ any: This parameter is unused in this event handler.
---@param charid string | number: The character identifier of the loaded player.
AddEventHandler("ox:playerLogout", function(id, _, charid)
	local jailData = jailed[charid]
	if not jailData then return end

	SetPlayerRoutingBucket(id, 0)
	Player(id).state:set("jailed", false, true)

	jailed[charid].active = false
end)

---@param eventData table: The data received from the event.
RegisterNetEvent("txAdmin:events:scheduledRestart", function(eventData)
	if eventData.secondsRemaining ~= 15 then return end

	local queries = {}
	for k, v in pairs(jailed) do
		local bucket = -1
		for k2, v2 in pairs(routingBuckets) do
			if v2 == k then bucket = k2 end
		end

		queries[#queries + 1] = {
			query = "INSERT INTO `jail` (identifier, time, jail, bucket, inventory, jailType) VALUES (:identifier, :time, :jail, :bucket, :inventory, :jailType) ON DUPLICATE KEY UPDATE `time` = :time",
			values = {
				identifier = k,
				time = v.time,
				jail = v.jail,
				bucket = bucket,
				inventory = json.encode(v.inventory),
				jailType = v.type,
			},
		}
	end

	if table.type(queries) == "empty" then return end
	MySQL.transaction(queries)
end)

---@param resource string: The name of the started resource.
AddEventHandler("onResourceStart", function(resource)
	if resource ~= GetCurrentResourceName() then return end

	local success, result = pcall(MySQL.query.await, "SELECT * FROM jail")
	if success then
		for i = 1, #result do
			local data = result[i]
			data.identifier = UseOx and tonumber(data.identifier) or data.identifier
			jailed[data.identifier] = {
				jail = data.jail,
				time = data.time,
				inventory = type(data.inventory) == "string" and json.decode(data.inventory) or data.inventory,
				active = false,
				type = data.jailType,
			}

			if data.bucket ~= -1 then
				routingBuckets[data.bucket] = data.identifier
			end

			local ply = UseOx and Ox.GetPlayerByFilter({ charid = data.identifier }) or not UseOx and ESX.GetPlayerFromIdentifier(data.identifier)
			if ply then
				local jail = Jails[data.jail]
				if data.bucket ~= -1 then
					SetPlayerRoutingBucket(ply.source, data.bucket)
				end

				SetEntityCoords(GetPlayerPed(ply.source), jail.insideCoords.x, jail.insideCoords.y, jail.insideCoords.z, true, false, false, false)

				Player(ply.source).state:set("jailed", true, true)
				jailed[data.identifier].active = true
			end
		end
		return
	end

	MySQL.query.await(([[
        CREATE TABLE jail (
            identifier VARCHAR(255) NOT NULL,
            time INT NOT NULL DEFAULT 99,
            jail LONGTEXT NOT NULL DEFAULT '%s',
            bucket INT NOT NULL DEFAULT -1,
            inventory LONGTEXT NOT NULL DEFAULT '{}',
            jailType VARCHAR(10) NOT NULL DEFAULT 'normal',

            PRIMARY KEY (identifier)
        )
    ]]):format(JailedState))
end)

---@param resource string: The name of the stopped resource.
AddEventHandler("onResourceStop", function(resource)
	if resource ~= GetCurrentResourceName() then return end

	local queries = {}
	for k, v in pairs(jailed) do
		local bucket = -1
		for k2, v2 in pairs(routingBuckets) do
			if v2 == k then bucket = k2 end
		end

		queries[#queries + 1] = {
			query = "INSERT INTO `jail` (identifier, time, jail, bucket, inventory, jailType) VALUES (:identifier, :time, :jail, :bucket, :inventory, :jailType) ON DUPLICATE KEY UPDATE `time` = :time",
			values = {
				identifier = k,
				time = v.time,
				jail = v.jail,
				bucket = bucket,
				inventory = json.encode(v.inventory),
				jailType = v.type,
			},
		}
	end

	if table.type(queries) == "empty" then return end
	MySQL.transaction(queries)
end)

CreateThread(function()
	while true do
		Wait(60000)
		for k, v in pairs(jailed) do
			if v.active then
				v.time -= 1
				if v.time == 0 then
					local ply = UseOx and Ox.GetPlayerByFilter({ charid = k }) or not UseOx and ESX.GetPlayerFromIdentifier(k)
					if ply then
						local id = ply.source
						local jail = Jails[v.jail]

						SetEntityCoords(GetPlayerPed(id), jail.outsideCoords.x, jail.outsideCoords.y, jail.outsideCoords.z, true, false, false, false)

						SetPlayerRoutingBucket(id, 0)
						Player(id).state:set("jailed", false, true)

						for k2, v2 in pairs(routingBuckets) do
							if v2 == k then routingBuckets[k2] = nil end
						end

						jailed[k] = nil
						MySQL.query("DELETE FROM jail WHERE identifier = ?", { k })
					end
				end
			end
		end
	end
end)