local this = UIComponent(Address)
local tab = UIComponent(this:Parent())
local panel = UIComponent(this:Parent(2))
local card_manager = UICardManager(false)
g_enabled = true
local card_type

function OnDestroyed()
  card_manager:SetInactive()
end

this:SetEventCallback("OnDestroyed", OnDestroyed)

function CardManagerPtr()
  return card_manager:Address()
end

function SetCardType(t)
  card_type = t
  this:DestroyChildren()
end

function CardType()
  return card_type
end

function ManageSelection(card, click_up)
  card_manager:ManageSelection(card, click_up)
end

function DragSelected()
  card_manager:DragSelected()
end

function OnAdopt(card)
  card_manager:AddCard(card)
end

function OnDivorce(card)
  card_manager:RemoveCard(card)
end

function Cards()
  local c = card_manager:Cards()
  local r = {}
  for i, v in ipairs(c) do
    if UIComponent(v):IsMoveable() then
      r[#r + 1] = v
    end
  end
  return r
end

function DisableAll()
  local cards = card_manager:Cards()
  for i, v in ipairs(cards) do
    local c = UIComponent(v)
    c:SetMoveable(false)
    if c:SetState("inactive") == false then
      c:SetDisabled(true)
    end
  end
end

function DeselectAll()
  card_manager:DeselectAll()
end

function Selected()
  return card_manager:Selected()
end

function Layout(children)
  local w = this:Width()
  local x, y = 0, 0
  for i, v in ipairs(children) do
    v.X = x
    v.Y = y
    x = x + v.Width
    if w < x + v.Width then
      x = 0
      y = y + v.Height
    end
  end
  return children
end

function CanBeRemoved(num)
  return card_type ~= "Ships" or num < this:ChildCount()
end

function HandleDrop(dropped)
  if g_enabled == true then
    local exchanged = false
    for i, v in ipairs(dropped) do
      local card = UIComponent(v.Address)
      local parent = UIComponent(card:Parent())
      local dropped_type = parent:LuaCall("CardType")
      local limit = panel:LuaCall("MaxItems", dropped_type)
      if parent:Address() ~= this:Address() and limit > this:ChildCount() and parent:LuaCall("CanBeRemoved", 1) then
        if dropped_type == card_type then
          this:Adopt(v.Address)
          v.Handled = true
          exchanged = true
        else
          return panel:LuaCall("PassOnDrop", dropped_type, dropped)
        end
      end
    end
    this:Layout()
  end
  if exchanged == true then
    CampaignUI.UnitsExchanged()
  end
  return dropped
end
