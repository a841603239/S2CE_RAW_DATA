module((...), package.seeall)
local core = require("CoreUtils")
for k, v in pairs(core) do
  if string.sub(k, 1, 1) ~= "_" then
    _G[k] = v
  end
end
BUILDING_ICON_TYPE_EMPTY = 0
BUILDING_ICON_TYPE_BUILT = 1
BUILDING_ICON_TYPE_CONSTRUCTING = 2
BUILDING_ICON_TYPE_CONSTRUCTABLE = 3
BUILDING_ICON_TYPE_UPGRADE = 4
BUILDING_ICON_TYPE_ALT_CHAIN = 5
MP_WINK_BEGIN_TURN_DIALOG_DISMISSED = 0
MP_WINK_SAVE_CONFIRM_DIALOG_DISMISSED = 1
MP_WINK_PRE_BATTLE_SELECTION_AUTO = 2
MP_WINK_PRE_BATTLE_SELECTION_BATTLE = 3
MP_WINK_PRE_BATTLE_SELECTION_RETREAT = 4
CAMERA_TARGET_POS_RIGHT = -1
CAMERA_TARGET_POS_CENTRE = 0
CAMERA_TARGET_POS_LEFT = 1
MAX_CAMERA_DISTANCE = 500
SPYING_UNIT_DATA_UNKNOWN = 0
SPYING_UNIT_DATA_ICON_KNOWN = 1
SPYING_UNIT_DATA_MEN_KNOWN = 2
SPYING_UNIT_DATA_GUNS_KNOWN = 4
SPYING_UNIT_DATA_XP_KNOWN = 8
SPYING_UNIT_DATA_OWNED = SPYING_UNIT_DATA_ICON_KNOWN + SPYING_UNIT_DATA_MEN_KNOWN + SPYING_UNIT_DATA_GUNS_KNOWN + SPYING_UNIT_DATA_XP_KNOWN
SPYING_DATA_LEVEL_INVALID = -1
SPYING_DATA_LEVEL_PASSIVE = 0
SPYING_DATA_LEVEL_BASIC = 1
SPYING_DATA_LEVEL_ADVANCED = 2
SPYING_DATA_LEVEL_OWNED = 3
CT_PRIMARY_GENERAL = 0
CT_SECONDARY_GENERAL = 1
CT_PRIMARY_ADMIRAL = 2
CT_SECONDARY_ADMIRAL = 3
CT_COMMODORE = 4
CT_BRIGADIER = 5
CT_NAVAL_UNIT = 6
CT_LAND_UNIT = 7
TECHNOLOGY_STATUS_RESEARCHED = 0
TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN = 1
TECHNOLOGY_STATUS_BEING_RESEARCHED = 1
TECHNOLOGY_STATUS_BEING_STOLEN = 1
TECHNOLOGY_STATUS_AVAILABLE = 2
TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE = 3
TECHNOLOGY_STATUS_UNAVAILABLE = 4
TECHNOLOGY_STATUS_NOT_PRESENT = 5
RPTS_GREYED = 0
RPTS_NORMAL = 1
RPTS_SELECTED = 2
RPTS_HIGHLIGHTED = 3
NUM_RPT_STATES = 4
battle_timeout_limits = {
  20,
  40,
  60,
  -1
}
tech_status_strings = {
  "TECHNOLOGY_STATUS_RESEARCHED",
  "TECHNOLOGY_STATUS_BEING_RESEARCHED_OR_STOLEN",
  "TECHNOLOGY_STATUS_AVAILABLE",
  "TECHNOLOGY_STATUS_AVAILABLE_TO_STEAL_OR_TRADE",
  "TECHNOLOGY_STATUS_UNAVAILABLE",
  "TECHNOLOGY_STATUS_NOT_PRESENT"
}
commander_typenames = {
  "CT_PRIMARY_GENERAL",
  "CT_SECONDARY_GENERAL",
  "CT_PRIMARY_ADMIRAL",
  "CT_SECONDARY_ADMIRAL",
  "CT_COMMODORE",
  "CT_BRIGADIER",
  "CT_NAVAL_UNIT",
  "CT_LAND_UNIT"
}
local cursor = Cursor()
local shane_output = false

function ShaneOutput(msg)
  if defined.debug and shane_output then
    out.shane(msg)
  end
end

function CreateCharacterCard(details, id, parent, x, y)
  ShaneOutput(">> CREATE CHARACTER CARD <<")
  return CampaignUI.CreateCharacterCard(id, details, parent, x, y)
end

function CreateUnitCard(unit, id, parent, x, y, moveable, selectable, show_replenished, square_image)
  ShaneOutput(">> CREATE UNIT CARD <<")
  local card = CampaignUI.CreateUnitCard(id, unit.Address, parent, x, y, square_image == true)
  if selectable ~= true then
    UIComponent(card):SetState("UnSelectable")
  end
  UIComponent(card):SetMoveable(moveable == true)
  local show_replenish = unit.IsNaval == false and show_replenished == true and unit.spying_data_level >= SPYING_DATA_LEVEL_ADVANCED
  UIComponent(UIComponent(card):Find("replenish_icon")):SetVisible(show_replenish)
  return card
end

function GetEffectList(effects, attribute_effects)
  local tooltip = ""
  for i = 1, #attribute_effects do
    if tooltip ~= "" then
      tooltip = tooltip .. "\n"
    end
    tooltip = tooltip .. attribute_effects[i]
  end
  local sorted_effects = {}
  for i = 1, #effects do
    if effects[i].Priority > 0 then
      table.insert(sorted_effects, effects[i])
    end
  end
  for i = 1, #sorted_effects - 1 do
    for j = i + 1, #sorted_effects do
      if sorted_effects[i].Priority < sorted_effects[j].Priority then
        local swap = sorted_effects[i]
        sorted_effects[i] = sorted_effects[j]
        sorted_effects[j] = swap
      end
    end
  end
  effects = sorted_effects
  for i = 1, #effects do
    if tooltip ~= "" then
      tooltip = tooltip .. "\n"
    end
    tooltip = tooltip .. effects[i].Description
  end
  return tooltip
end

function FitTextToComponent(root, component, text)
  local resized = false
  component = UIComponent(root:Find(component))
  local c_w = component:Width()
  local font_details = component:GetStateTextDetails()
  local t_w, t_h, t_l = component:SetStateText(text)
  local i = string.length(text)
  if c_w < t_w + font_details.XOffset or 1 < t_l then
    resized = true
  end
  while c_w < t_w + font_details.XOffset or 1 < t_l do
    local t = string.sub(text, 1, i) .. "..."
    t_w, t_h, t_l = component:SetStateText(t)
    i = i - 1
  end
  component:SetTooltipText(text, true)
  return resized
end

function CreateDiplomacyFlags(parent, details)
  local p = UIComponent(parent)
  p:DestroyChildren()
  local max_w = p:Width()
  local x = 0
  local flag_width = 0
  for k, v in pairs(details) do
    images = {
      "{flag:1}" .. v.Flag
    }
    flag = UIComponent(Component.CreateFromLayout("data/ui/campaign ui/faction_flag_small", "flag", parent, x, 0, images))
    flag:SetTooltipText(v.Name, true)
    flag_width = flag:Width()
    x = x + flag_width
  end
  if max_w < x then
    local offset = 1
    local start_x = 0
    local y = 0
    local p = UIComponent(parent)
    while x > max_w - offset and offset < flag_width - 1 do
      start_x, y = p:Position()
      x = 0
      for n = 0, p:ChildCount() - 1 do
        local child = UIComponent(p:Find(n))
        child:MoveTo(start_x + x, y)
        x = x + child:Width() - offset
      end
      offset = offset + 1
    end
  end
end

function PositionTooltip(addr, force_above)
  Component.PositionTooltip(addr, true, force_above)
end

function MouseOver(c)
  if c:Visible() then
    local m_x, m_y = Component.CursorPosition()
    local c_x, c_y = c:Position()
    return m_x >= c_x and m_x < c_x + c:Width() and m_y >= c_y and m_y < c_y + c:Height()
  end
  return false
end

function AddLine(parent, x1, y1, x2, y2, colour, line)
  local line_a, line_w
  if line == nil then
    line = UIComponent(Component.CreateFromLayout("data/ui/common ui/general_purpose_pixel", "line", parent, x1, y1))
  else
    local px, py = UIComponent(parent):Position()
    line:MoveTo(px + x1, py + y1)
  end
  local a = x2 - x1
  local o = y2 - y1
  local h = (a * a + o * o) ^ 0.5
  line_w = h
  line_a = math.asin(o / h)
  line:Resize(line_w, line:Height())
  line:SetImageRotation(0, line_a, -line_w * 0.5, 0)
  line:SetImageColour(0, colour.r * 255, colour.g * 255, colour.b * 255, 255)
  return line
end

function PropagateShader(component, technique, p1, p2, p3, p4)
  local root = UIComponent(component)
  for i = 0, root:ChildCount() - 1 do
    PropagateShader(root:Find(i), technique, p1, p2, p3, p4)
  end
  root:ShaderTechniqueSet(technique, true)
  root:ShaderVarsSet(p1, p2, p3, p4, true)
end

function PropagateInteractive(component, interactive)
  local c = UIComponent(component)
  for i = 0, c:ChildCount() - 1 do
    PropagateInteractive(c:Find(i), interactive)
  end
  c:SetInteractive(interactive)
end

function OffsetFrom(a, b)
  local a_x, a_y = a:Position()
  local b_x, b_y = b:Position()
  return b_x - a_x, b_y - a_y
end

function TableEquality(lhs, rhs)
  for k, v in pairs(lhs) do
    if rhs[k] == nil or rhs[k] ~= v then
      return false
    end
  end
  for i, v in ipairs(lhs) do
    if rhs[i] == nil or rhs[i] ~= v then
      return false
    end
  end
  return true
end

local function exportstring(s)
  s = string.format("%q", s)
  s = string.gsub(s, "\\\n", "\\n")
  s = string.gsub(s, "\r", "\\r")
  s = string.gsub(s, string.char(26), "\"..string.char(26)..\"")
  return s
end

function SaveTable(tbl, filename)
  local charS, charE = "   ", "\n"
  local file, err
  if not filename then
    file = {
      write = function(self, newstr)
        self.str = self.str .. newstr
      end,
      str = ""
    }
    charS, charE = "", ""
  elseif filename == true or filename == 1 then
    charS, charE, file = "", "", io.tmpfile()
  else
    file, err = io.open(filename, "w")
    if err then
      return _, err
    end
  end
  local tables, lookup = {tbl}, {
    [tbl] = 1
  }
  file:write("return {" .. charE)
  for idx, t in ipairs(tables) do
    if filename and filename ~= true and filename ~= 1 then
      file:write("-- Table: {" .. idx .. "}" .. charE)
    end
    file:write("{" .. charE)
    local thandled = {}
    for i, v in ipairs(t) do
      thandled[i] = true
      if type(v) ~= "userdata" then
        if type(v) == "table" then
          if not lookup[v] then
            table.insert(tables, v)
            lookup[v] = #tables
          end
          file:write(charS .. "{" .. lookup[v] .. "}," .. charE)
        elseif type(v) == "function" then
          file:write(charS .. "loadstring(" .. exportstring(string.dump(v)) .. ")," .. charE)
        else
          local value = type(v) == "string" and exportstring(v) or tostring(v)
          file:write(charS .. value .. "," .. charE)
        end
      end
    end
    for i, v in pairs(t) do
      if not thandled[i] and type(v) ~= "userdata" then
        if type(i) == "table" then
          if not lookup[i] then
            table.insert(tables, i)
            lookup[i] = #tables
          end
          file:write(charS .. "[{" .. lookup[i] .. "}]=")
        else
          local index = type(i) == "string" and "[" .. exportstring(i) .. "]" or string.format("[%d]", i)
          file:write(charS .. index .. "=")
        end
        if type(v) == "table" then
          if not lookup[v] then
            table.insert(tables, v)
            lookup[v] = #tables
          end
          file:write("{" .. lookup[v] .. "}," .. charE)
        elseif type(v) == "function" then
          file:write("loadstring(" .. exportstring(string.dump(v)) .. ")," .. charE)
        else
          local value = type(v) == "string" and exportstring(v) or tostring(v)
          file:write(value .. "," .. charE)
        end
      end
    end
    file:write("}," .. charE)
  end
  file:write("}")
  if not filename then
    return file.str .. "--|"
  elseif filename == true or filename == 1 then
    file:seek("set")
    return file:read("*a") .. "--|"
  else
    file:close()
    return 1
  end
end

function LoadTable(sfile)
  if string.sub(sfile, -3, -1) == "--|" then
    tables, err = loadstring(sfile)
  else
    tables, err = loadfile(sfile)
  end
  if err then
    return _, err
  end
  tables = tables()
  for idx = 1, #tables do
    local tolinkv, tolinki = {}, {}
    for i, v in pairs(tables[idx]) do
      if type(v) == "table" and tables[v[1]] then
        table.insert(tolinkv, {
          i,
          tables[v[1]]
        })
      end
      if type(i) == "table" and tables[i[1]] then
        table.insert(tolinki, {
          i,
          tables[i[1]]
        })
      end
    end
    for _, v in ipairs(tolinkv) do
      tables[idx][v[1]] = v[2]
    end
    for _, v in ipairs(tolinki) do
      tables[idx][v[2]], tables[idx][v[1]] = tables[idx][v[1]], nil
    end
  end
  return tables[1]
end

function SortCardsByRank(cards, primary_type, secondary_type, triatary_type)
  local sorted_cards = {}
  local secondary_index = 1
  for s = 1, #cards do
    if cards[s].CommanderType == primary_type then
      sorted_cards[1] = {}
      sorted_cards[1] = cards[s]
      secondary_index = 2
      break
    end
  end
  for s = 1, #cards do
    if cards[s].CommanderType == secondary_type or cards[s].CommanderType == triatary_type then
      sorted_cards[secondary_index] = {}
      sorted_cards[secondary_index] = cards[s]
      secondary_index = secondary_index + 1
    end
  end
  for s = 1, #cards do
    if cards[s].CommanderType ~= primary_type and cards[s].CommanderType ~= secondary_type and cards[s].CommanderType ~= triatary_type then
      sorted_cards[secondary_index] = {}
      sorted_cards[secondary_index] = cards[s]
      secondary_index = secondary_index + 1
    end
  end
  return sorted_cards
end

function TimeString(time)
  local minutes = TruncToInt(time / 60)
  local seconds = TruncToInt(time % 60)
  return string.format("%02d:%02d", minutes, seconds)
end

table.load = LoadTable
table.save = SaveTable
