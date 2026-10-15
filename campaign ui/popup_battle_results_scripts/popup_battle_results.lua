local this = UIComponent(Address)
local battle_details = UIComponent(this:Find("battle_details"))
local list_box = UIComponent(battle_details:Find("list_box"))

function CanSortColumn(column)
  local last_value
  for i = 1, list_box:ChildCount() do
    local entry = UIComponent(list_box:Find(i - 1))
    local value = entry:LuaCall("GetVar", column)
    if last_value ~= nil and value ~= last_value then
      return true
    end
    last_value = value
  end
  return false
end

function PanelManagerClose()
  this:InterfaceFunction("PanelManagerClose")
end
