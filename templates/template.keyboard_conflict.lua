local this = UIComponent(Address)
local m_key_details

function Initialise(key_details, old_key)
  m_key_details = key_details
  this:SetVisible(true)
  this:LockPriority()
  UIComponent(this:Find("dy_new_setting")):SetStateText(key_details.key_name)
  UIComponent(this:Find("dy_old_setting")):SetStateText(old_key)
  UIComponent(this:Find("button_ok")):SetEventCallback("OnMouseLClickUp", ClearUp)
end

function ClearUp()
  this:UnLockPriority()
  this:SetVisible(false)
end
