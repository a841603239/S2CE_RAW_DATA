local this = UIComponent(Address)

function AdvisorMouseAreaEntry()
  out.dylan("advisor mouse template enry. Priority: " .. this:Priority())
  Component.Call("Root.LuaCall", "ShowMinimisedAdvisor")
end

function AdvisorMouseAreaExit()
  out.dylan("advisor mouse exit")
end

this:SetEventCallback("OnMouseOn", AdvisorMouseAreaEntry)
