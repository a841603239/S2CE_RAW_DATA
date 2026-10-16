local utilities = require("Utilities")
local this = UIComponent(Address)
local m_tabs = {}
local m_tab_group = UIComponent(this:Find("TabGroup"))

function Initialise()
  this:InterfaceFunction("Initialise")
end

function ReInitialise()
  this:InterfaceFunction("Initialise")
end

function OnExit()
  this:InterfaceFunction("OnClose")
  m_initialised = false
end

function InitialiseTabs()
  InitTab("Family", ShowFamily)
  InitTab("Summary", ShowSummary)
  InitTab("Records", ShowRecords)
  SelectTab("Summary")
  m_tab_group:LuaCall("SetInitialTab", m_tabs.Summary.tab:Address())
  m_tabs.Family.tab:SetState("active")
  m_tabs.Summary.tab:SetState("selected")
  m_tabs.Records.tab:SetState("active")
end

function SelectTab(tab)
  m_tabs[tab].init()
end

function InitTab(tab, func)
  m_tabs[tab] = {}
  m_tabs[tab].tab = UIComponent(this:Find(tab))
  m_tabs[tab].tab:LuaCall("SetPadding", 20)
  m_tabs[tab].init = func
end

function ShowFamily()
  this:InterfaceFunction("ShowFamilyTab")
end

function ShowSummary()
  this:InterfaceFunction("ShowSummaryTab")
end

function ShowRecords()
  this:InterfaceFunction("ShowRecordsTab")
end
