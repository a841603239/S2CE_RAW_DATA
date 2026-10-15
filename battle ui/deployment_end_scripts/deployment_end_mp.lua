local utils = require("Utilities")
local this = UIComponent(Address)
local parent = UIComponent(this:Parent())
local timer_fill = UIComponent(this:Find("white_fill"))
local time_remaining_txt = UIComponent(this:Find("dy_time_remaining"))
local players_ready_txt = UIComponent(this:Find("dy_players_ready"))
local is_multiplayer, g_deployment_start_time
max_deployment_time = 60

function DeployDismissed()
  parent:LuaCall("DeployDismissed")
end
