-- ===========================================================================
-- Czechia: Ostsiedlung
-- Non-capital cities founded on hills start with 3 Population.
-- After unlocking Nationalism, those cities lose 5 Loyalty per turn.
-- ===========================================================================

print("Ostsiedlung: Czechia Ostsiedlung script loaded.")

local CZECHIA_CIVILIZATION = "CIVILIZATION_CZECHIA"
local NATIONALISM_CIVIC = "CIVIC_NATIONALISM"
local OSTSIEDLUNG_PROPERTY = "CZECHIA_OSTSIEDLUNG_CITY"
local OSTSIEDLUNG_LAST_LOYALTY_TURN = "CZECHIA_OSTSIEDLUNG_LAST_LOYALTY_TURN"

function IsCzechiaPlayer(playerID)
  local playerConfig = PlayerConfigurations[playerID]
  return playerConfig ~= nil and playerConfig:GetCivilizationTypeName() == CZECHIA_CIVILIZATION
end

function PlayerHasNationalism(playerID)
  local player = Players[playerID]
  if player == nil then
    return false
  end

  local civic = GameInfo.Civics[NATIONALISM_CIVIC]
  if civic == nil then
    return false
  end

  local playerCulture = player:GetCulture()
  return playerCulture ~= nil and playerCulture:HasCivic(civic.Index)
end

function IsCapitalCity(playerID, city)
  local player = Players[playerID]
  if player == nil or city == nil then
    return false
  end

  local capital = player:GetCities():GetCapitalCity()
  return capital ~= nil and capital:GetID() == city:GetID()
end

function IsHillCity(city)
  if city == nil then
    return false
  end

  local plot = Map.GetPlot(city:GetX(), city:GetY())
  if plot == nil then
    return false
  end

  return plot:IsHills()
end

function RaiseCityToThreePopulation(city)
  if city == nil then
    return
  end

  local amountToAdd = 3 - city:GetPopulation()

  if amountToAdd <= 0 then
    return
  end

  if CityManager ~= nil and CityManager.ChangePopulation ~= nil then
    CityManager.ChangePopulation(city, amountToAdd)
  elseif city.ChangePopulation ~= nil then
    city:ChangePopulation(amountToAdd)
  else
    print("Ostsiedlung error: no population change function was available.")
  end
end

function OnCityInitialized(playerID, cityID, x, y)
  if not IsCzechiaPlayer(playerID) then
    return
  end

  local city = CityManager.GetCity(playerID, cityID)
  if city == nil then
    return
  end

  if city:GetProperty(OSTSIEDLUNG_PROPERTY) == 1 then
    return
  end

  if IsCapitalCity(playerID, city) then
    return
  end

  if not IsHillCity(city) then
    return
  end

  city:SetProperty(OSTSIEDLUNG_PROPERTY, 1)
  RaiseCityToThreePopulation(city)

  print("Ostsiedlung: marked hill city for player " .. tostring(playerID) .. ", city ID " .. tostring(cityID))
end

function ApplyOstsiedlungLoyaltyPenalty(playerID)
  if not IsCzechiaPlayer(playerID) or not PlayerHasNationalism(playerID) then
    return
  end

  local player = Players[playerID]
  if player == nil then
    return
  end

  local currentTurn = Game.GetCurrentGameTurn()

  for _, city in player:GetCities():Members() do
    if city:GetProperty(OSTSIEDLUNG_PROPERTY) == 1 then
      local lastTurnApplied = city:GetProperty(OSTSIEDLUNG_LAST_LOYALTY_TURN)

      if lastTurnApplied ~= currentTurn then
        if city.ChangeLoyalty ~= nil then
          city:ChangeLoyalty(-5)
        end

        city:SetProperty(OSTSIEDLUNG_LAST_LOYALTY_TURN, currentTurn)
      end
    end
  end
end

Events.CityInitialized.Add(OnCityInitialized)
GameEvents.PlayerTurnStarted.Add(ApplyOstsiedlungLoyaltyPenalty)
