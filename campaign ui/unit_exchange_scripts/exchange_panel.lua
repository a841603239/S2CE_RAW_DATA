local utils = require("Utilities")
local this = UIComponent(Address)
local group = UIComponent(this:Find("group"))
local selected, details, other_panel
local tabs = {
  Units = {
    tab = UIComponent(this:Find("tab_units"))
  },
  Agents = {
    tab = UIComponent(this:Find("tab_agents"))
  },
  Ships = {
    tab = UIComponent(this:Find("tab_ships"))
  }
}
tabs.Units.group = UIComponent(tabs.Units.tab:Find(0))
tabs.Units.max_items = 20
tabs.Agents.group = UIComponent(tabs.Agents.tab:Find(0))
tabs.Agents.max_items = 3
tabs.Ships.group = UIComponent(tabs.Ships.tab:Find(0))
tabs.Ships.max_items = 10

function MaxItems(card_type)
  return tabs[card_type].max_items
end

function PassOnDrop(tab, dropped)
  if tabs[tab].group:GlobalExists("g_enabled") then
    SelectTab(tab)
    return tabs[tab].group:LuaCall("HandleDrop", dropped)
  end
  return dropped
end

function SelectFirstValidTab()
  for k, v in pairs(tabs) do
    if v.tab:ChildCount() > 0 then
      SelectTab(k)
      break
    end
  end
end

function SelectTab(tab)
  if selected ~= tab then
    if selected ~= nil then
      tabs[selected].tab:SetState("active", false)
      tabs[selected].group:SetVisible(false)
    end
    tabs[tab].tab:SetState("selected", false)
    tabs[tab].group:SetVisible(true)
    selected = tab
  end
end

function ShowUnits()
  other_panel:LuaCall("SelectTab", "Units")
  SelectTab("Units")
end

function ShowAgents()
  other_panel:LuaCall("SelectTab", "Agents")
  SelectTab("Agents")
end

function ShowShips()
  other_panel:LuaCall("SelectTab", "Ships")
  SelectTab("Ships")
end

function DisallowTypeExchange(type)
  tabs[type].group:LuaCall("DisableAll")
end

function Initialise(character, other_character, garrison, other_garrison, cost, target, the_other_panel, max_units_per_navy)
  selected = nil
  other_panel = the_other_panel
  tabs.Ships.max_items = max_units_per_navy
  tabs.Units.group:LuaCall("SetCardType", "Units")
  tabs.Agents.group:LuaCall("SetCardType", "Agents")
  tabs.Ships.group:LuaCall("SetCardType", "Ships")
  local other_target = character ~= nil and character or garrison
  if character ~= nil then
    details = CampaignUI.RetrieveContainedEntitiesFromCharacter(character, target)
  elseif garrison ~= nil then
    details = CampaignUI.RetrieveContainedEntitiesFromGarrison(garrison, target)
  end
  if other_character ~= nil then
    other_details = CampaignUI.RetrieveContainedEntitiesFromCharacter(other_character, other_target)
  elseif other_garrison ~= nil then
    other_details = CampaignUI.RetrieveContainedEntitiesFromGarrison(other_garrison, other_target)
  end
  UIComponent(this:Find("subheader")):SetStateText(details.ContainerName)
  for k, v in pairs(tabs) do
    v.tab:SetState("unselected", false)
    v.group:SetVisible(false)
  end
  local card_manager_ptr = tabs.Units.group:LuaCall("CardManagerPtr")
  local card_manager = UICardManager(card_manager_ptr)
  card_manager:RemoveAll()
  if (details.Units == nil or #details.Units == 0) and (other_details.Units == nil or #other_details.Units == 0) then
    tabs.Units.tab:SetState("inactive")
  else
    tabs.Units.tab:SetState("active")
    if details.Units ~= nil then
      for i, v in ipairs(details.Units) do
        local active = cost <= v.ActionPoints and v.Transferable
        local card = UIComponent(CampaignUI.CreateLandUnitCard("UnitCard" .. i, v.Address, tabs.Units.group:Address(), 0, 0, false, false, not CampaignUI.IsTimedMultiplayerGame(), card_manager_ptr))
        card:SetState(active and "active" or "inactive")
      end
    end
  end
  tabs.Units.group:Layout()
  local card_manager_ptr = tabs.Agents.group:LuaCall("CardManagerPtr")
  local card_manager = UICardManager(card_manager_ptr)
  card_manager:RemoveAll()
  if (details.Agents == nil or #details.Agents == 0) and (other_details.Agents == nil or #other_details.Agents == 0) then
    tabs.Agents.tab:SetState("inactive")
  else
    tabs.Agents.tab:SetState("active")
    if details.Agents ~= nil then
      for i, v in ipairs(details.Agents) do
        local card = UIComponent(CampaignUI.CreateExchangeCharacterCard("AgentCard" .. i, v.Address, tabs.Agents.group:Address(), 0, 0, card_manager_ptr, cost <= v.ActionPoints))
        if cost > v.ActionPoints then
          card:SetState("UnSelectable")
        else
          card:SetMoveable(true)
        end
      end
    end
  end
  tabs.Agents.group:Layout()
  local card_manager_ptr = tabs.Ships.group:LuaCall("CardManagerPtr")
  local card_manager = UICardManager(card_manager_ptr)
  card_manager:RemoveAll()
  if (details.Ships == nil or #details.Ships == 0) and (other_details.Ships == nil or #other_details.Ships == 0) then
    tabs.Ships.tab:SetState("inactive")
  else
    tabs.Ships.tab:SetState("active")
    if details.Ships ~= nil then
      for i, v in ipairs(details.Ships) do
        local active = cost <= v.ActionPoints and v.Transferable
        local card = UIComponent(CampaignUI.CreateNavalUnitCard("ShipCard" .. i, v.Address, tabs.Ships.group:Address(), 0, 0, false, false, not CampaignUI.IsTimedMultiplayerGame(), card_manager_ptr))
        card:SetState(active and "active" or "inactive")
      end
    end
  end
  tabs.Ships.group:Layout()
  if details.Ships ~= nil and #details.Ships > 1 then
    ShowShips()
  elseif details.Units ~= nil and #details.Units > 1 then
    ShowUnits()
  else
    ShowAgents()
  end
end

function RecieveCards(cards, tab, is_swapping)
  local left_over = {}
  local exchanged = false
  if tab ~= selected then
    SelectTab(tab)
  end
  local grp = tabs[tab].group
  for i, v in ipairs(cards) do
    local p = UIComponent(v):Parent(false)
    if p ~= nil then
      p = UIComponent(p)
    end
    local limit = tabs[tab].max_items
    out.shane("RecieveCards: " .. tab .. ", Limit (" .. limit .. "). ChildCount (" .. grp:ChildCount() .. ")")
    if limit > grp:ChildCount() and (p == nil or is_swapping == true or p:LuaCall("CanBeRemoved", 1)) then
      grp:Adopt(v)
      exchanged = true
    else
      left_over[#left_over + 1] = v
    end
  end
  if exchanged == true then
    CampaignUI.UnitsExchanged()
  end
  return left_over
end

function RemoveCards(cards, tab, is_swapping)
  local grp = tabs[tab].group
  for i, v in ipairs(cards) do
    if is_swapping == true or grp:LuaCall("CanBeRemoved", 1) then
      grp:Divorce(v)
    end
  end
end

function Cards()
  return tabs.Units.group:LuaCall("Cards"), tabs.Ships.group:LuaCall("Cards"), tabs.Agents.group:LuaCall("Cards")
end

function Selected()
  return tabs[selected].group:LuaCall("Selected"), selected
end

function DeselectAll()
  tabs[selected].group:LuaCall("DeselectAll")
end

function HasSelection()
  return #tabs[selected].group:LuaCall("Selected") > 0
end

function HasValidSelection(other_panels_selections)
  return HasSelection() and (0 < other_panels_selections or tabs[selected].group:LuaCall("CanBeRemoved", #tabs[selected].group:LuaCall("Selected")))
end

function HasSpace()
  return #tabs[selected].group:LuaCall("Cards") < tabs[selected].max_items
end
