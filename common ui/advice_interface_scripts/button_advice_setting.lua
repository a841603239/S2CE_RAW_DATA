local this = UIComponent(Address)
local parent = UIComponent(this:Parent("advice_interface"))

function InitState()
  local current_setting = this:CurrentState()
  local i, j = string.find(current_setting, "_")
  local subs_setting = string.sub(current_setting, 1, j - 1)
  parent:LuaCall("ChangeAdviceSettings", subs_setting)
end

function AdviceSettingClick()
end
