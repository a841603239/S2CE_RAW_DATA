local this = UIComponent(Address)

function CharacterInput(character)
  text = this:GetStateText()
  if string.byte(character) == 8 then
    if text ~= nil then
      text = string.sub(text, 0, string.len(text) - 1)
      this:SetStateText(text)
    end
  elseif text ~= nil then
    this:SetStateText(text .. character)
  else
    text = character
    this:SetStateText(text)
  end
end
