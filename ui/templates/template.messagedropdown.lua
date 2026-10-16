local utils = require("Utilities")
local this = UIComponent(Address)
local icon = UIComponent(this:Find("Icon"))
local banner = UIComponent(this:Find("banner_rollout"))

function Initialise(d, root, env)
  icon:LuaCall("Initialise", d, root, env)
  if d.Title ~= nil then
    UIComponent(banner:Find("dy_title")):SetStateText(d.Title)
    out.dylan("Setting msg icon title to: " .. d.Title)
  end
  if d.Data ~= nil and d.Data.Title ~= nil then
    UIComponent(banner:Find("dy_title")):SetStateText(d.Data.Title)
    out.dylan("Setting msg icon title to: " .. d.Data.Title)
  end
end

function SetMouseOver(over)
end

function Destroy(msg)
  return icon:LuaCall("Destroy", msg)
end

function ShowMessage(requires_response)
  icon:LuaCall("SetResponseStatus", requires_response)
  if CampaignUI ~= nil then
    icon:LuaCall("ShowMessage")
  else
    icon:SetState("Read")
  end
end

function RequiresResponse()
  return icon:LuaCall("RequiresResponse")
end

function WasRead()
  return icon:CurrentState() == "inactive"
end
