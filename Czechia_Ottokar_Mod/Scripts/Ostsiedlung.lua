-- ===========================================================================
-- Czechia: Ostsiedlung
-- Non-capital cities founded on hills start with 2 Population.
-- Until Nationalism, those cities receive 1 Culture per turn.
-- After unlocking Nationalism, those cities lose 5 Loyalty per turn.
-- ===========================================================================

print("Ostsiedlung: Czechia Ostsiedlung script loaded.")

local CZECHIA_CIVILIZATION = "CIVILIZATION_CZECHIA"
local NATIONALISM_CIVIC = "CIVIC_NATIONALISM"
local OSTSIEDLUNG_PROPERTY = "CZECHIA_OSTSIEDLUNG_CITY"
local OSTSIEDLUNG_CULTURE_MODIFIER = "CZECHIA_OSTSIEDLUNG_PRE_NATIONALISM_CULTURE"
local OSTSIEDLUNG_CULTURE_MODIFIER_ATTACHED = "CZECHIA_OSTSIEDLUNG_CULTURE_MODIFIER_ATTACHED"
local OSTSIEDLUNG_LOYALTY_MODIFIER = "CZECHIA_OSTSIEDLUNG_NATIONALISM_LOYALTY"
local OSTSIEDLUNG_LOYALTY_MODIFIER_ATTACHED = "CZECHIA_OSTSIEDLUNG_LOYALTY_MODIFIER_ATTACHED"

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

function RaiseCityToTwoPopulation(city)
  if city == nil then
    return
  end

  local amountToAdd = 2 - city:GetPopulation()

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

function EnsureOstsiedlungLoyaltyModifier(playerID, city)
  if city == nil or city:GetProperty(OSTSIEDLUNG_PROPERTY) ~= 1 then
    return
  end

  if not PlayerHasNationalism(playerID) then
    return
  end

  if city:GetProperty(OSTSIEDLUNG_LOYALTY_MODIFIER_ATTACHED) == 1 then
    return
  end

  if city.AttachModifierByID ~= nil then
    city:AttachModifierByID(OSTSIEDLUNG_LOYALTY_MODIFIER)
    city:SetProperty(OSTSIEDLUNG_LOYALTY_MODIFIER_ATTACHED, 1)
    print("Ostsiedlung: attached Nationalism loyalty modifier for player " .. tostring(playerID) .. ", city ID " .. tostring(city:GetID()))
  else
    print("Ostsiedlung error: no modifier attachment function was available.")
  end
end

function EnsureOstsiedlungCultureModifier(playerID, city)
  if city == nil or city:GetProperty(OSTSIEDLUNG_PROPERTY) ~= 1 then
    return
  end

  if city:GetProperty(OSTSIEDLUNG_CULTURE_MODIFIER_ATTACHED) == 1 then
    return
  end

  if city.AttachModifierByID ~= nil then
    city:AttachModifierByID(OSTSIEDLUNG_CULTURE_MODIFIER)
    city:SetProperty(OSTSIEDLUNG_CULTURE_MODIFIER_ATTACHED, 1)
    print("Ostsiedlung: attached pre-Nationalism culture modifier for player " .. tostring(playerID) .. ", city ID " .. tostring(city:GetID()))
  else
    print("Ostsiedlung error: no modifier attachment function was available.")
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
  RaiseCityToTwoPopulation(city)
  EnsureOstsiedlungCultureModifier(playerID, city)
  EnsureOstsiedlungLoyaltyModifier(playerID, city)

  print("Ostsiedlung: marked hill city for player " .. tostring(playerID) .. ", city ID " .. tostring(cityID))
end

function ApplyOstsiedlungLoyaltyPenalty(playerID)
  if not IsCzechiaPlayer(playerID) then
    return
  end

  local player = Players[playerID]
  if player == nil then
    return
  end

  for _, city in player:GetCities():Members() do
    EnsureOstsiedlungCultureModifier(playerID, city)
    EnsureOstsiedlungLoyaltyModifier(playerID, city)
  end
end

Events.CityInitialized.Add(OnCityInitialized)
GameEvents.PlayerTurnStarted.Add(ApplyOstsiedlungLoyaltyPenalty)
