local this = UIComponent(Address)
local movie_window = UIComponent(this:Find("movie_window"))
local movie_title = UIComponent(this:Find("dy_title"))
local message_handler = MessageManager
local panel_manager = PanelManager
local m_ok_callback

function ShowMovieType(details)
  out.dylan("hit ShowMovieType")
  if details.Data ~= nil and details.Data.ExitFunction ~= nil then
    AssignExitFunction(details.Data)
  end
  if details.title ~= nil then
    movie_title:SetStateText(details.title)
    movie_title:SetVisible(true)
  else
    movie_title:SetStateText("")
    movie_title:SetVisible(false)
  end
  local h_x, h_y = movie_window:Position()
  local h_w, h_h = movie_window:Dimensions()
  out.dylan("Movie panel. x: " .. h_x .. "y: " .. h_y .. "w: " .. h_w .. "h: " .. h_h)
  if not CampaignUI.IsMultiplayer() then
    CampaignUI.PauseCampaign(true)
  end
end

function AssignExitFunction(Data)
  if Data.only_call_function_for_local_faction == true and Data.local_faction_involved ~= true then
    out.dylan("not setting movie callback")
    return
  end
  out.dylan("assigning movie exit function. Data.ExitFunction is: " .. tostring(Data.ExitFunction))
  if Data.ExitFunction == "ExitGame" then
    m_ok_callback = CampaignUI.QuitToMainScreen
  elseif Data.ExitFunction == "FinalisePendingDuel" then
    m_ok_callback = FinalisePendingDuel
  elseif Data.ExitFunction == "ShowVictoryOptionsPopup" then
    m_ok_callback = ShowVictoryOptionsPopup
  elseif Data.ExitFunction == "ShowVictoryOptionsPopupGameLost" then
    m_ok_callback = ShowVictoryOptionsPopupGameLost
  elseif Data.ExitFunction == "ShowVictoryOptionsPopupGameWonNoContinue" then
    m_ok_callback = ShowVictoryOptionsPopupGameWonNoContinue
  end
  out.dylan("m_ok_callback is: " .. tostring(m_ok_callback))
end

function ClearExitFunction()
  m_ok_callback = nil
end

function ShowVictoryOptionsPopup()
  out.dylan("showing victory options")
  local victory = true
  local can_continue = true
  UIComponent(Component.Root()):LuaCall("ShowCampaignResultPopup", victory, can_continue)
end

function ShowVictoryOptionsPopupGameLost()
  out.dylan("showing victory options (game lost)")
  local victory = false
  local can_continue = false
  UIComponent(Component.Root()):LuaCall("ShowCampaignResultPopup", victory, can_continue)
end

function ShowVictoryOptionsPopupGameWonNoContinue()
  out.dylan("showing victory options (game won, but no continue)")
  local victory = true
  local can_continue = false
  UIComponent(Component.Root()):LuaCall("ShowCampaignResultPopup", victory, can_continue)
end

function FinalisePendingDuel()
  CampaignUI.FinalisePendingDuel()
end

function CloseThisPopup()
  CampaignUI.SkipOrCloseMovie()
end

function DismissMovieEvent()
  out.dylan("Dismiss movie event. m_ok_callback is: " .. tostring(m_ok_callback))
  if m_ok_callback then
    out.dylan("Dismiss movie event is not nil")
    m_ok_callback()
    m_ok_callback = nil
  end
  CloseThisPopup()
end

function RemoveMoviePanel()
  out.dylan("RemoveMoviePanel called.")
  CampaignUI.MovieDismissed()
  out.dylan("RemoveMoviePanel. m_ok_callback is: " .. tostring(m_ok_callback))
  if m_ok_callback then
    m_ok_callback()
    m_ok_callback = nil
  end
  if not CampaignUI.IsMultiplayer() and not panel_manager.IsPanelOpen("campaign_victory") then
    CampaignUI.PauseCampaign(false)
  end
end

function MovieComponentPosAndDimensions()
  local h_w, h_h = movie_window:Dimensions()
  local h_x, h_y = movie_window:Position()
  return h_h, h_w, h_y, h_x
end

function MovieComponentPos()
  local h_x, h_y = movie_window:Position()
  return h_y, h_x
end

function MovieComponentDimensions()
  local h_w, h_h = movie_window:Dimensions()
  return h_h, h_w
end
