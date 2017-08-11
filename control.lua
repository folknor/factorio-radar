-------------------------------------------------------------------------------
-- CONFIG
--

-- On on_configuration_changed, if we detect any entities of type "radar"
-- that are NOT included in this table, it means we need to track radars
-- being .destroy()'d and such in ontick, which is expensive.

-- So, to be clear: we only track radar destruction if we find any
-- radar-type entities that are NOT in this table.
-- We also check if the radar has a max_distance_of_sector_revealed property larger than zero.
-- And if it does not, we do not track that either.

-- Regardless, we only scan for instantly-replaced entities one time per on_configuration_changed.
-- Otherwise we depend on on_built_entity/on_robot_built_entity.
local CONFIG_TRACK_IGNORE = {
	radar = true,
	["smart-display-radar"] = true, -- Smart Display
	["vehicle-deployer-belt"] = true, -- AAI
	["train-tracker"] = true, -- Vehicle Radar
	["vehicular-tracker"] = true, -- Vehicle Radar
}
-- ZZZ needs to be the same as in data-final-fixes.lua
local CONFIG_REFERENCE_STRING = "zzz radar-reporter [[name]]"

-------------------------------------------------------------------------------
-- UTILITY
--

-- true/false
local function isValidRadar(radar)
	local reference = game.item_prototypes[CONFIG_REFERENCE_STRING:gsub("%[name%]", tostring(radar.name))]
	if type(reference) == "table" then return true end
	return false
end

-- Can return nil
local function findRadar(cc)
	local radars = cc.surface.find_entities_filtered({
		area = { { cc.position.x - 1, cc.position.y - 1 }, { cc.position.x + 1, cc.position.y + 1 } },
		type = "radar",
		force = cc.force,
	})
	if type(radars) == "table" then
		for _, radar in next, radars do
			if isValidRadar(radar) then
				return radar
			end
		end
	end
end

-------------------------------------------------------------------------------
-- SCANNING FOR UNITS
--

local scan
do
	-- ZZZ
	-- This map probably can grow quite large during a play session, but
	-- I dont really care.
	local radarCoverageMap = {}
	-- We presume that radars dont move!
	local function cacheCoverage(radar)
		local name = radar.name or "radar"
		local reference = game.item_prototypes[CONFIG_REFERENCE_STRING:gsub("%[name%]", tostring(name))]
		local chunks = reference and reference.order and tonumber(reference.order) or 14
		local tiles = ((chunks / 4) * 32) + 0.5 -- One chunk is 32 tiles
		--print("Radar coverage for " .. tostring(name) .. " is " .. tostring(chunks) .. "/" .. tostring(tiles))
		local x, y = radar.position.x, radar.position.y
		radarCoverageMap[radar.unit_number] = {
			area = { { x - tiles, y - tiles }, { x + tiles, y + tiles } },
			type = "unit",
		}
		--print(serpent.block(radarCoverageMap[radar.unit_number]))
	end

	local params = {
		parameters = {
			{ index = 1, count = 0, signal = { type = "virtual", name = "signal-radar-reporter-friendlies" } },
			{ index = 2, count = 0, signal = { type = "virtual", name = "signal-radar-reporter-enemies" } },
		}
	}
	scan = function(radar, control)
		-- Cached
		if not radarCoverageMap[radar.unit_number] then cacheCoverage(radar) end

		local entities = radar.surface.find_entities_filtered(radarCoverageMap[radar.unit_number])
		if not entities or #entities == 0 then
			control.parameters = nil
		else
			local friend, enemy = 0, 0
			for _, ent in next, entities do
				if ent and ent.valid and ent.force then
					if ent.force == radar.force then
						friend = friend + 1
					else
						enemy = enemy + 1
					end
				end
			end
			params.parameters[1].count = friend
			params.parameters[2].count = enemy
			control.parameters = params
		end
	end
end


-------------------------------------------------------------------------------
-- TICK HANDLER
-- Fired every 240 ticks (4 seconds?)
--

local tick
do
	local incomingReadSignal = { name = "signal-R", type = "virtual" }
	-- Every 4 seconds, so lets be careful!
	tick = function(event)
		if event.tick % 240 ~= 0 then return end
		if not global.reporters or #global.reporters == 0 then return end

		-- Clear out disfunctional or missing CCs
		for i = #global.reporters, 1, -1 do
			local m = global.reporters[i]
			if not m or not m.cc or not m.cc.valid then
				table.remove(global.reporters, i)
			end
		end

		-- Rehash the table if we removed the last item, just to be sure
		if #global.reporters == 0 then
			global.reporters = {}
			script.on_event(defines.events.on_tick, nil)
			return
		end

		-- Actually scan, if radar is available and we are connected
		for _, m in next, global.reporters do
			-- We only scan one time between config resets
			if global.needToTrackRadars and (not m.radar or not m.radar.valid) and not m.ignore then
				local newRadar = findRadar(m.cc)
				if newRadar then
					m.radar = newRadar
				else
					-- We didnt find any radar. Assume that there just isnt one there, and dont scan again.
					-- Until on_configuration_changed.
					m.ignore = true
				end
			end
			if m.cc and m.cc.valid and m.radar and m.radar.valid and m.radar.energy > 0 then
				local red = m.cc.get_circuit_network(defines.wire_type.red)
				local green = m.cc.get_circuit_network(defines.wire_type.green)
				if (red   and red.valid    and red.signals and   #red.signals > 0   and red.get_signal(incomingReadSignal) > 0 ) or
					(green and green.valid and green.signals and #green.signals > 0 and green.get_signal(incomingReadSignal) > 0 ) then
					scan(m.radar, m.cb)
				else
					m.cb.parameters = nil
				end
			elseif m.cc and m.cc.valid and m.cb then
				m.cb.parameters = nil
			end
		end
	end
end

-------------------------------------------------------------------------------
-- ON BUILT HANDLER
--

do
	local function onBuilt(event)
		local e = event.created_entity
		if event and e then
			if e.name == "radar-reporter" then
				if not global.reporters then global.reporters = {} end

				if #global.reporters == 0 then
					script.on_event(defines.events.on_tick, tick)
				end

				-- Prevents clicking it and using it like a normal constant combinator
				e.operable = false
				e.get_control_behavior().parameters = nil

				-- find out if we are next to a radar
				local newRadar = findRadar(e)
				-- Nothing to do for now, but lets wait for a radar
				if newRadar then
					global.reporters[#global.reporters + 1] = { cc = e, cb = e.get_control_behavior(), radar = newRadar }
				else
					global.reporters[#global.reporters + 1] = { cc = e, cb = e.get_control_behavior() }
				end
			elseif e.type == "radar" then
				-- find out if there is a reporter next to this radar
				local cc = e.surface.find_entities_filtered({
					area = { { e.position.x - 2.3, e.position.y - 2.3 }, { e.position.x + 2.3, e.position.y + 2.3 } },
					name = "radar-reporter",
					force = e.force,
					limit = 1,
				})
				if type(cc) ~= "table" or #cc == 0 then return end

				for _, m in next, global.reporters do
					if m and m.cc and m.cc.valid and m.cc.unit_number == cc[1].unit_number then
						m.radar = e
						m.ignore = nil
						m.cb.parameters = nil
						break
					end
				end
			end
		end
	end
	script.on_event(defines.events.on_built_entity, onBuilt)
	script.on_event(defines.events.on_robot_built_entity, onBuilt)
end

-------------------------------------------------------------------------------
-- CONFIGURATION HANDLING
-- Mostly checks if there are 3rd party mods that add custom radars.
-- If there is, we presume that they instantly destroy() and create_entity()
-- new radar types, which does NOT trigger any events.
--
-- So if we find any custom radar types in the data, we set a flag that enables
-- each CC-box to look around itself on the next tick (4 seconds) for any
-- randomly-appearing radars.
--
-- If it cant find any on that tick, it wont look again until the next
-- on_configuration_changed, but will obviously react to one that is built next
-- to it.
--

do
	local function checkForWeirdRadars()
		local found = false
		for name, ent in pairs(game.entity_prototypes) do
			if ent.type == "radar" and not CONFIG_TRACK_IGNORE[name] then
				-- Check if this radar type has a max_distance_of_sector_revealed bigger than zero
				if isValidRadar(ent) then
					global.needToTrackRadars = true
					found = true
					break
				end
			end
		end
		if not found then global.needToTrackRadars = false end

		-- Mark CCs for re-scanning for radar entities that are instantly replaced
		if global.reporters and #global.reporters > 0 then
			for _, m in next, global.reporters do
				m.ignore = nil
			end
		end
	end

	script.on_configuration_changed(checkForWeirdRadars)

	script.on_load(function()
		if #global.reporters > 0 then
			script.on_event(defines.events.on_tick, tick)
		end
	end)

	script.on_init(function()
		global.reporters = global.reporters or {}
		global.needToTrackRadars = global.needToTrackRadars or false
		checkForWeirdRadars()
	end)
end
