local this = UIComponent(Address)
local g_drop_in_interface
local syncronising = false
local client_id
local sync_bar = UIComponent(this:Find("sync_bar_fill"))
local sync_bar_width = sync_bar:Width()
local save_button = UIComponent(UIComponent(this:Parent("popup_pre_battle")):Find("savegame_button"))
local avatar = MPAvatar(CampaignUI.MPOnlinePresence())

function Initialise(is_land, is_siege)
  out.shane("Initialise matchmaking")
  UIComponent(this:Find("food_title")):SetDisabled(false)
  UIComponent(this:Find("food_title")):SetInteractive(false)
  save_button:SetState("inactive")
  if g_drop_in_interface == nil then
    g_drop_in_interface = UIMPDropInInterface(CampaignUI.MultiplayerDropInInterface(), 0)
  end
  if is_land ~= nil and is_siege ~= nil and CampaignUI.PlayDropInBattle(is_land, is_siege) then
    client_id = nil
    syncronising = false
    UIComponent(this:Find("Finding_opponent")):SetVisible(true)
    UIComponent(this:Find("Opponent_found")):SetVisible(false)
    UIComponent(this:Find("button_invite_friend")):SetVisible(false)
    return true
  end
  return false
end

function HasPlayerJoined()
  return client_id ~= nil
end

function OnDestroyed()
  if g_drop_in_interface ~= nil then
    g_drop_in_interface:Release()
  end
end

function NotifyPlayerJoined(id, player_name)
  out.tom("Player joined")
  UIComponent(this:Find("Finding_opponent")):SetVisible(false)
  UIComponent(this:Find("Opponent_found")):SetVisible(true)
  UIComponent(this:Find("sync_bar_frame")):SetVisible(true)
  if id ~= nil then
    UIComponent(this:Find("dy_name")):SetStateText(player_name)
    client_id = id
    if client_id ~= nil then
      avatar:RequestAvatarAndLoadFallback(id, this:Find("Steam_icon"), 0)
    end
  end
end

function NotifySyncStarted()
  syncronising = true
  out.tom("Sync started")
end

function NotifySyncFinished()
  out.tom("Sync finished")
  syncronising = false
end

function NotifyHostFailure()
  out.tom("Host failure")
  UIComponent(this:Parent("popup_pre_battle")):InterfaceFunction("DropinFailure")
end

function InviteFriends()
  local panel = UIComponent(Component.CreateFromLayout("ui/campaign ui/friends_list", "friends_list", Address, 0, 0))
  local screen_w, screen_h = CampaignUI.ScreenSize()
  panel:MoveTo((screen_w - panel:Width()) / 2, (screen_h - panel:Height()) / 2)
  panel:LuaCall("Initialise")
end

function NotifyPlayerDisconnected()
  out.tom("Disconnected")
  Initialise()
end

function CancelDropIn()
  if g_drop_in_interface:CanCancel() then
    if CampaignUI.CanSave() then
      save_button:SetState("unselected")
    end
    g_drop_in_interface:SetDropInAvailable(false)
    syncronising = false
    UIComponent(this:Find("dy_name")):SetStateText("")
  end
end

function UpdateCountdown(time_remaining)
  out.tom("Countdown", time_remaining)
  UIComponent(this:Find("tx_time to start")):SetVisible(true)
  UIComponent(this:Find("dy_time")):SetStateText(tostring(time_remaining))
end

this:SetEventCallback("OnDestroyed", OnDestroyed)
