local core = require "ui/CoreUtils"
local scripting			= core.Require "EpisodicScripting"
local camera_pan = ""
local current_advice = ""
EpisodicScripting = scripting
scripting.SetCampaign("tut_shogun")

-------------------------------------------------------------------------------------
--------------------------------------- CACHED VALUES -------------------------------
-------------------------------------------------------------------------------------

local slider_tax_level				= 100

--[[ SHANE COMMENT
     Richard you can now use: if CampaignUI.CurrentTabTypename() ~= "Land_Recruitment_Tab" then..
     I've also put the different tab names in a table here so you can easily find them.
--]]

local review_panel_tab_typenames	= 
{
	"Army_Tab",
	"Navy_Tab",
	"Agents_Tab",
	"Garrison_Tab",
	"Infrastructure_Tab",
	"Land_Recruitment_Tab",
	"Naval_Recruitment_Tab",
	"Slot_Construction_Tab",
	"Settlement_Construction_Tab",
	"Region_Construction_Tab"
}

-------------------------------------------------------------------------------------
--------------------------------------- BOOLS  --------------------------------------
-------------------------------------------------------------------------------------

local BOOL_Game_Loaded = false
local BOOL_Players_Turn = false
local BOOL_Unit_Created = false
local BOOL_Flash_Next_Button = false
local BOOL_Kochi_Selected = false
local BOOL_Imabari_Selected = false
local BOOL_Takamatsu_Selected = false
local BOOL_Tokushima_Selected = false
local BOOL_Research_Complete = false
local BOOL_Space_Pressed = false
local BOOL_Faction_Ending_Turn = false
local BOOL_Rebels_Spawned = false
local BOOL_Metsuke_Bribed_Army = false
local BOOL_Takamatsu_Camera_2 = false
local BOOL_Enemy_Trade_Route_Raided = false
local BOOL_Agreement_Made = false
local BOOL_Sogo_Army_Spawned = false
local BOOL_Mission_Capture_Takamatsu_Given = false
local BOOL_Minamiawaji_Captured = false
local BOOL_Imabari_Captured = false
local BOOL_Takamatsu_Captured = false
local BOOL_Tokushima_Captured = false
local BOOL_Gates_Opened = false
local BOOL_Trade_Route_Raided = false
local BOOL_Character_Has_Come_Of_Age = false
local BOOL_Archery_Dojo_Constructed = false
local BOOL_Region_Info_Opened = false	
local BOOL_Finance_Panel_Opened = false
local BOOL_Upkeep_Advice = false
local BOOL_Set_Clan_Active = false
local BOOL_Set_Diplomacy_Active = false
local BOOL_Set_Technology_Active = false
local BOOL_Set_Finance_Active = false
local BOOL_Set_Newest_Advice_Active = false
local BOOL_Set_Factions_Tab_Active = false
local BOOL_6073 = false
local BOOL_6075 = false
local BOOL_6076 = false
local BOOL_6078 = false
local BOOL_6081 = false
local BOOL_6089b = false
local BOOL_Advice_23 = false
local BOOL_Advice_6095 = false
local BOOL_Advice_6034 = false
local BOOL_Free_Play = false
local BOOL_Advice_Arrows_Clicked = false
local BOOL_Miyoshi_Fleet_Spawned = false
local BOOL_Commissions_Highlighted = false
local BOOL_Commission_Selected = false
local BOOL_Character_Ranked_Up = false
local BOOL_Character_Ranked_Up_Info = false
local BOOL_Ship_Near_Matsuda = false
local BOOL_Awa_Camera_Triggered = false
local BOOL_Trade_Node_Connected = false
local BOOL_Fleets_Merged = false
local BOOL_Sieging_Imabari_Advice = false
local BOOL_Chosokabe_Armies_Merged = false
local BOOL_Player_Attacking_Osaka = false
local BOOL_First_Agreement = false
local BOOL_AP_Replenished = false
local BOOL_Advice_6034_Played = false

-------------------------------------------------------------------------------------
------------------------------------- COUNTERS --------------------------------------
-------------------------------------------------------------------------------------

local COUNTER_Advice = 0
local COUNTER_First_Tech_Researched = 0
local COUNTER_Units_Entering_Kochi = 0
local COUNTER_Castle_Gates_Opened = 0

--------------------------------------------------------------------------------------
----------------------------------- DILEMMAS -----------------------------------------
--------------------------------------------------------------------------------------

local function Dilemma_General()
	--Dilemma 1 - Recruit a general or not
	scripting.game_interface:trigger_custom_dilemma("tut_chosokabe",
                                                    "s_promotion_turn_start",
                                                    "spawn_general:capital", 	--Option A Reward (Spawn General)
                                                    "") 						--Option B Reward (Nothing)
end

--------------------------------------------------------------------------------------
----------------------------------- MISSIONS -----------------------------------------
--------------------------------------------------------------------------------------

local function MissionCaptureTakamatsu()
	out.ting("Capture Tokushima Mission")
	scripting.game_interface:trigger_custom_mission("tut_capture_takamatsu", 
													"CLAN_ELDERS",
													"tut_chosokabe", 
													0,
													"region:jap_tut_sanuki", 
													"money:500")
end

--------------------------------------------------------------------------------------

local function MissionCaptureTokushima()
	out.ting("Capture Tokushima Mission")
	scripting.game_interface:trigger_custom_mission("tut_capture_tokushima", 
													"CLAN_ELDERS",
													"tut_chosokabe", 
													0,
													"region:jap_tut_awa", 
													"money:500")
end

--------------------------------------------------------------------------------------

local function MissionCaptureAwaji()
	out.ting("Capture Awaji Mission")
	scripting.game_interface:trigger_custom_mission("tut_capture_awaji", 
													"CLAN_ELDERS",
													"tut_chosokabe", 
													0,
													"region:jap_tut_awaji", 
													"money:500")
end

------------------------------------------------------------------------------------

local function MissionCaptureOsaka()
	out.ting("Capture Osaka Mission")
	scripting.game_interface:trigger_custom_mission("tut_capture_osaka", 
													"CLAN_ELDERS",
													"tut_chosokabe", 
													0,
													"region:jap_tut_settsu", 
													"money:500")
end

------------------------------------------------------------------------------------
--------------------------------------- TURNS --------------------------------------
------------------------------------------------------------------------------------

local function OnFactionTurnStart(context)
	BOOL_Faction_Ending_Turn = false
	if conditions.FactionIsLocal(context) then
		out.ting("start turn: " .. COUNTER_Advice)
		scripting.HighlightComponent("button_newest", false) --Highlight (true, false), Highlight Type(Square = true, Circle = false)
		scripting.game_interface:dismiss_advice_at_end_turn(false)
		BOOL_Players_Turn = true
		if COUNTER_Advice == 0 then	
			SetupDiplomacy()
			Restrict_Technologies()
			scripting.game_interface:set_event_generation_enabled(false)
			scripting.game_interface:set_general_offered_dilemma_permitted(false)
			scripting.game_interface:treasury_mod("tut_chosokabe", 100)
			scripting.game_interface:create_force("tut_chosokabe", "Cav_Sword_Katana_Cavalry", -127.3, -139.6, "player_force_1", true)
			scripting.game_interface:disable_rebellions_and_revolutions_worldwide(true)
			scripting.game_interface:disable_saving_game(true)
			scripting.game_interface:allow_player_to_embark_navies(false)
			scripting.game_interface:set_character_experience_disabled(true)
			BOOL_Chapter_1 = true
			effect.advance_scripted_advice_thread("6001_TUT_Welcome", 1)
			COUNTER_Advice = 1
			BOOL_Flash_Next_Button = false
			scripting.game_interface:steal_user_input(true)
			CampaignUI.ToggleCinematicBorders(true)
			scripting.game_interface:scroll_camera(18,	{-123.4, -143.0, 0.5},
														{-123.4, -143.0, 1.05})
			camera_pan = "Intro_Camera"			
			----------------------------------------- BUILDING RESTRICTIONS ---------------------------------------------
			scripting.game_interface:add_restricted_building_level_record("SHO_Archery_1_Archery_Dojo")
			scripting.game_interface:add_restricted_building_level_record("SHO_Stealth_2_Gambling_Hall")
			scripting.game_interface:add_restricted_building_level_record("SHO_Buddhist_1_Temple")
			scripting.game_interface:add_restricted_building_level_record("SHO_Christian_1_Chapel")
			scripting.game_interface:add_restricted_building_level_record("SHO_Siege_1_Workshop")
			scripting.game_interface:add_restricted_building_level_record("SHO_Stealth_1_Sake_Den")
			scripting.game_interface:add_restricted_building_level_record("SHO_Sword_1_Sword_School")
			scripting.game_interface:add_restricted_building_level_record("SHO_Buff_1_Encampment")
			scripting.game_interface:add_restricted_building_level_record("SHO_Yari_1_Drill_Yard")
			scripting.game_interface:add_restricted_building_level_record("SHO_Crafts_1_Market")
			scripting.game_interface:add_restricted_building_level_record("SHO_Cavalry_1_Stables")
			scripting.game_interface:add_restricted_building_level_record("SHO_Farming_2_Irrigation")
			scripting.game_interface:add_restricted_building_level_record("SHO_Region_Specialty_Timber_2_Lumberyards")
			scripting.game_interface:add_restricted_building_level_record("SHO_Infrastructure_1_Roads")
			scripting.game_interface:add_restricted_building_level_record("SHO_Castle_2_Stronghold")
			scripting.game_interface:add_restricted_building_level_record("SHO_Castle_3_Fortress")
			scripting.game_interface:add_restricted_building_level_record("SHO_Port_3_Military_Port")
			scripting.game_interface:add_restricted_building_level_record("SHO_Port_3_Nanban_Trade_Port")
			scripting.game_interface:add_restricted_building_level_record("SHO_Ikko_Temple_1_Jodo_Shinshu_Temple")
			--------------------------------------- UNIT RESTRICTIONS ---------------------------------------------------	
			scripting.game_interface:add_restricted_unit_record("Art_European_Cannons")	
			scripting.game_interface:add_restricted_unit_record("Art_Fire_Projecting_Mangonels")	
			scripting.game_interface:add_restricted_unit_record("Art_Large_Shafted_Fire_Rockets")	
			scripting.game_interface:add_restricted_unit_record("Cav_Spear_Great_Guard")	
			scripting.game_interface:add_restricted_unit_record("Cav_Spear_Light_Cavalry")
			scripting.game_interface:add_restricted_unit_record("Inf_Spear_Yari_Ashigaru")
			scripting.game_interface:add_restricted_unit_record("Inf_Spear_Yari_Ashigaru_Tutorial_No_Cap")
			scripting.game_interface:add_restricted_unit_record("Inf_Spear_Yari_Hero")			
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Bow_Hero")	
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Bow_Wako")	
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Bow_Ashigaru_Tutorial_No_Cap")
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Bow_Ashigaru_Chosokabe")		
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Bow_Hero_Chosokabe")	
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Bow_Warrior_Monks_Chosokabe")
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Matchlock_Samurai")	
			scripting.game_interface:add_restricted_unit_record("Inf_Missile_Matchlock_Warrior_Monks")
			scripting.game_interface:add_restricted_unit_record("Inf_Heavy_Naginata_Warrior_Monks")	
			scripting.game_interface:add_restricted_unit_record("Inf_Special_Fire_Bomb_Throwers")
			scripting.game_interface:add_restricted_unit_record("Inf_Sword_Katana_Samurai")	
			scripting.game_interface:add_restricted_unit_record("Inf_Sword_Katana_Hero")	
			scripting.game_interface:add_restricted_unit_record("Inf_Sword_Katana_Wako")	
			scripting.game_interface:add_restricted_unit_record("Inf_Special_Kisho_Ninjas")	
			--------------------------------------- SHIP RESTRICTIONS ---------------------------------------------------	
			scripting.game_interface:add_restricted_unit_record("Trade_Ship_Trade_Ship")	
			scripting.game_interface:add_restricted_unit_record("Light_Ship_Bow_Kobaya")		
			scripting.game_interface:add_restricted_unit_record("Medium_Ship_Medium_Bune")
			scripting.game_interface:add_restricted_unit_record("Light_Ship_Siege_Tower_Bune")
			------------------------------------- SETUP DYNAMIC UI COMPONENTS -------------------------------------------
			scripting.game_interface:override_ui("disable_end_turn", true) 
			scripting.game_interface:override_ui("disable_disband_unit", true)
			scripting.game_interface:override_ui("disable_repair_building", true)
			scripting.game_interface:override_ui("disable_dismantle_building", true)
			scripting.game_interface:override_ui("disable_enlist_ninja", true)
			scripting.game_interface:override_ui("disable_diplomacy", true)
			scripting.game_interface:override_ui("disable_trade_tab", true)
			scripting.game_interface:override_ui("disable_summary_tab", true)
			scripting.game_interface:override_ui("disable_character_information_panel", true)
			scripting.game_interface:override_ui("disable_region_information_panel", true)
			scripting.game_interface:override_ui("disable_scupper_ship", true)	
			------------------------------------- OVERRIDE MESSAGES -----------------------------------------------------
			scripting.OverrideMessageAutoShow("clan_other_daimyo_dies", false)
			scripting.OverrideMessageAutoShow("your_spy_detected", false)
			scripting.OverrideMessageAutoShow("character_trait_gained", false)
			scripting.OverrideMessageAutoShow("summary_character_trait_gained", false)
			scripting.OverrideMessageAutoShow("character_gains_level", false)
			scripting.OverrideMessageAutoShow("character_gains_level_ninja", false)
			-------------------------------------------------------------------------------------------------------------
		elseif COUNTER_Advice == 6001 then
			scripting.game_interface:override_ui("disable_end_turn", true)
			effect.advance_scripted_advice_thread("6001b_TUT_Movement", 1)
			scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-127.3,y:-139.6,r:1")
		elseif COUNTER_Advice == 2 then
			scripting.game_interface:override_ui("disable_end_turn", true)
			effect.advance_scripted_advice_thread("6002_TUT_Movement", 1)
		elseif (COUNTER_Advice == 7 and BOOL_Unit_Created) then
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			scripting.game_interface:treasury_mod("tut_chosokabe", 850)
			BOOL_Unit_Created = false
			effect.advance_scripted_advice_thread("6008_TUT_Construction", 1)
			COUNTER_Advice = 8
			BOOL_Flash_Next_Button = false	
			scripting.HighlightComponent("Garrison_Tab", true, true)		
		elseif (COUNTER_Advice == 11 and BOOL_Archery_Dojo_Constructed == false) then
			scripting.HighlightComponent("button_end_turn", true, false)
		elseif COUNTER_Advice == 6015 then
			scripting.game_interface:override_ui("disable_tax_slider", false) 
			scripting.game_interface:override_ui("disable_end_turn", true) 
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			effect.advance_scripted_advice_thread("6016_TUT_Armies", 1)
			COUNTER_Advice = 16
			BOOL_Flash_Next_Button = true
			scripting.HighlightComponent("income_icon", true, false)
			scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
			BOOL_Set_Newest_Advice_Active = true
		elseif COUNTER_Advice == 20 then
			scripting.game_interface:override_ui("disable_end_turn", true) 
		elseif COUNTER_Advice == 21 then
			scripting.game_interface:override_ui("disable_end_turn", true) 					
		elseif COUNTER_Advice == 23 then
			if BOOL_Sieging_Imabari_Advice == false then
				BOOL_Sieging_Imabari_Advice = true
				effect.advance_scripted_advice_thread("6024_TUT_Sieging", 1)
				COUNTER_Advice = 24
				BOOL_Flash_Next_Button = false
				scripting.game_interface:override_ui("disable_end_turn", false) 
			end
		elseif BOOL_Archery_Dojo_Constructed then	
			BOOL_Archery_Dojo_Constructed = false
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			effect.advance_scripted_advice_thread("6029_TUT_Victory_Con", 1)
			COUNTER_Advice = 29
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("Land_Recruitment_Tab", true, true)	
		elseif COUNTER_Advice == 27 then		
			scripting.HighlightComponent("button_clan", true, false)
		elseif COUNTER_Advice == 29 then
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6012_TUT_Revolt", 1)
			COUNTER_Advice = 12
			BOOL_Flash_Next_Button = false
		elseif COUNTER_Advice == 34 then	
			scripting.game_interface:override_ui("disable_end_turn", true) 
			if BOOL_Advice_6034_Played == false then
				BOOL_Advice_6034_Played = true
				effect.advance_scripted_advice_thread("6094_TUT_Battles", 1)
				scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:General")
				scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:colonel")
				scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1")
			end
		elseif COUNTER_Advice == 39 then
			scripting.game_interface:make_son_come_of_age("forename:2147278466")
		elseif (COUNTER_Advice == 53 and BOOL_Unit_Created) then
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			effect.advance_scripted_advice_thread("6054_TUT_Port", 1)
			COUNTER_Advice = 54
			BOOL_Flash_Next_Button = false	
			scripting.game_interface:add_circle_area_trigger(-162, -108, 11, "Trigger_Area_Trading_Area", "faction:tut_chosokabe", true, false, true) 
			scripting.game_interface:add_marker("Marker_Trade_Post", "campaign_map_marker01", -159.7, -109.1, 0, true)
			CampaignUI.highlight_character("x:-151.9,y:-118.3,r:1.0,faction:tut_chosokabe")	
			scripting.game_interface:add_restricted_unit_record("Light_Ship_Bow_Kobaya")
			scripting.game_interface:add_circle_area_trigger(-119, -112.5, 4, "Trigger_Area_Coast", "faction:tut_chosokabe", true, false, false) 
			scripting.game_interface:add_circle_area_trigger(-119, -112.5, 4, "Trigger_Area_Coast", "faction:tut_chosokabe", false, true, false) 
		elseif COUNTER_Advice == 55 then
			if BOOL_Trade_Node_Connected then
				CampaignUI.unhighlight_position(-163.3, -110.9)
				scripting.game_interface:override_ui("disable_event_panel_auto_open", true)
				scripting.game_interface:override_ui("disable_disband_unit", false)
				effect.advance_scripted_advice_thread("6056_TUT_Replenishment", 1)
				COUNTER_Advice = 56
				BOOL_Flash_Next_Button = false
				scripting.game_interface:steal_user_input(true)
				CampaignUI.ToggleCinematicBorders(true)
				local	x, z, y, theatre = CampaignUI.CameraTarget()
				scripting.game_interface:scroll_camera(5,	{x, y, z},
															{-131.1, -123.7, 0.6})
				camera_pan = "Takamatsu_Camera"
			else
				scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-159.7,y:-109.1,r:2")
			end
		elseif COUNTER_Advice == 56 then
			effect.advance_scripted_advice_thread("6057_TUT_Technology", 1)
			COUNTER_Advice = 57
			BOOL_Flash_Next_Button = false
			scripting.game_interface:override_ui("disable_tech_button", false)
			BOOL_Set_Technology_Active = true
			scripting.HighlightComponent("button_tech", true, false)
			scripting.game_interface:remove_restricted_building_level_record("SHO_Buddhist_1_Temple")
			scripting.game_interface:remove_restricted_building_level_record("SHO_Siege_1_Workshop")
			scripting.game_interface:add_restricted_building_level_record("SHO_Siege_2_Powder_Maker")
			scripting.game_interface:remove_restricted_building_level_record("SHO_Crafts_1_Market")			
		elseif COUNTER_Advice == 64 then
			scripting.game_interface:override_ui("disable_event_panel_auto_open", true)
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			effect.advance_scripted_advice_thread("6065_TUT_Trade_Route", 1)
			COUNTER_Advice = 65
			BOOL_Flash_Next_Button = false
			scripting.game_interface:create_force("tut_chosokabe", "Medium_Ship_Medium_Bune,Heavy_Ship_Heavy_Bune", -116.3, -117.3, "chosokabe_naval_force_1", true)
			scripting.game_interface:steal_user_input(true)
			CampaignUI.ToggleCinematicBorders(true)
			local	x, z, y, theatre = CampaignUI.CameraTarget()
			scripting.game_interface:scroll_camera(5,	{x, y, z},
														{-123.6, -115.3, 0.8})
			camera_pan = "Protect_Trade_Route_Camera"
		elseif COUNTER_Advice == 66 then
			scripting.game_interface:override_ui("disable_event_panel_auto_open", true)
			scripting.game_interface:override_ui("disable_scupper_ship", false)
			scripting.game_interface:override_ui("disable_end_turn", true) 
			effect.advance_scripted_advice_thread("6067_TUT_Trade_Ships", 1)
			COUNTER_Advice = 67
			BOOL_Flash_Next_Button = false
			scripting.game_interface:add_marker("Marker_Miyoshi_Trade_Route", "campaign_map_marker01", -103.3, -115.9, 0, true)
			scripting.game_interface:steal_user_input(true)
			CampaignUI.ToggleCinematicBorders(true)
			local	x, z, y, theatre = CampaignUI.CameraTarget()
			scripting.game_interface:scroll_camera(5,	{x, y, z},
														{-105.9, -114.8, 0.8})
			camera_pan = "Enemy_Trade_Route_Camera"
		elseif COUNTER_Advice == 67 then
			if BOOL_Enemy_Trade_Route_Raided then
				scripting.game_interface:disable_saving_game(false)
				scripting.game_interface:autosave_at_next_opportunity()
				effect.advance_scripted_advice_thread("6070_TUT_Missions", 1)
				COUNTER_Advice = 70
				BOOL_Flash_Next_Button = false
				scripting.game_interface:remove_barrier("TUT_Shroud_3")
				scripting.game_interface:unveil_black_shroud("TUT_Shroud_4")
				MissionCaptureTokushima()
				scripting.game_interface:add_marker("Marker_Tokushima", "campaign_map_marker01", -95, -138, 0, true)
				scripting.game_interface:add_circle_area_trigger(-95.6, -138.2, 3, "Trigger_Area_Tokushima", "faction:tut_chosokabe", true, false, true)
			end
		end
		if COUNTER_Advice == 24 or COUNTER_Advice == 40 or COUNTER_Advice == 41 or COUNTER_Advice == 42 or COUNTER_Advice == 43 or COUNTER_Advice == 44 or COUNTER_Advice == 45 or COUNTER_Advice == 46 or COUNTER_Advice == 47 or COUNTER_Advice == 6047 or COUNTER_Advice == 48 or COUNTER_Advice == 49 or COUNTER_Advice == 50 or COUNTER_Advice == 51 or COUNTER_Advice == 52 or COUNTER_Advice == 53 or COUNTER_Advice == 54 then
			scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-133.7,y:-139.1,r:1,type:colonel")
			scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-142.1,y:-118.1,r:1,type:colonel")
			scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-141.6,y:-115.2,r:1,type:colonel")
		end
   	else
		BOOL_Players_Turn = false
	end
end

--------------------------------------------------------------------------------------

local function OnFactionBeginTurnPhaseNormal(context)
	out.ting("Turn Phase Started")
 	if conditions.FactionName("rebels", context) then 
 		out.ting("Rebels turn")
 		if COUNTER_Advice == 34 then
 			out.ting("Rebel to attack Kochi Command")
 			scripting.game_interface:disable_movement_for_character("faction:rebels,x:-131.1,y:-132.7,r:1")
   		end
   	end
   	if conditions.FactionName("tut_miyoshi", context) then
   		out.ting("Miyoshi turn")
   		if BOOL_Free_Play == false then
   			scripting.game_interface:disable_movement_for_character("faction:tut_miyoshi,x:-95.5,y:-137.9,r:2")
   			scripting.game_interface:disable_movement_for_character("faction:tut_miyoshi,x:-60.8,y:-121.1,r:2")
   		else
   			scripting.game_interface:enable_movement_for_character("faction:tut_miyoshi,x:-95.5,y:-137.9,r:2")
   		end
 		if (COUNTER_Advice == 65 and BOOL_Fleets_Merged)then 
 			out.ting("Miyoshi Fleet to attack trade rout")
 			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_miyoshi", "war", true, true)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_chosokabe", "war", true, true)
 			scripting.game_interface:force_declare_war("tut_miyoshi", "tut_chosokabe")
 			scripting.game_interface:add_time_trigger("Miyoshi_Fleet_Attack", 0)
   		end
   	end
   	if conditions.FactionName("tut_kono", context) then
   		out.ting("Kono turn")
   		if BOOL_Free_Play == false then
   			scripting.game_interface:disable_movement_for_character("faction:tut_kono,x:-141.4,y:-116.3,r:2")
   		end
   		if COUNTER_Advice == 6015 then
   			out.ting("Move Monk into Tosa")
   			scripting.game_interface:move_to("x:-137.2,y:-123.5,r:2.0", -130.6, -137.5, false)
   		end
 	end 
 	if conditions.FactionName("tut_sogo", context) then
 		out.ting("Sogo turn")
   		scripting.game_interface:disable_movement_for_character("faction:tut_sogo,x:-108.0,y:-120.0,r:5")
 	end
end

--------------------------------------------------------------------------------------

local function OnPendingBattle(context)
	if conditions.FactionName("tut_miyoshi", context) then
 		if COUNTER_Advice == 65 then
   			scripting.game_interface:win_next_autoresolve_battle("tut_chosokabe")
   		end
   	elseif conditions.FactionName("tut_chosokabe", context) then
   		if COUNTER_Advice == 34 then
   			scripting.game_interface:win_next_autoresolve_battle("tut_chosokabe")
   			scripting.game_interface:modify_next_autoresolve_battle(0, -0.5, 0, 0, 0)
   		elseif COUNTER_Advice == 24 then
   			scripting.game_interface:win_next_autoresolve_battle("tut_chosokabe")
   			scripting.game_interface:modify_next_autoresolve_battle(0, -0.3, 0, 0, 0)
   		end
 	end 
end

--------------------------------------------------------------------------------------

local function OnFactionAboutToEndTurn(context)
	BOOL_Faction_Ending_Turn = true
	scripting.game_interface:set_campaign_ai_force_all_factions_boardering_humans_to_have_invasion_behaviour(false)
end

--------------------------------------------------------------------------------------

local function OnFactionTurnEnd(context)
	scripting.HighlightComponent("button_end_turn", false)
	if conditions.FactionIsLocal(context) then 
		out.ting("Local Turn Ended")
		if COUNTER_Advice == 27 then
			scripting.HighlightComponent("button_clan", false)
		elseif COUNTER_Advice == 29 then
			out.ting("Change Tax")
			scripting.game_interface:set_tax_rate("tut_chosokabe", "asia", false, 4) 
			scripting.game_interface:exempt_region_from_tax("jap_tut_tosa", false)
			scripting.game_interface:set_ignore_end_of_turn_public_order(true)
		elseif COUNTER_Advice == 6015 then
			scripting.game_interface:create_agent("tut_kono", "monk", -137.2, -123.5, "kono_monk_agent_1", true)
		elseif COUNTER_Advice == 34 then
			if BOOL_Rebels_Spawned == false then
				out.ting("Spawn Rebel Army")
				BOOL_Rebels_Spawned = true
				scripting.game_interface:force_rebellion_in_region("jap_tut_tosa", 0, "Inf_Spear_Yari_Samurai,Inf_Missile_Bow_Samurai,Inf_Missile_Bow_Samurai,Cav_Sword_Katana_Cavalry", "", "", -131.1, -132.7, true)
			end
		elseif (COUNTER_Advice == 65 and BOOL_Fleets_Merged) then
			if BOOL_Miyoshi_Fleet_Spawned == false then
				out.ting("Spawn Miyoshi Fleet")
				BOOL_Miyoshi_Fleet_Spawned = true
				scripting.game_interface:create_force("tut_miyoshi", "Light_Ship_Bow_Kobaya,Light_Ship_Bow_Kobaya,Medium_Ship_Medium_Bune,Medium_Ship_Medium_Bune", -99.9, -118.8, "miyoshi_naval_force_1", true)
			end
		end
	end
end

------------------------------------------------------------------------------------
-------------------------------- INITIAL DIPLOMACY ---------------------------------
------------------------------------------------------------------------------------

function SetupDiplomacy(context)
			out.ting("Setting Up Diplomacy")
			-- First Bool - Will Offer; Second Bool - Will Accept			
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_sogo", "peace", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_kono", "peace", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_miyoshi", "peace", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_sogo", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_kono", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_miyoshi", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_bessho", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_hatakeyama", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_kikkawa", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_matsuda", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_tsutsui", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_urakami", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_matsuda", "trade agreement", true, true)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_matsuda", "alliance", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_matsuda", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_bessho", "tut_tsutsui", "trade agreement", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_matsuda", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_hatakeyama", "tut_tsutsui", "trade agreement", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_matsuda", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kikkawa", "tut_tsutsui", "trade agreement", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_kono", "tut_sogo", "alliance", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_matsuda", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_tsutsui", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_chosokabe", "peace", false, false)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_chosokabe", "war", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_tsutsui", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_chosokabe", "trade agreement", true, true)
			scripting.game_interface:force_diplomacy("tut_matsuda", "tut_chosokabe", "alliance", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_matsuda", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_tsutsui", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_chosokabe", "peace", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_chosokabe", "war", false, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_urakami", "war", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_kono", "alliance", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_matsuda", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_tsutsui", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_chosokabe", "peace", false, false)
			scripting.game_interface:force_diplomacy("tut_sogo", "tut_chosokabe", "war", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_urakami", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_tsutsui", "tut_matsuda", "trade agreement", false, false)
			--
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_sogo", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_kono", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_miyoshi", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_bessho", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_hatakeyama", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_matsuda", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_kikkawa", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_tsutsui", "trade agreement", false, false)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_miyoshi", "war", false, false)
end

----------------------

function Restrict_Technologies()
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_chosokabe", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_miyoshi", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_bessho", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_hatakeyama", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_matsuda", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_kikkawa", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_sogo", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_tsutsui", "shogun_civil_core_tea_ceremony")
	--
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_spear_spear_expertise")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_core_the_five_elements")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_musket_attack_by_fire")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_naval_naval_expertise")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_bow_bow_expertise")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_core_horse_mastery")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_sword_sword_expertise")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_bow_way_of_the_bow")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_naval_way_of_the_sea")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_religion_essence_of_the_spirit")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_religion_scholarship")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_core_calligraphy")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_loyalty_sumo_tournament")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_ninja_ninjutsu_mastery")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_metsuke_sword_hunt")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_core_traditional_building")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_province_chonindo")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_ninja_school_of_shinobi")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_core_form")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_military_core_heaven_and_earth")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_core_tax_reform")
	scripting.game_interface:lock_technology("tut_urakami", "shogun_civil_core_tea_ceremony")
end

-------------------------------------------------------------------------------------
-------------------------------- ADVICE TRIGGERS ------------------------------------
-------------------------------------------------------------------------------------

local function OnAdviceTriggered(context)
	current_advice = context.string
	out.ting(context.string)
end

----------------------

local function OnAdviceDismissed(context)
	local local_current_advice = current_advice
	current_advice = ""
	if local_current_advice == context.string then
		out.ting("Matches")
	end
end

----------------------

local function OnAdviceFinished(context)
	local local_current_advice = current_advice
	current_advice = ""	
	if BOOL_Flash_Next_Button then
		scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
		BOOL_Set_Newest_Advice_Active = true
		scripting.HighlightComponent("button_newest", true, false)
		BOOL_Flash_Next_Button = false
	else
		if BOOL_Advice_Arrows_Clicked == false then
			scripting.EnableFeature("Set_Button_Newest_Advice_Inactive")
			BOOL_Set_Newest_Advice_Active = false
			scripting.HighlightComponent("button_newest", false, false)
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------- MOVEMENT & ENTERING --------------------------------
-------------------------------------------------------------------------------------

local function OnAreaEntered(context)
	out.ting("Location Entered")
	if BOOL_Players_Turn then
		if conditions.IsMessageType("Trigger_Area_Merge_Forces", context) then
			if COUNTER_Advice == 6001 then
				scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-127.3,y:-139.6,r:2,type:colonel")
				CampaignUI.clear_highlights()
				CampaignUI.unhighlight_character("x:-127.3,y:-139.6,r:1.0,faction:tut_chosokabe")			
				effect.advance_scripted_advice_thread("6002_TUT_Movement", 1)
				COUNTER_Advice = 2
				BOOL_Flash_Next_Button = false
				CampaignUI.highlight_settlement("settlement:jap_tut_tosa:kochi")
			end
		elseif conditions.IsMessageType("Trigger_Area_Reveal_Sogo_Army", context) then
			if COUNTER_Advice == 44 then
				if BOOL_Sogo_Army_Spawned == false then
					BOOL_Sogo_Army_Spawned = true
					scripting.game_interface:create_force("tut_sogo", "Inf_Spear_Yari_Ashigaru", -121.0, -125.3, "sogo_force", true)
					scripting.game_interface:add_time_trigger("Disable_Movement_Of_Sogo_Army", 0)
				end
			end
		elseif conditions.IsMessageType("Trigger_Area_Ninja_Actions", context) then
			if COUNTER_Advice == 44 then
				scripting.game_interface:disable_saving_game(true)
				effect.advance_scripted_advice_thread("6045_TUT_Agents", 1)
				COUNTER_Advice = 45
				BOOL_Flash_Next_Button = false
				scripting.game_interface:cancel_actions_for(context)
				scripting.game_interface:force_agent_action_success_for_human(true)
				scripting.game_interface:steal_user_input(true)
				CampaignUI.ToggleCinematicBorders(true)
				local	x, z, y, theatre = CampaignUI.CameraTarget()
				scripting.game_interface:scroll_camera(3,	{x, y, z},
															{-122.5, -124.3, 1.15})
				camera_pan = "Ninja_Sabotage_Army_Camera"
			end
		elseif conditions.IsMessageType("Trigger_Area_Coast", context) then
			BOOL_Ship_Near_Matsuda = true
			if COUNTER_Advice == 6060 then
				scripting.game_interface:disable_saving_game(true)
				scripting.game_interface:add_marker("Marker_Coast", "campaign_map_marker01", -119, -112.5, 0, false)
				effect.advance_scripted_advice_thread("6061_TUT_Diplomacy", 1)
				COUNTER_Advice = 61
				BOOL_Flash_Next_Button = false
				scripting.game_interface:override_ui("disable_diplomacy", false)
				scripting.game_interface:override_ui("disable_diplomacy_button", false)
				BOOL_Set_Diplomacy_Active = true
				scripting.HighlightComponent("button_diplomacy", true, false)	
			end
		elseif conditions.IsMessageType("Trigger_Area_Left_Coast", context) then
			BOOL_Ship_Near_Matsuda = false
		elseif conditions.IsMessageType("Trigger_Area_Trading_Area", context) then
			if COUNTER_Advice == 54 then
				scripting.game_interface:disable_saving_game(true)
				effect.advance_scripted_advice_thread("6055_TUT_Trade_Ships", 1)
				COUNTER_Advice = 55
				BOOL_Flash_Next_Button = false
				scripting.game_interface:override_ui("disable_end_turn", true) 
				scripting.game_interface:add_marker("Marker_Trade_Post", "campaign_map_marker01", -159.7, -109.1, 0, false)
				scripting.game_interface:create_force("tut_chosokabe", "Trade_Ship_Trade_Ship", -167.0, -115.0, "chosokabe_naval_force_2", true)	
				scripting.game_interface:add_time_trigger("Highlight_Trade_Ship", 0)		
				scripting.game_interface:steal_user_input(true)
				CampaignUI.ToggleCinematicBorders(true)
				local	x, z, y, theatre = CampaignUI.CameraTarget()
				scripting.game_interface:scroll_camera(3,	{x, y, z},
															{-166.0, -117.7, 1.15})
				camera_pan = "Trade_Post_Camera"	
			end
		elseif conditions.IsMessageType("Trigger_Area_Trade_Post", context) then
			if COUNTER_Advice == 55 then
				out.ting("Trigger Area Trade Post")
				CampaignUI.unhighlight_position(-163.3, -110.9)
				scripting.game_interface:override_ui("disable_end_turn", false) 
				scripting.HighlightComponent("button_end_turn", true, false)
			end
		elseif conditions.IsMessageType("Trigger_Area_Remove_Takamatsu_Marker", context) then
			if COUNTER_Advice == 6047 or COUNTER_Advice == 6089 or BOOL_Character_Ranked_Up_Info then
				scripting.game_interface:add_marker("Marker_Takamatsu", "campaign_map_marker01", -108, -119, 0, false)
			end
		elseif conditions.IsMessageType("Trigger_Area_Tokushima", context) then
			scripting.game_interface:add_marker("Marker_Tokushima", "campaign_map_marker01", -95, -138, 0, false)
		elseif conditions.IsMessageType("Trigger_Area_Imabari", context) then
			if BOOL_Sieging_Imabari_Advice == false then
				BOOL_Sieging_Imabari_Advice = true
				scripting.game_interface:add_marker("Marker_Imabari", "campaign_map_marker01", -140, -115, 0, false)
				effect.advance_scripted_advice_thread("6024_TUT_Sieging", 1)
				COUNTER_Advice = 24
				BOOL_Flash_Next_Button = false
				scripting.game_interface:override_ui("disable_end_turn", false) 
			end
		elseif conditions.IsMessageType("Trigger_Area_Osaka", context) then
			BOOL_Player_Attacking_Osaka = true
		elseif conditions.IsMessageType("Trigger_Area_Osaka_Exit", context) then
			BOOL_Player_Attacking_Osaka = false
		end
	end
end

-------------------------------------------------------------------------------------

local function OnEnteredGarrison(context)
	out.ting("Entered City")
	if conditions.CharacterIsLocalCampaign(context) then
		out.ting("Player Entered City")
		if conditions.SettlementName("settlement:jap_tut_tosa:kochi", context) then
			out.ting("Kochi is controlled by the player") 
			if conditions.GarrisonUnitCount(context) == 2 then
				if COUNTER_Advice == 2 then
					effect.advance_scripted_advice_thread("6003_TUT_Camera", 1)
					COUNTER_Advice = 3
					BOOL_Flash_Next_Button = true
					scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
					BOOL_Set_Newest_Advice_Active = true
					CampaignUI.unhighlight_settlement("settlement:jap_tut_tosa:kochi")
					scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:General")
					scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:colonel")
					scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1")
				end
			end
		elseif conditions.SettlementName("settlement:jap_tut_iyo:imabari", context) then
			BOOL_Imabari_Captured = true
			out.ting("Imabari is controlled by the player")  
			out.ting(COUNTER_Advice)
			if COUNTER_Advice == 25 then
				scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-141.0,y:-116.0,r:2,type:General")
				scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-141.0,y:-116.0,r:2,type:colonel")
				scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-141.0,y:-116.0,r:2")
				scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:General")
				scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:colonel")
				scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1")
			end
		elseif conditions.SettlementName("settlement:jap_tut_sanuki:takamatsu", context) then
			BOOL_Takamatsu_Captured = true
			out.ting("Takamatsu is controlled by the player") 	
		elseif conditions.SettlementName("settlement:jap_tut_awa:tokushima", context) then
			BOOL_Tokushima_Captured = true
			out.ting("Tokushima is controlled by the player") 	
		elseif conditions.SettlementName("settlement:jap_tut_awaji:minamiawaji", context) then
			BOOL_Minamiawaji_Captured = true
			out.ting("Minamiawaji is controlled by the player") 	
		end
	end
end
			
-------------------------------------------------------------------------------------
------------------------------------ PANELS -----------------------------------------
-------------------------------------------------------------------------------------

local function OnPanelOpen(context)
	out.ting("Panel Opened")
	if conditions.IsComponentType("agent_options", context) then 
		if COUNTER_Advice == 45 then
			scripting.game_interface:add_time_trigger("Highlight_Agent_Action_Sabotage", 0)
		elseif COUNTER_Advice == 6047 then
			scripting.game_interface:add_time_trigger("Highlight_Agent_Action_Gates", 0)
		end
	elseif conditions.IsComponentType("character_skills", context) then
		if (BOOL_Character_Ranked_Up_Info and BOOL_6089b == false) then
			BOOL_6089b = true
			effect.advance_scripted_advice_thread("6089b_TUT_Agents", 1)
			BOOL_Flash_Next_Button = false
		end
	elseif conditions.IsComponentType("clan", context) then 
		scripting.HighlightComponent("button_clan", false)
		if COUNTER_Advice == 27 then
				effect.advance_scripted_advice_thread("6028_TUT_Victory_Con", 1)
				scripting.HighlightComponent("button_tick", true, true)
				COUNTER_Advice = 28
		elseif COUNTER_Advice == 39 then
			if BOOL_Character_Has_Come_Of_Age then
				effect.advance_scripted_advice_thread("6032_TUT_Generals", 1)
				COUNTER_Advice = 32
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("Family", true, true)
			end		
		end		
	elseif conditions.IsComponentType("diplomacy_panel", context) then 
		scripting.HighlightComponent("button_diplomacy", false)
		if COUNTER_Advice == 61 then
			scripting.game_interface:treasury_mod("tut_chosokabe", 1000)
			effect.advance_scripted_advice_thread("6062_TUT_Diplomacy", 1)
			COUNTER_Advice = 62
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("faction_Matsuda", true, true)
		elseif BOOL_Free_Play then
			if BOOL_6078 == false then
				BOOL_6078 = true
				effect.advance_scripted_advice_thread("6078_TUT_Alliance", 1)
				COUNTER_Advice = 78
				BOOL_Flash_Next_Button = true
				scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
				BOOL_Set_Newest_Advice_Active = true
			end
		end
	elseif conditions.IsComponentType("events", context) then
		if COUNTER_Advice == 29 then
			scripting.HighlightComponent("button_ok", true, true, "OK_zoom")
		elseif COUNTER_Advice == 46 then
			effect.advance_scripted_advice_thread("6047_TUT_Agents", 1)
			COUNTER_Advice = 47
			BOOL_Flash_Next_Button = false
			scripting.game_interface:enable_movement_for_character("faction:tut_sogo,x:-121.0,y:-125.3,r:1")
		end		
	elseif conditions.IsComponentType("finance_screen", context) then 
		scripting.HighlightComponent("button_finance", false)
		scripting.HighlightComponent("button_taxes", false)
		scripting.HighlightComponent("Public order panel layout", false)
		BOOL_Finance_Panel_Opened = true
		if COUNTER_Advice == 60122 then
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6014_TUT_Finance", 1)
			COUNTER_Advice = 14
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("slider", true, true, "tx_classes_lower")
		end
	elseif conditions.IsComponentType("move_options", context) then
		if COUNTER_Advice == 20 then
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6021_TUT_War", 1)
			COUNTER_Advice = 21
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("options_bar1", true, true) 
		end	
		if BOOL_Free_Play == false then
			scripting.EnableFeature("Set_Military_Access_Inactive")
		else
			scripting.InitFeature("Set_Military_Access_Inactive")
		end
	elseif conditions.IsComponentType("popup_pre_battle", context) then 
		if COUNTER_Advice == 34 then
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6018_TUT_Battles", 1)
			COUNTER_Advice = 18
			BOOL_Flash_Next_Button = false
			scripting.game_interface:override_ui("disable_end_turn", false) 
			scripting.HighlightComponent("button_autoresolve", true, true, "button_set_attack")
			scripting.HighlightComponent("button_attack", true, false, "button_set_attack")
		elseif COUNTER_Advice == 23 or COUNTER_Advice == 24 then
			effect.advance_scripted_advice_thread("6025_TUT_Sieging", 1)
			COUNTER_Advice = 25
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("button_autoresolve", true, true, "button_set_siege")
		elseif COUNTER_Advice == 65 then
			scripting.HighlightComponent("button_attack", true, false, "button_set_attack")
			scripting.HighlightComponent("button_autoresolve", true, true, "button_set_attack")
		elseif COUNTER_Advice == 56 or COUNTER_Advice == 57 or COUNTER_Advice == 58 or COUNTER_Advice == 59 or COUNTER_Advice == 70 or COUNTER_Advice == 71 then
			if (CampaignUI.IsPreBattleTypeSiege() and BOOL_Players_Turn) then
				scripting.HighlightComponent("button_attack", true, false, "button_set_siege")
			end
		end	
		if BOOL_Free_Play then
			if CampaignUI.IsPreBattleTypeSiege() then
				if BOOL_Player_Attacking_Osaka then
					scripting.game_interface:enable_movement_for_character("faction:tut_miyoshi,x:-60.8,y:-121.1,r:2")
				end
			end
		end	
	elseif conditions.IsComponentType("popup_battle_results", context) then 
		if COUNTER_Advice == 18 then
			effect.advance_scripted_advice_thread("6019_TUT_Battle_Results", 1)
			COUNTER_Advice = 19
			BOOL_Flash_Next_Button = false
			scripting.game_interface:kill_character("faction:rebels", true, true)
			scripting.game_interface:remove_custom_battlefield("TutorialBattles/TUT_Battle_Ashigaru.xml", false)
		elseif COUNTER_Advice == 65 then
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6066_TUT_Naval_Battle", 1)
			COUNTER_Advice = 66
			BOOL_Flash_Next_Button = false
			scripting.game_interface:force_make_trade_agreement("tut_miyoshi", "tut_urakami")
			scripting.game_interface:kill_character("x:-114.0,y:-112.0,r:10,faction:tut_miyoshi", true, false)
			scripting.game_interface:remove_custom_battlefield("TutorialBattles/TUT_Naval_Ashigaru.xml", false)
			scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-116.3,y:-117.3,r:1")
		end	
	elseif conditions.IsComponentType("region_info", context) then
		BOOL_Region_Info_Opened = true
		scripting.HighlightComponent("text_button", false, false)
		if COUNTER_Advice == 6012 then
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6012c_TUT_Region_Panel", 1)
			COUNTER_Advice = 60122
			BOOL_Flash_Next_Button = false
			scripting.game_interface:override_ui("disable_finance_button", false)
			BOOL_Set_Finance_Active = true
			scripting.HighlightComponent("button_taxes", true, false)
			scripting.HighlightComponent("button_finance", true, false)
			scripting.HighlightComponent("Public order panel layout", true, true)
		end		
	elseif conditions.IsComponentType("settlement_captured", context) then
		if COUNTER_Advice == 25 then
			effect.advance_scripted_advice_thread("6026_TUT_Looting", 1)
			COUNTER_Advice = 26
			BOOL_Flash_Next_Button = false
		end
		if BOOL_Free_Play == false then
			scripting.HighlightComponent("occupy_text_button", true, true)
		end
	elseif conditions.IsComponentType("technology", context) then 
		scripting.HighlightComponent("button_tech", false)
		if COUNTER_Advice == 57 then
			effect.advance_scripted_advice_thread("6058_TUT_Technology", 1)
			COUNTER_Advice = 58
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("tech_card_1", true, true)
		end
	end
end

-------------------------------------------------------------------------------------

local function OnPanelClosed(context)
	out.ting("Panel Closed")
	if conditions.IsComponentType("clan", context) then 
		if COUNTER_Advice == 28 then
			scripting.game_interface:override_ui("disable_end_turn", true)
			CampaignUI.highlight_settlement("settlement:jap_tut_iyo:imabari")
			effect.advance_scripted_advice_thread("6035_TUT_Castle", 1)
			COUNTER_Advice = 35
			BOOL_Flash_Next_Button = false
		elseif COUNTER_Advice == 33 then
			effect.advance_scripted_advice_thread("6040_TUT_Farms", 1)
			COUNTER_Advice = 40
			BOOL_Flash_Next_Button = false
		end
	elseif conditions.IsComponentType("diplomacy_panel", context) then 
		if COUNTER_Advice == 6063 then
			if BOOL_Agreement_Made then
				effect.advance_scripted_advice_thread("6064_TUT_Diplomacy", 1)
				COUNTER_Advice = 64
				BOOL_Flash_Next_Button = false
				scripting.game_interface:override_ui("disable_dismantle_building", false)
				scripting.HighlightComponent("button_end_turn", true, false)
				scripting.HighlightComponent("button_cancel", false, false, "diplomatic_relations")
			else
				scripting.HighlightComponent("button_diplomacy", true, false)
				COUNTER_Advice = 61
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("button_cancel", false, false, "diplomatic_relations")
			end
		end
	elseif conditions.IsComponentType("events", context) then
		if COUNTER_Advice == 12 then
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			scripting.game_interface:override_ui("disable_region_information_panel", false)
			effect.advance_scripted_advice_thread("6012b_TUT_Region_Panel", 1)
			COUNTER_Advice = 6012
			BOOL_Flash_Next_Button = false
			CampaignUI.highlight_settlement("settlement:jap_tut_tosa:kochi")
			scripting.HighlightComponent("text_button", true, true)
			scripting.HighlightComponent("button_ok", false, false)
			scripting.HighlightComponent("button_close", false, false)
			scripting.game_interface:override_ui("disable_end_turn", true) 
		elseif COUNTER_Advice == 23 then
			scripting.HighlightComponent("button_end_turn", true, false)
		elseif COUNTER_Advice == 39 then
			if BOOL_Character_Has_Come_Of_Age then
				scripting.HighlightComponent("button_clan", true, false)
			end
		elseif COUNTER_Advice == 47 then
			if BOOL_Takamatsu_Camera_2 == false then
				effect.advance_scripted_advice_thread("6047b_TUT_Agents", 1)
				COUNTER_Advice = 6047
				BOOL_Flash_Next_Button = false
				BOOL_Takamatsu_Camera_2 = true
				scripting.game_interface:steal_user_input(true)
				CampaignUI.ToggleCinematicBorders(true)
				local	x, z, y, theatre = CampaignUI.CameraTarget()
				scripting.game_interface:scroll_camera(5,	{x, y, z},
															{-119.3, -120.2, 0.9})
				camera_pan = "Takamatsu_Camera_2"
			end
		elseif (COUNTER_Advice == 70 and BOOL_Awa_Camera_Triggered == false) then
			BOOL_Awa_Camera_Triggered = true
			scripting.game_interface:add_time_trigger("Awa_Camera", 0)
		elseif BOOL_Gates_Opened then
			COUNTER_Castle_Gates_Opened = COUNTER_Castle_Gates_Opened + 1
			if COUNTER_Castle_Gates_Opened == 2 then
				BOOL_Gates_Opened = false
				scripting.game_interface:add_time_trigger("Resource_Sanuki_Camera", 0)
			end
		end
	elseif conditions.IsComponentType("event_movie_panel", context) then
		if COUNTER_Advice == 42 then
			scripting.game_interface:override_ui("disable_end_turn", true) 
			effect.advance_scripted_advice_thread("6043_TUT_Agents", 1)
			COUNTER_Advice = 43
			BOOL_Flash_Next_Button = false
			CampaignUI.highlight_character("x:-142.1,y:-118.2,r:1.0,faction:tut_chosokabe")
		end
	elseif conditions.IsComponentType("finance_screen", context) then
		BOOL_Finance_Panel_Opened = false
		if ((COUNTER_Advice == 15 or COUNTER_Advice == 6015)and BOOL_Region_Info_Opened == false) then
			BOOL_Flash_Next_Button = false
			COUNTER_Advice = 6015
			scripting.game_interface:override_ui("disable_end_turn", false) 
			scripting.HighlightComponent("button_end_turn", true, false)
		end	
	elseif conditions.IsComponentType("popup_battle_results", context) then	
		if COUNTER_Advice == 19 then
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			effect.advance_scripted_advice_thread("6020_TUT_War", 1)
			COUNTER_Advice = 20
			BOOL_Flash_Next_Button = false
			scripting.game_interface:override_ui("disable_end_turn", true) 
			scripting.game_interface:add_marker("Marker_Imabari", "campaign_map_marker01", -140, -115, 0, true)
			--scripting.game_interface:override_ui("disable_disband_unit", false)
			scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_kono", "war", true, true)
			scripting.game_interface:force_diplomacy("tut_kono", "tut_chosokabe", "war", true, true)
			scripting.game_interface:add_circle_area_trigger(-141.0, -116.6, 5, "Trigger_Area_Imabari", "faction:tut_chosokabe", true, false, true) 
		end	
	elseif conditions.IsComponentType("region_info", context) then
		BOOL_Region_Info_Opened = false	
		if ((COUNTER_Advice == 15 or COUNTER_Advice == 6015) and BOOL_Finance_Panel_Opened == false) then
			BOOL_Flash_Next_Button = false
			COUNTER_Advice = 6015
			scripting.game_interface:override_ui("disable_end_turn", false) 
			scripting.HighlightComponent("button_end_turn", true, false)
		end		
	elseif conditions.IsComponentType("settlement_captured", context) then 
		if COUNTER_Advice == 26 then
			effect.advance_scripted_advice_thread("6027_TUT_Fame_Honour", 1)
			COUNTER_Advice = 27
			BOOL_Flash_Next_Button = false			
			scripting.game_interface:override_ui("disable_clan_button", false)
			BOOL_Set_Clan_Active = true	
			scripting.HighlightComponent("button_clan", true, false)
			scripting.game_interface:force_declare_war("tut_sogo", "tut_chosokabe")
		elseif COUNTER_Advice == 57 or COUNTER_Advice == 58 or COUNTER_Advice == 59 then
			scripting.HighlightComponent("button_tech", false, false)
			scripting.game_interface:remove_custom_battlefield("TutorialBattles/TUT_Battle_Samurai.xml", false)
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6060_TUT_Diplomacy", 1)
			COUNTER_Advice = 60
			BOOL_Flash_Next_Button = false
			scripting.game_interface:add_time_trigger("Scouting_Coast_Camera", 0)	
		elseif COUNTER_Advice == 70 or COUNTER_Advice == 71 then
			if BOOL_Tokushima_Captured then
				scripting.game_interface:add_marker("Marker_Tokushima", "campaign_map_marker01", -95, -138, 0, false)
				scripting.game_interface:disable_saving_game(false)
				scripting.game_interface:autosave_at_next_opportunity()
				effect.advance_scripted_advice_thread("6072_TUT_Stables", 1)
				COUNTER_Advice = 72
				if BOOL_Character_Ranked_Up then
					BOOL_Flash_Next_Button = true
					scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
				else
					BOOL_Flash_Next_Button = false
				end
				scripting.game_interface:add_time_trigger("Mainland_Camera", 0)	
				scripting.game_interface:remove_barrier("TUT_Shroud_4")
				scripting.game_interface:unveil_black_shroud("TUT_Shroud_5")
				scripting.game_interface:add_marker("Marker_Osaka", "campaign_map_marker01", -61, -123, 0, true)	
				scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_matsuda", "alliance", true, true)
				scripting.game_interface:force_diplomacy("tut_matsuda", "tut_chosokabe", "alliance", true, true)
				scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_bessho", "war", true, true)
				scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_hatakeyama", "war", true, true)
				scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_kikkawa", "war", true, true)
				scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_matsuda", "war", true, true)
				scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_tsutsui", "war", true, true)
				scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_urakami", "war", true, true)
			end			
		end
	elseif conditions.IsComponentType("technology", context) then
		if COUNTER_Advice == 59 then
			if BOOL_Mission_Capture_Takamatsu_Given == false then
				BOOL_Mission_Capture_Takamatsu_Given = true
				MissionCaptureTakamatsu()
				scripting.HighlightComponent("button_end_turn", true, false)
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------- MISSIONS, MESSAGE & RESEARCH -----------------------
-------------------------------------------------------------------------------------
		
local function OnMissionSuccess(context)
	out.ting("Mission Success")
	if conditions.MissionName("tut_capture_takamatsu", context) then
		scripting.game_interface:remove_restricted_unit_record("Inf_Sword_Katana_Samurai")	
		scripting.game_interface:remove_restricted_unit_record("Cav_Spear_Light_Cavalry")
	elseif conditions.MissionName("tut_capture_tokushima", context) then
		BOOL_Tokushima_Captured = true	
		BOOL_Free_Play = true
		scripting.game_interface:add_circle_area_trigger(-61, -121, 4, "Trigger_Area_Osaka", "faction:tut_chosokabe,type:General", true, false, false) 
		scripting.game_interface:add_circle_area_trigger(-61, -121, 4, "Trigger_Area_Osaka", "faction:tut_chosokabe,type:colonel", true, false, false) 
		scripting.game_interface:add_circle_area_trigger(-61, -121, 5, "Trigger_Area_Osaka_Exit", "faction:tut_chosokabe,type:General", false, true, false) 
		scripting.game_interface:add_circle_area_trigger(-61, -121, 5, "Trigger_Area_Osaka_Exit", "faction:tut_chosokabe,type:colonel", false, true, false) 
		scripting.game_interface:remove_custom_battlefield("TutorialBattles/TUT_Battle_Shogun.xml", false)
		scripting.game_interface:set_event_generation_enabled(true)
		scripting.game_interface:override_ui("disable_character_information_panel", false)
		scripting.game_interface:set_character_experience_disabled(false)
		scripting.game_interface:set_character_skill_tier_limit(1)
		scripting.game_interface:allow_player_to_embark_navies(true)
	elseif conditions.MissionName("tut_capture_awaji", context) then
		out.ting("Awaji Mission Success")
		effect.advance_scripted_advice_thread("6086_TUT_Agents", 1)
		COUNTER_Advice = 86
		BOOL_Flash_Next_Button = true
		scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
		BOOL_Set_Newest_Advice_Active = true
	elseif conditions.MissionName("tut_capture_osaka", context) then
		scripting.game_interface:add_marker("Marker_Osaka", "campaign_map_marker01", -61, -123, 0, false)
	end
end

-------------------------------------------------------------------------------------	

local function OnResearchCompleted(context)
	out.ting("Research Complete")
	if COUNTER_First_Tech_Researched == 0 then
		COUNTER_First_Tech_Researched = 1
		BOOL_Research_Complete = true
	end
end

-------------------------------------------------------------------------------------
----------------------------------- RECRUITMENT -------------------------------------
-------------------------------------------------------------------------------------

local function OnUnitCreated(context)
	out.ting("Unit Created")
	if conditions.FactionName("tut_chosokabe", context) then
		out.ting("Chosokabe Unit Created")
		BOOL_Unit_Created = true
		if COUNTER_Advice == 24 or COUNTER_Advice == 40 or COUNTER_Advice == 41 or COUNTER_Advice == 42 or COUNTER_Advice == 43 or COUNTER_Advice == 44 or COUNTER_Advice == 45 or COUNTER_Advice == 46 or COUNTER_Advice == 47 or COUNTER_Advice == 6047 or COUNTER_Advice == 48 or COUNTER_Advice == 49 or COUNTER_Advice == 50 or COUNTER_Advice == 51 or COUNTER_Advice == 52 or COUNTER_Advice == 53 or COUNTER_Advice == 54 then
			scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-133.7,y:-139.1,r:1,type:colonel")
			scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-142.1,y:-118.1,r:1,type:colonel")
			scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-141.6,y:-115.2,r:1,type:colonel")
		end
	end 
end

-------------------------------------------------------------------------------------

local function OnRecruitmentItemIssuedByPlayer(context)
	if ((COUNTER_Advice > 39 and BOOL_Upkeep_Advice == false) and COUNTER_Advice ~= 53) then
		BOOL_Upkeep_Advice = true
		effect.advance_scripted_advice_thread("6081_TUT_Loyalty", 1)
		scripting.HighlightComponent("income_icon", true, false)
		scripting.game_interface:add_time_trigger("Stop_Highlighting_Income_Icon", 5)
	end
end

-------------------------------------------------------------------------------------
----------------------------------- CONSTRUCTION ------------------------------------
-------------------------------------------------------------------------------------

local function OnBuildingCompleted(context)
	if conditions.GarrisonIsLocal(context) then
		if conditions.CharacterBuildingConstructed("SHO_Archery_1_Archery_Dojo", context) then
			if COUNTER_Advice == 11 then
				BOOL_Archery_Dojo_Constructed = true	
			end
		elseif conditions.CharacterBuildingConstructed("SHO_Castle_2_Stronghold", context) then
			if COUNTER_Advice == 40 then
				scripting.game_interface:add_time_trigger("Stronghold_Upgrade_Camera", 0)
			end	
		end
	end
end

-------------------------------------------------------------------------------------
------------------------------ SELECTED OBJECTS -------------------------------------
-------------------------------------------------------------------------------------

local function OnSettlementSelected(context)
	out.ting("Settlement Selected")
	if conditions.SettlementName("settlement:jap_tut_tosa:kochi", context) then
		out.ting("Kochi Selected")
		BOOL_Kochi_Selected = true	
		BOOL_Imabari_Selected = false
		BOOL_Takamatsu_Selected = false
		BOOL_Tokushima_Selected = false
		CampaignUI.unhighlight_settlement("settlement:jap_tut_tosa:kochi")
		if (COUNTER_Advice == 6012 and BOOL_Game_Loaded)then
			scripting.HighlightComponent("text_button", true, true)	
		end
	elseif conditions.SettlementName("settlement:jap_tut_iyo:imabari", context) then
		out.ting("Imabari Selected")
		BOOL_Kochi_Selected = false
		BOOL_Imabari_Selected = true
		BOOL_Takamatsu_Selected = false
		BOOL_Tokushima_Selected = false
		if COUNTER_Advice == 41 then
			scripting.HighlightComponent("Slot2_Construction_Site", true, true)
		elseif COUNTER_Advice == 35 then
			scripting.game_interface:remove_restricted_building_level_record("SHO_Castle_2_Stronghold")
			scripting.game_interface:treasury_mod("tut_chosokabe", 1600)
			CampaignUI.unhighlight_settlement("settlement:jap_tut_iyo:imabari")
			scripting.HighlightComponent("SHO_Castle_1_Fort", true, true)
		end
	elseif conditions.SettlementName("settlement:jap_tut_sanuki:takamatsu", context) then
		BOOL_Kochi_Selected = false
		BOOL_Imabari_Selected = false
		BOOL_Takamatsu_Selected = true
		BOOL_Tokushima_Selected = false
	elseif conditions.SettlementName("settlement:jap_tut_awa:tokushima", context) then
		BOOL_Kochi_Selected = false
		BOOL_Imabari_Selected = false
		BOOL_Takamatsu_Selected = false
		BOOL_Tokushima_Selected = true
		if COUNTER_Advice == 74 then
			CampaignUI.unhighlight_settlement("settlement:jap_tut_awa:tokushima")
		end
	else
		BOOL_Kochi_Selected = false
		BOOL_Imabari_Selected = false
		BOOL_Takamatsu_Selected = false
		BOOL_Tokushima_Selected = false
	end
end

-------------------------------------------------------------------------------------

local function OnTownPortSelected(context)
	out.ting("Town/Port Selected")
	BOOL_Kochi_Selected = false
	BOOL_Imabari_Selected = false
	BOOL_Takamatsu_Selected = false
	BOOL_Tokushima_Selected = false
	if conditions.SlotName("port:jap_tut_iyo:matsuyama", context) then
		out.ting("Iyo Port selected");
		CampaignUI.unhighlight_settlement("port:jap_tut_iyo:matsuyama")
		if COUNTER_Advice == 50 then
			effect.advance_scripted_advice_thread("6051_TUT_Port", 1)
			COUNTER_Advice = 51
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("Land_Recruitment_Tab", true, true)	
		end
	end
	if conditions.SlotName("rice:jap_tut_iyo:farm", context) then
		out.ting("Iyo farm selected");
		CampaignUI.unhighlight_settlement("rice:jap_tut_iyo:farm")
		CampaignUI.unhighlight_settlement("rice:jap_tut_tosa:farm")
		if COUNTER_Advice == 38 then
			effect.advance_scripted_advice_thread("6039_TUT_Farms", 1)
			COUNTER_Advice = 39
			BOOL_Flash_Next_Button = false
			scripting.HighlightComponent("SHO_Farming_2_Irrigation", true, true)
			scripting.HighlightComponent("food_icon", true, false)
			scripting.game_interface:add_time_trigger("Stop_Highlighting_Food_Icon", 5)
		end
	elseif conditions.SlotName("rice:jap_tut_tosa:farm", context) then
		out.ting("Tosa farm selected");
		CampaignUI.unhighlight_settlement("rice:jap_tut_tosa:farm")
		CampaignUI.unhighlight_settlement("rice:jap_tut_iyo:farm")
		if COUNTER_Advice == 38 then
			effect.advance_scripted_advice_thread("6039_TUT_Farms", 1)
			COUNTER_Advice = 39
			BOOL_Flash_Next_Button = false
			scripting.game_interface:remove_restricted_building_level_record("SHO_Farming_2_Irrigation")
			scripting.HighlightComponent("SHO_Farming_2_Irrigation", true, true)
		end
	end
	if conditions.SlotName("town:jap_tut_tosa:region_specialty", context) then
		out.ting("Tosa Regional Building selected");
	end
end

-------------------------------------------------------------------------------------

local function OnCharacterSelected(context)
	out.ting("Character Selected")
	BOOL_Kochi_Selected = false
	BOOL_Imabari_Selected = false
	BOOL_Takamatsu_Selected = false
	BOOL_Tokushima_Selected = false
	if conditions.CharacterFactionName("tut_chosokabe", context) then
		if (BOOL_Free_Play and BOOL_Advice_6095 == false) then
			if BOOL_Minamiawaji_Captured then
				BOOL_Advice_6095 = true
				effect.advance_scripted_advice_thread("6095_TUT_Board_Ship", 1)
			end
		end
		if conditions.CharacterForename("names_name_names_chosokabeMotochika", context) then
			if COUNTER_Advice == 1 then
				effect.advance_scripted_advice_thread("6001b_TUT_Movement", 1)
				COUNTER_Advice = 6001
				BOOL_Flash_Next_Button = false
				scripting.game_interface:add_circle_area_trigger(-127, -139, 2, "Trigger_Area_Merge_Forces", "faction:tut_chosokabe", true, false, true) 
				CampaignUI.highlight_character("x:-127.3,y:-139.6,r:1.0,faction:tut_chosokabe")
			elseif COUNTER_Advice == 34 then
				if conditions.MapPosition(-278, -279, context) then
					CampaignUI.highlight_settlement("settlement:jap_tut_tosa:kochi")
				end
			end
		end
		if conditions.CharacterType("ninja", context) then
			if COUNTER_Advice == 43 then
				CampaignUI.unhighlight_character("x:-142.1,y:-118.1,r:1.0,faction:tut_chosokabe")
				scripting.game_interface:disable_saving_game(true)
				effect.advance_scripted_advice_thread("6044_TUT_Agents", 1)
				COUNTER_Advice = 44
				BOOL_Flash_Next_Button = false
				scripting.game_interface:add_circle_area_trigger(-121, -125, 12, "Trigger_Area_Reveal_Sogo_Army", "faction:tut_chosokabe,type:ninja", true, false, true)
				scripting.game_interface:add_circle_area_trigger(-121, -125, 5, "Trigger_Area_Ninja_Actions", "faction:tut_chosokabe,type:ninja", true, false, true)
				scripting.game_interface:add_circle_area_trigger(-108.5, -120.1, 3, "Trigger_Area_Remove_Takamatsu_Marker", "faction:tut_chosokabe,type:ninja", true, false, true)
				scripting.game_interface:add_marker("Marker_Takamatsu", "campaign_map_marker01", -108, -119, 0, true)
				scripting.game_interface:steal_user_input(true)
				CampaignUI.ToggleCinematicBorders(true)
				local	x, z, y, theatre = CampaignUI.CameraTarget()
				scripting.game_interface:scroll_camera(10,	{x, y, z},
															{-121.7, -123.0, 0.7})
				camera_pan = "Ninja_Target_Camera"
			end
		end
		if conditions.CharacterType("captain", context) then
			if COUNTER_Advice == 54 then
				CampaignUI.unhighlight_character("x:-151.9,y:-118.3,r:1.0,faction:tut_chosokabe")	
			elseif COUNTER_Advice == 55 then
				out.ting("Highlight Trade Post")
				CampaignUI.unhighlight_position(-167.0, -114.5)
				CampaignUI.highlight_position(-163.3, -110.9)
			elseif COUNTER_Advice == 65 then	
				CampaignUI.highlight_character("x:-116.1,y:-116.7,r:3.0,faction:tut_chosokabe")	
			end
		end
	end
end

-------------------------------------------------------------------------------------

local function OnCharacterComesOfAge(context)
	out.ting("Character Comes of Age")
	if conditions.CharacterFactionName("tut_chosokabe", context) then
		if BOOL_Character_Has_Come_Of_Age == false then
			effect.advance_scripted_advice_thread("6031_TUT_Generals", 1)
			BOOL_Character_Has_Come_Of_Age = true
		end
	end
end

-------------------------------------------------------------------------------------

local function OnCharacterRankUp(context)
	out.ting("Character Upgrade")
	if conditions.CharacterFactionName("tut_chosokabe", context) then
		out.ting("Chosokabe Character Upgrade")
		BOOL_Character_Ranked_Up = true
		if (BOOL_Free_Play and BOOL_Character_Ranked_Up_Info == false) then
			BOOL_Character_Ranked_Up_Info = true 
			effect.advance_scripted_advice_thread("6089_TUT_Agents", 1)
			BOOL_Flash_Next_Button = false
		end
	end
end

-------------------------------------------------------------------------------------

local function OnMovementPointsExhausted(context)
	if (COUNTER_Advice == 23 and BOOL_Advice_23 == false) then
		BOOL_Advice_23 = true
		scripting.game_interface:add_marker("Marker_Imabari", "campaign_map_marker01", -140, -115, 0, false)
		scripting.game_interface:override_ui("disable_end_turn", false)
		scripting.HighlightComponent("button_end_turn", true, false)
	end
	if COUNTER_Advice == 6001 or COUNTER_Advice == 2 then
		if BOOL_Chosokabe_Armies_Merged == false then
			effect.advance_scripted_advice_thread("6007_TUT_Seasons", 1)
			scripting.game_interface:override_ui("disable_end_turn", false)
			scripting.HighlightComponent("button_end_turn", true, false)
		else
			if BOOL_AP_Replenished == false then
				scripting.game_interface:replenish_action_points("faction:tut_chosokabe,x:-127.3,y:-139.6,r:2")
				BOOL_AP_Replenished = true
			else
				effect.advance_scripted_advice_thread("6007_TUT_Seasons", 1)
				scripting.game_interface:override_ui("disable_end_turn", false)
				scripting.HighlightComponent("button_end_turn", true, false)
			end
		end	
	end
	if COUNTER_Advice == 20 or COUNTER_Advice == 21 or COUNTER_Advice == 34 or COUNTER_Advice == 55 then
		scripting.game_interface:override_ui("disable_end_turn", false) 
		scripting.HighlightComponent("button_end_turn", true, false)
	end
end

-------------------------------------------------------------------------------------

local function OnMultiTurnMove(context)
	if COUNTER_Advice == 21 then
		effect.advance_scripted_advice_thread("6023_TUT_Multi_Move", 1)
		COUNTER_Advice = 23
		BOOL_Flash_Next_Button = false
	end
end

-------------------------------------------------------------------------------------

local function OnCampaignArmiesMerge(context)
	out.ting("Armies Merged")
	if conditions.CharacterFactionName("tut_chosokabe", context) then
		out.ting("Chosokabe Armies Merged")
		BOOL_Chosokabe_Armies_Merged = true
		if conditions.ForcesComposedOf("Light_Ship_Bow_Kobaya;Medium_Ship_Medium_Bune;Heavy_Ship_Heavy_Bune", context) then
			out.ting("Correct Chosokabe Fleet Merged")
			if (COUNTER_Advice == 65 and BOOL_Fleets_Merged == false) then
				BOOL_Fleets_Merged = true
				scripting.game_interface:add_custom_battlefield(-115.8, -113.4, 7, "TutorialBattles/TUT_Naval_Ashigaru.xml")
				scripting.HighlightComponent("button_end_turn", true, false)
			end
		end
		if conditions.ForcesComposedOf("Light_Ship_Bow_Kobaya;Trade_Ship_Trade_Ship", context) then
			out.ting("Unhighlight Ship")
			CampaignUI.unhighlight_position(-167.0, -114.5)
			scripting.game_interface:replenish_action_points("faction:tut_chosokabe,x:-159.7,y:-109.1,r:2")
		end	
	end
end

-------------------------------------------------------------------------------------

local function OnEmbarkShip(context)
	if conditions.CharacterFactionName("tut_chosokabe", context) then
		if BOOL_Free_Play then
			if BOOL_6073 == false then
				BOOL_6073 = true
				effect.advance_scripted_advice_thread("6073_TUT_Naval_Invasion", 1)
				COUNTER_Advice = 73
				BOOL_Flash_Next_Button = true
				scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
				BOOL_Set_Newest_Advice_Active = true
			end
		end
	end
end

-------------------------------------------------------------------------------------

local function OnComponentMouseOn(context)
	out.shane("Component mouse on: " .. context.string..", COUNTER_Advice = "..tostring(COUNTER_Advice))
	if scripting.IsOnCampaignMap() then
		if conditions.IsComponentType("Slot1_Construction_Site", context) then	
			if COUNTER_Advice == 9 then
				scripting.HighlightComponent("Slot1_Construction_Site", false, false)
				scripting.HighlightComponent("SHO_Archery_1_Archery_Dojo", true, true)	
				COUNTER_Advice = 10
			end
		elseif conditions.IsComponentType("SHO_Castle_1_Fort", context) then	
			if (COUNTER_Advice == 35 and BOOL_Imabari_Selected) then
				scripting.HighlightComponent("SHO_Castle_1_Fort", false, false)
				scripting.HighlightComponent("SHO_Castle_2_Stronghold", true, true)
			end
		elseif conditions.IsComponentType("Slot2_Construction_Site", context) then	
			if (BOOL_Imabari_Selected and COUNTER_Advice == 41) then
				scripting.HighlightComponent("Slot2_Construction_Site", false, false)
				scripting.HighlightComponent("SHO_Yari_1_Drill_Yard", true, true)
				scripting.HighlightComponent("SHO_Archery_1_Archery_Dojo", true, true)
			end
		end
	end
end

-------------------------------------------------------------------------------------

local function OnComponentMoved(context)
	if conditions.IsComponentType("handle", context) and COUNTER_Advice == 14 and slider_tax_level <= 30 then
		scripting.HighlightComponent("slider", false, false, "tx_classes_lower")	
		scripting.game_interface:override_ui("disable_tax_slider", true) 
		scripting.game_interface:disable_saving_game(true)
		effect.advance_scripted_advice_thread("6015_TUT_Finance", 1)
		COUNTER_Advice = 15
		BOOL_Flash_Next_Button = true
		scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
		BOOL_Set_Newest_Advice_Active = true
		scripting.HighlightComponent("income_icon", true, false)
	end
end

-------------------------------------------------------------------------------------

local function OnComponentLClickUp(context)
	out.ting("Component clicked " .. context.string)
	if scripting.IsOnCampaignMap() then
		if conditions.IsComponentType("button_next", context) or conditions.IsComponentType("button_previous", context) then
			BOOL_Advice_Arrows_Clicked = true
		else
			BOOL_Advice_Arrows_Clicked = false
		end
		if conditions.IsComponentType("action_button_single_128", context) then
			scripting.HighlightComponent("action_button_single_128", false, false)
		elseif conditions.IsComponentType("action_button_single_1048576", context) then --Sabotage Castle Gates
			if COUNTER_Advice == 6047 then
				BOOL_Gates_Opened = true
				scripting.HighlightComponent("action_button_single_1048576", false, false)
			end
		elseif conditions.IsComponentType("action_button_single_1024", context) then -- Bribe Army Button
			if COUNTER_Advice == 79 then
				BOOL_Metsuke_Bribed_Army = true
			end
		elseif conditions.IsComponentType("button_accept", context) then	
			if (BOOL_Agreement_Made and BOOL_First_Agreement == false) then
				BOOL_First_Agreement = true
				scripting.HighlightComponent("button_cancel", true, true)
			elseif BOOL_First_Agreement == false then
				out.ting("TEST BUTTON ACCEPT")
				scripting.HighlightComponent("diplomacy_button_trade", true, true)
			end
		elseif conditions.IsComponentType("button_autoresolve", context) then	
			scripting.HighlightComponent("button_autoresolve", false, false, "button_set_attack")
			scripting.HighlightComponent("button_attack", false, false, "button_set_attack")
			scripting.HighlightComponent("button_autoresolve", false, false, "button_set_siege")
			scripting.HighlightComponent("button_attack", false, false, "button_set_siege")
		elseif conditions.IsComponentType("button_attack", context) then	
			scripting.HighlightComponent("button_autoresolve", false, false, "button_set_attack")
			scripting.HighlightComponent("button_attack", false, false, "button_set_attack")
			scripting.HighlightComponent("button_autoresolve", false, false, "button_set_siege")
			scripting.HighlightComponent("button_attack", false, false, "button_set_siege")
		elseif conditions.IsComponentType("button_cancel", context) then
			scripting.HighlightComponent("button_cancel", false, false)
			scripting.HighlightComponent("button_cancel", false, false, "diplomatic_relations")
			if (COUNTER_Advice == 6063 and BOOL_Agreement_Made) then
				scripting.HighlightComponent("button_cancel", true, true, "diplomatic_relations")
			elseif COUNTER_Advice == 18 or COUNTER_Advice == 65 then
				scripting.HighlightComponent("button_autoresolve", true, true, "button_set_attack")
				scripting.HighlightComponent("button_attack", true, false, "button_set_attack")
			elseif CampaignUI.IsPreBattleTypeSiege() then
				if COUNTER_Advice == 25 or COUNTER_Advice == 56 or COUNTER_Advice == 57 or COUNTER_Advice == 58 or COUNTER_Advice == 59 or COUNTER_Advice == 70 or COUNTER_Advice == 71 then
					scripting.HighlightComponent("button_autoresolve", true, true, "button_set_siege")
					scripting.HighlightComponent("button_attack", true, false, "button_set_siege")
				end
			end
		elseif conditions.IsComponentType("button_clan", context) then
			scripting.HighlightComponent("button_clan", false, false)
		elseif conditions.IsComponentType("button_close", context) then	
			scripting.HighlightComponent("button_close", false, false)	
			scripting.HighlightComponent("button_close", false, false, "popup_battle_results")
		elseif conditions.IsComponentType("button_close_captured", context) then
			scripting.HighlightComponent("button_close_captured", false, false, "popup_battle_results")	
		elseif conditions.IsComponentType("button_close_noscript", context) then
			scripting.HighlightComponent("button_close_noscript", false, false)
			if COUNTER_Advice == 6015 then
				scripting.HighlightComponent("finance_screen_button_close", true, true)	
			end
		elseif conditions.IsComponentType("button_counteroffer", context) then	
			scripting.HighlightComponent("button_send", true, true)
		elseif conditions.IsComponentType("build_demolish", context) then
			scripting.HighlightComponent("build_demolish", false, false)
		elseif conditions.IsComponentType("button_diplomacy", context) then
			scripting.HighlightComponent("button_diplomacy", false, false)
		elseif conditions.IsComponentType("button_end_turn", context) then
			scripting.HighlightComponent("button_end_turn", false, false)
			if COUNTER_Advice == 44 or COUNTER_Advice == 59 then
				scripting.game_interface:disable_saving_game(false)
				scripting.game_interface:autosave_at_next_opportunity()
			end
		elseif conditions.IsComponentType("button_enter_negotions", context) then	
			scripting.HighlightComponent("button_enter_negotions", false)
			if	COUNTER_Advice == 62 then
				effect.advance_scripted_advice_thread("6063_TUT_Trade_Route", 1)
				COUNTER_Advice = 63
				BOOL_Flash_Next_Button = false
				out.ting("TEST BUTTON ENTER DIPLOMACY")
				scripting.HighlightComponent("diplomacy_button_trade", true, true)
			end
			if BOOL_Agreement_Made then
				scripting.HighlightComponent("diplomacy_button_trade", false)
			end
		elseif conditions.IsComponentType("button_finance", context) then
			scripting.HighlightComponent("button_taxes", false)
			scripting.HighlightComponent("button_finance", false)
			scripting.HighlightComponent("Public order panel layout", false)
		elseif conditions.IsComponentType("button_taxes", context) then
			scripting.HighlightComponent("button_taxes", false)
			scripting.HighlightComponent("button_finance", false)
			scripting.HighlightComponent("Public order panel layout", false)
		elseif conditions.IsComponentType("button_hire_ninja", context) then	
			scripting.HighlightComponent("button_hire_ninja", false, false)	
		elseif conditions.IsComponentType("button_hire_metsuke", context) then
			scripting.HighlightComponent("button_hire_metsuke", false, false)
			if BOOL_Free_Play then
				if BOOL_6076 == false then
					BOOL_6076 = true
					effect.advance_scripted_advice_thread("6076_TUT_Agents", 1)
					COUNTER_Advice = 76
					BOOL_Flash_Next_Button = true
					scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
					BOOL_Set_Newest_Advice_Active = true
				end
			end
		elseif conditions.IsComponentType("button_messages", context) then
			scripting.HighlightComponent("button_messages", false, false)
		elseif conditions.IsComponentType("button_menu", context) then
			if BOOL_Commissions_Highlighted then
				scripting.HighlightComponent("button_warfare", false, "commissions")
				scripting.HighlightComponent("button_supplies", false, "commissions")
				scripting.HighlightComponent("button_finance_post", false, "commissions")
				scripting.HighlightComponent("button_development", false, "commissions")
				scripting.HighlightComponent("Chikayasu", true, true)
				scripting.HighlightComponent("Chosokabe Chikayasu", true, true)
				BOOL_Commissions_Highlighted = false
				BOOL_Commission_Selected = true
			end
		elseif conditions.IsComponentType("button_newest", context) then
			Check_Advice()
			scripting.HighlightComponent("button_newest", false, false)
			scripting.EnableFeature("Set_Button_Newest_Advice_Inactive")
			BOOL_Set_Newest_Advice_Active = false
		elseif conditions.IsComponentType("button_ok", context) then	
			scripting.HighlightComponent("button_ok", false, false)
			scripting.HighlightComponent("button_ok", false, false, "OK_zoom")
		elseif conditions.IsComponentType("button_ok_declare", context) then
			scripting.HighlightComponent("button_ok_declare", false, false)
			if COUNTER_Advice == 22 then
				scripting.HighlightComponent("button_ok", true, true)
			end
		elseif conditions.IsComponentType("button_previous", context) then
			scripting.HighlightComponent("button_previous", false, false)
		elseif conditions.IsComponentType("build_repair", context) then
			scripting.HighlightComponent("build_repair", false, false)
			if COUNTER_Advice == 36 then
				effect.advance_scripted_advice_thread("6037_TUT_Castle", 1)
				COUNTER_Advice = 37
				BOOL_Flash_Next_Button = true	
				scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
				BOOL_Set_Newest_Advice_Active = true
			end
		elseif conditions.IsComponentType("button_send", context) then
			scripting.HighlightComponent("button_send", false, false)
		elseif conditions.IsComponentType("button_supplies", context) or conditions.IsComponentType("button_warfare", context) or conditions.IsComponentType("button_finance_post", context) or conditions.IsComponentType("button_development", context) then
			scripting.HighlightComponent("button_warfare", false, false, "commissions")
			scripting.HighlightComponent("button_supplies", false, false, "commissions")
			scripting.HighlightComponent("button_finance_post", false, false, "commissions")
			scripting.HighlightComponent("button_development", false, false, "commissions")
			BOOL_Commissions_Highlighted = false
			BOOL_Commission_Selected = true
		elseif conditions.IsComponentType("button_tech", context) then
			scripting.HighlightComponent("button_tech", false, false)
		elseif conditions.IsComponentType("button_tick", context) then	
			scripting.HighlightComponent("button_tick", false, false)
		elseif conditions.IsComponentType("cancel_payments", context) then
			scripting.HighlightComponent("diplomacy_button_payments", true, true)
		elseif conditions.IsComponentType("Chikayasu", context) or conditions.IsComponentType("Chosokabe Chikayasu", context) then	
			out.ting("Chosokabe Chikayasu Selected")
			scripting.HighlightComponent("Chikayasu", false, false)
			scripting.HighlightComponent("Chosokabe Chikayasu", false, false)
			if (COUNTER_Advice == 33 and BOOL_Commission_Selected == false) then
				BOOL_Commissions_Highlighted = true
				scripting.HighlightComponent("button_warfare", true, false, "commissions")
				scripting.HighlightComponent("button_supplies", true, false, "commissions")
				scripting.HighlightComponent("button_finance_post", true, false, "commissions")
				scripting.HighlightComponent("button_development", true, false, "commissions")
			end
		elseif conditions.IsComponentType("diplomacy_button_payments", context) then
			scripting.HighlightComponent("diplomacy_button_payments", false, false)
		elseif conditions.IsComponentType("diplomacy_button_trade", context) then
			scripting.HighlightComponent("diplomacy_button_trade", false, false)
			if COUNTER_Advice == 63 then
				effect.advance_scripted_advice_thread("6063b_TUT_Trade_Route", 1)
				COUNTER_Advice = 6063
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("diplomacy_button_payments", true, true)
			elseif COUNTER_Advice == 6063 then
				scripting.HighlightComponent("diplomacy_button_payments", true, true)
			end
		elseif conditions.IsComponentType("factions", context) then
			scripting.HighlightComponent("factions", false, false)
			if COUNTER_Advice == 17 then
				effect.advance_scripted_advice_thread("6034_TUT_Generals", 1)
				COUNTER_Advice = 34
				BOOL_Flash_Next_Button = false
				if CampaignUI.CurrentTabTypename() ~= "Land_Recruitment_Tab" then
					scripting.HighlightComponent("Land_Recruitment_Tab", true, true)
				else
					if BOOL_Advice_6034 == false then
						scripting.HighlightComponent("Inf_Missile_Bow_Samurai_Chosokabe_recruitable", true, true)
					end	
				end
			end
		elseif conditions.IsComponentType("faction_Matsuda", context) then
			scripting.HighlightComponent("faction_Matsuda", false, false)
			if COUNTER_Advice == 62 then
				scripting.HighlightComponent("button_enter_negotions", true, true)
			end
		elseif conditions.IsComponentType("Family", context) then
			scripting.HighlightComponent("Family", false, false)
			if COUNTER_Advice == 32 then
				effect.advance_scripted_advice_thread("6033_TUT_Generals", 1)
				COUNTER_Advice = 33
				BOOL_Flash_Next_Button = false	
				scripting.HighlightComponent("Chikayasu", true, true)
				scripting.HighlightComponent("Chosokabe Chikayasu", true, true)
			end
		elseif conditions.IsComponentType("finance_screen_button_close", context) then
			scripting.HighlightComponent("finance_screen_button_close", false, false)
		elseif conditions.IsComponentType("Garrison_Tab", context) then	
			scripting.HighlightComponent("Garrison_Tab", false, false)	
			if COUNTER_Advice == 8 then
				scripting.game_interface:disable_saving_game(true)
				effect.advance_scripted_advice_thread("6009_TUT_Construction", 1)
				COUNTER_Advice = 9
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("Region_Construction_Tab", true, true)
			end
		elseif conditions.IsComponentType("Land_Recruitment_Tab", context) then	
			scripting.HighlightComponent("Land_Recruitment_Tab", false, false)	
			if COUNTER_Advice == 4 then
				scripting.game_interface:remove_restricted_unit_record("Inf_Spear_Yari_Ashigaru")
				scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Bow_Ashigaru_Chosokabe")		
				effect.advance_scripted_advice_thread("6005_TUT_Recruitment", 1)
				COUNTER_Advice = 5
				BOOL_Flash_Next_Button = false 
				scripting.HighlightComponent("Inf_Spear_Yari_Ashigaru_recruitable", true, true)
			elseif COUNTER_Advice == 34 then
				if BOOL_Advice_6034 == false then
					scripting.HighlightComponent("Inf_Missile_Bow_Samurai_Chosokabe_recruitable", true, true)
				end
			elseif COUNTER_Advice == 29 then
				scripting.game_interface:disable_saving_game(true)
				scripting.HighlightComponent("Inf_Missile_Bow_Samurai_Chosokabe_recruitable", true, true)
			elseif COUNTER_Advice == 42 then
				scripting.game_interface:treasury_mod("tut_chosokabe", 500)
				scripting.HighlightComponent("button_hire_ninja", true, true)	
			elseif COUNTER_Advice == 51 then	
				scripting.game_interface:treasury_mod("tut_chosokabe", 150)
				effect.advance_scripted_advice_thread("6052_TUT_Port", 1)
				COUNTER_Advice = 52
				BOOL_Flash_Next_Button = false 
				scripting.HighlightComponent("Light_Ship_Bow_Kobaya_recruitable", true, true)
			elseif COUNTER_Advice == 70 then
				if BOOL_Takamatsu_Selected then
					scripting.game_interface:disable_saving_game(true)
					effect.advance_scripted_advice_thread("6071_TUT_Stables", 1)
					COUNTER_Advice = 71
					BOOL_Flash_Next_Button = false
				end
			elseif BOOL_Free_Play then
				if BOOL_Tokushima_Selected then
					if BOOL_6075 == false then
						BOOL_6075 = true
						effect.advance_scripted_advice_thread("6075_TUT_Agents", 1)
						COUNTER_Advice = 75
						BOOL_Flash_Next_Button = false
					end
				end
			end	
		elseif conditions.IsComponentType("loot_text_button", context) then
			if COUNTER_Advice == 26 then
				scripting.game_interface:instant_set_building_health_percent("jap_tut_iyo", "SHO_Castle_1_Fort", 100)
			end
		elseif conditions.IsComponentType("map", context) then
			scripting.HighlightComponent("map", false, false)
		elseif conditions.IsComponentType("occupy_text_button", context) then
			scripting.HighlightComponent("occupy_text_button", false, false)
			if COUNTER_Advice == 26 then
				scripting.game_interface:instant_set_building_health_percent("jap_tut_iyo", "SHO_Castle_1_Fort", 100)
				scripting.game_interface:instant_set_building_health_percent("jap_tut_iyo", "SHO_Stealth_1_Sake_Den", 75)
			end
		elseif conditions.IsComponentType("options_bar1", context) then		
			scripting.HighlightComponent("options_bar1", false, false)
		elseif conditions.IsComponentType("options_bar2", context) then		
			scripting.HighlightComponent("options_bar2", false, false)
		elseif conditions.IsComponentType("options_bar3", context) then		
			scripting.HighlightComponent("options_bar3", false, false)
		elseif conditions.IsComponentType("projected_income", context) then	
			scripting.HighlightComponent("projected_income", false, false)
		elseif conditions.IsComponentType("Inf_Spear_Yari_Ashigaru_recruitable", context) then	
			scripting.HighlightComponent("Inf_Spear_Yari_Ashigaru_recruitable", false, false)
			if COUNTER_Advice == 5 then
				effect.advance_scripted_advice_thread("6006_TUT_Recruitment", 1)
				COUNTER_Advice = 6
				BOOL_Flash_Next_Button = true
				scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
				BOOL_Set_Newest_Advice_Active = true
				scripting.HighlightComponent("treasury_icon", true, false)
			end
		elseif conditions.IsComponentType("Light_Ship_Bow_Kobaya_recruitable", context) then	
			scripting.HighlightComponent("Light_Ship_Bow_Kobaya_recruitable", false, false)
			if COUNTER_Advice == 52 then
				effect.advance_scripted_advice_thread("6053_TUT_Port", 1)
				COUNTER_Advice = 53
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("button_end_turn", true, false)
			end
		elseif conditions.IsComponentType("Inf_Missile_Bow_Samurai_Chosokabe_recruitable", context) then
			scripting.HighlightComponent("Inf_Missile_Bow_Samurai_Chosokabe_recruitable", false, false)
			if COUNTER_Advice == 29 then
				scripting.game_interface:override_ui("disable_end_turn", false) 
				scripting.HighlightComponent("button_end_turn", true, false)
			end
			if COUNTER_Advice == 34 then
				if BOOL_Advice_6034 == false then
					scripting.game_interface:override_ui("disable_end_turn", false) 
					scripting.HighlightComponent("button_end_turn", true, false)
					BOOL_Advice_6034 = true
				end
			end
		elseif conditions.IsComponentType("ok_payments", context) then
			if COUNTER_Advice == 6063 then
				scripting.HighlightComponent("button_send", true, true)
			end	
		elseif conditions.IsComponentType("Region_Construction_Tab", context) then	
			scripting.HighlightComponent("Region_Construction_Tab", false, false)	
			out.ting("left clicked: " .. COUNTER_Advice)
			if COUNTER_Advice == 9 then
				effect.advance_scripted_advice_thread("6010_TUT_Construction", 1)
				BOOL_Flash_Next_Button = false
				scripting.game_interface:remove_restricted_building_level_record("SHO_Archery_1_Archery_Dojo")
				scripting.HighlightComponent("Slot1_Construction_Site", true, true)
			end
		elseif conditions.IsComponentType("SHO_Archery_1_Archery_Dojo", context) then	
			if COUNTER_Advice == 10 then
				scripting.HighlightComponent("SHO_Archery_1_Archery_Dojo", false, false)	
				effect.advance_scripted_advice_thread("6011_TUT_Construction", 1)
				COUNTER_Advice = 11
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("button_end_turn", true, false)
			elseif COUNTER_Advice == 41 then
				scripting.HighlightComponent("SHO_Yari_1_Drill_Yard", false, false)
				scripting.HighlightComponent("SHO_Archery_1_Archery_Dojo", false, false)
				scripting.game_interface:disable_saving_game(true)
				effect.advance_scripted_advice_thread("6042_TUT_Agents", 1)
				COUNTER_Advice = 42
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("Land_Recruitment_Tab", true, true)
				scripting.game_interface:treasury_mod("tut_chosokabe", 850)
				scripting.game_interface:override_ui("disable_enlist_ninja", false)
			end
		elseif conditions.IsComponentType("SHO_Yari_1_Drill_Yard", context) then
			if COUNTER_Advice == 41 then
				scripting.HighlightComponent("SHO_Yari_1_Drill_Yard", false, false)
				scripting.HighlightComponent("SHO_Archery_1_Archery_Dojo", false, false)
				scripting.game_interface:disable_saving_game(true)
				effect.advance_scripted_advice_thread("6042_TUT_Agents", 1)
				COUNTER_Advice = 42
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("Land_Recruitment_Tab", true, true)
				scripting.game_interface:override_ui("disable_enlist_ninja", false)
			end
		elseif conditions.IsComponentType("SHO_Castle_2_Stronghold", context) then	
			if COUNTER_Advice == 35 then
				scripting.HighlightComponent("SHO_Castle_2_Stronghold", false, false)	
				effect.advance_scripted_advice_thread("6036_TUT_Castle", 1)
				COUNTER_Advice = 36
				BOOL_Flash_Next_Button = false
				scripting.game_interface:treasury_mod("tut_chosokabe", 250)
				scripting.HighlightComponent("SHO_Stealth_1_Sake_Den", true, true)
				scripting.game_interface:override_ui("disable_repair_building", false)
				scripting.game_interface:override_ui("disable_cancel_construction", true)
			end
		elseif conditions.IsComponentType("SHO_Farming_2_Irrigation", context) then
			if COUNTER_Advice == 38 or COUNTER_Advice == 39 then
				if COUNTER_Advice == 38 then
					effect.advance_scripted_advice_thread("6039_TUT_Farms", 1)
					BOOL_Flash_Next_Button = false
				end
				COUNTER_Advice = 39
				CampaignUI.unhighlight_settlement("rice:jap_tut_tosa:farm")
				CampaignUI.unhighlight_settlement("rice:jap_tut_iyo:farm")
				scripting.HighlightComponent("SHO_Farming_2_Irrigation", false, false)	
				scripting.game_interface:remove_restricted_building_level_record("SHO_Infrastructure_1_Roads")
				scripting.game_interface:override_ui("disable_end_turn", false)
				scripting.HighlightComponent("button_end_turn", true, false)
			end
		elseif conditions.IsComponentType("SHO_Stealth_1_Sake_Den", context) then
			if COUNTER_Advice == 36 then
				scripting.HighlightComponent("SHO_Stealth_1_Sake_Den", false, false)	
				scripting.HighlightComponent("build_repair", true, false)
			end
		elseif conditions.IsComponentType("slider", context) then	
			scripting.HighlightComponent("slider", false, false, "tx_classes_lower")
		elseif conditions.IsComponentType("tech_card_1", context) then
			scripting.HighlightComponent("tech_card_1", false, false)
			if COUNTER_Advice == 58 then
				scripting.game_interface:disable_saving_game(false)
				scripting.game_interface:autosave_at_next_opportunity()
				effect.advance_scripted_advice_thread("6059_TUT_Technology", 1)
				COUNTER_Advice = 59
				BOOL_Flash_Next_Button = false
				scripting.HighlightComponent("button_tick", true, true)
			end
		end
	end
end
		
-------------------------------------------------------------------------------------

function Check_Advice()
	if COUNTER_Advice == 3 then
		effect.advance_scripted_advice_thread("6003b_TUT_Camera", 1)
		COUNTER_Advice = 6003
		BOOL_Flash_Next_Button = true	
		scripting.game_interface:add_time_trigger("Make_Advice_Button_Active", 0)	
	elseif COUNTER_Advice == 6003 then
		effect.advance_scripted_advice_thread("6004_TUT_Recruitment", 1)
		COUNTER_Advice = 4
		BOOL_Flash_Next_Button = false
		scripting.game_interface:remove_restricted_unit_record("Inf_Spear_Yari_Ashigaru")
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Bow_Ashigaru_Chosokabe")	
		CampaignUI.highlight_settlement("settlement:jap_tut_tosa:kochi")
		if CampaignUI.CurrentTabTypename() ~= "Land_Recruitment_Tab" then
			scripting.HighlightComponent("Land_Recruitment_Tab", true, true)
		else
			effect.advance_scripted_advice_thread("6005_TUT_Recruitment", 1)
			COUNTER_Advice = 5
			BOOL_Flash_Next_Button = false 
			scripting.HighlightComponent("Inf_Spear_Yari_Ashigaru_recruitable", true, true)
		end	
	elseif COUNTER_Advice == 6 then
		scripting.HighlightComponent("treasury_icon", false, false)
		effect.advance_scripted_advice_thread("6007_TUT_Seasons", 1)
		COUNTER_Advice = 7
		BOOL_Flash_Next_Button = false
		scripting.game_interface:override_ui("disable_end_turn", false)
		scripting.HighlightComponent("button_end_turn", true, false)
	elseif COUNTER_Advice == 15 then
		scripting.game_interface:disable_saving_game(true)
		effect.advance_scripted_advice_thread("6015b_TUT_Finance", 1)
		COUNTER_Advice = 6015
		BOOL_Flash_Next_Button = false
		scripting.HighlightComponent("income_icon", false)
		scripting.HighlightComponent("button_close_noscript", true, true)	
	elseif COUNTER_Advice == 16 then
		scripting.game_interface:disable_saving_game(true)
		effect.advance_scripted_advice_thread("6017_TUT_Armies", 1)
		COUNTER_Advice = 17
		BOOL_Flash_Next_Button = false
		scripting.HighlightComponent("income_icon", false, false)
		scripting.InitFeature("Set_Factions_Tab_Inactive")
		scripting.HighlightComponent("factions", true, true)
		BOOL_Set_Factions_Tab_Active = true
	elseif COUNTER_Advice == 37 then
		scripting.game_interface:treasury_mod("tut_chosokabe", 950)
		effect.advance_scripted_advice_thread("6038_TUT_Castle", 1)
		COUNTER_Advice = 38
		BOOL_Flash_Next_Button = false
		CampaignUI.highlight_settlement("rice:jap_tut_tosa:farm")
		CampaignUI.highlight_settlement("rice:jap_tut_iyo:farm")
		scripting.game_interface:steal_user_input(true)
		CampaignUI.ToggleCinematicBorders(true)
		local	x, z, y, theatre = CampaignUI.CameraTarget()
		scripting.game_interface:scroll_camera(10,	{x, y, z},
													{-147.6, -135.3, 0.85})
		camera_pan = "Rice_Paddie_Camera"
	elseif COUNTER_Advice == 72 then
		BOOL_Character_Ranked_Up_Info = true 
		effect.advance_scripted_advice_thread("6089_TUT_Agents", 1)
		BOOL_Flash_Next_Button = false
	elseif COUNTER_Advice == 73 then
		effect.advance_scripted_advice_thread("6074_TUT_Naval_Invasion", 1)
		COUNTER_Advice = 74
		BOOL_Flash_Next_Button = false
	elseif COUNTER_Advice == 76 then
		effect.advance_scripted_advice_thread("6077_TUT_Agents", 1)
		COUNTER_Advice = 77
		BOOL_Flash_Next_Button = false
	elseif COUNTER_Advice == 78 then
		effect.advance_scripted_advice_thread("6079_TUT_Alliance", 1)
		COUNTER_Advice = 79
		BOOL_Flash_Next_Button = true
		scripting.game_interface:add_time_trigger("Enable_Button_Newest", 0)
	elseif COUNTER_Advice == 79 then
		effect.advance_scripted_advice_thread("6080_TUT_Loyalty", 1)
		COUNTER_Advice = 80
		BOOL_Flash_Next_Button = false
	elseif COUNTER_Advice == 86 then
		effect.advance_scripted_advice_thread("6087_TUT_Agents", 1)
		COUNTER_Advice = 87
		BOOL_Flash_Next_Button = false
	end
end	

-------------------------------------------------------------------------------------
------------------------------------- TAX & TRADE -----------------------------------
-------------------------------------------------------------------------------------

local function OnGovernorshipTaxChange(context)
	out.ting("Tax Changed")
	slider_tax_level = conditions.GovernorshipsTaxLevel(context)
end

-------------------------------------------------------------------------------------

local function OnTradeRouteEstablished(context)
	if conditions.FactionName("tut_chosokabe", context) then
		out.ting("TRADE ROUTE ESTABLISHED")
		BOOL_Agreement_Made = true
	end
end

-------------------------------------------------------------------------------------

local function OnTradeNodeConnected(context)
	out.ting("Trade Node Connected")
	BOOL_Trade_Node_Connected = true
end

-------------------------------------------------------------------------------------

local function OnSeaTradeRouteRaided(context)
	out.ting("Trade Route Raided")
	if conditions.CharacterIsLocalCampaign(context) then
		if BOOL_Trade_Route_Raided == false then
			BOOL_Trade_Route_Raided = true
			out.ting("Chosokabe Raiding Trade Route")
			BOOL_Enemy_Trade_Route_Raided = true
			scripting.game_interface:add_marker("Marker_Miyoshi_Trade_Route", "campaign_map_marker01", -103.3, -115.9, 0, false)
			scripting.HighlightComponent("button_end_turn", true, false)
			scripting.game_interface:force_diplomacy("tut_miyoshi", "tut_urakami", "war", true, true)
			scripting.game_interface:force_diplomacy("tut_urakami", "tut_miyoshi", "war", true, true)
		end
	end
end

-------------------------------------------------------------------------------------

local function OnBankruptcy(context)
	effect.advance_scripted_advice_thread("6082_TUT_Loyalty", 1)
end

-------------------------------------------------------------------------------------
--------------------------------- TIMERS & CAMERAS ----------------------------------
-------------------------------------------------------------------------------------

local function OnTimeTrigger(context)
	out.ting("Timer Finished")
	if context.string == "Stronghold_Upgrade_Camera" then
		scripting.game_interface:disable_saving_game(false)
		scripting.game_interface:autosave_at_next_opportunity()
		effect.advance_scripted_advice_thread("6041_TUT_Building_Chains", 1)
		COUNTER_Advice = 41
		BOOL_Flash_Next_Button = false
		scripting.game_interface:steal_user_input(true)
		CampaignUI.ToggleCinematicBorders(true)
		local	x, z, y, theatre = CampaignUI.CameraTarget()
		scripting.game_interface:scroll_camera(5,	{x, y, z},
													{-140.3, -118.5, 1.1})
		camera_pan = "Stronghold_Upgrade_Camera"
		scripting.game_interface:treasury_mod("tut_chosokabe", 850)
		CampaignUI.highlight_settlement("settlement:jap_tut_iyo:imabari")
		scripting.game_interface:override_ui("disable_cancel_construction", false)
		scripting.game_interface:remove_restricted_building_level_record("SHO_Sword_1_Sword_School")
		scripting.game_interface:remove_restricted_building_level_record("SHO_Yari_1_Drill_Yard")
	elseif context.string == "Resource_Sanuki_Camera" then
		scripting.game_interface:force_agent_action_success_for_human(false)
		effect.advance_scripted_advice_thread("6048_TUT_Resources", 1)
		COUNTER_Advice = 48
		BOOL_Flash_Next_Button = false
		BOOL_Set_Newest_Advice_Active = false
		scripting.game_interface:steal_user_input(true)
		CampaignUI.highlight_settlement("town:jap_tut_sanuki:region_specialty")
		CampaignUI.ToggleCinematicBorders(true)
		local	x, z, y, theatre = CampaignUI.CameraTarget()
		scripting.game_interface:scroll_camera(12,	{x, y, z},
													{-113.0, -120.5, 0.97})
		camera_pan = "Resource_Sanuki_Camera"
	elseif context.string == "Resource_Sanuki_Camera_2" then
		effect.advance_scripted_advice_thread("6049_TUT_Resources", 1)
		COUNTER_Advice = 49
		BOOL_Flash_Next_Button = false
		CampaignUI.highlight_settlement("town:jap_tut_tosa:region_specialty")
		scripting.game_interface:steal_user_input(true)
		scripting.game_interface:scroll_camera(18,	{-113.0, -120.5, 0.97},											
														{-165.9, -151.4, 0.9},
														{-150.9, -119.4, 1.05})
		camera_pan = "Resource_Sanuki_Camera_2"	
	elseif context.string == "Highlight_Trade_Ship" then
		CampaignUI.highlight_position(-167.0, -114.5)
		scripting.game_interface:add_circle_area_trigger(-163, -112, 1, "Trigger_Area_Trade_Post", "faction:tut_chosokabe", true, false, true) 
	elseif context.string == "Invasion_Force_Attack_Tokushima" then
		scripting.game_interface:attack("x:-94.6,y:-136.0,r:1.0", "x:-95.8,y:-138.1,r:1.0,faction:tut_chosokabe", false)
	elseif context.string == "Highlight_Agent_Action_Sabotage" then
		effect.advance_scripted_advice_thread("6046_TUT_Agents", 1)
		COUNTER_Advice = 46
		BOOL_Flash_Next_Button = false
		scripting.HighlightComponent("action_button_single_128", true, true)
	elseif context.string == "Highlight_Agent_Action_Gates" then
		scripting.game_interface:treasury_mod("tut_chosokabe", 150)
		scripting.HighlightComponent("action_button_single_1048576", true, true)
	elseif context.string == "Awa_Camera" then
		scripting.game_interface:steal_user_input(true)
		CampaignUI.ToggleCinematicBorders(true)
		local	x, z, y, theatre = CampaignUI.CameraTarget()
		scripting.game_interface:scroll_camera(5,	{x, y, z},
													{-98.2, -132.8, 0.83})
		camera_pan = "Awa_Camera"
	elseif context.string == "Scouting_Coast_Camera" then
		scripting.game_interface:steal_user_input(true)
		CampaignUI.ToggleCinematicBorders(true)
		local	x, z, y, theatre = CampaignUI.CameraTarget()
		scripting.game_interface:scroll_camera(12,	{x, y, z},
													{-131.1, -117.5, 0.63})
		camera_pan = "Coast_Camera"
		scripting.game_interface:add_marker("Marker_Coast", "campaign_map_marker01", -119.0, -112.5, 0, true)
		CampaignUI.highlight_character("x:-161.0,y:-107.0,r:30.0,faction:tut_chosokabe,type:captain")	
	elseif context.string == "Mainland_Camera" then
		scripting.game_interface:steal_user_input(true)
		CampaignUI.ToggleCinematicBorders(true)
		local	x, z, y, theatre = CampaignUI.CameraTarget()
		scripting.game_interface:scroll_camera(30,	{x, y, z},
													{-76.0, -138.7, 0.63})
		camera_pan = "Mainland_Camera"
	elseif context.string == "Set_Newest_Advice_Button" then
		scripting.EnableFeature("Set_Button_Newest_Advice_Inactive")
	elseif context.string == "Make_Advice_Button_Active" then
		scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
	elseif context.string == "Stop_Highlighting_Income_Icon" then
		scripting.HighlightComponent("income_icon", false, false)
	elseif context.string == "Stop_Highlighting_Food_Icon" then
		scripting.HighlightComponent("food_icon", false, false)	
	elseif context.string == "Miyoshi_Fleet_Attack" then	
		scripting.game_interface:attack("x:-99.9,y:-118.8,r:2.0", "x:-118.7,y:-114.2,r:10.0,faction:tut_chosokabe,type:captain", false)
		scripting.game_interface:add_circle_area_trigger(-118, -114, 10, "Trigger_Area_Merged_Ships", "faction:tut_chosokabe", true, false, true) 
		scripting.game_interface:remove_restricted_unit_record("Light_Ship_Bow_Kobaya")		
		scripting.game_interface:remove_restricted_unit_record("Medium_Ship_Medium_Bune")
	elseif context.string == "Disable_Movement_Of_Sogo_Army" then
		scripting.game_interface:disable_movement_for_character("faction:tut_sogo,x:-121.0,y:-125.3,r:1")
	elseif context.string == "Enable_Button_Newest" then
		scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
		BOOL_Set_Newest_Advice_Active = true
	end
end

-------------------------------------------------------------------------------------

local function OnCameraMoverFinished(context)
	out.ting("Camera Pan Finished")
	local local_camera_pan = camera_pan
	camera_pan = ""
	if local_camera_pan == "Intro_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-127.3,y:-139.6,r:2")
		scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-127.3,y:-139.6,r:2")
		scripting.game_interface:set_zoom_limit(1.079, 0.715)
		CampaignUI.SetCameraZoom(1.05)
		CampaignUI.SetCameraTargetInstant(-123.4, -143.0)
		scripting.game_interface:steal_user_input(false)
		CampaignUI.highlight_character("x:-123.0,y:-144.0,r:1.0,faction:tut_chosokabe")
	elseif local_camera_pan == "Rice_Paddie_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.85)
		CampaignUI.SetCameraTargetInstant(-147.6, -135.3)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:remove_restricted_building_level_record("SHO_Farming_2_Irrigation")
	elseif local_camera_pan == "Stronghold_Upgrade_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.1)
	 	CampaignUI.SetCameraTargetInstant(-140.3, -118.5)
		scripting.game_interface:steal_user_input(false)
	elseif local_camera_pan == "Ninja_Target_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.7)
		CampaignUI.SetCameraTargetInstant(-121.7, -123.0)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:remove_barrier("TUT_Shroud_1")
		scripting.game_interface:unveil_black_shroud("TUT_Shroud_2")
		scripting.game_interface:override_ui("disable_end_turn", false) 
		scripting.HighlightComponent("button_end_turn", true, false)
	elseif local_camera_pan == "Ninja_Sabotage_Army_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.15)
		CampaignUI.SetCameraTargetInstant(-122.5, -124.3)
		scripting.game_interface:steal_user_input(false)
	elseif local_camera_pan =="Takamatsu_Camera_2" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.9)
		CampaignUI.SetCameraTargetInstant(-119.3, -120.2)
		scripting.game_interface:force_diplomacy("tut_chosokabe", "tut_sogo", "war", true, true)
		scripting.game_interface:force_diplomacy("tut_sogo", "tut_chosokabe", "war", true, true)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:override_ui("disable_event_panel_auto_open", false)
		scripting.HighlightComponent("button_end_turn", true, false)
	elseif local_camera_pan == "Resource_Sanuki_Camera" then	
		if BOOL_Space_Pressed then	
			CampaignUI.ToggleCinematicBorders(false)
			CampaignUI.SetCameraZoom(1.05)
			CampaignUI.SetCameraTargetInstant(-150.9, -119.4)
			scripting.game_interface:steal_user_input(false)
			effect.advance_scripted_advice_thread("6050_TUT_Port", 1)
			CampaignUI.unhighlight_settlement("town:jap_tut_sanuki:region_specialty")
			CampaignUI.unhighlight_settlement("town:jap_tut_tosa:region_specialty")
			COUNTER_Advice = 50
			BOOL_Flash_Next_Button = false
			scripting.game_interface:remove_barrier("TUT_Shroud_2")
			scripting.game_interface:unveil_black_shroud("TUT_Shroud_3")
			CampaignUI.highlight_settlement("port:jap_tut_iyo:matsuyama")
			scripting.game_interface:remove_restricted_building_level_record("SHO_Region_Specialty_Timber_2_Lumberyards")
			scripting.game_interface:remove_restricted_unit_record("Light_Ship_Bow_Kobaya")
		else
			scripting.game_interface:add_time_trigger("Resource_Sanuki_Camera_2", 1)
		end
	elseif local_camera_pan == "Resource_Sanuki_Camera_2" then	
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.05)
		CampaignUI.SetCameraTargetInstant(-150.9, -119.4)
		scripting.game_interface:steal_user_input(false)
		effect.advance_scripted_advice_thread("6050_TUT_Port", 1)
		CampaignUI.unhighlight_settlement("town:jap_tut_sanuki:region_specialty")
		CampaignUI.unhighlight_settlement("town:jap_tut_tosa:region_specialty")
		COUNTER_Advice = 50
		BOOL_Flash_Next_Button = false
		scripting.game_interface:remove_barrier("TUT_Shroud_2")
		scripting.game_interface:unveil_black_shroud("TUT_Shroud_3")
		CampaignUI.highlight_settlement("port:jap_tut_iyo:matsuyama")
		scripting.game_interface:remove_restricted_building_level_record("SHO_Region_Specialty_Timber_2_Lumberyards")
		scripting.game_interface:remove_restricted_unit_record("Light_Ship_Bow_Kobaya")
	elseif local_camera_pan == "Trade_Post_Camera" then	
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.15)
		CampaignUI.SetCameraTargetInstant(-166.0, -117.7)
		scripting.game_interface:steal_user_input(false)	
		scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-159.7,y:-109.1,r:7")
	elseif local_camera_pan == "Coast_Camera" then	
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.63)
		CampaignUI.SetCameraTargetInstant(-131.1, -117.5)
		scripting.game_interface:steal_user_input(false)
		if BOOL_Ship_Near_Matsuda == false then
			scripting.game_interface:disable_saving_game(false)
			scripting.game_interface:autosave_at_next_opportunity()
			effect.advance_scripted_advice_thread("6060b_TUT_Diplomacy", 1)
			COUNTER_Advice = 6060
			BOOL_Flash_Next_Button = false
		else
			scripting.game_interface:add_marker("Marker_Coast", "campaign_map_marker01", -113, -108, 0, false)
			scripting.game_interface:disable_saving_game(true)
			effect.advance_scripted_advice_thread("6061_TUT_Diplomacy", 1)
			COUNTER_Advice = 61
			BOOL_Flash_Next_Button = false
			scripting.game_interface:override_ui("disable_diplomacy", false)
			scripting.game_interface:override_ui("disable_diplomacy_button", false)
			BOOL_Set_Diplomacy_Active = true
			scripting.HighlightComponent("button_diplomacy", true, false)
		end
	elseif local_camera_pan == "Takamatsu_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.6)
		CampaignUI.SetCameraTargetInstant(-131.1, -123.7)
		scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-141.0,y:-116.0,r:2,type:General")
		scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-141.0,y:-116.0,r:2,type:colonel")
		scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-141.0,y:-116.0,r:2")
		scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:General")
		scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1,type:colonel")
		scripting.game_interface:enable_movement_for_character("faction:tut_chosokabe,x:-133.0,y:-139.0,r:1")
		scripting.game_interface:steal_user_input(false)
	elseif local_camera_pan == "Protect_Trade_Route_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.8)
		CampaignUI.SetCameraTargetInstant(-123.6, -115.3)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:override_ui("disable_event_panel_auto_open", false)
		scripting.game_interface:disable_movement_for_character("faction:tut_chosokabe,x:-116.3,y:-117.3,r:1")
		scripting.game_interface:zero_action_points("faction:tut_chosokabe,x:-116.3,y:-117.3,r:1")
		CampaignUI.highlight_character("x:-118.8,y:-112.4,r:3.0,faction:tut_chosokabe")	
	elseif local_camera_pan == "Enemy_Trade_Route_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.8)
		CampaignUI.SetCameraTargetInstant(-105.9, -114.8)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:override_ui("disable_event_panel_auto_open", false)
		scripting.game_interface:override_ui("disable_end_turn", false) 
	elseif local_camera_pan == "Awa_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.83)
		CampaignUI.SetCameraTargetInstant(-98.2, -132.8)
		scripting.game_interface:steal_user_input(false)
	elseif local_camera_pan == "Mainland_Camera" then
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.63)
		CampaignUI.SetCameraTargetInstant(-76.0, -138.7)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:override_ui("disable_clan_button", false)
		BOOL_Set_Clan_Active = true
		MissionCaptureOsaka()
		if BOOL_Minamiawaji_Captured == false then
			MissionCaptureAwaji()
		end
		----------------------------------- BUILDING RESTRICTIONS ------------------------------------------
		scripting.game_interface:remove_restricted_building_level_record("SHO_Sword_1_Sword_School")
		scripting.game_interface:remove_restricted_building_level_record("SHO_Yari_1_Drill_Yard")
		scripting.game_interface:remove_restricted_building_level_record("SHO_Cavalry_1_Stables")
		scripting.game_interface:remove_restricted_building_level_record("SHO_Stealth_1_Sake_Den")	
		scripting.game_interface:remove_restricted_building_level_record("SHO_Buff_1_Encampment")
		------------------------------------- UNIT RESTRICTIONS ---------------------------------------------
		scripting.game_interface:add_restricted_unit_record("Inf_Spear_Yari_Ashigaru_Tutorial")
		scripting.game_interface:add_restricted_unit_record("Inf_Missile_Bow_Ashigaru_Tutorial")
		scripting.game_interface:remove_restricted_unit_record("Inf_Spear_Yari_Ashigaru_Tutorial_No_Cap")
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Bow_Ashigaru_Tutorial_No_Cap")
		scripting.game_interface:remove_restricted_unit_record("Inf_Special_Fire_Bomb_Throwers")
		scripting.game_interface:remove_restricted_unit_record("Art_European_Cannons")	
		scripting.game_interface:remove_restricted_unit_record("Art_Fire_Projecting_Mangonels")	
		scripting.game_interface:remove_restricted_unit_record("Art_Large_Shafted_Fire_Rockets")	
		scripting.game_interface:remove_restricted_unit_record("Cav_Spear_Great_Guard")	
		scripting.game_interface:remove_restricted_unit_record("Inf_Spear_Yari_Hero")			
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Bow_Hero")	
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Bow_Wako")		
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Bow_Hero_Chosokabe")	
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Bow_Warrior_Monks_Chosokabe")
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Matchlock_Samurai")	
		scripting.game_interface:remove_restricted_unit_record("Inf_Missile_Matchlock_Warrior_Monks")
		scripting.game_interface:remove_restricted_unit_record("Inf_Heavy_Naginata_Warrior_Monks")	
		scripting.game_interface:remove_restricted_unit_record("Inf_Sword_Katana_Hero")	
		scripting.game_interface:remove_restricted_unit_record("Inf_Sword_Katana_Wako")	
		scripting.game_interface:remove_restricted_unit_record("Inf_Special_Kisho_Ninjas")	
		--------------------------------------- SHIP RESTRICTIONS ---------------------------------------------------	
		scripting.game_interface:remove_restricted_unit_record("Trade_Ship_Trade_Ship")	
		scripting.game_interface:remove_restricted_unit_record("Light_Ship_Bow_Kobaya")		
		scripting.game_interface:remove_restricted_unit_record("Medium_Ship_Medium_Bune")
		scripting.game_interface:remove_restricted_unit_record("Light_Ship_Siege_Tower_Bune")
		------------------------------------- OTHER RESTRICTIONS ---------------------------------------------
		scripting.game_interface:disable_rebellions_and_revolutions_worldwide(false) 
		scripting.game_interface:set_general_offered_dilemma_permitted(true)
		scripting.OverrideMessageAutoShow("character_gains_level", true)
		scripting.OverrideMessageAutoShow("character_gains_level_ninja", true)
	end
	BOOL_Space_Pressed = false
end

-------------------------------------------------------------------------------------
-------------------------------------- VICTORY CONDITIONS ---------------------------
-------------------------------------------------------------------------------------

local function OnVictoryConditionMet(context)
	scripting.game_interface:register_outro_movie("Faction/Tut/TUT_OUT.bik")
end

-------------------------------------------------------------------------------------
-------------------------------------- KEY PRESSED  ---------------------------------
-------------------------------------------------------------------------------------

function OnKeyPressed(key, is_key_up)
	if is_key_up == true then
		if key == "SPACE" or key == "ESCAPE" then
			out.ting("Space/Escape Key Pressed")
			out.ting(camera_pan)
			if camera_pan ~= "" then
				scripting.game_interface:stop_camera()
				BOOL_Space_Pressed = true
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------- ONE-TIME INITIALISATION  ---------------------
-------------------------------------------------------------------------------------

local function OnNewCampaignStarted()
	new_game = true
	scripting.game_interface:add_custom_battlefield(-131.1, -133.1, 3, "TutorialBattles/TUT_Battle_Ashigaru.xml")
	scripting.game_interface:add_custom_battlefield(-108.3, -119.8, 3, "TutorialBattles/TUT_Battle_Samurai.xml")
	scripting.game_interface:add_custom_battlefield(-96.3, -137.5, 3, "TutorialBattles/TUT_Battle_Shogun.xml")
end

-------------------------------------------------------------------------------------
--------------------------------------- LOAD / SAVE ---------------------------------
-------------------------------------------------------------------------------------

local function OnGameSave(context)
	out.ting("Game Saved")
	out.ting(COUNTER_Advice)
	scripting.game_interface:save_named_value("VERSION", 1, context)
	scripting.game_interface:save_named_value("COUNTER_Advice", COUNTER_Advice, context)
	scripting.game_interface:save_named_value("COUNTER_First_Tech_Researched", COUNTER_First_Tech_Researched, context)
	scripting.game_interface:save_named_value("COUNTER_Units_Entering_Kochi", COUNTER_Units_Entering_Kochi, context)
	scripting.game_interface:save_named_value("COUNTER_Castle_Gates_Opened", COUNTER_Castle_Gates_Opened, context)
	scripting.game_interface:save_named_value("BOOL_Set_Clan_Active", BOOL_Set_Clan_Active, context)
	scripting.game_interface:save_named_value("BOOL_Set_Diplomacy_Active", BOOL_Set_Diplomacy_Active, context)
	scripting.game_interface:save_named_value("BOOL_Set_Technology_Active", BOOL_Set_Technology_Active, context)
	scripting.game_interface:save_named_value("BOOL_Set_Finance_Active", BOOL_Set_Finance_Active, context)
	scripting.game_interface:save_named_value("BOOL_Set_Newest_Advice_Active", BOOL_Set_Newest_Advice_Active, context)
	scripting.game_interface:save_named_value("BOOL_Set_Factions_Tab_Active", BOOL_Set_Factions_Tab_Active, context)
	scripting.game_interface:save_named_value("BOOL_Unit_Created", BOOL_Unit_Created, context)
	scripting.game_interface:save_named_value("BOOL_Flash_Next_Button", BOOL_Flash_Next_Button, context)
	scripting.game_interface:save_named_value("BOOL_Kochi_Selected", BOOL_Kochi_Selected, context)
	scripting.game_interface:save_named_value("BOOL_Imabari_Selected", BOOL_Imabari_Selected, context)
	scripting.game_interface:save_named_value("BOOL_Takamatsu_Selected", BOOL_Takamatsu_Selected, context)
	scripting.game_interface:save_named_value("BOOL_Tokushima_Selected", BOOL_Tokushima_Selected, context)
	scripting.game_interface:save_named_value("BOOL_Research_Complete", BOOL_Research_Complete, context)
	scripting.game_interface:save_named_value("BOOL_Faction_Ending_Turn", BOOL_Faction_Ending_Turn, context)
	scripting.game_interface:save_named_value("BOOL_Rebels_Spawned", BOOL_Rebels_Spawned, context)
	scripting.game_interface:save_named_value("BOOL_Metsuke_Bribed_Army", BOOL_Metsuke_Bribed_Army, context)
	scripting.game_interface:save_named_value("BOOL_Takamatsu_Camera_2", BOOL_Takamatsu_Camera_2, context)
	scripting.game_interface:save_named_value("BOOL_Enemy_Trade_Route_Raided", BOOL_Enemy_Trade_Route_Raided, context)
	scripting.game_interface:save_named_value("BOOL_Agreement_Made", BOOL_Agreement_Made, context)
	scripting.game_interface:save_named_value("BOOL_Sogo_Army_Spawned", BOOL_Sogo_Army_Spawned, context)
	scripting.game_interface:save_named_value("BOOL_Mission_Capture_Takamatsu_Given", BOOL_Mission_Capture_Takamatsu_Given, context)
	scripting.game_interface:save_named_value("BOOL_Minamiawaji_Captured", BOOL_Minamiawaji_Captured, context)
	scripting.game_interface:save_named_value("BOOL_Imabari_Captured", BOOL_Imabari_Captured, context)
	scripting.game_interface:save_named_value("BOOL_Takamatsu_Captured", BOOL_Takamatsu_Captured, context)
	scripting.game_interface:save_named_value("BOOL_Tokushima_Captured", BOOL_Tokushima_Captured, context)
	scripting.game_interface:save_named_value("BOOL_Gates_Opened", BOOL_Gates_Opened, context)
	scripting.game_interface:save_named_value("BOOL_Trade_Route_Raided", BOOL_Trade_Route_Raided, context)
	scripting.game_interface:save_named_value("BOOL_Character_Has_Come_Of_Age", BOOL_Character_Has_Come_Of_Age, context)
	scripting.game_interface:save_named_value("BOOL_Archery_Dojo_Constructed", BOOL_Archery_Dojo_Constructed, context)
	scripting.game_interface:save_named_value("BOOL_Region_Info_Opened", BOOL_Region_Info_Opened, context)
	scripting.game_interface:save_named_value("BOOL_Finance_Panel_Opened", BOOL_Finance_Panel_Opened, context)
	scripting.game_interface:save_named_value("BOOL_Upkeep_Advice", BOOL_Upkeep_Advice, context)
	scripting.game_interface:save_named_value("BOOL_6073", BOOL_6073, context)
	scripting.game_interface:save_named_value("BOOL_6075", BOOL_6075, context)
	scripting.game_interface:save_named_value("BOOL_6076", BOOL_6076, context)
	scripting.game_interface:save_named_value("BOOL_6078", BOOL_6078, context)
	scripting.game_interface:save_named_value("BOOL_6081", BOOL_6081, context)
	scripting.game_interface:save_named_value("BOOL_6089b", BOOL_6089b, context)
	scripting.game_interface:save_named_value("BOOL_Advice_23", BOOL_Advice_23, context)
	scripting.game_interface:save_named_value("BOOL_Advice_6095", BOOL_Advice_6095, context)
	scripting.game_interface:save_named_value("BOOL_Advice_6034", BOOL_Advice_6034, context)
	scripting.game_interface:save_named_value("BOOL_Free_Play", BOOL_Free_Play, context)
	scripting.game_interface:save_named_value("BOOL_Advice_Arrows_Clicked", BOOL_Advice_Arrows_Clicked, context)
	scripting.game_interface:save_named_value("BOOL_Miyoshi_Fleet_Spawned", BOOL_Miyoshi_Fleet_Spawned, context)
	scripting.game_interface:save_named_value("BOOL_Commissions_Highlighted", BOOL_Commissions_Highlighted, context)
	scripting.game_interface:save_named_value("BOOL_Character_Ranked_Up", BOOL_Character_Ranked_Up, context)
	scripting.game_interface:save_named_value("BOOL_Character_Ranked_Up_Info", BOOL_Character_Ranked_Up_Info, context)
	scripting.game_interface:save_named_value("BOOL_Ship_Near_Matsuda", BOOL_Ship_Near_Matsuda, context)
	scripting.game_interface:save_named_value("BOOL_Awa_Camera_Triggered", BOOL_Awa_Camera_Triggered, context)
	scripting.game_interface:save_named_value("BOOL_Trade_Node_Connected", BOOL_Trade_Node_Connected, context)
	scripting.game_interface:save_named_value("BOOL_Fleets_Merged", BOOL_Fleets_Merged, context)
	scripting.game_interface:save_named_value("BOOL_Sieging_Imabari_Advice", BOOL_Sieging_Imabari_Advice, context)
	scripting.game_interface:save_named_value("BOOL_First_Agreement", BOOL_First_Agreement, context)
end

-------------------------------------------------------------------------------------

local function OnGameLoad(context)
	out.ting("Game Loaded")
	COUNTER_Advice = scripting.game_interface:load_named_value("COUNTER_Advice", 0, context)
	COUNTER_First_Tech_Researched = scripting.game_interface:load_named_value("COUNTER_First_Tech_Researched", 0, context)
	COUNTER_Units_Entering_Kochi = scripting.game_interface:load_named_value("COUNTER_Units_Entering_Kochi", 0, context)
	COUNTER_Castle_Gates_Opened = scripting.game_interface:load_named_value("COUNTER_Castle_Gates_Opened", 0, context)
	BOOL_Set_Clan_Active = scripting.game_interface:load_named_value("BOOL_Set_Clan_Active", false, context)
	BOOL_Set_Diplomacy_Active = scripting.game_interface:load_named_value("BOOL_Set_Diplomacy_Active", false, context)
	BOOL_Set_Technology_Active = scripting.game_interface:load_named_value("BOOL_Set_Technology_Active", false, context)
	BOOL_Set_Finance_Active = scripting.game_interface:load_named_value("BOOL_Set_Finance_Active", false, context)
	BOOL_Set_Newest_Advice_Active = scripting.game_interface:load_named_value("BOOL_Set_Newest_Advice_Active", false, context)
	BOOL_Set_Factions_Tab_Active = scripting.game_interface:load_named_value("BOOL_Set_Factions_Tab_Active", false, context)
	BOOL_Unit_Created = scripting.game_interface:load_named_value("BOOL_Unit_Created", false, context)
	BOOL_Flash_Next_Button = scripting.game_interface:load_named_value("BOOL_Flash_Next_Button", false, context)
	BOOL_Kochi_Selected = scripting.game_interface:load_named_value("BOOL_Kochi_Selected", false, context)
	BOOL_Imabari_Selected = scripting.game_interface:load_named_value("BOOL_Imabari_Selected", false, context)
	BOOL_Takamatsu_Selected = scripting.game_interface:load_named_value("BOOL_Takamatsu_Selected", false, context)
	BOOL_Tokushima_Selected = scripting.game_interface:load_named_value("BOOL_Tokushima_Selected", false, context)
	BOOL_Research_Complete = scripting.game_interface:load_named_value("BOOL_Research_Complete", false, context)
	BOOL_Faction_Ending_Turn = scripting.game_interface:load_named_value("BOOL_Faction_Ending_Turn", false, context)
	BOOL_Rebels_Spawned = scripting.game_interface:load_named_value("BOOL_Rebels_Spawned", false, context)
	BOOL_Metsuke_Bribed_Army = scripting.game_interface:load_named_value("BOOL_Metsuke_Bribed_Army", false, context)
	BOOL_Takamatsu_Camera_2 = scripting.game_interface:load_named_value("BOOL_Takamatsu_Camera_2", false, context)
	BOOL_Enemy_Trade_Route_Raided = scripting.game_interface:load_named_value("BOOL_Enemy_Trade_Route_Raided", false, context)
	BOOL_Agreement_Made = scripting.game_interface:load_named_value("BOOL_Agreement_Made", false, context)
	BOOL_Sogo_Army_Spawned = scripting.game_interface:load_named_value("BOOL_Sogo_Army_Spawned", false, context)
	BOOL_Mission_Capture_Takamatsu_Given = scripting.game_interface:load_named_value("BOOL_Mission_Capture_Takamatsu_Given", false, context)
	BOOL_Minamiawaji_Captured = scripting.game_interface:load_named_value("BOOL_Minamiawaji_Captured", false, context)
	BOOL_Imabari_Captured = scripting.game_interface:load_named_value("BOOL_Imabari_Captured", false, context)
	BOOL_Takamatsu_Captured = scripting.game_interface:load_named_value("BOOL_Takamatsu_Captured", false, context)
	BOOL_Tokushima_Captured = scripting.game_interface:load_named_value("BOOL_Tokushima_Captured", false, context)
	BOOL_Gates_Opened = scripting.game_interface:load_named_value("BOOL_Gates_Opened", false, context)
	BOOL_Trade_Route_Raided = scripting.game_interface:load_named_value("BOOL_Trade_Route_Raided", false, context)
	BOOL_Character_Has_Come_Of_Age = scripting.game_interface:load_named_value("BOOL_Character_Has_Come_Of_Age", false, context)
	BOOL_Archery_Dojo_Constructed = scripting.game_interface:load_named_value("BOOL_Archery_Dojo_Constructed", false, context)
	BOOL_Region_Info_Opened = scripting.game_interface:load_named_value("BOOL_Region_Info_Opened", false, context)
	BOOL_Finance_Panel_Opened = scripting.game_interface:load_named_value("BOOL_Finance_Panel_Opened", false, context)
	BOOL_Upkeep_Advice = scripting.game_interface:load_named_value("BOOL_Upkeep_Advice", false, context)
	BOOL_6073 = scripting.game_interface:load_named_value("BOOL_6073", false, context)
	BOOL_6075 = scripting.game_interface:load_named_value("BOOL_6075", false, context)
	BOOL_6076 = scripting.game_interface:load_named_value("BOOL_6076", false, context)
	BOOL_6078 = scripting.game_interface:load_named_value("BOOL_6078", false, context)
	BOOL_6081 = scripting.game_interface:load_named_value("BOOL_6081", false, context)
	BOOL_6089b = scripting.game_interface:load_named_value("BOOL_6089b", false, context)
	BOOL_Advice_23 = scripting.game_interface:load_named_value("BOOL_Advice_23", false, context)
	BOOL_Advice_6095 = scripting.game_interface:load_named_value("BOOL_Advice_6095", false, context)
	BOOL_Advice_6034 = scripting.game_interface:load_named_value("BOOL_Advice_6034", false, context)
	BOOL_Free_Play = scripting.game_interface:load_named_value("BOOL_Free_Play", false, context)
	BOOL_Advice_Arrows_Clicked = scripting.game_interface:load_named_value("BOOL_Advice_Arrows_Clicked", false, context)
	BOOL_Miyoshi_Fleet_Spawned = scripting.game_interface:load_named_value("BOOL_Miyoshi_Fleet_Spawned", false, context)
	BOOL_Commissions_Highlighted = scripting.game_interface:load_named_value("BOOL_Commissions_Highlighted", false, context)
	BOOL_Character_Ranked_Up = scripting.game_interface:load_named_value("BOOL_Character_Ranked_Up", false, context)
	BOOL_Character_Ranked_Up_Info = scripting.game_interface:load_named_value("BOOL_Character_Ranked_Up_Info", false, context)
	BOOL_Ship_Near_Matsuda = scripting.game_interface:load_named_value("BOOL_Ship_Near_Matsuda", false, context)
	BOOL_Awa_Camera_Triggered = scripting.game_interface:load_named_value("BOOL_Awa_Camera_Triggered", false, context)
	BOOL_Trade_Node_Connected = scripting.game_interface:load_named_value("BOOL_Trade_Node_Connected", false, context)
	BOOL_Fleets_Merged = scripting.game_interface:load_named_value("BOOL_Fleets_Merged", false, context)
	BOOL_Sieging_Imabari_Advice = scripting.game_interface:load_named_value("BOOL_Sieging_Imabari_Advice", false, context)
	BOOL_First_Agreement = scripting.game_interface:load_named_value("BOOL_First_Agreement", false, context)
	BOOL_Players_Turn = true
	BOOL_Game_Loaded = true
	out.ting(COUNTER_Advice)
	out.ting("Load Complete")
end

--------------------------------------------------------------------------------------

local function OnLoadTimeTrigger(context)
	out.ting("Load OnLoadShowAdvice")
	Restrict_Technologies()
	if context.string == "LoadShowAdvice" then
		if BOOL_Game_Loaded then
			if COUNTER_Advice == 8 then --Construct Archery Dojo
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.97)
				CampaignUI.SetCameraTargetInstant(-132.8, -138.1) 
				CampaignUI.highlight_settlement("settlement:jap_tut_tosa:kochi")
				effect.advance_scripted_advice_thread("6008_TUT_Construction", 1)
				scripting.HighlightComponent("Garrison_Tab", true, false)
			elseif COUNTER_Advice == 29 then --Recruit Bow Samurai
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.97)
				CampaignUI.SetCameraTargetInstant(-132.8, -138.1) 
				CampaignUI.highlight_settlement("settlement:jap_tut_tosa:kochi")
				effect.advance_scripted_advice_thread("6029_TUT_Victory_Con", 1)
				scripting.HighlightComponent("Land_Recruitment_Tab", true, false)
			elseif COUNTER_Advice == 6012 then --View Region Unrest
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.97)
				CampaignUI.SetCameraTargetInstant(-132.8, -138.1)
				CampaignUI.highlight_settlement("settlement:jap_tut_tosa:kochi")
				effect.advance_scripted_advice_thread("6012b_TUT_Region_Panel", 1)			
			elseif COUNTER_Advice == 16 then --Monk Emerges
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.97)
				CampaignUI.SetCameraTargetInstant(-132.8, -138.1)
				effect.advance_scripted_advice_thread("6016_TUT_Armies", 1)
				scripting.game_interface:override_ui("disable_end_turn", true) 
				BOOL_Flash_Next_Button = true
				scripting.HighlightComponent("income_icon", true, false)
				scripting.InitFeature("Set_Button_Newest_Advice_Inactive")
				BOOL_Set_Newest_Advice_Active = true
			elseif COUNTER_Advice == 20 then --Declare War on the Kono
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.91)
				CampaignUI.SetCameraTargetInstant(-131.6, -131.9)
				effect.advance_scripted_advice_thread("6020_TUT_War", 1)
			elseif COUNTER_Advice == 41 then --Stronghold Completed
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(1.05)
				CampaignUI.SetCameraTargetInstant(-140.3, -118.5)
				effect.advance_scripted_advice_thread("6041_TUT_Building_Chains", 1)
				CampaignUI.highlight_settlement("settlement:jap_tut_iyo:imabari")
			elseif COUNTER_Advice == 44 then --Ninja to Sabotage Army
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraTargetInstant(-121.7, -123.0)
				effect.advance_scripted_advice_thread("6044_TUT_Agents", 1)
				CampaignUI.highlight_character("x:-142.1,y:-118.2,r:1.0,faction:tut_chosokabe")
			elseif COUNTER_Advice == 54 then --Ship Recruited
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(1.05)
				CampaignUI.SetCameraTargetInstant(-150.9, -118.4)
				effect.advance_scripted_advice_thread("6054_TUT_Port", 1)
				CampaignUI.highlight_character("x:-151.9,y:-118.3,r:1.0,faction:tut_chosokabe")	
			elseif COUNTER_Advice == 59 then --Technology being researched
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.63)
				CampaignUI.SetCameraTargetInstant(-121.7, -130.0)
				effect.advance_scripted_advice_thread("6059_TUT_Technology", 1)
			elseif COUNTER_Advice == 6060 then --Scout Coast
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.63)
				CampaignUI.SetCameraTargetInstant(-131.1, -117.5)
				effect.advance_scripted_advice_thread("6060b_TUT_Diplomacy", 1)
				CampaignUI.highlight_character("x:-161.0,y:-107.0,r:30.0,faction:tut_chosokabe,type:captain")
			elseif COUNTER_Advice == 65 then --Merge Fleets
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.8)
				CampaignUI.SetCameraTargetInstant(-123.6, -115.3)
				effect.advance_scripted_advice_thread("6065_TUT_Trade_Route", 1)
				CampaignUI.highlight_character("x:-119.3,y:-112.4,r:3.0,faction:tut_chosokabe")	
			elseif COUNTER_Advice == 70 then --Capture Awa
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.83)
				CampaignUI.SetCameraTargetInstant(-98.2, -132.8)
				effect.advance_scripted_advice_thread("6070_TUT_Missions", 1)
			elseif COUNTER_Advice == 72 then --Capture the Mainland
				-- SAVE/LOAD
				CampaignUI.SetCameraZoom(0.63)
				CampaignUI.SetCameraTargetInstant(-76.0, -138.6)
				effect.advance_scripted_advice_thread("6072_TUT_Stables", 1)
			end
		end
	end
end

--------------------------------------------------------------------------------------

local function OnWorldCreated(context)
	scripting.game_interface:add_time_trigger("LoadShowAdvice", 0)
	scripting.game_interface:unveil_black_shroud("TUT_Shroud_1")
end

--------------------------------------------------------------------------------------

local function OnUICreated(context)
	if new_game then
		scripting.game_interface:register_movies("Faction/Start/FSM_CHO.bik")
	end
	if scripting.IsOnCampaignMap() then
		if new_game then
			out.ting("Moving camera to initial position")
			scripting.game_interface:set_zoom_limit(1.15, 0.55)
			CampaignUI.SetCameraZoom(0.5)
			CampaignUI.SetCameraTargetInstant(-123.4, -143.0) 
			new_game = false
		end
		if BOOL_Set_Clan_Active == false then	
			scripting.game_interface:override_ui("disable_clan_button", true)
		else
			scripting.game_interface:override_ui("disable_clan_button", false)
		end
		if BOOL_Set_Diplomacy_Active == false then
			scripting.game_interface:override_ui("disable_diplomacy_button", true)
		else
			scripting.game_interface:override_ui("disable_diplomacy_button", false)
		end
		if BOOL_Set_Technology_Active == false then
			scripting.game_interface:override_ui("disable_tech_button", true)
		else
			scripting.game_interface:override_ui("disable_tech_button", false)
		end
		if BOOL_Set_Finance_Active == false then	
			scripting.game_interface:override_ui("disable_finance_button", true)
		else
			scripting.game_interface:override_ui("disable_finance_button", false)
		end
		if BOOL_Set_Newest_Advice_Active == false then
			scripting.game_interface:add_time_trigger("Set_Newest_Advice_Button", 0)
		end
		if BOOL_Set_Factions_Tab_Active == false then
			scripting.EnableFeature("Set_Factions_Tab_Inactive")
		end
		if BOOL_Free_Play == false then
			scripting.game_interface:set_event_generation_enabled(false)
		end
	end
end

--------------------------------------------------------------------------------------
-- Add event callbacks
-- For a list of all events supported create a "documentation" directory in your empire directory, run a debug build of the game and see
-- the events.txt file
--------------------------------------------------------------------------------------

scripting.AddEventCallBack("AdviceDismissed", 				OnAdviceDismissed)
scripting.AddEventCallBack("AdviceFinishedTrigger", 		OnAdviceFinished)
scripting.AddEventCallBack("AdviceIssued", 					OnAdviceTriggered)
scripting.AddEventCallBack("AreaEntered", 					OnAreaEntered)
scripting.AddEventCallBack("BuildingCompleted",				OnBuildingCompleted)
scripting.AddEventCallBack("CameraMoverCancelled", 			OnCameraMoverFinished)
scripting.AddEventCallBack("CameraMoverFinished", 			OnCameraMoverFinished)
scripting.AddEventCallBack("CampaignArmiesMerge", 			OnCampaignArmiesMerge)
scripting.AddEventCallBack("CharacterComesOfAge", 			OnCharacterComesOfAge)
scripting.AddEventCallBack("CharacterEmbarksNavy", 			OnEmbarkShip)
scripting.AddEventCallBack("CharacterEntersGarrison", 		OnEnteredGarrison)
scripting.AddEventCallBack("CharacterRankUp", 				OnCharacterRankUp)
scripting.AddEventCallBack("CharacterSelected", 			OnCharacterSelected)
scripting.AddEventCallBack("ComponentLClickUp", 			OnComponentLClickUp)
scripting.AddEventCallBack("ComponentMouseOn", 				OnComponentMouseOn)
scripting.AddEventCallBack("ComponentMoved", 				OnComponentMoved)
scripting.AddEventCallBack("FactionAboutToEndTurn", 		OnFactionAboutToEndTurn)
scripting.AddEventCallBack("FactionTurnStart", 				OnFactionTurnStart)
scripting.AddEventCallBack("FactionTurnEnd", 				OnFactionTurnEnd)
scripting.AddEventCallBack("FactionBeginTurnPhaseNormal",	OnFactionBeginTurnPhaseNormal)
scripting.AddEventCallBack("GovernorshipTaxRateChanged", 	OnGovernorshipTaxChange)
scripting.AddEventCallBack("LoadingGame", 					OnGameLoad)
scripting.AddEventCallBack("MissionSucceeded", 				OnMissionSuccess)
scripting.AddEventCallBack("MovementPointsExhausted", 		OnMovementPointsExhausted)
scripting.AddEventCallBack("MultiTurnMove", 				OnMultiTurnMove)
scripting.AddEventCallBack("NewCampaignStarted", 			OnNewCampaignStarted)
scripting.AddEventCallBack("PanelOpenedCampaign", 			OnPanelOpen)
scripting.AddEventCallBack("PanelClosedCampaign", 			OnPanelClosed)
scripting.AddEventCallBack("PendingBankruptcy", 			OnBankruptcy)
scripting.AddEventCallBack("PendingBattle", 				OnPendingBattle)
scripting.AddEventCallBack("RecruitmentItemIssuedByPlayer", OnRecruitmentItemIssuedByPlayer)
scripting.AddEventCallBack("ResearchCompleted", 			OnResearchCompleted)
scripting.AddEventCallBack("SavingGame", 					OnGameSave)
scripting.AddEventCallBack("SeaTradeRouteRaided", 			OnSeaTradeRouteRaided)
scripting.AddEventCallBack("SettlementSelected", 			OnSettlementSelected)
scripting.AddEventCallBack("SlotSelected", 					OnTownPortSelected)
scripting.AddEventCallBack("TimeTrigger", 					OnTimeTrigger)
scripting.AddEventCallBack("TimeTrigger", 					OnLoadTimeTrigger)
scripting.AddEventCallBack("TradeNodeConnected", 			OnTradeNodeConnected)
scripting.AddEventCallBack("TradeRouteEstablished", 		OnTradeRouteEstablished)
scripting.AddEventCallBack("UICreated",						OnUICreated)
scripting.AddEventCallBack("UnitTrained", 					OnUnitCreated)
scripting.AddEventCallBack("VictoryConditionMet", 			OnVictoryConditionMet)
scripting.AddEventCallBack("WorldCreated",					OnWorldCreated)