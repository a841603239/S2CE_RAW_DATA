local utils = require("Utilities")
local this = UIComponent(Address)

function Initialise(entries, region, faction, slot_key)
  local num_entries = #entries
  if 5 < num_entries then
    num_entries = 5
  end
  local sorted_entries = {}
  for i = 1, num_entries do
    if entries[i].New ~= true then
      sorted_entries[#sorted_entries + 1] = entries[i]
    end
  end
  for i = 1, num_entries do
    if entries[i].New == true then
      sorted_entries[#sorted_entries + 1] = entries[i]
    end
  end
  for i = 1, num_entries do
    local tech = UIComponent(this:Find("tech_window" .. i))
    tech:LuaCall("Initialise", sorted_entries[i].Key, region, faction, slot_key)
    local image = UIImage(sorted_entries[i].IconFilename)
    image:SetComponentTexture(tech:Address(), 0)
    tech:SetTooltipText(sorted_entries[i].Name, true)
    tech:SetVisible(true)
    if sorted_entries[i].New == true then
      utils.PropagateShader(tech:Address(), "brighten_t0", 0.5)
    end
  end
end
