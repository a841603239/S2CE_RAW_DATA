local this = UIComponent(Address)
local txt = UIComponent(this:Find(0))
local text_off_x, text_off_y = txt:Position()
local txt_col = txt:GetStateTextDetails().Colour

function Initialise()
  local x, y = this:Position()
  text_off_x = text_off_x - x
  text_off_y = text_off_y - y
  local tx = txt:GetStateText()
  txt:SetStateText(tx, true, 1)
end

function InitState(details)
  if details.State == "inactive" then
    txt:SetStateTextDetails({
      Colour = {
        r = 128,
        g = 128,
        b = 128,
        a = 128
      }
    })
  else
    txt:SetStateTextDetails({Colour = txt_col})
  end
  local x, y = this:Position()
  if details.State == "down" then
    txt:MoveTo(x + text_off_x + 1, y + text_off_y + 1)
  else
    txt:MoveTo(x + text_off_x, y + text_off_y)
  end
end

Initialise()
