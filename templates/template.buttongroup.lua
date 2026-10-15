local this = UIComponent(Address)
g_notify_func = nil

function InitState()
  if Component.GetProperty("Allow None Selected") == 0 and UIComponent(this:Find(0)):SetState("selected") == false then
    UIComponent(this:Find(0)):SetState("Selected")
  end
end

function SelectButton(address)
  if Component.GetProperty("Single Selection") == 1 then
    for n = 1, this:ChildCount() do
      local c = UIComponent(this:Find(n - 1))
      if address ~= c:Address() and c:CurrentState() ~= "inactive" and c:SetState("Normal") == false then
        c:SetState("normal")
      end
    end
  end
  if UIComponent(address):SetState("selected") == false then
    UIComponent(address):SetState("Selected")
  end
end

function Notify(value, msg, address)
  msg = string.lower(msg)
  if value == Component.Messages.StateChange then
    if (msg == "selected" or msg == "down") and Component.GetProperty("Single Selection") == 1 then
      for n = 1, this:ChildCount() do
        local c = UIComponent(this:Find(n - 1))
        if address ~= c:Address() and c:CurrentState() ~= "inactive" and c:SetState("normal") == false then
          c:SetState("Normal")
        end
      end
    elseif (msg == "normal" or msg == "selected_down") and Component.GetProperty("Allow None Selected") == 0 then
      local any_selected = false
      for n = 1, this:ChildCount() do
        local c = UIComponent(this:Find(n - 1))
        if address ~= c:Address() and string.lower(c:CurrentState()) == "selected" then
          any_selected = true
          break
        end
      end
      if any_selected == false then
        c = UIComponent(address)
        if c:SetState("selected") == false then
          c:SetState("Selected")
        end
        return
      end
    end
  end
  if g_notify_func ~= nil then
    g_notify_func(address)
  end
end

function SelectedButton()
  for i = 0, this:ChildCount() - 1 do
    local c = UIComponent(this:Find(i))
    local state = c:CurrentState()
    if state == "selected" or state == "Selected" then
      return i, c
    end
  end
  return -1
end
