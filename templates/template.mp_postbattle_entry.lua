local utils = require("Utilities")
local this = UIComponent(Address)
local type = UIComponent(this:Find("unit_type"))
local custom_name = UIComponent(this:Find("custom_name"))
local end_xp = UIComponent(this:Find("experience_new"))
local start_xp = UIComponent(this:Find("experience_old"))
local deployed = UIComponent(this:Find("stat1"))
local lost = UIComponent(this:Find("stat2"))
local kills = UIComponent(this:Find("stat3"))
local icon = UIComponent(this:Find("icon"))
local g_details

function InitPostBattleStatEntry(details)
  out.dylan("in InitPostBattleStatEntry for:" .. details.name)
  g_details = details
  type:SetStateText(details.name)
  if details.CustomName ~= nil then
    custom_name:SetStateText(details.CustomName)
  else
    custom_name:SetVisible(false)
  end
  lost:SetStateText(details.lost)
  kills:SetStateText(details.kills)
  deployed:SetStateText(details.deployed)
  start_xp:SetState(details.start_xp)
  end_xp:SetState(details.end_xp)
end

function Details()
  return g_details
end

function LessThan(c, column)
  local our_details = g_details
  local their_details = UIComponent(c):LuaCall("Details")
  if column == 0 then
    return our_details.name < their_details.name
  elseif column == 1 then
    return our_details.end_xp < their_details.end_xp
  elseif column == 2 then
    return our_details.deployed < their_details.deployed
  elseif column == 3 then
    return our_details.lost < their_details.lost
  elseif column == 4 then
    return our_details.kills < their_details.kills
  else
    return false
  end
end
