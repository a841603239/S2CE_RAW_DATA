local utils = require("Utilities")
local core = require("CoreUtils")
local this = UIComponent(Address)
local item_name = UIComponent(this:Find("item_name"))
local item_id = UIComponent(this:Find("item_ID"))
local m_force_above = false
local m_last_trade_route_value = 0
local lines = {}
this:SetStateTextDetails({
  Colour = {
    r = 255,
    g = 255,
    b = 255,
    a = 255
  },
  XOffset = 8,
  YOffset = 34
})
local created_trade_routes = {}

function Update(time)
  utils.PositionTooltip(Address, m_force_above)
end

this:SetEventCallback("OnUpdatePulse", Update)

function SetText(addr, env, PrimaryColour, line1, line2, line3, force_above, trade_routes)
  m_force_above = force_above
  if line1 ~= lines[1] or line2 ~= lines[2] or line3 ~= lines[3] or trade_routes.SumValue ~= m_last_trade_route_value then
    m_last_trade_route_value = trade_routes.SumValue
    for i, v in ipairs(created_trade_routes) do
      Component.Destroy(v)
    end
    created_trade_routes = {}
    lines = {
      line1,
      line2,
      line3
    }
    this:SetVisible(true)
    if trade_routes.Header ~= nil then
      PrimaryColour = trade_routes.Header
    end
    local text_details = {
      Colour = {
        r = 255,
        g = 255,
        b = 255,
        a = 255
      }
    }
    item_name:SetStateTextDetails(text_details)
    item_id:SetStateTextDetails(text_details)
    local w1, h1, l1 = item_name:SetStateText(line1, false, 1)
    local w2, h2, l2 = item_id:SetStateText(line2, false, 1)
    local top_bar_width = w1 + w2 + (0 < w2 and 24 or 16)
    if top_bar_width < this:WidthOfTextLine(line3) then
      this:Resize(300, 10, false)
    else
      this:Resize(top_bar_width, 10, false)
    end
    local width = this:Width()
    if top_bar_width > width or #line3 == 0 then
      width = top_bar_width
    end
    local text_height = 27
    local bg_height = 27
    if 0 < #line3 then
      bg_height = 22
      local w3, h3, l3 = this:SetStateText(line3)
      text_height = text_height + core.Max(h3 + 12, 27)
    end
    if 0 < #trade_routes then
      bg_height = 22
      if #line3 == 0 then
        this:SetStateText("")
      end
      for i, v in ipairs(trade_routes) do
        local c = Component.CreateFromLayout("data/ui/campaign ui/trade_route_row", "trade_route_" .. i, Address, 4, text_height, {}, {
          source = v.Text,
          value = tostring(v.Value)
        })
        created_trade_routes[#created_trade_routes + 1] = c
        c = UIComponent(c)
        UIComponent(c:Find("source")):Resize(261, 16)
        c:Resize(width - 8, c:Height())
        local x, y = this:Position()
        UIComponent(c:Find("value")):Resize(48, 16)
        UIComponent(c:Find("value")):MoveTo(x + width - 52, y + text_height)
        text_height = text_height + c:Height()
        Component.Destroy(c:Find("arrow", false))
        Component.Destroy(c:Find("destination", false))
      end
    end
    if 0 < #trade_routes then
      text_height = text_height + 8
    end
    this:Resize(width, text_height, false)
    this:Resize(width + 16, text_height, false, false)
    local x, y = this:Position()
    item_id:MoveTo(x + this:Width() - item_id:Width(), y)
  end
end
