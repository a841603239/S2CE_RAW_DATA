local utils = require("Utilities")
local this = UIComponent(Address)
parent = UIComponent(this:Parent())
local selected
tabs = {}
local spacer
tab_ids = {}
local original_tab_offset = 0
local m_tab_spacing = this:GetProperty("Tab Spacing", true)
local m_text_padding = this:GetProperty("Text Padding", true)
if m_tab_spacing == nil then
  m_tab_spacing = 3
end
if m_text_padding == nil then
  m_text_padding = 10
end
for i = 0, this:ChildCount() - 1 do
  local c = UIComponent(this:Find(i))
  out.tom(i, c:Id())
  if c:Id() ~= "spacer" and c:Id() ~= "scroll_top" then
    if 0 < c:ChildCount() then
      UIComponent(c:Find(0)):SetVisible(false)
    end
    tabs[#tabs + 1] = c
    tab_ids[c:Id()] = #tabs
  elseif c:Id() == "spacer" then
    spacer = c
  end
end
if 0 < this:ChildCount() then
  original_tab_offset = UIComponent(this:Find(0)):Position() - this:Position()
end

function RemoveTab(tab_index)
  table.remove(tabs, tab_index + 1)
  Component.Destroy(this:Find(tab_index))
  Notify(Component.Messages.Move)
end

function SetTabVisibility(tab_ptr, visible)
  UIComponent(tab_ptr):SetVisible(visible)
  Notify(Component.Messages.Move)
  local visible_tabs = 0
  for i = 0, this:ChildCount() - 1 do
    if UIComponent(this:Find(i)):Visible() then
      visible_tabs = visible_tabs + 1
    end
  end
  local lone_tab = visible_tabs < 2
  local technique = lone_tab and "alpha_over_time_t0" or "normal_t0"
  for i = 0, this:ChildCount() - 1 do
    local tab = UIComponent(this:Find(i))
    for c = 0, tab:ChildCount() - 1 do
      if 0 < c then
        local child = UIComponent(tab:Find(c))
        child:ShaderTechniqueSet(technique, true)
        child:ShaderVarsSet(0, 0, 0, 0)
        child:TextShaderTechniqueSet(technique, true)
        child:TextShaderVarsSet(0, 0, 0, 0)
      end
    end
    tab:ShaderTechniqueSet(technique, true)
    tab:ShaderVarsSet(0, 0, 0, 0)
    tab:TextShaderTechniqueSet(technique, true)
    tab:TextShaderVarsSet(0, 0, 0, 0)
    tab:SetInteractive(not lone_tab)
  end
end

function SelectTab(tab)
  if selected ~= tab_ids[tab] then
    local address = tabs[tab_ids[tab]]:Address()
    if selected ~= nil then
      if tabs[selected]:CurrentState() ~= "inactive" and tabs[selected]:SetState("active") == false then
        tabs[selected]:SetState("unselected")
      end
      if tabs[selected]:ChildCount() > 0 then
        UIComponent(tabs[selected]:Find(0)):SetVisible(false)
      end
    end
    local childlist = {}
    local added = 1
    for i, v in ipairs(tabs) do
      if v:Address() ~= address then
        childlist[#tabs - added] = v:Address()
        v:SetState("unselected")
        if v:CurrentState() ~= "inactive" and v:SetState("active") == false then
          v:SetState("unselected")
        end
        if v:ChildCount() > 0 then
          UIComponent(v:Find(0)):SetVisible(false)
        end
        added = added + 1
      else
        selected = i
        v:SetState("selected")
        if v:ChildCount() > 0 then
          UIComponent(v:Find(0)):SetVisible(true)
        end
      end
    end
    childlist[#childlist + 1] = address
    this:ReorderChildren(childlist)
    local f = parent:GlobalExists("SelectTab")
    if f ~= nil then
      f(tab)
    elseif g_selected_func ~= nil then
      g_selected_func(address)
    elseif this:HasInterface() then
      this:InterfaceFunction("NotifyTabSelected", tab)
    end
    return true
  end
  return false
end

function Notify(value, address)
  if value == Component.Messages.LClickUp then
    SelectTab(UIComponent(address):Id())
  elseif value == Component.Messages.Move then
    if this:HasInterface() then
      this:InterfaceFunction("PositionChildren")
    else
      local posX = this:Position()
      local nextX = posX + original_tab_offset
      for k, v in ipairs(tabs) do
        if v:Visible() then
          local grp = UIComponent(v:Find(0))
          local grp_x, grp_y = grp:Position()
          local v_x, v_y = v:Position()
          v:MoveTo(nextX, v_y)
          nextX = nextX + v:Width() + m_tab_spacing
          grp:MoveTo(grp_x, grp_y)
        end
      end
      if spacer ~= nil then
        local sx, sy = spacer:Position()
        spacer:Resize(this:Width() - nextX + posX, spacer:Height())
        spacer:MoveTo(nextX - m_tab_spacing, sy)
      end
    end
  end
end

function SetInitialTab(address)
  selected = nil
  if this:ChildCount() > 0 then
    for i = 0, this:ChildCount() - 1 do
      local c = UIComponent(this:Find(i))
      if c ~= spacer then
        c:LuaCall("SetPadding", m_text_padding)
      end
    end
  end
  Notify(Component.Messages.Move)
  Notify(Component.Messages.LClickUp, address)
end
