function ClearDynamicMPMessageBox(message_type)
  local clear_function = UIComponent(this:Parent()):GlobalExists("MultiplayerClearMessageBox")
  
  if clear_function ~= nil then
    clear_function(message_type)
  end
end
