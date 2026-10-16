dofile("data/ui/templates/template.TabGroup.lua")
local this = UIComponent(Address)

function SelectTab(tab)
  local listname = tabs[tab_ids[tab]]:Id()
  local topcomp = UIComponent(UIComponent(parent:Parent()):Parent())
  local isvisible = UIComponent(tabs[tab_ids[tab]]:Find(0)):Visible()
  local main_radar = UIComponent(UIComponent(Address):Parent())
  topcomp:LuaCall("SetMapMode", "campaign_radar")
  if isvisible then
    UIComponent(tabs[tab_ids[tab]]:Find(0)):SetVisible(false)
  else
    UIComponent(tabs[tab_ids[tab]]:Find(0)):SetVisible(true)
    if listname == "factions" then
      main_radar:InterfaceFunction("RefreshFactions")
    else
      if listname == "regions" then
        main_radar:InterfaceFunction("RefreshRegions")
      end
      if listname == "armies" then
        main_radar:InterfaceFunction("RefreshArmies")
      end
      if listname == "fleets" then
        main_radar:InterfaceFunction("RefreshFleets")
      end
      if listname == "agents" then
        main_radar:InterfaceFunction("RefreshAgents")
      end
      if listname == "victory_conditions" then
        main_radar:InterfaceFunction("RefreshVictoryConditions")
      end
    end
  end
  if selected ~= tab_ids[tab] then
    local address = tabs[tab_ids[tab]]:Address()
    for i, v in ipairs(tabs) do
      if v:Address() ~= address then
        if 0 < v:ChildCount() then
          UIComponent(v:Find(0)):SetVisible(false)
          local list_box = UIComponent(v:Find("list_box"))
          if 0 < list_box:ChildCount() then
            v:SetState("active")
          else
            v:SetState("inactive")
          end
        end
      else
        selected = i
        if 0 < v:ChildCount() then
          UIComponent(v:Find(0)):SetVisible(true)
        end
      end
    end
  end
  UIComponent(this:Parent()):InterfaceFunction("PositionEffects")
  return true
end
