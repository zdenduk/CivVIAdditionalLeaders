-- ===========================================================================
-- Czechia: Hussite War Wagon
-- Marks plots occupied by fortified War Wagons so XML combat requirements can
-- apply Wagenburg only while the unit is defending from a fortified position.
-- ===========================================================================

print("Hussite War Wagon: Wagenburg fortified-state script loaded.")

local WAR_WAGON_UNIT = "UNIT_CZECH_HUSSITE_WAR_WAGON"
local FORTIFIED_PROPERTY = "CZECH_HUSSITE_WAR_WAGON_FORTIFIED"

local markedPlotIndices = {}

function ClearWarWagonFortifiedPlots()
  for plotIndex, _ in pairs(markedPlotIndices) do
    local plot = Map.GetPlotByIndex(plotIndex)
    if plot ~= nil then
      plot:SetProperty(FORTIFIED_PROPERTY, nil)
    end
  end

  markedPlotIndices = {}
end

function IsFortifiedWarWagon(unit)
  if unit == nil then
    return false
  end

  local unitInfo = GameInfo.Units[unit:GetType()]
  if unitInfo == nil or unitInfo.UnitType ~= WAR_WAGON_UNIT then
    return false
  end

  return unit.GetFortifyTurns ~= nil and unit:GetFortifyTurns() > 0
end

function RefreshWarWagonFortifiedPlots()
  ClearWarWagonFortifiedPlots()

  for playerID = 0, PlayerManager.GetWasEverAliveCount() - 1 do
    local player = Players[playerID]
    if player ~= nil then
      local units = player:GetUnits()
      if units ~= nil then
        for _, unit in units:Members() do
          if IsFortifiedWarWagon(unit) then
            local plot = Map.GetPlot(unit:GetX(), unit:GetY())
            if plot ~= nil then
              plot:SetProperty(FORTIFIED_PROPERTY, 1)
              markedPlotIndices[plot:GetIndex()] = true
            end
          end
        end
      end
    end
  end
end

GameEvents.PlayerTurnStarted.Add(RefreshWarWagonFortifiedPlots)

if Events.UnitRemovedFromMap ~= nil then
  Events.UnitRemovedFromMap.Add(RefreshWarWagonFortifiedPlots)
end

if Events.UnitMoved ~= nil then
  Events.UnitMoved.Add(RefreshWarWagonFortifiedPlots)
end

RefreshWarWagonFortifiedPlots()
