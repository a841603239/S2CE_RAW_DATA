dofile("data/ui/templates/template.TabGroup.lua")
local old_select_tab = SelectTab

function SelectTab(tab)
  local list_box = UIComponent(tabs[tab_ids[tab]]:Find("list_box"))
  if list_box ~= nil then
    for i = 0, list_box:ChildCount() - 1 do
      local row_item = UIComponent(list_box:Find(i))
      local nation = UIComponent(row_item:Find("nation_DY")):GetStateText()
      local attitude = UIComponent(row_item:Find("attitude_DY")):GetStateText()
      row_item:LuaCall("Initialise", tostring(nation), tostring(attitude))
    end
  end
  return old_select_tab(tab)
end
