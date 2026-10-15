local this = UIComponent(Address)
local utils = require("CoreUtils")
local listview = UIComponent(this:Parent(2))
local m_current_selected = {}
local m_selection_manager = UISelectionManager(this:GetProperty("MultiSelect", true) == true)
local clip_height = Component.Call("Parent.Height")
local spacing = 0
local list_height_offset = 0
g_notify_func = nil

function SetListSpacing(space)
  spacing = space
end

function SetListHeightOffset(offset)
  list_height_offset = offset
end

function Layout(children)
  local w, h = this:Dimensions()
  local y = 0
  m_selection_manager:RemoveAll()
  if children ~= nil then
    for i, v in ipairs(children) do
      v.Y = y
      y = y + v.Height + spacing
      m_selection_manager:Add(v.Address)
    end
  end
  y = y + list_height_offset
  this:Resize(w, utils.Max(y, clip_height), false)
  listview:LuaCall("SetSliderValue", utils.Max(0, y - clip_height))
  if children ~= nil and 0 < #children then
    local avge_child_height = clip_height / #children
    UIComponent(listview:Find("top")):SetProperty("stepSize", avge_child_height)
    UIComponent(listview:Find("bottom")):SetProperty("stepSize", avge_child_height)
  end
  UIComponent(listview:Find("handle")):SetVisible(y > clip_height)
  return children
end

function ChildList()
  local children = {}
  for n = 1, this:ChildCount() do
    children[n] = this:Find(n - 1)
  end
  return children
end

function SelectedItem()
  local selected = m_selection_manager:Selected()
  return selected[#selected]
end

function SelectedItems()
  return m_selection_manager:Selected()
end

function SelectedIndex()
  local selected = SelectedItem()
  for i = 0, this:ChildCount() - 1 do
    if this:Find(i) == selected then
      return i, UIComponent(UIComponent(selected):Find(0)):GetStateText()
    end
  end
  return nil
end

function OnDivorceChild(c)
  m_selection_manager:Remove(c)
end

function FindChild(offset_x, offset_y)
  for n = 1, this:ChildCount() do
    local child = UIComponent(this:Find(n - 1))
    if child:IsInteractive() then
      x, y = child:Position()
      our_x, our_y = this:Position()
      x = x - our_x
      y = y - our_y
      w, h = child:Dimensions()
      if offset_x >= x and offset_x <= x + w and offset_y >= y and offset_y <= y + h then
        return child:Address()
      end
    end
  end
end

function OnLClickUp(offset_x, offset_y)
  local clicked = FindChild(offset_x, offset_y)
  if clicked ~= nil then
    SelectItem(clicked, true)
  end
end

function OnLClickDown(offset_x, offset_y)
  local clicked = FindChild(offset_x, offset_y)
  if clicked ~= nil then
    SelectItem(clicked, false)
  end
end

function SelectItem(address, clicked_up)
  if this:HasInterface() == false then
    if address ~= nil then
      local selection_changed = false
      if clicked_up ~= nil then
        local shift_held, ctrl_held, alt_held = Component.KeyboardModifiersHeld()
        selection_changed = m_selection_manager:ManageSelection(address, clicked_up, shift_held, ctrl_held)
      else
        selection_changed = m_selection_manager:ManageSelection(address, true, false, false)
      end
      if selection_changed == true then
        local c = UIComponent(address)
        local component_x, component_y = c:Position()
        local list_x, list_y = this:Position()
        local clip_x, clip_y = UIComponent(this:Parent()):Position()
        local offset_from_clip = component_y - list_y - (clip_y - list_y)
        offset_from_clip = utils.Min(offset_from_clip, this:Height() - clip_height)
        if offset_from_clip + c:Height() > clip_height then
          listview:LuaCall("ScrollTo", offset_from_clip)
        end
        if g_notify_func ~= nil then
          g_notify_func(address)
        end
      end
    else
      m_selection_manager:DeselectAll()
    end
  end
end

this:SetEventCallback("OnDivorceChild", OnDivorceChild)
this:SetEventCallback("OnMouseLClickDown", OnLClickDown)
