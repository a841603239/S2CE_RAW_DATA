local this = UIComponent(Address)
local m_building, m_zoom_func

function Initialise(details, type_a_bg, zoom_func)
  if type_a_bg then
    this:SetState("A_normal")
  else
    this:SetState("B_normal")
  end
  m_building = details
  m_zoom_func = zoom_func
  local image = UIImage(details.Icon)
  image:SetComponentTexture(this:Find("dy_icon"), 0)
  UIComponent(this:Find("dy_name")):SetStateText(details.Name)
  UIComponent(this:Find("dy_location")):SetStateText(details.Location)
  local pips = UIComponent(this:Find("upgrade_pips"))
  for i = 0, 6 do
    local pip = UIComponent(pips:Find(i))
    if i <= details.Level then
      pip:SetState("filled")
    else
      pip:SetState("empty")
    end
    pip:SetVisible(i <= details.MaxLevel)
  end
  this:SetEventCallback("OnMouseLDblClick", OnLeftDblClick)
  this:SetTooltipText(CampaignUI.LocalisationString("lists_tooltip"), true)
end

function OnLeftDblClick()
  if m_zoom_func ~= nil then
    m_zoom_func({
      X = m_building.PosX,
      Y = m_building.PosY
    })
  end
end

function OnLeftClickUp()
end

function OnRightClickUp()
  ShowInfoPanel()
end

function ShowInfoPanel()
  UIComponent(Component.Root()):LuaCall("ShowFullBuildingInfo", m_building.BuildingKey, m_building.RegionKey, m_building.FactionKey, m_building.SlotKey)
end

function CloseInfoPanel()
  UIComponent(Component.Root()):LuaCall("InfoPanelNotUsed")
end
