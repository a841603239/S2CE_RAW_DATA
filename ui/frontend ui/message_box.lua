local this = UIComponent(Address)

function Initialise(title, msg, ok_callback, cancel_callback)
  local heading = UIComponent(this:Find("heading_txt"))
  heading:SetStateText(title)
  local text = UIComponent(this:Find("txt"))
  text:SetStateText(msg)
  _, text_y = text:TextDimensions()
  _, component_y = text:Dimensions()
  local new_height = UIComponent(this:Find("spacer")):Height() + text_y + 30 + heading:Height() + UIComponent(this:Find("confirm")):Height()
  if new_height > this:Height() then
    this:Resize(this:Width(), new_height)
  end
  this:Layout()
  local show_both = ok_callback ~= nil and cancel_callback ~= nil
  local ok_cancel = UIComponent(this:Find("ok-cancel"))
  local confirm = UIComponent(this:Find("button_ok_confirm"))
  ok_cancel:SetVisible(show_both)
  confirm:SetVisible(not show_both)
  if ok_callback then
    UIComponent(ok_cancel:Find("button_ok")):SetEventCallback("OnMouseLClickUp", ok_callback)
    confirm:SetEventCallback("OnMouseLClickUp", ok_callback)
  end
  if cancel_callback then
    UIComponent(ok_cancel:Find("button_cancel")):SetEventCallback("OnMouseLClickUp", cancel_callback)
  end
end
