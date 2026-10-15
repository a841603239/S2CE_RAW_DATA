local m_owner, m_id

function Initialise(details)
  c = UIComponent(Component.Call("CharacterAttribute.Children[0].Address"))
  c:SetState(tostring(details.Attributes.PrimaryLevel))
end

function OnLeftClickUp()
  Component.Call("Root.LuaCall", "SelectAgentCard", Address)
end

function OnLDblClick()
  if nil ~= m_id then
    Component.Call("Root.LuaCall", "ShowAgentInfo", m_id)
  end
end

function SetOwnerAndId(owner, id)
  m_owner = owner
  m_id = id
end
