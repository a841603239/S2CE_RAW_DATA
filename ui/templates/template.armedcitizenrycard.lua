local utils = require("Utilities")
local this = UIComponent(Address)
local banner = UIComponent(this:Find("Banner"))

function Initialise(unit_record)
  if unit_record.spying_data_level > utils.SPYING_UNIT_DATA_LEVEL_BASIC then
    banner:SetStateText(unit_record.Men)
  else
    banner:SetStateText("?")
  end
  this:SetTooltipText(unit_record.Name, true)
end
