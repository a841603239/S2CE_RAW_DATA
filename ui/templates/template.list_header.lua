local this = UIComponent(Address)
local m_column = this:GetProperty("Column")
local m_list = UIComponent(this:Parent(2))

function SortList()
  m_list:LuaCall("Notify", Address, m_column)
end
