local utils = require("Utilities")
local this = UIComponent(Address)
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(entries, region_key, faction_key, slot_key)
  local num_entries = #entries
  if 6 < num_entries then
    num_entries = 6
  end
  for i = 1, num_entries do
    local building = UIComponent(this:Find("building_icon" .. i))
    ShaneOutput("Initialising construction effect with key " .. entries[i].Key .. " and region " .. tostring(region))
    building:LuaCall("Initialise", entries[i], region_key, faction_key, slot_key, entries[i].potential_recruitment)
  end
end
