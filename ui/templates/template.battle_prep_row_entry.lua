local utils = require("Utilities")
local this = UIComponent(Address)
local status_icon = UIComponent(this:Find("status"))
local dropdown = UIComponent(this:Find("mini_flag"))
local m_panel, m_era, m_player_name
local avatar = MPAvatar(FrontEnd.MPOnlinePresence())
g_player = nil
g_ai = false
UnitSetup = nil
Team = nil
this:SetState("unselected")

function OnSelect()
  local p = this:Parent("main_panel", false)
  if p == nil then
    p = this:Parent("mp_battle3_scenario")
  end
  UIComponent(p):LuaCall("PlayerSelected", g_player, Team)
end

function SelectFaction(fac, setup, index_into_repeated_factions)
  local details = FrontEnd.FactionDetails(fac, m_era)
  local flag = UIImage(details.FlagPath .. "/flag_132.tga")
  flag:SetComponentTexture(dropdown:Address(), 0)
  local number = dropdown:Find("number", false)
  if number ~= nil then
    number = UIComponent(number)
    if 0 < index_into_repeated_factions then
      number:SetVisible(true)
      number:SetStateText(tostring(index_into_repeated_factions))
    else
      number:SetVisible(false)
    end
  end
  local notify = dropdown:GlobalExists("SelectOption")
  if notify ~= nil then
    notify(fac, false)
  end
  if setup ~= nil then
    UnitSetup = setup
  end
end

function NotifyFactionSelected(faction)
  m_panel:LuaCall("NotifyFactionSelected", faction, Team, g_player)
end

function SetAsAI(ai)
  g_ai = ai
  if ai then
    status_icon:SetState("AI")
  else
    status_icon:SetState("not_ready")
  end
end

function SetReady(ready)
  if ready then
    status_icon:SetState("ready")
  else
    SetAsAI(g_ai)
  end
end

function SetSetup(s)
  UnitSetup = utils.CopyTable(s)
  return FullDetails()
end

function SwapTeam(new_team)
  Team = new_team
  if g_ai == false then
    local id = m_panel:LuaCall("PlayerIdFromSlot", g_player)
    avatar:RequestAvatarAndLoadFallback(id, this:Find("avatar"), 0)
  end
end

function Initialise(player_id, ai, faction, team_index, isNaval, panel, local_player_leads, era, player_name, command_stars)
  out.tom("Initialising player", player_id, ai, faction, team_index, local_player_leads, command_stars)
  g_player = player_id
  Team = team_index
  m_panel = panel
  m_era = era
  m_player_name = player_name
  local player_rank = UIComponent(this:Find("player_rank"))
  if command_stars ~= nil then
    player_rank:SetState(tostring(utils.Min(command_stars, 8)))
    player_rank:SetVisible(true)
  else
    player_rank:SetVisible(false)
  end
  SetAsAI(ai)
  if ai == false then
    SetImage()
  end
  UnitSetup = {Faction = faction}
  SetTeamLeaderStatus(local_player_leads)
  if dropdown:GlobalExists("Initialise") then
    return dropdown:LuaCall("Initialise", isNaval, faction, era)
  else
    return faction
  end
end

function SetImage()
  if set == true and g_player ~= nil and g_ai == false then
    local id = m_panel:LuaCall("PlayerIdFromSlot", g_player)
    avatar:RequestAvatarAndLoadFallback(id, this:Find("avatar"), 0)
  end
end

function FactionAllowed(fac_key)
  return dropdown:LuaCall("FactionPresent", fac_key)
end

function FullDetails()
  local d = UnitSetup
  d.Name = m_player_name
  d.IsHuman = g_ai == false
  return d
end

function UnitCount()
  if UnitSetup ~= nil and UnitSetup.Units ~= nil and UnitSetup.Ships ~= nil then
    return #UnitSetup.Units + #UnitSetup.Ships
  else
    return 0
  end
end

function SetTeamLeaderStatus(local_player_leads)
  local is_local_player = m_panel:LuaCall("IsLocalPlayer", g_player)
  local is_local_hosting = m_panel:LuaCall("IsLocalPlayerHost")
  local show_kick = is_local_player == false and (local_player_leads == true or is_local_hosting == true) and (local_player_leads ~= false or g_ai ~= true)
  UIComponent(this:Find("button_kick")):SetVisible(show_kick)
  UIComponent(this:Find("leader_icon")):SetVisible(local_player_leads and is_local_player)
  if is_local_player or local_player_leads and g_ai then
    if this:CurrentState() == "inactive" then
      this:SetState("unselected")
      UIComponent(this:Find("mini_flag")):SetState("up")
    end
  else
    this:SetState("inactive")
    UIComponent(this:Find("mini_flag")):SetState("inactive")
  end
end
