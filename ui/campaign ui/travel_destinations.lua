local utils = require("Utilities")
local panel_manager = PanelManager
local this = UIComponent(Address)
local ok_button = UIComponent(this:Find("button_ok"))
local buttons = {
  "button_america",
  "button_europe",
  "button_india",
  "button_trade_s_america",
  "button_trade_w_africa",
  "button_trade_e_africa",
  "button_trade_e_indies"
}
local current_details, selected_theatre

function Initialise(details)
  current_details = details
  selected_theatre = nil
  ok_button:SetState("inactive")
  for i, v in ipairs(buttons) do
    local c = UIComponent(this:Find(v))
    local theatre = c:GetProperty("Theatre")
    if details.CurrentTheatre == theatre then
      local x, y = c:Position()
      local w, h = c:Dimensions()
      local scale_w = w / details.BoundsWidth
      local scale_h = h / details.BoundsHeight
      x = x + details.BoundsOffsetX * scale_w
      y = y + (h - details.BoundsOffsetY * scale_h)
      local icon = UIComponent(this:Find("ship_icon"))
      local iw, ih = icon:Dimensions()
      icon:MoveTo(x - iw / 2, y - ih / 2)
    end
    if details.Transitions[theatre] ~= nil then
      c:SetState("Unselected")
    else
      c:SetState("Inactive")
    end
  end
end

function SelectTheatre(theatre)
  local previous_selected = selected_theatre
  if selected_theatre ~= nil then
    selected_theatre:SetState("Unselected")
    selected_theatre = nil
    ok_button:SetState("inactive")
  end
  if theatre ~= previous_selected then
    ok_button:SetState("normal")
    selected_theatre = theatre
    selected_theatre:SetState("Selected")
  end
end

function OnAccept()
  if ok_button:CurrentState() ~= "inactive" then
    CampaignUI.FinaliseMoveTransition(current_details.Character, current_details.Units, current_details.PositionX, current_details.PositionY, current_details.Transitions[selected_theatre:GetProperty("Theatre")])
  end
  panel_manager.ClosePopup(Address)
end

function OnCancel()
  CampaignUI.FinaliseMoveTransition(current_details.Character, current_details.Units, current_details.PositionX, current_details.PositionY)
  panel_manager.ClosePopup(Address)
end
