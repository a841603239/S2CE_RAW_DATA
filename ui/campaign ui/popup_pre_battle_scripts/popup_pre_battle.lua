local this = UIComponent(Address)

function OnExit()
  this:StealShortcutKey(false)
  g_start_presentation_time = 0
end
