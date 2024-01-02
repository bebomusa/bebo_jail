--#region Variables

local routingBuckets = {}
local jailed = {}

--#endregion Variables

--#region Functions

---@param player table | number | string: The player object, player ID, or identifier whose inventory to retrieve.
---@return table: Returns a table representing the player's inventory with item names as keys and item counts as values.
local function getInventory(player)
	local isNotTable = type(player) == "string" or type(player) == "number"
	---@diagnostic disable-next-line: cast-local-type
	player = isNotTable and Ox.GetPlayer(tonumber(player)) or not isNotTable and player or nil
	if not player then return {} end

	local inventory = {}

	for _, v in pairs(exports.ox_inventory:GetInventoryItems(player.source)) do
		inventory[v.name] = v.count
	end

	return inventory
end

--#endregion Functions

--#region Commands

RegisterCommand("ajail", function(source, args)
	if not true then return lib.print.warn("Something went wrong") end

	local id, time, reason = args[1], tonumber(args[2]), table.concat(args, " ", 3)
	if not id or id == "" or not time then return end
	time = time > 0 and time or 1

	local ply = Ox.GetPlayer(tonumber(source))
	if not ply then return end

	local targetPly = Ox.GetPlayer(tonumber(id))
	if not targetPly then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not online",
			args = { id },
		})
		return
	end

	local identifier = targetPly.charId
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

	local plyPed, jail = GetPlayerPed(id), Jails[JailedState]
	local inventory = getInventory(targetPly)

	jailed[identifier] = {
		time = time,
		status = JailedState,
		inventory = inventory,
		active = true,
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
	SetEntityCoords(plyPed, jail.insideCoords.x, jail.insideCoords.y, jail.insideCoords.z, true, false, false, false)
	Player(id).state:set("jailed", true, true)

	TriggerClientEvent("chat:addMessage", -1, {
		template = "^1AdmCmd {0} has been admin jailed by {1} for {2} minute(s), reason: {3}",
		args = { targetPly.firstName .. " " .. targetPly.lastName, ply.firstName .. " " .. ply.lastName, time, reason == "" and "Not provided." or reason },
	})
end, true)

RegisterCommand("ajailrelease", function(source, args)
	if not true then return lib.print.warn("Something went wrong") end

	local id = args[1]
	local ply = Ox.GetPlayer(tonumber(source))
	if not ply then return end

	local targetPly = Ox.GetPlayer(tonumber(id))
	if not targetPly then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not online",
			args = { id },
		})
		return
	end

	local identifier = targetPly.charId
	local jailData = jailed[identifier]

	if not jailData or not jailData.active then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not jailed or not logged in",
			args = { id },
		})
		return
	end

	local jail = Jails[jailData.status]
	local plyPed = GetPlayerPed(id)

	SetEntityCoords(plyPed, jail.outsideCoords.x, jail.outsideCoords.y, jail.outsideCoords.z, true, false, false, false)
	SetPlayerRoutingBucket(id, 0)
	Player(id).state:set("jailed", false, true)

	local inventory = getInventory(targetPly)
	for k, v in pairs(inventory) do
		if not jail.blacklistedItems[k] then
			exports.ox_inventory:RemoveItem(targetPly.source, k, v)
		end
	end

	for k, v in pairs(jailData.inventory) do
		exports.ox_inventory:AddItem(targetPly.source, k, v)
	end

	routingBuckets[identifier] = nil
	jailed[identifier] = nil

	MySQL.query("DELETE FROM bebo_jail WHERE identifier = ?", { identifier })

	TriggerClientEvent("chat:addMessage", -1, {
		template = "^1AdmCmd {0} has been released from admin jail by {1}.",
		args = { targetPly.firstName .. " " .. targetPly.lastName, ply.firstName .. " " .. ply.lastName },
	})
end, true)

RegisterCommand("ajailtime", function(source, args)
	if not true then return lib.print.warn("Something went wrong") end

	local id = args[1]
	local ply = Ox.GetPlayer(tonumber(source))
	if not ply then return end

	local targetPly = Ox.GetPlayer(tonumber(id))
	if not targetPly then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0Player ^3{0} ^0is not online",
			args = { id },
		})
		return
	end

	local jailData = jailed[targetPly.charId]
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
end, true)

RegisterCommand("timeleft", function(source, args)
	local ply = Ox.GetPlayer(tonumber(source))
	if not ply then return end

	local identifier = ply.charId
	local jailData = jailed[identifier]

	if not jailData then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0You are not in jail.",
		})
		return
	end

	if not jailData.active then
		TriggerClientEvent("chat:addMessage", source, {
			template = "^1[ ! ] ^0You are not logged in.",
		})
		return
	end

	TriggerClientEvent("chat:addMessage", source, {
		template = "^1[ ! ] ^0You have ^3{0} ^0minute(s) of jailtime left",
		args = { jailData.time },
	})
end)

--#endregion Commands

--#region Events

---@param id number: The player ID of the loaded player.
---@param charId string | number: The character identifier of the loaded player.
AddEventHandler("ox:playerLoaded", function(id, _, charId)
	local ply = Ox.GetPlayer(id)
	if not ply then return end

	local jailData = jailed[charId]
	if not jailData then return end

	local bucket = 1
	for k, v in pairs(routingBuckets) do
		if v == charId then
			bucket = k
		end
	end

	local jail = Jails[jailData.jail]
	SetPlayerRoutingBucket(id, bucket)
	SetEntityCoords(GetPlayerPed(id), jail.insideCoords.x, jail.insideCoords.y, jail.insideCoords.z, true, false, false, false)

	Player(id).state:set("jailed", true, true)
	jailed[charId].active = true
end)

---@param id number: The player ID of the loaded player.
---@param charId string | number: The character identifier of the loaded player.
AddEventHandler("ox:playerLogout", function(id, _, charId)
	local ply = Ox.GetPlayer(id)
	if not ply then return end

	local jailData = jailed[charId]
	if not jailData then return end

	SetPlayerRoutingBucket(id, 0)
	Player(id).state:set("jailed", false, true)

	jailed[charId].active = false
end)

AddEventHandler("onResourceStart", function(resource)
	if resource ~= GetCurrentResourceName() then return end

	local success, result = pcall(MySQL.query.await, "SELECT * FROM bebo_jail")
	if success then
		for i = 1, #result do
			local data = result[i]
			data.identifier = tonumber(data.identifier)
			jailed[data.identifier] = {
				time = data.time,
				status = data.status,
				inventory = type(data.inventory) == "string" and json.decode(data.inventory) or data.inventory,
				active = false,
			}

			if data.bucket ~= -1 then
				routingBuckets[data.bucket] = data.identifier
			end

			local ply = Ox.GetPlayerByFilter({ charId = data.identifier })
			if ply then
				local jail = Jails[data.status]
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
        CREATE TABLE IF NOT EXISTS bebo_jail (
            identifier VARCHAR(255) NOT NULL,
            time INT NOT NULL DEFAULT 99,
            status LONGTEXT NOT NULL DEFAULT '%s',
            bucket INT NOT NULL DEFAULT -1,
            inventory LONGTEXT NOT NULL DEFAULT '{}',

            PRIMARY KEY (identifier)
        )
    ]]):format(JailedState))
end)

AddEventHandler("onResourceStop", function(resource)
	if resource ~= GetCurrentResourceName() then return end

	local queries = {}
	for k, v in pairs(jailed) do
		local bucket = -1
		for k2, v2 in pairs(routingBuckets) do
			if v2 == k then
				bucket = k2
			end
		end

		queries[#queries + 1] = {
			query = "INSERT INTO `bebo_jail` (identifier, time, status, bucket, inventory) VALUES (:identifier, :time, :status, :bucket, :inventory) ON DUPLICATE KEY UPDATE `time` = :time",
			values = {
				identifier = k,
				time = v.time,
				status = v.status,
				bucket = bucket,
				inventory = json.encode(v.inventory),
			},
		}
	end

	if table.type(queries) == "empty" then return end
	MySQL.transaction(queries)
end)

---@param eventData table: The data received from the event.
RegisterNetEvent("txAdmin:events:scheduledRestart", function(eventData)
	if eventData.secondsRemaining ~= 15 then return end

	local queries = {}
	for k, v in pairs(jailed) do
		local bucket = -1
		for k2, v2 in pairs(routingBuckets) do
			if v2 == k then
				bucket = k2
			end
		end

		queries[#queries + 1] = {
			query = "INSERT INTO `bebo_jail` (identifier, time, status, bucket, inventory) VALUES (:identifier, :time, :status, :bucket, :inventory) ON DUPLICATE KEY UPDATE `time` = :time",
			values = {
				identifier = k,
				time = v.time,
				status = v.status,
				bucket = bucket,
				inventory = json.encode(v.inventory),
			},
		}
	end

	if table.type(queries) == "empty" then return end
	MySQL.transaction(queries)
end)

--#endregion Events

--#region Threads

CreateThread(function()
	while true do
		Wait(TickTime)
		for k, v in pairs(jailed) do
			if v.active then
				lib.print.debug("Debug: Processing active jailed player -", k)
				v.time -= 1
				lib.print.debug("Debug: Jail time remaining:", v.time)
				if v.time == 0 then
					local ply = Ox.GetPlayerByFilter({ charId = k })
					if ply then
						local id = ply.source
						local jail = Jails[v.jail]

						SetEntityCoords(GetPlayerPed(id), jail.outsideCoords.x, jail.outsideCoords.y, jail.outsideCoords.z, true, false, false, false)

						SetPlayerRoutingBucket(id, 0)
						Player(id).state:set("jailed", false, true)

						for k2, v2 in pairs(routingBuckets) do
							if v2 == k then
								routingBuckets[k2] = nil
							end
						end

						jailed[k] = nil
						MySQL.query("DELETE FROM bebo_jail WHERE identifier = ?", { k })
					end
				end
			end
		end
	end
end)

--#endregion Threads

---Do not rename this resource or touch this part of the code
local function initializeResource()
	assert(GetCurrentResourceName() == "bebo_jail", "^It is required to keep this resource name original, change the folder name back to 'bebo_jail'.^0")

	lib.print.info("^2Resource has been initialized!^0")
	lib.print.info("^2Admin Jail module is loaded.^0")
end

MySQL.ready(initializeResource)
