local utilities = require("Utilities")
local card
local effects_bg = UIComponent(Component.Call("effects_bg.Address"))
local this = UIComponent(Address)

function Initialise(details)
  if card ~= nil then
    Component.Destroy(card)
  end
  effects_bg:DestroyChildren()
  this:SetTooltipText(details.Name .. "||" .. details.Post)
  if details ~= nil then
    card = utilities.CreateCharacterCard(details, "Minister", Address, 0, 0, false, false, false)
    local y = 0
    for i, v in ipairs(details.Effects) do
      local effect = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/minister_effect_cartouche", "effect" .. i, effects_bg:Address(), -3, y))
      out.tom("Adding effect")
      effect:LuaCall("Initialise", v)
      y = y + 35
    end
  end
end
