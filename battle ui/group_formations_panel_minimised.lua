local this = UIComponent(Address)

function Group_Formations()
  local panel = UIComponent(this:Find(0))
  if panel:Visible() then
    panel:SetVisible(false)
  else
    panel:SetVisible(true)
  end
end

function Slide(time)
end

function Activate(active)
  currentState = this:CurrentState()
  if active then
    if currentState ~= "Selected" then
      this:SetState("Unselected")
    end
  else
    this:SetState("Inactive")
  end
  out.kostas("activate state is " .. this:CurrentState())
end

function HideFormationsPanel()
  UIComponent(this:Find(0)):SetVisible(false)
end

HideFormationsPanel()
