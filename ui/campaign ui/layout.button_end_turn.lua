local utils = require("Utilities")
local message_handler = MessageManager
local panel_manager = PanelManager
local this = UIComponent(Address)
local root = UIComponent(Component.Root())
local end_turn_timer = UIComponent(this:Find("end_turn_timer"))
local multiplayer_timer_active = false
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function EndTurn()
  if this:CurrentState() ~= "inactive" and root:LuaCall("OnEndTurnClearPanels") then
    CampaignUI.EndTurn()
  end
end

function OnShortcut(func, ended)
  if ended == true then
    EndTurn()
  end
end
