local utils = require("Utilities")
local this = UIComponent(Address)
local panel_manager, card_manager
local initialised = false
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function Initialise(manager, multiple_selections_allowed)
  ShaneOutput("** INITIALISING **   Manager = " .. tostring(manager) .. "   Multiple allowed = " .. tostring(multiple_selections_allowed))
  panel_manager = manager
  card_manager = UICardManager(false, multiple_selections_allowed)
  initialised = true
end

function SetAsActive()
  if initialised == false then
    ShaneOutput("** SetAsActive CALLED BEFORE INITIALISE **")
  end
  card_manager:SetAsActive()
end

function SelectionChanged()
  if initialised == false then
    ShaneOutput("** SelectionChanged CALLED BEFORE INITIALISE **")
  end
  panel_manager.SelectionChanged(card_manager:Selected())
end

function AddAllChildren()
  for n = 0, this:ChildCount() - 1 do
    card_manager:AddCard(this:Find(n))
  end
end

function OnDestroyed()
  card_manager:SetInactive()
end

function RemoveAll()
  local cards = card_manager:RemoveAll()
end

function ManageSelection(card, click_up)
  card_manager:ManageSelection(card, click_up)
end

function DragSelected()
  card_manager:DragSelected()
end

function OnDivorce(card)
  card_manager:RemoveCard(card)
end

function Cards()
  return card_manager:Cards()
end

function Selected()
  return card_manager:Selected()
end

function Layout(children)
  local local_TruncToInt = utils.TruncToInt
  local local_RoundToInt = utils.RoundToInt
  for i, v in ipairs(children) do
    v.X = (i - 1) % 10 * v.Width
    v.Y = local_TruncToInt(local_RoundToInt(i - 1) * 0.1) * v.Height
  end
  return children
end
