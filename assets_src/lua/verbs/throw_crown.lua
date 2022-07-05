local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Ragnarok = require "initialized/ragnarok"

local throwCrown = Verb:new()

local stateKey = "crown"

function throwCrown:getMaximumRange(unit, endPos)
	if unit.unitClassId == "commander_vesper" then
		return 2
	end
    return 1
end

function throwCrown:getTargetType()
    return "all"
end

function throwCrown:canExecuteAnywhere(unit)
    local crown = Wargroove.getUnitState(unit, stateKey)
    return crown ~= nil
end

function throwCrown:canExecuteWithTarget(unit, endPos, targetPos, strParam)    
    local gizmo = Wargroove.getGizmoAt(targetPos)
    local targetUnit = Wargroove.getUnitAt(targetPos)
    return not targetUnit and gizmo and gizmo.type == "pressure_plate"
end

local crownAnimation = "ui/icons/fx_crown"
function throwCrown:execute(unit, targetPos, strParam, path)
    Ragnarok.removeCrown()
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefGoldReleased", targetPos)
    Wargroove.spawnMapAnimation(unit.pos, 0, "fx/ransack_1", "default", "over_units", { x = 12, y = 0 })
    Wargroove.updateUnit(unit)
    Wargroove.waitTime(1.0)
    Wargroove.spawnMapAnimation(targetPos, 0, "fx/ransack_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.waitTime(0.2)
    Wargroove.playMapSound("thiefDeposit", targetPos)
    Wargroove.waitTime(0.4)
    Ragnarok.dropCrown(unit.playerId,targetPos)
end

return throwCrown
