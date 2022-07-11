local Wargroove = require "wargroove/wargroove"


local Ragnarok = {}
Ragnarok.seaTiles = {"sea","sea_alt", "ocean","reef"}
Ragnarok.groundTags = {"type.ground.light", "type.ground.heavy"}
function Ragnarok.init()
end

local cantAttackBuildingsSet = {}
local goldRobbed = {}
local crownID = {}
local crownPos = {}
local crownBearerID = {}
local crownAnimation = "ui/icons/fx_crown"
local crownStateKey = "crown"

function Ragnarok.addAIToCantAttackBuildings(playerId)
	cantAttackBuildingsSet[tostring(playerId)] = true
end

function Ragnarok.addGoldRobbed(playerId, amount)
	print("addGoldRobbed starts here")
	print(playerId)
	print(amount)
	print("type")
	print(type(amount))
	if goldRobbed[playerId] then
		goldRobbed[playerId] = goldRobbed[playerId]+amount
	else
		goldRobbed[playerId] = amount
	end
	print(goldRobbed[playerId])
end

function Ragnarok.getGoldRobbed(playerId)
	print("getGoldRobbed starts here")
	local robbedMoney = goldRobbed[playerId]
	print(robbedMoney)
	print("type")
	print(type(robbedMoney))
	if robbedMoney then return robbedMoney end
	return 0
end

function Ragnarok.cantAttackBuildings(playerId)
	if cantAttackBuildingsSet[tostring(playerId)] then return true end
	return false
end

function Ragnarok.getCrownPos()
	local crown = Wargroove.getUnitById(crownID)
	if crown ~= nil then
		return crownPos
	end
	local crownBearer = Wargroove.getUnitById(crownBearerID)
	if crownBearer ~= nil then
		return crownBearer.pos
	end
	
	return nil
end

function Ragnarok.hasCrown(unit)
	return crownBearerID and crownBearerID == unit.id 
end

function Ragnarok.removeCrown()
	local crown = Wargroove.getUnitById(crownID)
	if crown ~= nil then
		crown.health = 0
		Wargroove.updateUnit(crown)
	end
	local crownBearer = Wargroove.getUnitById(crownBearerID)
	if crownBearer ~= nil then
		for i, _stateKey in ipairs(crownBearer.state) do
			if (_stateKey.key == crownStateKey) then
				_stateKey.value = nil
				_stateKey.key = nil
				_stateKey = nil
			end
		end

		if Wargroove.hasUnitEffect(crownBearer.id, crownAnimation) then
			Wargroove.deleteUnitEffectByAnimation(crownBearer.id, crownAnimation)
		end
		Wargroove.updateUnit(crownBearer)
	end
end

function Ragnarok.dropCrown(playerId,targetPos)
	Ragnarok.removeCrown()
	local startingState = {}
    local pos = {key = "pos", value = "" .. targetPos.x .. "," .. targetPos.y}
    table.insert(startingState, pos)
	crownID = Wargroove.spawnUnit(playerId, {x = -100, y = -100}, "crown", false, "", startingState)
	crownPos = targetPos
	crownBearerID = nil
	return crownID
end

function Ragnarok.grabCrown(unit)
	Ragnarok.removeCrown()
	Wargroove.setUnitState(unit, crownStateKey, "")
	if not Wargroove.hasUnitEffect(unit.id, crownAnimation) then
		Wargroove.spawnUnitEffect(unit.id, crownAnimation, "idle", startAnimation, true, false)
	end
	crownBearerID = unit.id
	Wargroove.updateUnit(unit)
	return
end

function Ragnarok.cantAttackBuildings(playerId)
	if cantAttackBuildingsSet[tostring(playerId)] then return true end
	return false
end

local activator = {}
local invertedGizmos = {}

local gizmoSoundMapOn = {["pressure_plate"] = "cutscene/stoneScrape1",["drawbridge_left"] = "cutscene/drawbridgeDrop",["drawbridge_right"] = "cutscene/drawbridgeDrop",["drawbridge_top"] = "cutscene/drawbridgeDrop",["drawbridge_down"] = "cutscene/drawbridgeDrop"}
local gizmoSoundMapOff = {["pressure_plate"] = "cutscene/stoneScrape2",["drawbridge_left"] = "cutscene/drawbridgeRaise",["drawbridge_right"] = "cutscene/drawbridgeRaise",["drawbridge_top"] = "cutscene/drawbridgeRaise",["drawbridge_down"] = "cutscene/drawbridgeRaise"}

function Ragnarok.setState(gizmo, state, playSound)
	if playSound == nil then playSound = true end
	print("Ragnarok.setState(gizmo,state) starts here")
	print(invertedGizmos[Ragnarok.generateGizmoKey(gizmo)]) 
	local changedState = Ragnarok.getGizmoState(gizmo) ~= state
	local soundPlayed
	print(changedState)
	if changedState then
		local soundOn = gizmoSoundMapOn[gizmo.type]
		local soundOff = gizmoSoundMapOff[gizmo.type]
		if soundOn and state then
			soundPlayed = soundOn
		end
		if soundOff and not state then
			soundPlayed = soundOff
		end
	end
	if playSound then
		Wargroove.playMapSound(soundPlayed, gizmo.pos)
	end
	local key = Ragnarok.generateGizmoKey(gizmo)
	gizmo:setState(not(state  == (invertedGizmos[key]==true)))
	return {changedState = changedState, soundPlayed = soundPlayed}
end

function Ragnarok.wouldStateChange(gizmo, state)
	local changedState = Ragnarok.getGizmoState(gizmo) ~= state
	return changedState
end

function Ragnarok.wouldAnyStatesChange(gizmos, state)
	local changedState = false
    for i, gizmo in ipairs(gizmos) do
		changedState = changedState or Ragnarok.wouldStateChange(gizmo,state)
    end
	return changedState
end

function Ragnarok.setStates(gizmos, state, playSound)
	print("Ragnarok.setStates starts here") 
	if playSound == nil then playSound = true end
	local changedState = false
	local soundsPlayed = {}
	local soundCount = 0
    for i, gizmo in ipairs(gizmos) do
		local result = Ragnarok.setState(gizmo,state, false)
		sound = result.soundPlayed
		changedState = changedState or result.changedState
		if sound and playSound and soundsPlayed[sound] == nil then
			print(sound)
			print(soundsPlayed[sound])
			Wargroove.playMapSound(sound, gizmo.pos)
			soundsPlayed[sound] = true
			soundCount = soundCount + 1
		end
    end
	return changedState
end

function Ragnarok.setActivator(gizmo,state)
    activator[gizmo] = true
	if state == false then activator[gizmo] = nil end
end

function Ragnarok.invertGizmo(gizmo)
	gizmo:setState(not gizmo:getState())
	local key = Ragnarok.generateGizmoKey(gizmo)
	if invertedGizmos[gizmo] then invertedGizmos[key] = nil
	else invertedGizmos[key] = true
	end
end

function Ragnarok.getGizmoState(gizmo)
	local key = Ragnarok.generateGizmoKey(gizmo)
	return not(gizmo:getState()  == (invertedGizmos[key]==true))
end

function Ragnarok.generateGizmoKey(gizmo)
	return gizmo.pos.x*1000+gizmo.pos.y --Should work as long as people don't make maps taller than 1000 tiles.
end

function Ragnarok.isActivator(gizmo)
	return activator[gizmo] == true
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

return Ragnarok
