local utils = require("Utilities")
local this = UIComponent(Address)
local max_h = 0
local start_time = -1
local orig_x, orig_y = utils.OffsetFrom(this, UIComponent(this:Parent()))
local p_x, p_y = UIComponent(this:Parent()):Position()
local text_area = UIComponent(this:Find("text_area"))

function SetText(text)
  this:SetVisible(true)
  local w, h = UIComponent(this:Find("text_area")):SetStateText(text)
  max_h = h + 60
  this:Resize(148, 16, false)
  this:MoveTo(0, -16)
end

function OnUpdate(time_ms)
  if this:Visible() then
    if start_time == -1 then
      start_time = time_ms
    end
    local scalar = (time_ms - start_time) / 750
    if 1 < scalar then
      scalar = 1
    end
    local w = 292 * scalar
    local h = max_h * scalar
    local x = -orig_x * scalar
    local y = -(h + 8)
    this:Resize(w, h, false)
    text_area:Resize(text_area:Width(), h - 38)
    this:MoveTo(p_x + x, p_y + y)
  end
end
