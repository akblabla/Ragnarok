local Wargroove = require "wargroove/wargroove"
local Events = require "wargroove/events"
local Ragnarok = require "initialized/ragnarok"

local Actions = {}

-- This is called by the game when the map is loaded.
function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    dst["ai_set_no_building_attacking"] = Actions.setNoBuildingAttacking
    dst["set_state"] = Actions.setState
    dst["transfer_gold_robbed"] = Actions.transferGoldRobbed
	dst["message_counter"] = Actions.messageCounter
	dst["dialogue_box_with_counter"] = Actions.dialogueBoxWithCounter
	dst["change_objective_with_3_counters"] = Actions.changeObjectiveWith3Counters
	dst["give_crown"] = Actions.giveCrown
	dst["link_gizmo_state_with_activators"] = Actions.linkGizmoStateWithActivators
	dst["gizmo_active_when_stood_on"] = Actions.gizmoActiveWhenStoodOn
	dst["invert_gizmo"] = Actions.invertGizmo
	dst["set_threat_at_location"] = Actions.setThreatAtLocation
	dst["spawn_unit"] = Actions.spawnUnit
	dst["spawn_unit_closest_to_location"] = Actions.spawnUnitClosestToLocation
	dst["move_location_to_next_structure"] = Actions.moveLocationToNextStructure
end

function Actions.setNoBuildingAttacking(context)
    local targetPlayer = context:getPlayerId(0)
	print(targetPlayer)
	Ragnarok.addAIToCantAttackBuildings(targetPlayer)
end

function Actions.setState(context)
    -- "Add set state {3} to {4} for unit type(s) {0} at location {1} owned by player {2}."

	print("setState starts here")
    -- The context contains an ordered table of values and has accessor methods for various types.
    local units = context:gatherUnits(2, 0, 1)  -- A useful function for gathering units of type, location, and player
    local stateKey = context:getString(3)       -- Gets a string
    local stateValue = context:getString(4)
	print("gathered values")
    for i, unit in ipairs(units) do
        Wargroove.setUnitState(unit, stateKey, stateValue)
		print("set a state")
		print(stateKey)
		print(stateValue)
        Wargroove.updateUnit(unit)
    end
end

function Actions.giveCrown(context)
    -- "Give the crown to units of type {0} at location {1} owned by player {2}."

    -- The context contains an ordered table of values and has accessor methods for various types.
    local units = context:gatherUnits(2, 0, 1)  -- A useful function for gathering units of type, location, and player
    for i, unit in ipairs(units) do
        Ragnarok.grabCrown(unit)
		return
    end
end

function Actions.transferGoldRobbed(context)
    -- "Transfer gold robbed by {0}: {1}{2}"
    local playerId = context:getPlayerId(0)
    local transfer = context:getString(1)
    local value = context:getMapCounter(2)
	
	if transfer == "store" then
		context:setMapCounter(2, Ragnarok.getGoldRobbed(playerId))
	end
end

function Actions.messageCounter(context)
    -- "Display message: \"{0}\" and then counter {1}."
    local value = context:getMapCounter(1)
    Wargroove.showMessage(context:getString(0) .. tostring(value))
end

function Actions.dialogueBoxWithCounter(context)
    -- "Display dialogue box with {0} {1} saying \"{2}\" with shout: {3}. Use counter {4}."
    Wargroove.showDialogueBox(context:getString(0), context:getString(1), context:getString(2) .. tostring(context:getMapCounter(4)), context:getString(3))
end

function Actions.changeObjectiveWith3Counters(context)
    -- "Sets the map objective to {0} ({1}) {2} ({3}) {4}."
	local counter1 = context:getMapCounter(0)
	local counter1enroute = context:getMapCounter(1)
	local counter2 = context:getMapCounter(2)
	local counter2enroute = context:getMapCounter(3)
	local counter3 = context:getMapCounter(4)
	local superString = "Win the Pirate Bout!\nStolen by Wulfar: "..tostring(counter1)
	if counter1enroute ~= 0 then
		superString = superString.." ("..tostring(counter1enroute).." enroute)"
	end
	superString = superString.."\nStolen by Rival: "..tostring(counter2)
	if counter2enroute ~= 0 then
		superString = superString.." ("..tostring(counter2enroute).." enroute)"
	end
	superString = superString.."\nVillage Gold: "..tostring(counter3)

    Wargroove.changeObjective(superString)
end

function dump(o,level)
   if type(o) == 'table' then
      local s = '\n' .. string.rep("   ", level) .. '{\n'
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. string.rep("   ", level+1) .. '['..k..'] = ' .. dump(v,level+1) .. ',\n'
      end
      return s .. string.rep("   ", level) .. '}'
   else
      return tostring(o)
   end
end


function Actions.linkGizmoStateWithActivators(context)
    -- "Link all gizmos with the activators at location {0}."
    local location = context:getLocation(0)
	
	local isActivated = true
	local actuators = {}
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
		if Ragnarok.isActivator(gizmo) then
			if gizmo:getState() == false then
				isActivated = false
			end
		else
			table.insert(actuators, gizmo)
		end
    end
	if actuators and Ragnarok.wouldAnyStatesChange(actuators, isActivated) then
		Wargroove.waitTime(0.3)
		Ragnarok.setStates(actuators, isActivated, playSound)
	end
end

function Actions.gizmoActiveWhenStoodOn(context)
    -- "Gizmos activate when stood on location {0}."
	local location = context:getLocation(0)
	
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
		Ragnarok.setActivator(gizmo, true)
		local unit = Wargroove.getUnitAt(gizmo.pos)
		local crownPos = Ragnarok.getCrownPos()
		local isCrown = crownPos and (crownPos.x == gizmo.pos.x) and (crownPos.y == gizmo.pos.y)
		local isPressed = isCrown or unit ~= nil
		Ragnarok.setState(gizmo,isPressed)
    end

end

function Actions.invertGizmo(context)
    -- "Invert active states of gizmos at location {0}."
	local location = context:getLocation(0)
	
    for i, gizmo in ipairs(Wargroove.getGizmosAtLocation(location)) do
		Ragnarok.invertGizmo(gizmo)
    end

end

function Actions.setThreatAtLocation(context)
    -- "Sets the threat level of {0} to {1}, sourcing the owner as {2} at {3} owned by {4}"
    local units = context:gatherUnits(2, 3, 4)  -- A useful function for gathering units of type, location, and player
	local location = context:getLocation(0)
    local value = context:getInteger(1)
    local result = {}
	local chosenUnit = nil
	for i, unit in ipairs(units) do
		 chosenUnit = unit
	end
	if chosenUnit then
		for i, pos in ipairs(location.positions) do
			 table.insert(result, {position = {x = pos.x, y = pos.y},  value = value})
		end
		Wargroove.setThreatMap(chosenUnit.id, result)
	end
end

local function findCentreOfLocation(location)
    local centre = { x = 0, y = 0 }
    for i, pos in ipairs(location.positions) do
        centre.x = centre.x + pos.x
        centre.y = centre.y + pos.y
    end
    centre.x = centre.x / #(location.positions)
    centre.y = centre.y / #(location.positions)

    return centre
end

local function spawnUnitCompareBestLocation(a, b)
--	return a.dist < b.dist
	if a.dist ~= b.dist then return a.dist < b.dist end
	if a.pos.y ~= b.pos.y then return a.pos.y < b.pos.y end
	return a.pos.x < b.pos.x
end

function Actions.spawnUnit(context)
    -- "Spawn {0} at {1} for {2} (silent = {3})"
    local unitClassId = context:getUnitClass(0)
    local location = context:getLocation(1)
    local playerId = context:getPlayerId(2)
    local silent = context:getBoolean(3)

    local candidates = {}

    if location == nil then
        -- No location, use centre of map
        local mapSize = Wargroove.getMapSize()
        local cX = math.floor(mapSize.x / 2)
        local cY = math.floor(mapSize.y / 2)
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                local pos = { x = x, y = y }
                if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                    local dx = x - cX
                    local dy = y - cY
                    local dist = math.abs(dx) + math.abs(dy)
                    table.insert(candidates, { pos = pos, dist = dist })
                end
            end
        end
    else
        -- Find the centre of the location
        local centre = findCentreOfLocation(location)

        -- All candidates
        for i, pos in ipairs(location.positions) do
            if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                local dx = pos.x - centre.x
                local dy = pos.y - centre.y
                local dist = math.abs(dx) + math.abs(dy)
                table.insert(candidates, { pos = pos, dist = dist })
            end
        end
    end

    -- Sort candidates
    table.sort(candidates, spawnUnitCompareBestLocation)

    -- Spawn at the best candidate
    if #candidates > 0 then
        local pos = candidates[1].pos
        if not silent then
            Wargroove.trackCameraTo(pos)
        end
        Wargroove.spawnUnit(playerId, pos, unitClassId, false)
        Wargroove.clearCaches()
        if silent or (not Wargroove.canCurrentlySeeTile(pos)) then
            -- Need to wait two frames to prevent being able to spawn on top of other units
            Wargroove.waitFrame()
            Wargroove.waitFrame()
        else
            Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
            Wargroove.playMapSound("spawn", pos)
            Wargroove.waitTime(0.5)
        end
    end
end

function Actions.spawnUnitClosestToLocation(context)
    -- "Spawn {0} at {1} as close as possible to {4} for {2} (silent = {3})"
    local unitClassId = context:getUnitClass(0)
    local location = context:getLocation(1)
    local playerId = context:getPlayerId(2)
    local silent = context:getBoolean(3)
    local targetLocation = context:getLocation(4)

    local candidates = {}

    local targetCenter = findCentreOfLocation(targetLocation)
    if location == nil then
        -- No location, use centre of map
        local mapSize = Wargroove.getMapSize()
        for x = 0, mapSize.x - 1 do
            for y = 0, mapSize.y - 1 do
                local pos = { x = x, y = y }
                if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                    local dx = x - targetCenter.x
                    local dy = y - targetCenter.y
                    local dist = math.abs(dx) + math.abs(dy)
                    table.insert(candidates, { pos = pos, dist = dist })
                end
            end
        end
    else
        -- Find the centre of the location

        -- All candidates
        for i, pos in ipairs(location.positions) do
            if Wargroove.getUnitIdAt(pos) == -1 and Wargroove.canStandAt(unitClassId, pos) then
                local dx = pos.x - targetCenter.x
                local dy = pos.y - targetCenter.y
                local dist = math.abs(dx) + math.abs(dy)
                table.insert(candidates, { pos = pos, dist = dist })
            end
        end
    end

    -- Sort candidates
    table.sort(candidates, spawnUnitCompareBestLocation)

    -- Spawn at the best candidate
    if #candidates > 0 then
        local pos = candidates[1].pos
        if not silent then
            Wargroove.trackCameraTo(pos)
        end
        Wargroove.spawnUnit(playerId, pos, unitClassId, false)
        Wargroove.clearCaches()
        if (not silent) and Wargroove.canCurrentlySeeTile(pos) then
            Wargroove.spawnMapAnimation(pos, 0, "fx/mapeditor_unitdrop")
            Wargroove.playMapSound("spawn", pos)
            Wargroove.waitTime(0.5)
        end
    end
end

function Actions.moveLocationToNextStructure(context)
    -- "Move location {0} to next {1} owned by {2} at {3} to the right."
    location = context:getLocation(0)
    units = context:gatherUnits(2, 1, 3)
    local center = findCentreOfLocation(location)
	nextLocation = {x = 1000, y = 0}
    for i, unit in ipairs(units) do
		if unit.pos.x<nextLocation.x and unit.pos.x>center.x then
			nextLocation = unit.pos
		end
    end
	if nextLocation.x~=1000 then
		print("I moved!")
		nextLocation.x = nextLocation.x+1
		Wargroove.moveLocationTo(location.id, nextLocation)
	end
end



return Actions
