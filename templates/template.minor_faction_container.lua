local this = UIComponent(Address)
local template = this:Find("minor_faction_button_template")
local num_columns = tonumber(this:GetProperty("NumColumns"))
local cell_spacing = tonumber(this:GetProperty("CellSpacing"))
local stagger_offset = tonumber(this:GetProperty("StaggerOffset")) or 0

function Initialise(faction_list)
  local col = 0
  local row = 0
  local num_rows = math.ceil(#faction_list / num_columns)
  local total_width = cell_spacing * num_columns
  if 1 < num_rows then
    total_width = total_width + stagger_offset
  end
  local total_height = cell_spacing * num_rows
  local offset_x = (this:Width() - total_width) / 2
  local offset_y = (this:Height() - total_height) / 2
  local x = offset_x
  local y = offset_y
  for _, faction in ipairs(faction_list) do
    local details = FrontEnd.FactionDetails(faction)
    local flag_path = details.FlagPath .. "/mon_64.tga"
    local faction_component = UIComponent(Component.CreateFromComponent(template, "button_" .. details.Key, Address, x, y, {}, {}))
    faction_component:SetTooltipText(details.Name, true)
    faction_component:SetVisible(true)
    UIImage(flag_path):SetComponentTexture(faction_component:Address(), 0, false)
    col = col + 1
    if col < num_columns then
      x = x + cell_spacing
    else
      col = 0
      row = row + 1
      if row % 2 == 0 then
        x = offset_x
      else
        x = offset_x + stagger_offset
      end
      y = y + cell_spacing
    end
  end
  Component.Destroy(template)
end
