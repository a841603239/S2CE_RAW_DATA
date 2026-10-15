local this = UIComponent(Address)

function ToggleDiplomacy()
  UIComponent(Component.Root()):LuaCall("ToggleDiplomacyPopup", nil)
end

function OnShortcut(func, ended)
  if ended then
    ToggleDiplomacy()
  end
end

function OnUpdate()
end
