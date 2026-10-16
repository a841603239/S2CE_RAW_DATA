local this = UIComponent(Address)
local diplomacy = UIComponent(this:Parent("diplomacy_panel"))

function RemoveDiplomacyItem()
  diplomacy:LuaCall("RemoveDiplomacyItem", Address)
end

function RemoveHostage()
  diplomacy:LuaCall("RemoveHostage", Address)
  local hostage = UIComponent(this:Find("hostage"))
  hostage:SetVisible(false)
end

function ShowRegion(region)
  diplomacy:LuaCall("ShowRegion", region)
end
