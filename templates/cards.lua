this = UIComponent(Address)
m_owner = nil
m_id = nil
m_item_address = nil
ComponentType = nil
local g_group_id = -1

function SetGroupId(id)
  g_group_id = id
end

function GroupId()
  return g_group_id
end

local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function SetComponentType(type)
  ComponentType = type
end

function SetUnitAddress(address)
  m_item_address = address
end

function SetOwnerAndId(owner, id, address)
  m_owner = owner
  m_id = id
  m_item_address = address
end

function ItemAddress()
  return m_item_address
end

function OnLeftClickUp()
  if false == Component.Call("IsDragged") and this:CurrentState() ~= "UnSelectable" then
    ShaneOutput("OnLeftClickUp: Looking for parents ManageSelection function")
    local parent = UIComponent(this:Parent())
    local func = parent:GlobalExists("ManageSelection")
    if func ~= nil then
      ShaneOutput("OnLeftClickUp: Calling parents ManageSelection function")
      func(Address, true)
    end
  else
    ShaneOutput("OnLeftClickUp: false == Component.Call( IsDragged ) and this:CurrentState() ~= UnSelectable. Failed")
  end
end

function OnLeftClickDown()
  if false == Component.Call("IsDragged") and this:CurrentState() ~= "UnSelectable" then
    local parent = UIComponent(this:Parent())
    local func = parent:GlobalExists("ManageSelection")
    if func ~= nil then
      func(Address, false)
    end
  end
end

function BeginDrag()
  local parent = UIComponent(this:Parent())
  local func = parent:GlobalExists("DragSelected")
  if func ~= nil then
    func(Address)
  end
end
