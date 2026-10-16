-------------------------------------------------------------------------------
------------------------------ SCRIPT SETUP -----------------------------------
-------------------------------------------------------------------------------
local core = require "ui/CoreUtils"
local advice = require "export_advice"
local scripting = require "EpisodicScripting"
local camera_pan = 0
local new_game = false
local panning = false
local becoming_shogun_advice = false

EpisodicScripting = scripting

scripting.SetCampaign("jap_shogun")
out.ting("Shogun Japan campaign script!")

local function OnNewCampaignStarted(context)
	new_game = true
	becoming_shogun_advice = true
	scripting.game_interface:add_restricted_building_level_record("SHO_Port_3_Nanban_Trade_Port")
	scripting.game_interface:add_restricted_unit_record("Cav_Spear_Great_Guard_Takeda")
	scripting.game_interface:add_restricted_unit_record("Heavy_Ship_Nihon_Maru_Mori")
	
	-- Unlock the nanban port for the Otomo and Shimazu (just in case they lose it)
	scripting.game_interface:remove_restricted_building_level_record_for_faction("SHO_Port_3_Nanban_Trade_Port", "otomo")
	scripting.game_interface:remove_restricted_building_level_record_for_faction("SHO_Port_3_Nanban_Trade_Port", "shimazu")
		
end

local function OnUICreated(context)

	if scripting.IsOnCampaignMap() then
		
		if new_game and not CampaignUI.IsMultiplayer() then
			
			-- Add black screen cover, hide pop-in
			CampaignUI.ToggleScreenCover(true)
			CampaignUI.ToggleCinematicBorders(true)
			
			if conditions.FactionKeyIsLocal("date", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_DAT.bik")
				out.ting("DATE! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.676)
				CampaignUI.SetCameraHeading(-0.98)
				CampaignUI.SetCameraTargetInstant(198.0, -34.0)
				new_game = false
		
			elseif conditions.FactionKeyIsLocal("mori", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_MOR.bik")
				out.ting("MORI! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraHeading(0.02)
				CampaignUI.SetCameraTargetInstant(-155.0, -112.0)
				new_game = false

			elseif conditions.FactionKeyIsLocal("chosokabe", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_CHO.bik")
				out.ting("CHOSOKABE! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.68)
				CampaignUI.SetCameraHeading(0.5)
				CampaignUI.SetCameraTargetInstant(-142.0, -152.0)
				new_game = false
		
			elseif conditions.FactionKeyIsLocal("shimazu", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_SHI.bik")
				out.ting("SHIMAZU! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(1.0)
				CampaignUI.SetCameraHeading(-0.87)
				CampaignUI.SetCameraTargetInstant(-248.0, -162.0)
				new_game = false
		
			elseif conditions.FactionKeyIsLocal("oda", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_ODA.bik")
				out.ting("ODA! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.68)
				CampaignUI.SetCameraHeading(0.69)
				CampaignUI.SetCameraTargetInstant(-23.0, -156.0)
				new_game = false
		

			elseif conditions.FactionKeyIsLocal("takeda", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_TAK.bik")
				out.ting("TAKEDA! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.8)
				CampaignUI.SetCameraHeading(0.26)
				CampaignUI.SetCameraTargetInstant(39.0, -157.0)
				new_game = false

			elseif conditions.FactionKeyIsLocal("tokugawa", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_TOK.bik")
				out.ting("TOKUGAWA! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.88)
				CampaignUI.SetCameraHeading(-0.49)
				CampaignUI.SetCameraTargetInstant(4.0, -160.0)
				new_game = false

			elseif conditions.FactionKeyIsLocal("iga_ninja", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_IGA.bik")
				out.ting("HATTORI! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.676)
				CampaignUI.SetCameraHeading(0.19)
				CampaignUI.SetCameraTargetInstant(-41.0, -158.0)
				new_game = false

			elseif conditions.FactionKeyIsLocal("hojo", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_HOJ.bik")
				out.ting("HOJO! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraHeading(-0.36)
				CampaignUI.SetCameraTargetInstant(57.0, -165.0)
				new_game = false

			elseif conditions.FactionKeyIsLocal("uesugi", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_UES.bik")
				out.ting("UESUGI! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.92)
				CampaignUI.SetCameraHeading(0.047)
				CampaignUI.SetCameraTargetInstant(76.4, -106.0)
				new_game = false
				
			elseif conditions.FactionKeyIsLocal("ikko_ikki", context) then
				scripting.game_interface:register_movies("Faction/Start/FSM_IKO.bik")
				out.ting("Ikko Ikki! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.75)
				CampaignUI.SetCameraHeading(1.0)
				CampaignUI.SetCameraTargetInstant(-16.0, -89.0)
				new_game = false
			
			
			-- OTOMO START --
			
			elseif conditions.FactionKeyIsLocal("otomo", context) then
				scripting.game_interface:register_movies("Otomo/FSM_OTO.bik")
				out.ting("Otomo! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(1.15)
				CampaignUI.SetCameraHeading(0.58)
				CampaignUI.SetCameraTargetInstant(-254.0, -212.0)
				new_game = false

			-- OTOMO END --
			
			else
				out.ting("Minor faction! Setting the game scripts up")
				CampaignUI.ToggleCinematicBorders(false)
				CampaignUI.ToggleScreenCover(false)
				
				-- MTB-anton.korzhuk [WAS-3311] BEGIN: fix map zoom for minor faction
				
				-- we have no cut-scenes, so just go and set zoom limit to the normal gameplay one
				scripting.game_interface:set_zoom_limit(1.1, 0.8) 
				CampaignUI.SetCameraZoom(0.95)
				new_game = false
				
				-- MTB-anton.korzhuk [WAS-3311] END: fix map zoom for minor faction
			end
			
		elseif new_game and CampaignUI.IsMultiplayer() then
			scripting.game_interface:set_zoom_limit(1.1, 0.8)
			CampaignUI.SetCameraZoom(0.95)		
		end
	end
end


local VAR_previous_shogun_ID = 0

local message_handler = MessageManager

-------------------------------------------------------------------------------------------------------------------------
--
-- INTRO MISSION SETUP
--

local AI_FORCE_small = "Inf_Spear_Yari_Ashigaru,Inf_Missile_Bow_Ashigaru,Cav_Spear_Light_Cavalry"
local AI_FORCE_medium = "Inf_Spear_Yari_Ashigaru,Inf_Spear_Yari_Ashigaru,Inf_Missile_Bow_Ashigaru,Cav_Spear_Light_Cavalry"
local AI_FORCE_large = "Inf_Spear_Yari_Ashigaru,Inf_Spear_Yari_Ashigaru,Inf_Spear_Yari_Samurai,Inf_Missile_Bow_Ashigaru,Cav_Spear_Yari_Cavalry"

local final_zoom_limit = 1.1, 0.8

--
-- CHOSOKABE --
--
	-- MISSIONS --
	
		-- Chosokabe Mission 1: Crush Tosa Rebellion
		local function chosokabe_intro_mission_one()
			out.ting("Chosokabe Mission One: Crush Tosa Rebellion")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_chosokabe_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"chosokabe",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_tosa",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
		end

		local BOOL_chosokabe_tosa_rebellion_crushed = false
		
			
		-- Chosokabe Mission 2: Research Way Of The Bow
		local function chosokabe_intro_mission_two()
			out.ting("Chosokabe Mission: Research Way Of The Bow")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_chosokabe_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"chosokabe",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_military_bow_way_of_the_bow",
															--[REWARD]--
																"grant_unit:Inf_Missile_Bow_Samurai_Chosokabe#capital")
		end

		-- Chosokabe Mission 3: Capture Any Region
		local function chosokabe_intro_mission_three()
			out.ting("Chosokabe Mission: Capture Any Region")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_chosokabe_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"chosokabe",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_call_to_arms#4")
		end
		
		local BOOL_chosokabe_mission_three_issued = false
		local BOOL_chosokabe_tosa_free = true

	
	
--
-- ODA --
--
	-- MISSIONS --
		-- Oda Mission 1: Crush Owari Rebellion
		local function oda_intro_mission_one()
			out.ting("Oda Mission One: Crush Owari Rebellion")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_oda_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"oda",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_owari",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
		end

		local BOOL_oda_owari_rebellion_crushed = false


		-- Oda Mission 2: Research Way Of The Spear
		local function oda_intro_mission_two()
			out.ting("Oda Mission: Research Way Of The Spear")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_oda_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"oda",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_military_spear_way_of_the_spear",
															--[REWARD]--
																"grant_unit:Inf_Spear_Yari_Ashigaru_Oda#capital,grant_unit:Inf_Spear_Yari_Ashigaru_Oda#capital")
		end

		-- Oda Mission 3: Capture Any Region
		local function oda_intro_mission_three()
			out.ting("Oda Mission: Capture Any Region")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_oda_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"oda",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_call_to_arms#4")
		end
		
		local BOOL_oda_mission_three_issued = false
		


--
-- TAKEDA --
--
	-- MISSIONS --
		-- Takeda Mission 1: Defeat Murakami Force
		local function takeda_intro_mission_one()
			out.ting("Takeda Mission: Defeat Murakami Force")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_takeda_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"takeda",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"faction:murakami,requires_victory:true,armies_only:true",
															--[REWARD]--
																"effect_bundle:p_dreaded_force#4")
		end

		local BOOL_takeda_murakami_defeated = false
		

		-- Takeda Mission 2: Research Form
		local function takeda_intro_mission_two()
			out.ting("Takeda Mission: Research Form")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_takeda_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"takeda",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_military_core_form",
															--[REWARD]--
																"grant_unit:Cav_Missile_Bow_Cavalry_Takeda#capital")
		end

		-- Takeda Mission 3: Capture North Shinano

		local function takeda_intro_mission_three()
			out.ting("Takeda Mission: Capture North Shinano")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_takeda_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"takeda",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_north_shinano",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
		end

		local BOOL_takeda_north_shinano_captured = false
		local BOOL_takeda_mission_three_issued = false
	

	
--
-- TOKUGAWA
--
	-- MISSIONS --
	
		-- Tokugawa Mission 1: Defeat Oda Force
		local function tokugawa_intro_mission_one()
			out.ting("Tokugawa Mission: Defeat Oda Force")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_tokugawa_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"tokugawa",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"faction:oda,requires_victory:true,armies_only:true",
															--[REWARD]--
																"effect_bundle:p_call_to_arms#4")
		end

		local BOOL_tokugawa_oda_defeated = false


		-- Tokugawa Mission 2: Research Secret Police
		local function tokugawa_intro_mission_two()
			out.ting("Tokugawa Mission: Research Secret Police")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_tokugawa_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"tokugawa",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_civil_metsuke_secret_police",
															--[REWARD]--
																"grant_agent:metsuke#capital")
		end

		-- Tokugawa Mission 3: Capture Any Region
		local function tokugawa_intro_mission_three()
			out.ting("Tokugawa Mission: Capture Any Region")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_tokugawa_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"tokugawa",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
		end
		
		local BOOL_tokugawa_mission_three_issued = false
		

--
-- UESUGI --
--
	-- MISSIONS --
	
		-- Uesugi Mission 1: Crush Echigo Rebellion
		local function uesugi_intro_mission_one()
			out.ting("Uesugi Mission: Crush Echigo Rebellion")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_uesugi_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"uesugi",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_echigo",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
		end

		local BOOL_uesugi_echigo_rebellion_crushed = false


		-- Uesugi Mission 2: Research Essence of the Spirit
		local function uesugi_intro_mission_two()
			out.ting("Uesugi Mission: Research Essence of the Spirit")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_uesugi_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"uesugi",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_civil_religion_essence_of_the_spirit",
															--[REWARD]--
																"grant_unit:Inf_Heavy_Naginata_Warrior_Monks_Uesugi#capital")
		end

		-- Uesugi Mission 3: Capture Any Region
		local function uesugi_intro_mission_three()
			out.ting("Uesugi Mission: Capture Any Region")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_uesugi_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"uesugi",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_call_to_arms#4")
		end
		
		local BOOL_uesugi_mission_three_issued = false
		
		
		
--
-- DATE --
--
	-- MISSIONS --
	
		-- Date Mission 1: Crush Iwate Rebellion
		local function date_intro_mission_one()
			out.ting("Date Mission: Crush Echigo Rebellion")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_date_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"date",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_iwate",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#6")
		end

		local BOOL_date_iwate_rebellion_crushed = false


		-- Date Mission 2: Research Way Of The Sword
		local function date_intro_mission_two()
			out.ting("Date Mission: Research Way of the Sword")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_date_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"date",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_military_sword_way_of_the_sword",
															--[REWARD]--
																"grant_unit:Inf_Sword_Nodachi_Samurai_Date#capital")
																
		end


		-- Date Mission 3: Capture A Mogami Province
		local function date_intro_mission_three()
			out.ting("Date Mission: Capture A Mogami Province")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_date_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"date",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"faction:mogami",
															--[REWARD]--
																"effect_bundle:p_dreaded_force#6")
																
		end
		
		local BOOL_date_mission_three_issued = false
		
	
		
--
-- HOJO --
--

	-- MISSIONS --
	
		-- Hojo Mission 1: Defeat Ogigayatsu Force
		local function hojo_intro_mission_one()
			out.ting("Hojo Mission: Defeat Ogigayatsu Force")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_hojo_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"hojo",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"faction:ogigayatsu_uesugi,requires_victory:true,armies_only:true",
															--[REWARD]--
																"effect_bundle:p_dreaded_force#4")
		end

		local BOOL_hojo_ogigayatsu_defeated = false
											
												
		-- Hojo Mission 2: Research Strategy of Attack
		local function hojo_intro_mission_two()
			out.ting("Hojo Mission: Research Strategy of Attack")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_hojo_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"hojo",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_military_core_strategy_of_attack",
															--[REWARD]--
																"grant_unit:Art_Fire_Projecting_Mangonels_Hojo#capital")
		end

		-- Hojo Mission 3: Capture Musashi
		local function hojo_intro_mission_three()
			out.ting("Hojo Mission: Capture Musashi")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_hojo_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"hojo",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_musashi",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
		end

		local BOOL_hojo_musashi_captured = false
		local BOOL_hojo_mission_three_issued = false
		
		
--
-- MORI --
--
	-- MISSIONS --
	
		-- Mori Mission 1: Defeat Amako Force
		local function mori_intro_mission_one()
			out.ting("Mori Mission One: Defeat Amako Force")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_mori_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"mori",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"faction:amako,requires_victory:true,armies_only:true",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
		end

		local BOOL_mori_amako_defeated = false


		-- Mori Mission 2: Research Way of the Sea
		local function mori_intro_mission_two()
			out.ting("Mori Mission: Research Way of the Sea")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_mori_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"mori",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_military_naval_way_of_the_sea",
															--[REWARD]--
																"effect_bundle:p_master_shipwrights#4")
			BOOL_mori_mission_three_issued = true
		end

		-- Mori Mission 3: Capture Iwami
		local function mori_intro_mission_three()
			out.ting("Mori Mission: Capture Iwami")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_mori_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"mori",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_iwami",
															--[REWARD]--
																"effect_bundle:p_call_to_arms#4")
		end

		local BOOL_mori_iwami_captured = false
		local BOOL_mori_mission_three_issued = false

		

--
-- SHIMAZU --
--
	-- MISSIONS --
		
		-- Shimazu Mission 1: Capture Osumi Province
		local function shimazu_intro_mission_one()
			out.ting("Shimazu Mission: Capture Osumi Province")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_shimazu_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"shimazu",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_osumi",
															--[REWARD]--
																"effect_bundle:p_call_to_arms#4")
		end

		local BOOL_shimazu_osumi_captured = false


		-- Shimazu Mission 2: Research Way of the Sword
		local function shimazu_intro_mission_two()
			out.ting("Shimazu Mission: Research Way of the Sword")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_shimazu_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"shimazu",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_military_sword_way_of_the_sword",
															--[REWARD]--
																"grant_unit:Inf_Sword_Katana_Samurai_Shimazu#capital")
		end

		-- Shimazu Mission 3: Build Trade Port
		local function shimazu_intro_mission_three()
			out.ting("Shimazu Mission: Build Trade Port")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_shimazu_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"shimazu",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"building_level:SHO_Port_2_Trading_Port",
															--[REWARD]--
																"money:1000")
		end

		local BOOL_shimazu_trade_port_built = false
		local BOOL_shimazu_mission_three_issued = false


		
--
-- HATTORI --
--
	-- MISSIONS --
	
		-- Hattori Mission 1: Sabotage a Farm
		local function hattori_intro_mission_one()
			out.ting("Hattori Mission: Sabotage a Farm")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_hattori_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"iga_ninja",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_ample_supplies#4")
																
		end

		-- Hattori Mission 2: Research School of Shinobi
		local function hattori_intro_mission_two()
			out.ting("Hattori Mission: Research School of Shinobi")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_hattori_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"iga_ninja",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_civil_ninja_school_of_shinobi",
															--[REWARD]--
																"grant_unit:Inf_Special_Kisho_Ninjas_Hattori#capital")
		end

		-- Hattori Mission 3: Conquer Any Province
		local function hattori_intro_mission_three()
			out.ting("Hattori Mission: Conquer Any Province")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_hattori_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"iga_ninja",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_inspired_endeavours_global#4")
																
		end

		local BOOL_hattori_mission_three_issued = false
		
	
--
-- IKKO IKKI --
--
	-- MISSIONS --
	
		-- Ikko Mission 1: Sabotage a Farm
		local function ikko_intro_mission_one()
			out.ting("Ikko Mission: Convert Omi")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_ikko_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"ikko_ikki",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_omi",
															--[REWARD]--
																"effect_bundle:p_master_ikko_monks#4")
																
		end

		local BOOL_ikko_omi_converted = false
		local BOOL_ikko_omi_captured = false
		
		-- Ikko Mission 2: Research School of Shinobi
		local function ikko_intro_mission_two()
			out.ting("Ikko Mission: Research Essence of the Spirit")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_ikko_intro_mission_two",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"ikko_ikki",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"technology:shogun_civil_religion_essence_of_the_spirit",
															--[REWARD]--
																"grant_unit:Inf_Heavy_Naginata_Warrior_Monks_Ikko_Ikki#capital")
		end

		--Ikko Mission 3: Conquer Omi
		local function ikko_intro_mission_three()
			out.ting("Ikko Mission: Conquer Omi")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_ikko_intro_mission_three",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"ikko_ikki",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"region:jap_omi",
															--[REWARD]--
																"effect_bundle:p_wisdom_shinran_global#4")
																
		end

		local BOOL_ikko_mission_three_issued = false

--
-- OTOMO --
--
	-- MISSION ONE --
	
		-- Otomo Mission 1: Build a Chapel
		local function otomo_intro_mission_one()
			out.ting("Ikko Mission: Convert Omi")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"jap_otomo_intro_mission_one",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"otomo",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"building_level:SHO_Christian_1_Chapel",
															--[REWARD]--
																"effect_bundle:p_word_of_god_global#4")
																
		end
	
-------------------------------------------------------------------------------------------------------------------------
--
-- OTHER MISSIONS
--

local function mission_two()
	out.ting ("Mission Two - Research Tech")
	shimazu_intro_mission_two()
	chosokabe_intro_mission_two()
	oda_intro_mission_two()
	tokugawa_intro_mission_two()
	takeda_intro_mission_two()
	uesugi_intro_mission_two()
	hojo_intro_mission_two()
	date_intro_mission_two()
	mori_intro_mission_two()
	hattori_intro_mission_two()
	ikko_intro_mission_two()
end


local BOOL_mission_three_issued = false


-------------------------------------------------------------------------------------------------------------------------
--
-- SET DIFFICULTY LEVEL BOOLS
--

local BOOL_dif_easy = false
local BOOL_dif_normal = false
local BOOL_dif_hard = false
local BOOL_dif_very_hard = false


-------------------------------------------------------------------------------------------------------------------------
--
-- TECH BUTTON FLASH
--


local BOOL_tech_panel_opened = false
local BOOL_turn_two = false


-- Flash the button -- NOTE: MEANS THAT THE TECH BUTTON IS THE ONLY ONE THAT MAY THEN BE CLICKED!

local function OnPanelClosedCampaign(context)
	if conditions.IsComponentType("events", context) then
	
		if BOOL_turn_two and not BOOL_tech_panel_opened and not CampaignUI.IsMultiplayer() then
			out.ting("Flashing the tech button")
			scripting.HighlightComponent("button_tech", true)
			scripting.game_interface:add_time_trigger("trigger_remove_button_flash", 1.5)
		end
		
		if becoming_shogun_advice then
			out.ting("Triggering the becoming Shogun advice in a few seconds!")
			effect.advance_scripted_advice_thread("1113_Campaign_Advice_Becoming_Shogun_Thread", 1)
			becoming_shogun_advice = false
		end
	end
	

end



-------------------------------------------------------------------------------------------------------------------------
--
-- BECOMING SHOGUN
--

-- context.string is used to retreive the event context faction, in this case the clan who has assumed control of the shogunate.
-- Use in place of the usual "faction_key" to avoid having to make a shedload of script duplicates.

local current_shogun = "ashikaga"
local previous_shogun = "ashikaga"
local human_shogun = ""
local BOOL_ashikaga_hate_player = false

local function OnFactionBecomesShogun(context)
	out.ting (context.string .. " became shogun.")
	
	current_shogun = context.string
	
	out.ting("The outgoing shogun is the " .. previous_shogun)
	
	if conditions.FactionIsHuman(current_shogun, context) then
		out.ting("Spawning Great Guard and Nihon Maru for the " .. current_shogun)
		scripting.game_interface:create_force(--[FACTION]--
												current_shogun, 
											--[SPECIFIC ARMY LIST]--
												"Cav_Spear_Great_Guard,Cav_Spear_Yari_Cavalry,Cav_Spear_Yari_Cavalry", 
											--[COORDINATES]--	
												-44.0, -124.0, 
											--[ID]--
												"Great Guard", 
											--[USE_COMMAND_QUEUE]--
												true)
				
		scripting.game_interface:create_force(--[FACTION]--
												current_shogun, 
											--[SPECIFIC ARMY LIST]--
												"Heavy_Ship_Nihon_Maru,Light_Ship_Bow_Kobaya,Light_Ship_Bow_Kobaya",
											--[COORDINATES]--	
												-64.0, -130.5, 
											--[ID]--
												"Epic Ship", 
											--[USE_COMMAND_QUEUE]--
												true)
		
		out.ting("Giving the shogun effect bundle to the " .. current_shogun)										
		scripting.game_interface:apply_effect_bundle("s_shogun_effects", current_shogun, 0)
		human_shogun = current_shogun
		out.ting("Human shogun: " .. human_shogun)


	end

	out.ting("Taking away the shogun effect bundle from the " .. previous_shogun)		
	scripting.game_interface:remove_effect_bundle("s_shogun_effects", previous_shogun)
		
	previous_shogun = current_shogun
		
	out.ting("Therefore! current_shogun = " .. current_shogun .. "    previous_shogun = " .. VAR_previous_shogun_ID .. ", " .. previous_shogun)
end


local function OnFactionBecomesLiberationProtectorate(context)
	out.ting("LiberatedProtectorate: "..context.string)
	if context.string == "ashikaga" and human_shogun ~= "" then
		out.ting("Ashikaga reinstated.")-- Make them hate the player! That is to say: " .. human_shogun)
		BOOL_ashikaga_hate_player = true
	--	scripting.game_interface:force_declare_war("ashikaga", human_shogun)
	end
end

-------------------------------------------------------------------------------------------------------------------------
--
-- SETTLEMENT OCCUPIED EVENTS
--

local function OnSettlementOccupied(context)

	if conditions.SettlementIsLocal(context) then
		if conditions.SettlementName("settlement:jap_north_shinano:matsumoto", context) then
			out.ting("North Shinano has been taken by the player.")
			BOOL_takeda_north_shinano_captured = true
	
		elseif conditions.SettlementName("settlement:jap_musashi:edo", context) then
			out.ting("Musashi has been taken by the player.")
			BOOL_hojo_musashi_captured = true

		elseif conditions.SettlementName("settlement:jap_osumi:kokubu", context) then
			out.ting("Osumi has been taken by the player.")
			BOOL_shimazu_osumi_captured = true

		elseif conditions.SettlementName("settlement:jap_iwami:hamada", context) then
			out.ting("Iwami has been taken by the player.")
			BOOL_mori_iwami_captured = true
	
		elseif conditions.SettlementName("settlement:jap_omi:otsu", context) then
			out.ting("Omi has been taken by the player.")
			BOOL_ikko_omi_captured = true
		end
	
	elseif not conditions.SettlementIsLocal(context) then
		if conditions.SettlementName("settlement:jap_north_shinano:matsumoto", context) then
			out.ting("North Shinano has been taken by the AI.")
			BOOL_takeda_north_shinano_captured = true
	
		elseif conditions.SettlementName("settlement:jap_musashi:edo", context) then
			out.ting("Musashi has been taken by the AI.")
			BOOL_hojo_musashi_captured = true

		elseif conditions.SettlementName("settlement:jap_osumi:kokubu", context) then
			out.ting("Osumi has been taken by the AI.")
			BOOL_shimazu_osumi_captured = true

		elseif conditions.SettlementName("settlement:jap_iwami:hamada", context) then
			out.ting("Iwami has been taken by the AI.")
			BOOL_mori_iwami_captured = true
			
		elseif conditions.SettlementName("settlement:jap_tosa:kochi", context) then
			out.ting("Tosa has been taken by the AI.")
			BOOL_chosokabe_tosa_free = false
			
		end
	end
end
			
local function OnCampaignSettlementAttacked(context)
	if conditions.SettlementName("settlement:jap_tosa:kochi", context) then
		out.ting("Tosa has been attacked.")
		BOOL_chosokabe_tosa_free = false		
	end		
end


			
-------------------------------------------------------------------------------------------------------------------------
--
-- MISSION SUCCESSES
--

local function OnMissionSucceeded(context)
	out.ting("Mission Success!")
	
	if conditions.MissionName("jap_chosokabe_intro_mission_one", context) then
		out.ting("Tosa Rebellion Crushed!")
		BOOL_chosokabe_tosa_rebellion_crushed = true
	
	elseif conditions.MissionName("jap_oda_intro_mission_one", context) then
		out.ting("Owari Rebellion Crushed!")
		BOOL_oda_owari_rebellion_crushed = true
	
	elseif conditions.MissionName("jap_takeda_intro_mission_one", context) then
		out.ting("Takeda Mission One Success!")
		BOOL_takeda_murakami_defeated = true
	
	elseif conditions.MissionName("jap_tokugawa_intro_mission_one", context) then
		out.ting("Tokugawa Mission One Success!")
		BOOL_tokugawa_oda_defeated = true
	
	elseif conditions.MissionName("jap_uesugi_intro_mission_one", context) then
		out.ting("Echigo Rebellion Crushed!")
		BOOL_uesugi_echigo_rebellion_crushed = true
	
	elseif conditions.MissionName("jap_date_intro_mission_one", context) then
		out.ting("Echigo Rebellion Crushed!")
		BOOL_date_iwate_rebellion_crushed = true
	
	elseif conditions.MissionName("jap_hojo_intro_mission_one", context) then
		out.ting("Hojo Mission One Success!")
		BOOL_hojo_ogigayatsu_defeated = true
	
	elseif conditions.MissionName("jap_mori_intro_mission_one", context) then
		out.ting("Mori Mission One Success!")
		BOOL_mori_amako_defeated = true
		
	elseif conditions.MissionName("jap_shimazu_intro_mission_one", context) then
		out.ting("Shimazu Mission One Success!")
		BOOL_shimazu_osumi_captured = true
		
	elseif conditions.MissionName("jap_hattori_intro_mission_one", context) then
		out.ting("Hattori Mission One Success!")

	elseif conditions.MissionName("jap_ikko_intro_mission_one", context) then
		out.ting("Ikko Mission One Success!")
		BOOL_ikko_omi_converted = true
	end

end




-------------------------------------------------------------------------------------------------------------------------
--
-- MISSION TRIGGERS
--

local function OnTimeTrigger(context)

	if context.string == "trigger_chosokabe_intro_mission_one" then
		chosokabe_intro_mission_one()

	elseif context.string == "trigger_oda_intro_mission_one" then	
		oda_intro_mission_one()
	
	elseif context.string == "trigger_hattori_intro_mission_one" then	
		hattori_intro_mission_one()

	elseif context.string == "trigger_takeda_intro_mission_one" then
		takeda_intro_mission_one()

	elseif context.string == "trigger_tokugawa_intro_mission_one" then
		tokugawa_intro_mission_one()

	elseif context.string == "trigger_shimazu_intro_mission_one" then
		shimazu_intro_mission_one()

	elseif context.string == "trigger_uesugi_intro_mission_one" then
		uesugi_intro_mission_one()

	elseif context.string == "trigger_date_intro_mission_one" then
		date_intro_mission_one()

	elseif context.string == "trigger_hojo_intro_mission_one" then
		hojo_intro_mission_one()

	elseif context.string == "trigger_mori_intro_mission_one" then
		mori_intro_mission_one()

	elseif context.string == "trigger_ikko_intro_mission_one" then
		ikko_intro_mission_one()				

-- OTOMO START --
	elseif context.string == "trigger_otomo_intro_mission_one" then
		otomo_intro_mission_one()
-- OTOMO END --
		
		
	elseif context.string == "trigger_become_shogun_advice" then
		effect.advance_scripted_advice_thread("1113_Campaign_Advice_Becoming_Shogun_Thread", 1)


	elseif context.string == "trigger_remove_button_flash" then
		scripting.HighlightComponent("button_tech", false)
		BOOL_tech_panel_opened = true
	
	
-- INTRO CAMERA PAN TIMERS, GAPS BETWEEN ADVICE PIECES	
		
-- CHOSOKABE
	elseif context.string == "trigger_chosokabe_advice_two" then
		effect.advance_scripted_advice_thread("3001_STW2_Clan_Intro_Chosokabe_2", 1)
		scripting.game_interface:scroll_camera_with_direction(16,
												{-128.0, -142.0, 0.801, -0.46},
												{-132.0, -127.0, 1.0, -0.41},
												{-140.0, -119.0, 1.15, -0.29})
															
		camera_pan = 104
	
	elseif context.string == "trigger_chosokabe_advice_three" then
		effect.advance_scripted_advice_thread("3002_STW2_Clan_Intro_Chosokabe_3", 1)
		scripting.game_interface:scroll_camera_with_direction(12,
												{-100.0, -135.0, 0.809, -1.65},
												{-98.0, -144.0, 1.11, -5.0})
												
		camera_pan = 108
	
	
	elseif context.string == "trigger_chosokabe_advice_two_nosound" then
		if (camera_pan == 103) then
			scripting.game_interface:add_time_trigger("trigger_chosokabe_advice_two", 0.01)
			out.ting("No sound? Forwarding chosokabe_advice_two regardless.")
		end
		
	elseif context.string == "trigger_chosokabe_advice_three_nosound" then
		if (camera_pan == 107) then
			scripting.game_interface:add_time_trigger("trigger_chosokabe_advice_three", 0.01)
			out.ting("No sound? Forwarding chosokabe_advice_three regardless.")
		end
		
-- ODA
	elseif context.string == "trigger_oda_advice_two" then
		effect.advance_scripted_advice_thread("3004_STW2_Clan_Intro_Oda_2", 1)
		scripting.game_interface:scroll_camera_with_direction(16,
												{-12.0, -131.0, 0.859, 1.27},
												{-8.0, -141.0, 1.0, 2.0},
												{-3.0, -147.0, 1.15, -0.62})
															
		camera_pan = 114
	
	elseif context.string == "trigger_oda_advice_three" then
		effect.advance_scripted_advice_thread("3005_STW2_Clan_Intro_Oda_3", 1)
		scripting.game_interface:scroll_camera_with_direction(13,
												{-7.9, -121.0, 1.149, -0.25},
												{-25.0, -146.0, 0.95, -1.43},
												{-26.0, -157.0, 1.15, -0.93})
												
		camera_pan = 118
		
	elseif context.string == "trigger_oda_advice_two_nosound" then
		if (camera_pan == 113) then
			scripting.game_interface:add_time_trigger("trigger_oda_advice_two", 0.01)
			out.ting("No sound? Forwarding oda_advice_two regardless.")
		end
		
	elseif context.string == "trigger_oda_advice_three_nosound" then
		if (camera_pan == 117) then
			scripting.game_interface:add_time_trigger("trigger_oda_advice_three", 0.01)
			out.ting("No sound? Forwarding oda_advice_three regardless.")
		end		
		
-- UESUGI	
	elseif context.string == "trigger_uesugi_advice_two" then
		effect.advance_scripted_advice_thread("3007_STW2_Clan_Intro_Uesugi_2", 1)
		scripting.game_interface:scroll_camera_with_direction(9,
												{76.0, -82.0, 0.861, 0.53},
												{33.0, -82.3, 1.02, -1.83})
															
		camera_pan = 124
	
	elseif context.string == "trigger_uesugi_advice_three" then
		effect.advance_scripted_advice_thread("3008_STW2_Clan_Intro_Uesugi_3", 1)
		scripting.game_interface:scroll_camera_with_direction(35,
												{118.8, -90.0, 1.149, -7.5},	
												{76.0, -116.0, 0.97, -8.2},
												{-13.0, -136.0, 0.7, -7.0},
												{34.0, -107.0, 0.85, -6.5},
												{79.0, -81.0, 1.1, -6.28})
												
		camera_pan = 128
		
	elseif context.string == "trigger_uesugi_advice_two_nosound" then
		if (camera_pan == 123) then
			scripting.game_interface:add_time_trigger("trigger_uesugi_advice_two", 0.01)
			out.ting("No sound? Forwarding uesugi_advice_two regardless.")
		end
		
	elseif context.string == "trigger_uesugi_advice_three_nosound" then
		if (camera_pan == 127) then
			scripting.game_interface:add_time_trigger("trigger_uesugi_advice_three", 0.01)
			out.ting("No sound? Forwarding uesugi_advice_three regardless.")
		end			
		
-- DATE		
	elseif context.string == "trigger_date_advice_two" then
		effect.advance_scripted_advice_thread("3010_STW2_Clan_Intro_Date_2", 1)
		scripting.game_interface:scroll_camera_with_direction(30,
												{186.0, -27.0, 1.149, -0.54},
												{209.0, -10.0, 0.8, -2.18},
												{192.0, 9.0, 1.0, -2.44},
												{165.0, -3.5, 1.15, -1.96})
															
		camera_pan = 132
	
	elseif context.string == "trigger_date_advice_three" then
		effect.advance_scripted_advice_thread("3011_STW2_Clan_Intro_Date_3", 1)
		scripting.game_interface:scroll_camera_with_direction(14,
												{165.0, -3.5, 1.149, -1.96},	
												{171.0, -17.0, 0.995, -1.67},
												{166.0, -64.0, 1.15, -2.83})
												
		camera_pan = 134
		
	elseif context.string == "trigger_date_advice_two_nosound" then
		if (camera_pan == 131) then
			scripting.game_interface:add_time_trigger("trigger_date_advice_two", 0.01)
			out.ting("No sound? Forwarding date_advice_two regardless.")
		end
		
	elseif context.string == "trigger_date_advice_three_nosound" then
		if (camera_pan == 133) then
			scripting.game_interface:add_time_trigger("trigger_date_advice_three", 0.01)
			out.ting("No sound? Forwarding date_advice_three regardless.")
		end			
				
-- HOJO
	elseif context.string == "trigger_hojo_advice_two" then
		effect.advance_scripted_advice_thread("3013_STW2_Clan_Intro_Hojo_2", 1)
		scripting.game_interface:scroll_camera_with_direction(11,
												{75.0, -157.0, 1.149, 0.07},
												{48, -151.0, 0.95, -0.00},
												{31, -157.0, 1.15, -0.9})
															
		camera_pan = 142
	
	elseif context.string == "trigger_hojo_advice_three" then
		effect.advance_scripted_advice_thread("3014_STW2_Clan_Intro_Hojo_3", 1)
		scripting.game_interface:scroll_camera_with_direction(28,
												{45, -148.0, 0.881, -1.27},	
												{-20.0, -117.0, 0.8, -1.5},	
												{-5.0, -144.0, 0.9, 0.0},
												{57.0, -157.0, 1.0, 0.0})
												
		camera_pan = 146

	elseif context.string == "trigger_hojo_advice_two_nosound" then
		if (camera_pan == 141) then
			scripting.game_interface:add_time_trigger("trigger_hojo_advice_two", 0.01)
			out.ting("No sound? Forwarding hojo_advice_two regardless.")
		end
		
	elseif context.string == "trigger_hojo_advice_three_nosound" then
		if (camera_pan == 145) then
			scripting.game_interface:add_time_trigger("trigger_hojo_advice_three", 0.01)
			out.ting("No sound? Forwarding hojo_advice_three regardless.")
		end			
			
-- MORI
	elseif context.string == "trigger_mori_advice_two" then
		effect.advance_scripted_advice_thread("3016_STW2_Clan_Intro_Mori_2", 1)
		scripting.game_interface:scroll_camera_with_direction(8,
												{-150.0, -95.0, 1.051, -0.99},
												{-139.0, -77.0, 1.15, -2.0})
															
		camera_pan = 152
	
	elseif context.string == "trigger_mori_advice_three" then
		effect.advance_scripted_advice_thread("3017_STW2_Clan_Intro_Mori_3", 1)
		scripting.game_interface:scroll_camera_with_direction(30,
												{-129.0, -103.0, 1.49, -5.0},	
												{-87.0, -104.0, 1.0, -4.0},	
												{-76.0, -142.0, 0.8, -5.8},
												{-153.0, -96.0, 1.1, -6.28})
												
		camera_pan = 156

	elseif context.string == "trigger_mori_advice_two_nosound" then
		if (camera_pan == 151) then
			scripting.game_interface:add_time_trigger("trigger_mori_advice_two", 0.01)
			out.ting("No sound? Forwarding mori_advice_two regardless.")
		end
		
	elseif context.string == "trigger_mori_advice_three_nosound" then
		if (camera_pan == 155) then
			scripting.game_interface:add_time_trigger("trigger_mori_advice_three", 0.01)
			out.ting("No sound? Forwarding mori_advice_three regardless.")
		end		
		
-- HATTORI
	elseif context.string == "trigger_hattori_advice_two" then
		effect.advance_scripted_advice_thread("3019_STW2_Clan_Intro_Hattori_2", 1)
		scripting.game_interface:scroll_camera_with_direction(15,
												{-33.0, -119.0, 0.749, 3.6},
												{-45.0, -124.0, 1.15, 5.5})
															
		camera_pan = 164
	
	elseif context.string == "trigger_hattori_advice_three" then
		effect.advance_scripted_advice_thread("3020_STW2_Clan_Intro_Hattori_3", 1)
		scripting.game_interface:scroll_camera_with_direction(35,
												{-32.0, -113.0, 1.149, 5.5},	
												{-22.0, -131.0, 1.15, 3.5},	
												{-20.0, -152.0, 1.1, 4.4},
												{-35.0, -149.0, 1.0, 7.0},
												{-39.0, -138.0, 1.1, 6.28})
												
		camera_pan = 168
	
	elseif context.string == "trigger_hattori_advice_two_nosound" then
		if (camera_pan == 163) then
			scripting.game_interface:add_time_trigger("trigger_hattori_advice_two", 0.01)
			out.ting("No sound? Forwarding hattori_advice_two regardless.")
		end
		
	elseif context.string == "trigger_hattori_advice_three_nosound" then
		if (camera_pan == 167) then
			scripting.game_interface:add_time_trigger("trigger_hattori_advice_three", 0.01)
			out.ting("No sound? Forwarding hattori_advice_three regardless.")
		end			
		
-- TAKEDA
	elseif context.string == "trigger_takeda_advice_two" then
		effect.advance_scripted_advice_thread("3022_STW2_Clan_Intro_Takeda_2", 1)
		scripting.game_interface:scroll_camera_with_direction(16,
												{42.0, -136.0, 1.149, 0.43},
												{48.0, -127.0, 0.95, -1.48},
												{37.0, -109.0, 1.15, -0.95})
															
		camera_pan = 172
	
	elseif context.string == "trigger_takeda_advice_three" then
		effect.advance_scripted_advice_thread("3023_STW2_Clan_Intro_Takeda_3", 1)
		scripting.game_interface:scroll_camera_with_direction(45,
												{55.0, -158.0, 1.149, -5.5},
												{60.0, -143.0, 0.95, -3.5},
												{-29.0, -124.0, 0.75, -1.5},
												{30.0, -118.0, 0.7, -0.64},
												{44.5, -137.0, 1.1, 0.0})
															
		camera_pan = 178		

	elseif context.string == "trigger_takeda_advice_two_nosound" then
		if (camera_pan == 171) then
			scripting.game_interface:add_time_trigger("trigger_takeda_advice_two", 0.01)
			out.ting("No sound? Forwarding takeda_advice_two regardless.")
		end
		
	elseif context.string == "trigger_takeda_advice_three_nosound" then
		if (camera_pan == 177) then
			scripting.game_interface:add_time_trigger("trigger_takeda_advice_three", 0.01)
			out.ting("No sound? Forwarding takeda_advice_three regardless.")
		end		
		
-- SHIMAZU
	elseif context.string == "trigger_shimazu_advice_two" then
		effect.advance_scripted_advice_thread("3025_STW2_Clan_Intro_Shimazu_2", 1)
		scripting.game_interface:scroll_camera_with_direction(19,
												{-248.0, -164.0, 1.149, -0.02},
												{-241.0, -170.0, 1.0, 0.6},
												{-235.0, -166.0, 1.15, -1.0})
															
		camera_pan = 182
	
	elseif context.string == "trigger_shimazu_advice_three" then
		effect.advance_scripted_advice_thread("3026_STW2_Clan_Intro_Shimazu_3", 1)
		scripting.game_interface:scroll_camera_with_direction(36,
												{-218.0, -139.0, 0.681, 0},
												{-123.0, -109.0, 0.9, 1.8},
												{-140.0, -156.0, 0.75, -0.17},
												{-249.0, -165.0, 1.0, 0.0})
															
		camera_pan = 188	

	elseif context.string == "trigger_shimazu_advice_two_nosound" then
		if (camera_pan == 181) then
			scripting.game_interface:add_time_trigger("trigger_shimazu_advice_two", 0.01)
			out.ting("No sound? Forwarding shimazu_advice_two regardless.")
		end
		
	elseif context.string == "trigger_shimazu_advice_three_nosound" then
		if (camera_pan == 187) then
			scripting.game_interface:add_time_trigger("trigger_shimazu_advice_three", 0.01)
			out.ting("No sound? Forwarding shimazu_advice_three regardless.")
		end				
		
-- TOKUGAWA
	elseif context.string == "trigger_tokugawa_advice_two" then
		effect.advance_scripted_advice_thread("3028_STW2_Clan_Intro_Tokugawa_2", 1)
		scripting.game_interface:scroll_camera_with_direction(8,
												{-10.0, -142.0, 0.861, 1.34},
												{-11.0, -129.0, 1.15, -0.12})
															
		camera_pan = 194
	
	elseif context.string == "trigger_tokugawa_advice_three" then
		effect.advance_scripted_advice_thread("3029_STW2_Clan_Intro_Tokugawa_3", 1)
		scripting.game_interface:scroll_camera_with_direction(45,
												{17.1, -133.1, 1.150, 1.47},
												{14.0, -141.0, 1.08, 1.05},
												{8.0, -156.0, 1.00, -0.0},
												{-18.0, -133.0, 0.73, -1.21},
												{-43.5, -141.2, 0.73, 0.2},
												{-5.5, -145.3, 1.1, 0.0})
															
		camera_pan = 198	
		
	elseif context.string == "trigger_tokugawa_advice_two_nosound" then
		if (camera_pan == 193) then
			scripting.game_interface:add_time_trigger("trigger_tokugawa_advice_two", 0.01)
			out.ting("No sound? Forwarding tokugawa_advice_two regardless.")
		end
		
	elseif context.string == "trigger_tokugawa_advice_three_nosound" then
		if (camera_pan == 197) then
			scripting.game_interface:add_time_trigger("trigger_tokugawa_advice_three", 0.01)
			out.ting("No sound? Forwarding tokugawa_advice_three regardless.")
		end		
	
-- IKKO IKKI
	elseif context.string == "trigger_ikko_advice_two" then
		effect.advance_scripted_advice_thread("3031_STW2_Clan_Intro_Ikko_Ikki_2", 1)
		scripting.game_interface:scroll_camera_with_direction(8,
												{-14.7, -91.1, 1.101, 0.76},
												{-5.8, -87.8, 0.85, -0.43})
															
		camera_pan = 202
	
	elseif context.string == "trigger_ikko_advice_three" then
		effect.advance_scripted_advice_thread("3032_STW2_Clan_Intro_Ikko_Ikki_3", 1)
		scripting.game_interface:scroll_camera_with_direction(33,
												{16.34, -77.46, 1.001, 1.18},
												{-6.21, -96.0, 0.71, 2.05},
												{-62.9, -121.0, 0.71, 2.2},
												{-28.86, -136.6, 0.71, 0.50},
												{-16.0, -89.0, 1.0, 0.0})
															
		camera_pan = 206	

	elseif context.string == "trigger_ikko_advice_two_nosound" then
		if (camera_pan == 201) then
			scripting.game_interface:add_time_trigger("trigger_ikko_advice_two", 0.01)
			out.ting("No sound? Forwarding ikko_advice_two regardless.")
		end
		
	elseif context.string == "trigger_ikko_advice_three_nosound" then
		if (camera_pan == 205) then
			scripting.game_interface:add_time_trigger("trigger_ikko_advice_three", 0.01)
			out.ting("No sound? Forwarding ikko_advice_three regardless.")
		end		
		
	end
end





-------------------------------------------------------------------------------------------------------------------------
--
-- CLAN INTROS AND CAMERA PANS
--

-- TRIGGER A PAN BASED UPON A PIECE OF ADVICE TRIGGERING

local function OnAdviceIssued(context)

	-- 3000_STW2_Clan_Intro_Chosokabe_1
	if conditions.AdviceJustDisplayed("2139658104", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(20,	
												{-142.0, -152.0, 0.68, 0.5},
												{-133.0, -137.0, 1.15, 0.2})

		camera_pan = 100
	
	-- 3003_STW2_Clan_Intro_Oda_1
	elseif conditions.AdviceJustDisplayed("2139658125", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(25,	
												{-23.0, -156.0, 0.68, 0.69},
												{-11.0, -132.0, 1.15, 0.27})
			
		camera_pan = 110
	
	-- 3006_STW2_Clan_Intro_Uesugi_1
	elseif conditions.AdviceJustDisplayed("2139658142", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(23,
												{76.4, -106.0, 0.92, 0.047},
												{77.7, -96.9, 1.0, -0.16},
												{80.0, -78.0, 1.15, -0.1})
			
		camera_pan = 120
	

	-- 3009_STW2_Clan_Intro_Date_1
	elseif conditions.AdviceJustDisplayed("2139658158", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
	
		scripting.game_interface:scroll_camera_with_direction(32,	
												{198.0, -34.0, 0.676, -0.98},
												{187.0, -33.0, 0.94, -0.05},
												{186.0, -27.0, 1.15, -0.54})
															
		camera_pan = 130
	
	
	-- 3012_STW2_Clan_Intro_Hojo_1
	elseif conditions.AdviceJustDisplayed("2139658169", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(31,
												{57.0, -165.0, 0.7, -0.36},
												{50.0, -165.0, 0.85, -0.03},
												{59.0, -158.0, 1.1, 0.85},
												{75.0, -157.0, 1.15, 0.07})
			
		camera_pan = 140
		
	-- 3015_STW2_Clan_Intro_Mori_1
	elseif conditions.AdviceJustDisplayed("2139658177", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(45,	
												{-155.0, -112.0, 0.8, 0.02},
												{-151.0, -96.0, 1.0, -0.14},
												{-154.0, -86.0, 1.1, 1.2},
												{-145.0, -77.0, 1.125, 1.0},
												{-132.0, -72.0, 1.125, 1.0},
												{-125.0, -79.0, 1.0, 0.6},
												{-150.0, -95.0, 1.05, -0.99})
			
		camera_pan = 150
		
	-- 3018_STW2_Clan_Intro_Hattori_1
	elseif conditions.AdviceJustDisplayed("2139658185", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		
		scripting.game_interface:scroll_camera_with_direction(18,	
												{-41.0, -158.0, 0.676, 0.19},
												{-39.0, -144.0, 1.1, 0.49},
												{-40.0, -135.0, 1.15, 1.66})
			
		camera_pan = 160
		
	-- 3021_STW2_Clan_Intro_Takeda_1
	elseif conditions.AdviceJustDisplayed("2139658201", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(22,	
												{39.0, -157.0, 0.8, 0.26},
												{38.0, -150.0, 1.0, -0.05},
												{42.0, -136.0, 1.15, 0.43})
			
		camera_pan = 170
		
	-- 3024_STW2_Clan_Intro_Shimazu_1
	elseif conditions.AdviceJustDisplayed("2139658215", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)

		scripting.game_interface:scroll_camera_with_direction(49,
												{-248.0, -162.0, 1.0, -0.87},
												{-230.0, -189.0, 0.8, -1.63},
												{-249.0, -204.0, 1.0, -1.04},
												{-248.0, -164.0, 1.15, -0.02})
		camera_pan = 180
		
	-- 3027_STW2_Clan_Intro_Tokugawa_1
	elseif conditions.AdviceJustDisplayed("2139658236", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(20,	
												{4.0, -160.0, 0.88, -0.49},
												{3.0, -159.0, 0.93, -0.22},
												{-8.1, -145.7, 1.15, 0.52})
			
		camera_pan = 190	
		
	-- 3030_STW2_Clan_Intro_Ikko_Ikki_1
	elseif conditions.AdviceJustDisplayed("2139658512", context) and not CampaignUI.IsMultiplayer() then
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(34,	
												{-6.5, -94.4, 0.65, -0.41},
												{-35.0, -136.5, 0.87, 0.06},
												{-25.0, -104.8, 1.1, 0.57},
												{-14.7, -91.1, 1.1, 0.76})
			
		camera_pan = 200	


	-- START OTOMO PAN GUBBINS --
	-- 4000_STW2_Clan_Intro_Otomo
	elseif conditions.AdviceJustDisplayed("2139659780", context) and not CampaignUI.IsMultiplayer() then
		CampaignUI.ToggleScreenCover(false)
		panning = true
		scripting.game_interface:set_zoom_limit(1.19, 0.676)
		scripting.game_interface:scroll_camera_with_direction(22,	
												{-254.0, -212.0, 1.15, 0.58},
												{-224.0, -190.0, 1.00, 0.37},
												{-193.0, -157.0, 0.718, -0.31},
												{-192.0, -123.0, 0.95, 0.0})
			
		camera_pan = 210
		
	-- END OTOMO PAN GUBBINS
		
	end	
end

-- TRIGGER A PIECE OF ADVICE BASED ON A PREVIOUS PIECE OF ADVICE ENDING

local function OnAdviceFinished(context)

-- CHOSOKABE --
	if (camera_pan == 103) then
		scripting.game_interface:add_time_trigger("trigger_chosokabe_advice_two", 0.5)
		
	elseif (camera_pan == 107) then
		scripting.game_interface:add_time_trigger("trigger_chosokabe_advice_three", 0.2)
	
-- ODA --
	elseif (camera_pan == 113) then
		scripting.game_interface:add_time_trigger("trigger_oda_advice_two", 0.5)
		
	elseif (camera_pan == 117) then
		scripting.game_interface:add_time_trigger("trigger_oda_advice_three", 0.5)
	
-- UESUGI --
	elseif (camera_pan == 123) then
		scripting.game_interface:add_time_trigger("trigger_uesugi_advice_two", 0.5)
		
	elseif (camera_pan == 127) then
		scripting.game_interface:add_time_trigger("trigger_uesugi_advice_three", 0.2)
		

-- DATE --
	elseif (camera_pan == 131) then
		scripting.game_interface:add_time_trigger("trigger_date_advice_two", 0.5)
		
	elseif (camera_pan == 133) then
		scripting.game_interface:add_time_trigger("trigger_date_advice_three", 0.2)
		
-- HOJO --
	elseif (camera_pan == 141) then
		scripting.game_interface:add_time_trigger("trigger_hojo_advice_two", 0.5)
		
	elseif (camera_pan == 145) then
		scripting.game_interface:add_time_trigger("trigger_hojo_advice_three", 1.0)

-- MORI --
	elseif (camera_pan == 151) then
		scripting.game_interface:add_time_trigger("trigger_mori_advice_two", 1.0)
		
	elseif (camera_pan == 155) then
		scripting.game_interface:add_time_trigger("trigger_mori_advice_three", 1.0)

-- HATTORI --
	elseif (camera_pan == 163) then
		scripting.game_interface:add_time_trigger("trigger_hattori_advice_two", 0.5)
		
	elseif (camera_pan == 167) then
		scripting.game_interface:add_time_trigger("trigger_hattori_advice_three", 0.5)

-- TAKEDA
	elseif (camera_pan == 171) then
		scripting.game_interface:add_time_trigger("trigger_takeda_advice_two", 1.0)
		
	elseif (camera_pan == 177) then
		scripting.game_interface:add_time_trigger("trigger_takeda_advice_three", 0.5)
		
-- SHIMAZU --
	elseif (camera_pan == 181) then
		scripting.game_interface:add_time_trigger("trigger_shimazu_advice_two", 1.0)
		
	elseif (camera_pan == 187) then
		scripting.game_interface:add_time_trigger("trigger_shimazu_advice_three", 0.5)
	
-- TOKUGAWA --
	elseif (camera_pan == 193) then
		scripting.game_interface:add_time_trigger("trigger_tokugawa_advice_two", 1.0)
		
	elseif (camera_pan == 197) then
		scripting.game_interface:add_time_trigger("trigger_tokugawa_advice_three", 1.0)
		
-- IKKO IKKI --
	elseif (camera_pan == 201) then
		scripting.game_interface:add_time_trigger("trigger_ikko_advice_two", 1.0)
		
	elseif (camera_pan == 205) then
		scripting.game_interface:add_time_trigger("trigger_ikko_advice_three", 1.0)
		
		
	end
end


-- TRIGGER A CAMERA PAN BASED UPON A PREVIOUS CAMERA PAN ENDING

local function OnCameraMoverFinished(context)

	-- 3000_STW2_Clan_Intro_Chosokabe_1
	if camera_pan == 100 then
		scripting.game_interface:scroll_camera_with_direction(5,
												{-133.0, -137.0, 1.15, 0.2},
												{-133.0, -137.0, 1.149, 0.2})
		
		camera_pan = 101
	
	elseif camera_pan == 101 then
		scripting.game_interface:scroll_camera_with_direction(10,
												{-133.0, -137.0, 1.149, 0.2},
												{-140.0, -139.0, 1.0, -0.52},
												{-128.0, -142.0, 0.8, -0.46})
		
		camera_pan = 102

	elseif camera_pan == 102 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-128.0, -142.0, 0.8, -0.46},
												{-128.0, -142.0, 0.801, -0.46})
		
		camera_pan = 103
		scripting.game_interface:add_time_trigger("trigger_chosokabe_advice_two_nosound", 20.0)
		
	elseif camera_pan == 104 then
		scripting.game_interface:scroll_camera_with_direction(5,
												{-140.0, -119.0, 1.15, -0.29},
												{-140.0, -119.0, 1.149, -0.29})
		
		camera_pan = 105
		
	elseif camera_pan == 105 then
		scripting.game_interface:scroll_camera_with_direction(23,
												{-140.0, -119.0, 1.149, -0.29},
												{-125.0, -116.0, 0.73, -0.85},
												{-100.0, -135.0, 0.81, -1.65})
		
		camera_pan = 106

	elseif camera_pan == 106 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-100.0, -135.0, 0.81, -1.65},
												{-100.0, -135.0, 0.809, -1.65})
		
		camera_pan = 107
		scripting.game_interface:add_time_trigger("trigger_chosokabe_advice_three_nosound", 20.0)

	elseif camera_pan == 108 then
		scripting.game_interface:scroll_camera_with_direction(7,
												{-98.0, -144.0, 1.11, -5.0},
												{-98.0, -144.0, 1.111, -5.0})
		
		camera_pan = 109
		
	elseif camera_pan == 109 then
		scripting.game_interface:scroll_camera_with_direction(32,
												{-98.0, -144.0, 1.111, -5.0},
												{-65.0, -135.0, 0.84, -5.5},
												{-125.0, -153.0, 0.68, -6.5},
												{-135.0, -140.0, 1.0, -6.28})

		
		camera_pan = 1010	
		
	elseif camera_pan == 1010 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.0)
		CampaignUI.SetCameraHeading(-6.28)
		CampaignUI.SetCameraTargetInstant(-135.0, -140.0)
		camera_pan = 0
		
		scripting.game_interface:add_time_trigger("trigger_chosokabe_intro_mission_one", 0.01)
			

			
	-- 3003_STW2_Clan_Intro_Oda_1
	elseif camera_pan == 110 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-11.0, -132.0, 1.15, 0.27},
												{-11.0, -132.0, 1.149, 0.27})

		
		camera_pan = 111	

	elseif camera_pan == 111 then
		scripting.game_interface:scroll_camera_with_direction(9,
												{-11.0, -132.0, 1.15, 0.27},
												{-12.0, -131.0, 0.86, 1.27})

		
		camera_pan = 112	
		
	elseif camera_pan == 112 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-12.0, -131.0, 0.86, 1.27},
												{-12.0, -131.0, 0.859, 1.27})

		
		camera_pan = 113
		scripting.game_interface:add_time_trigger("trigger_oda_advice_two_nosound", 20.0)

	elseif camera_pan == 114 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-3.0, -147.0, 1.15, -0.62},
												{-3.0, -147.0, 1.149, -0.62})

		
		camera_pan = 115

	elseif camera_pan == 115 then
		scripting.game_interface:scroll_camera_with_direction(16,
												{-3.0, -147.0, 1.149, -0.62},
												{1.8, -135.0, 1.0, -0.40},
												{1.15, -128.0, 1.0, -0.62},
												{-7.9, -121.0, 1.15, -0.25})

		
		camera_pan = 116

	elseif camera_pan == 116 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-7.9, -121.0, 1.15, -0.25},
												{-7.9, -121.0, 1.149, -0.25})

		
		camera_pan = 117
		scripting.game_interface:add_time_trigger("trigger_oda_advice_three_nosound", 20.0)
		
	elseif camera_pan == 118 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-26.0, -157.0, 1.15, -0.93},
												{-26.0, -157.0, 1.149, -0.93})

		
		camera_pan = 119

	elseif camera_pan == 119 then
		scripting.game_interface:scroll_camera_with_direction(34,
												{-26.0, -157.0, 1.149, -0.93},
												{-50.0, -126.0, 0.68, 0.6},
												{-12.0, -133.0, 1.1, 0.0})

		
		camera_pan = 1110
		
	elseif camera_pan == 1110 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.1)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(-12.0, -133.0)
		camera_pan = 0

		scripting.game_interface:add_time_trigger("trigger_oda_intro_mission_one", 0.01)
		
-- UESUGI --
	elseif camera_pan == 120 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{80.0, -78.0, 1.15, -0.1},
												{80.0, -78.0, 1.149, -0.1})
		
		camera_pan = 121

	elseif camera_pan == 121 then
		scripting.game_interface:scroll_camera_with_direction(12,
												{80.0, -78.0, 1.149, -0.1},
												{76.0, -82.0, 0.86, 0.53})
		
		camera_pan = 122

	elseif camera_pan == 122 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{76.0, -82.0, 0.86, 0.53},
												{76.0, -82.0, 0.861, 0.53})
		
		camera_pan = 123
		scripting.game_interface:add_time_trigger("trigger_uesugi_advice_two_nosound", 20.0)

	elseif camera_pan == 124 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{33.0, -82.3, 1.02, -1.83},
												{33.0, -82.3, 1.021, -1.83})
		
		camera_pan = 125

	elseif camera_pan == 125 then
		scripting.game_interface:scroll_camera_with_direction(33,
												{33.0, -82.3, 1.021, -1.83},
												{64.0, -89.0, 0.95, -3.5},
												{77.2, -64.0, 0.90, -6.0},
												{118.8, -90.0, 1.15, -7.5})
		
		camera_pan = 126

	elseif camera_pan == 126 then
		scripting.game_interface:scroll_camera_with_direction(5,
												{118.8, -90.0, 1.15, -7.5},
												{118.8, -90.0, 1.149, -7.5})
		
		camera_pan = 127
		scripting.game_interface:add_time_trigger("trigger_uesugi_advice_three_nosound", 20.0)
		
	elseif camera_pan == 128 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.1)
		CampaignUI.SetCameraHeading(-6.28)
		CampaignUI.SetCameraTargetInstant(79.0, -81.0)
		camera_pan = 0

		scripting.game_interface:add_time_trigger("trigger_uesugi_intro_mission_one", 0.01)
	
-- DATE --
	elseif camera_pan == 130 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{186.0, -27.0, 1.15, -0.54},
												{186.0, -27.0, 1.149, -0.54})
		
		camera_pan = 131
		scripting.game_interface:add_time_trigger("trigger_date_advice_two_nosound", 20.0)
		
	elseif camera_pan == 132 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{165.0, -3.5, 1.15, -1.96},
												{165.0, -3.5, 1.149, -1.96})
		
		camera_pan = 133
		scripting.game_interface:add_time_trigger("trigger_date_advice_three_nosound", 20.0)

	elseif camera_pan == 134 then
		scripting.game_interface:scroll_camera_with_direction(7,
												{166.0, -64.0, 1.15, -2.83},
												{166.0, -64.0, 1.149, -2.83})
		
		camera_pan = 135	
		
	elseif camera_pan == 135 then
		scripting.game_interface:scroll_camera_with_direction(20,
												{166.0, -64.0, 1.149, -2.83},
												{140.0, -78.0, 0.7, -1.88},
												{185.0, -34.0, 1.0, 0.0})
		
		camera_pan = 136
		
	elseif camera_pan == 136 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.0)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(185.0, -34.0)
		camera_pan = 0
	
		scripting.game_interface:add_time_trigger("trigger_date_intro_mission_one", 0.01)
	
	
-- HOJO --
	elseif camera_pan == 140 then
		scripting.game_interface:scroll_camera_with_direction(8,
												{75.0, -157.0, 1.15, 0.07},
												{75.0, -157.0, 1.149, 0.07})
		
		camera_pan = 141
		scripting.game_interface:add_time_trigger("trigger_hojo_advice_two_nosound", 20.0)

	elseif camera_pan == 142 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{31, -157.0, 1.15, -0.9},
												{31, -157.0, 1.149, -0.9})
		
		camera_pan = 143	
		
	elseif camera_pan == 143 then
		scripting.game_interface:scroll_camera_with_direction(21,
												{31, -157.0, 1.149, -0.9},
												{42, -138.0, 1.0, 0.52},
												{45, -148.0, 0.88, -1.27})
		
		camera_pan = 144	
		
	elseif camera_pan == 144 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{45, -148.0, 0.88, -1.27},
												{45, -148.0, 0.881, -1.27})
		
		camera_pan = 145	
		scripting.game_interface:add_time_trigger("trigger_hojo_advice_three_nosound", 20.0)
		
	elseif camera_pan == 146 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.0)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(57.0, -157.0)
		camera_pan = 0
		
		scripting.game_interface:add_time_trigger("trigger_hojo_intro_mission_one", 0.01)
	
-- MORI --
	elseif camera_pan == 150 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-150.0, -95.0, 1.05, -0.99},
												{-150.0, -95.0, 1.051, -0.99})
		
		camera_pan = 151	
		scripting.game_interface:add_time_trigger("trigger_mori_advice_two_nosound", 20.0)
	
	elseif camera_pan == 152 then
		scripting.game_interface:scroll_camera_with_direction(7,
												{-139.0, -77.0, 1.15, -2.0},
												{-139.0, -77.0, 1.149, -2.0})
		
		camera_pan = 153	

	elseif camera_pan == 153 then
		scripting.game_interface:scroll_camera_with_direction(28,
												{-139.0, -77.0, 1.149, -2.0},
												{-168.0, -89.0, 0.95, -3.5},
												{-169.0, -99.0, 1.1, -4.0},
												{-144.0, -98.0, 1.15, -4.5},
												{-129.0, -103.0, 1.15, -5.0})
		
		camera_pan = 154	

	elseif camera_pan == 154 then
		scripting.game_interface:scroll_camera_with_direction(7,
												{-129.0, -103.0, 1.15, -5.0},
												{-129.0, -103.0, 1.49, -5.0})
		
		camera_pan = 155	
		scripting.game_interface:add_time_trigger("trigger_mori_advice_three_nosound", 20.0)
		
	elseif camera_pan == 156 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.1)
		CampaignUI.SetCameraHeading(-6.28)
		CampaignUI.SetCameraTargetInstant(-153.0, -96.0)
		camera_pan = 0
	
		scripting.game_interface:add_time_trigger("trigger_mori_intro_mission_one", 0.01)
	
--HATTORI
	elseif camera_pan == 160 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-40.0, -135.0, 1.15, 1.66},
												{-40.0, -135.0, 1.149, 1.66})
		
		camera_pan = 161	

	elseif camera_pan == 161 then
		scripting.game_interface:scroll_camera_with_direction(20,
												{-40.0, -135.0, 1.149, 1.66},
												{-33.0, -119.0, 0.75, 3.6})
		
		camera_pan = 162			
	
	elseif camera_pan == 162 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-33.0, -119.0, 0.75, 3.6},
												{-33.0, -119.0, 0.749, 3.6})
		
		camera_pan = 163
		scripting.game_interface:add_time_trigger("trigger_hattori_advice_two_nosound", 20.0)
		
	elseif camera_pan == 164 then
		scripting.game_interface:scroll_camera_with_direction(7,
												{-45.0, -124.0, 1.15, 5.5},
												{-45.0, -124.0, 1.149, 5.5})
		
		camera_pan = 165		
		
	elseif camera_pan == 165 then
		scripting.game_interface:scroll_camera_with_direction(20,
												{-45.0, -124.0, 1.149, 5.5},
												{-35.0, -135.0, 0.9, 4.0},
												{-32.0, -113.0, 1.15, 5.5})
		
		camera_pan = 166			

	elseif camera_pan == 166 then
		scripting.game_interface:scroll_camera_with_direction(5,
												{-32.0, -113.0, 1.15, 5.5},
												{-32.0, -113.0, 1.149, 5.5})
		
		camera_pan = 167	
		scripting.game_interface:add_time_trigger("trigger_hattori_advice_three_nosound", 20.0)
		
	elseif camera_pan == 168 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.1)
		CampaignUI.SetCameraHeading(6.28)
		CampaignUI.SetCameraTargetInstant(-39.0, -138.0)
		camera_pan = 0
		scripting.game_interface:add_time_trigger("trigger_hattori_intro_mission_one", 0.01)
	
-- 3021_STW2_Clan_Intro_Takeda_1
	elseif camera_pan == 170 then
		scripting.game_interface:scroll_camera_with_direction(5,
												{42.0, -136.0, 1.15, 0.43},
												{42.0, -136.0, 1.149, 0.43})
		
		camera_pan = 171	
		scripting.game_interface:add_time_trigger("trigger_takeda_advice_two_nosound", 20.0)	
	
	elseif camera_pan == 172 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{37.0, -109.0, 1.15, -0.95},
												{37.0, -109.0, 1.149, -0.95})
		
		camera_pan = 173		

	elseif camera_pan == 173 then
		scripting.game_interface:scroll_camera_with_direction(10,
												{37.0, -109.0, 1.149, -0.95},
												{31.0, -123.0, 1.149, -2.63},
												{21.0, -131.0, 1.149, -1.9})
		
		camera_pan = 174	

	elseif camera_pan == 174 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{21.0, -131.0, 1.149, -1.9},
												{21.0, -131.0, 1.15, -1.9})
		
		camera_pan = 175	

	elseif camera_pan == 175 then
		scripting.game_interface:scroll_camera_with_direction(16,
												{21.0, -131.0, 1.15, -1.9},
												{20.0, -145.0, 1.0, -2.88},
												{27.0, -155.0, 1.1, -4.0},
												{55.0, -158.0, 1.15, -5.5})
		
		camera_pan = 176	

	elseif camera_pan == 176 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{55.0, -158.0, 1.15, -5.5},
												{55.0, -158.0, 1.149, -5.5})
		
		camera_pan = 177	
		scripting.game_interface:add_time_trigger("trigger_takeda_advice_three_nosound", 20.0)	
		
	elseif camera_pan == 178 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.1)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(44.5, -137.0)
		camera_pan = 0
	
		scripting.game_interface:add_time_trigger("trigger_takeda_intro_mission_one", 0.01)
	
-- 3024_STW2_Clan_Intro_Shimazu_1
	elseif camera_pan == 180 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-248.0, -164.0, 1.15, -0.02},
												{-248.0, -164.0, 1.149, -0.02})
		
		camera_pan = 181	
		scripting.game_interface:add_time_trigger("trigger_shimazu_advice_two_nosound", 20.0)	

	elseif camera_pan == 182 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-235.0, -166.0, 1.15, -1.0},
												{-235.0, -166.0, 1.149, -1.0})
		
		camera_pan = 183			

	elseif camera_pan == 183 then
		scripting.game_interface:scroll_camera_with_direction(20,
												{-235.0, -166.0, 1.149, -1.0},
												{-222.0, -134.0, 1.0, 0.5},
												{-233.0, -144.0, 1.15, 1.5})
		
		camera_pan = 184	

	elseif camera_pan == 184 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-233.0, -144.0, 1.15, 1.5},
												{-233.0, -144.0, 1.149, 1.5})
		
		camera_pan = 185
		
	elseif camera_pan == 185 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-233.0, -144.0, 1.149, 1.5},
												{-218.0, -139.0, 0.68, 0})
		
		camera_pan = 186

	elseif camera_pan == 186 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-218.0, -139.0, 0.68, 0},
												{-218.0, -139.0, 0.681, 0})
		
		camera_pan = 187
		scripting.game_interface:add_time_trigger("trigger_shimazu_advice_three_nosound", 20.0)	
		
	elseif camera_pan == 188 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.0)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(-249.0, -165.0)
		camera_pan = 0
	
		scripting.game_interface:add_time_trigger("trigger_shimazu_intro_mission_one", 0.01)
	
-- 3027_STW2_Clan_Intro_Tokugawa_1
	elseif camera_pan == 190 then
		scripting.game_interface:scroll_camera_with_direction(7,
												{-8.1, -145.7, 1.15, 0.52},
												{-8.1, -145.7, 1.149, 0.52})
		
		camera_pan = 191

	elseif camera_pan == 191 then
		scripting.game_interface:scroll_camera_with_direction(12,
												{-8.1, -145.7, 1.149, 0.52},
												{-11.0, -140.0, 1.0, 1.13},
												{-10.0, -142.0, 0.86, 1.34})
		
		camera_pan = 192

	elseif camera_pan == 192 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-10.0, -142.0, 0.86, 1.34},
												{-10.0, -142.0, 0.861, 1.34})
		
		camera_pan = 193
		scripting.game_interface:add_time_trigger("trigger_tokugawa_advice_two_nosound", 20.0)	

	elseif camera_pan == 194 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{-11.0, -129.0, 1.15, -0.12},
												{-11.0, -129.0, 1.149, -0.12})
		
		camera_pan = 195
		
	elseif camera_pan == 195 then
		scripting.game_interface:scroll_camera_with_direction(22,
												{-11.0, -129.0, 1.149, -0.12},
												{8.7, -128.0, 1.1, 2.08},
												{17.1, -133.1, 1.149, 1.47})
		
		camera_pan = 196	

	elseif camera_pan == 196 then
		scripting.game_interface:scroll_camera_with_direction(5,
												{17.1, -133.1, 1.149, 1.47},
												{17.1, -133.1, 1.150, 1.47})
		
		camera_pan = 197	
		scripting.game_interface:add_time_trigger("trigger_tokugawa_advice_three_nosound", 20.0)
		
	elseif camera_pan == 198 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.1)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(-5.5, -145.3)
		camera_pan = 0
	
		scripting.game_interface:add_time_trigger("trigger_tokugawa_intro_mission_one", 0.01)
	
	
-- 3030_STW2_Clan_Intro_Ikko_Ikki_1
	elseif camera_pan == 200 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-14.7, -91.1, 1.1, 0.76},
												{-14.7, -91.1, 1.101, 0.76})
		
		camera_pan = 201		
		scripting.game_interface:add_time_trigger("trigger_ikko_advice_two_nosound", 12.0)
	
	elseif camera_pan == 202 then
		scripting.game_interface:scroll_camera_with_direction(6,
												{-5.8, -87.8, 0.85, -0.43},
												{-5.8, -87.8, 0.851, -0.43})
		
		camera_pan = 203	

	elseif camera_pan == 203 then
		scripting.game_interface:scroll_camera_with_direction(23,
												{-5.8, -87.8, 0.851, -0.43},
												{-26.3, -123.9, 0.9, -0.91},
												{-29.19, -107.7, 1.0, -0.91},
												--{-4.22, -93.04, 0.85, 0.75},
												{16.34, -77.46, 1.0, 1.18})
		
		camera_pan = 204

	elseif camera_pan == 204 then
		scripting.game_interface:scroll_camera_with_direction(4,
												{16.34, -77.46, 1.0, 1.18},
												{16.34, -77.46, 1.001, 1.18})
		
		camera_pan = 205
		scripting.game_interface:add_time_trigger("trigger_ikko_advice_three_nosound", 12.0)
		
	elseif camera_pan == 206 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(1.0)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(-16.0, -89.0)
		camera_pan = 0
	
		scripting.game_interface:add_time_trigger("trigger_ikko_intro_mission_one", 0.01)


-- OTOMO PAN CONTINUATION START --	

	-- 4000_STW2_Clan_Intro_Otomo
	elseif camera_pan == 210 then
		scripting.game_interface:scroll_camera_with_direction(3,
												{-192.0, -123.0, 0.95, 0.0},
												{-192.0, -123.0, 0.9501, 0.0})
		
		camera_pan = 211

	elseif camera_pan == 211 then
		scripting.game_interface:scroll_camera_with_direction(54,
												{-192.0, -123.0, 0.9501, 0.0},
											--	{-117.0, -130.0, 0.80, 1.3},
												{-100.0, -120.0, 0.80, 0.7},
											--	{-74.0, -132.0, 0.95, 0.45},
												{-185.0, -87.0, 0.80, -1.9},
												{-232.0, -157.0, 1.0, -1.4},
												{-192.0, -123.0, 0.9501, 0.0})
		
		camera_pan = 212

	elseif camera_pan == 212 then
		scripting.game_interface:scroll_camera_with_direction(5,
												{-192.0, -123.0, 0.9501, 0.0},
												{-192.0, -123.0, 0.95, 0.0})
		
		camera_pan = 213
		
	elseif camera_pan == 213 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.95)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(-192.0, -123.0)
		camera_pan = 0
	
		scripting.game_interface:add_time_trigger("trigger_otomo_intro_mission_one", 0.01)
	

-- OTOMO PAN CONTINUATION END --	
	
	end
	
end


local function OnAdviceDismissed(context)
	
	if camera_pan ~= 0 then
		
		-- 3000_STW2_Clan_Intro_Chosokabe_1
		if (camera_pan == 100) or (camera_pan == 101) or (camera_pan == 102) or (camera_pan == 103) or (camera_pan == 104) or (camera_pan == 105) or (camera_pan == 106) or (camera_pan == 107)  or (camera_pan == 108) or (camera_pan == 109)then
			camera_pan = 1010
			scripting.game_interface:stop_camera()

		-- 3003_STW2_Clan_Intro_Oda_1
		elseif (camera_pan == 110) or (camera_pan == 111) or (camera_pan == 112) or (camera_pan == 113) or (camera_pan == 114) or (camera_pan == 115) or (camera_pan == 116) or (camera_pan == 117) or (camera_pan == 118) or (camera_pan == 119) then
			camera_pan = 1110
			scripting.game_interface:stop_camera()
		
		-- 3006_STW2_Clan_Intro_Uesugi_1
		elseif (camera_pan == 120) or (camera_pan == 121) or (camera_pan == 122) or (camera_pan == 123) or (camera_pan == 124) or (camera_pan == 125) or (camera_pan == 126) or (camera_pan == 127)then
			camera_pan = 128
			scripting.game_interface:stop_camera()
		
		-- 3009_STW2_Clan_Intro_Date_1
		elseif (camera_pan == 130) or (camera_pan == 131) or (camera_pan == 132) or (camera_pan == 133) or (camera_pan == 134) or (camera_pan == 135) then
			camera_pan = 136
			scripting.game_interface:stop_camera()
		
		-- 3012_STW2_Clan_Intro_Hojo_1
		elseif (camera_pan == 140) or (camera_pan == 141) or (camera_pan == 142) or (camera_pan == 143) or (camera_pan == 144) or (camera_pan == 145) then
			camera_pan = 146
			scripting.game_interface:stop_camera()
			
		-- 3015_STW2_Clan_Intro_Mori_1
		elseif (camera_pan == 150) or (camera_pan == 151) or (camera_pan == 152) or (camera_pan == 153) or (camera_pan == 154) or (camera_pan == 155) then
			camera_pan = 156
			scripting.game_interface:stop_camera()
			
		-- 3018_STW2_Clan_Intro_Hattori_1
		elseif (camera_pan == 160) or (camera_pan == 161) or (camera_pan == 162) or (camera_pan == 163) or (camera_pan == 164) or (camera_pan == 165) or (camera_pan == 166) or (camera_pan == 167)then
			camera_pan = 168
			scripting.game_interface:stop_camera()
		
		-- 3021_STW2_Clan_Intro_Takeda_1
		elseif (camera_pan == 170) or (camera_pan == 171) or (camera_pan == 172) or (camera_pan == 173) or (camera_pan == 174) or (camera_pan == 175) or (camera_pan == 176) or (camera_pan == 177)then
			camera_pan = 178
			scripting.game_interface:stop_camera()
			
		-- 3024_STW2_Clan_Intro_Shimazu_1
		elseif (camera_pan == 180) or (camera_pan == 181) or (camera_pan == 182) or (camera_pan == 183) or (camera_pan == 184) or (camera_pan == 185) or (camera_pan == 186) or (camera_pan == 187)then
			camera_pan = 188
			scripting.game_interface:stop_camera()
		
		-- 3027_STW2_Clan_Intro_Tokugawa_1
		elseif (camera_pan == 190) or (camera_pan == 191) or (camera_pan == 192) or (camera_pan == 193) or (camera_pan == 194) or (camera_pan == 195) or (camera_pan == 196) or (camera_pan == 197)then
			camera_pan = 198
			scripting.game_interface:stop_camera()
			
		-- 	3030_STW2_Clan_Intro_Ikko_Ikki_1
		elseif (camera_pan == 200) or (camera_pan == 201) or (camera_pan == 202) or (camera_pan == 203) or (camera_pan == 204) or (camera_pan == 205) or (camera_pan == 206) then	
			camera_pan = 206
			scripting.game_interface:stop_camera()

		
	-- 	4000_STW2_Clan_Intro_Otomo
		elseif (camera_pan == 210) or (camera_pan == 211) or (camera_pan == 212) or (camera_pan == 213)then	
			camera_pan = 213
			scripting.game_interface:stop_camera()
		
		end
		
	end


end






-------------------------------------------------------------------------------------------------------------------------
--
-- POSITIONS THE STARTING CAMERA APPROPRIATELY IN MP CAMPAIGNS DEPENDING ON THE CURRENT FACTION
--


local function OnFactionTurnStart(context)
	
	-- TURN ONE EVENTS
	
	if conditions.TurnNumber(context) == 1 then
		out.ting ("Turn 1. Playing as the " .. context.string)
		
		-- DIFFICULTY LEVEL DETECTION
		if conditions.DifficultyLevel(context) == 1 then
			out.ting("Playing on Easy.")
			BOOL_dif_easy = true
		
		elseif conditions.DifficultyLevel(context) == 0 then
			out.ting("Playing on Normal.")
			BOOL_dif_normal = true
			
		elseif conditions.DifficultyLevel(context) == -1 then
			out.ting("Playing on Hard.")
			BOOL_dif_hard = true
			
		elseif conditions.DifficultyLevel(context) == -2 then
			out.ting("Playing on Very Hard.")
			BOOL_dif_very_hard = true
		
		elseif conditions.DifficultyLevel(context) == -3 then
			out.ting("Playing on Legendary.")
			BOOL_dif_legendary = true
		
		end
		
		
		-- INITIAL ENEMY FORCES AND MP CAMERA
		
		if conditions.FactionIsLocal(context) then
		
			
			if conditions.FactionName("chosokabe", context) and conditions.FactionIsHuman("chosokabe", context) then
				out.ting ("Playing as Chosokabe!")
								
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-133.0, -138.0)
					
				else
					if BOOL_dif_easy then
						out.ting("Chosokabe Mission One: Spawn Medium Tosa Rebellion")
						scripting.game_interface:force_rebellion_in_region(--[TARGET REGION]--
																				"jap_tosa", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_small,
																			--[FORENAME]--	
																				"names_name_names_japaneseFusamoto", 
																			--[FAMILY NAME]--
																				"names_name_names_japaneseIchijo", 
																			--[COORDINATES]--
																				-140.5, -138.0,
																			--[SUPPRESS MESSAGE]--
																				true)
						
					elseif  BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Chosokabe Mission One: Spawn Medium Tosa Rebellion")
						scripting.game_interface:force_rebellion_in_region(--[TARGET REGION]--
																				"jap_tosa", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_medium,
																			--[FORENAME]--	
																				"names_name_names_japaneseFusamoto", 
																			--[FAMILY NAME]--
																				"names_name_names_japaneseIchijo", 
																			--[COORDINATES]--
																				-140.5, -138.0,
																			--[SUPPRESS MESSAGE]--
																				true)
					
					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Chosokabe Mission One: Spawn Large Tosa Rebellion")
						scripting.game_interface:force_rebellion_in_region(--[TARGET REGION]--
																				"jap_tosa", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_large,
																			--[FORENAME]--	
																				"names_name_names_japaneseFusamoto", 
																			--[FAMILY NAME]--
																				"names_name_names_japaneseIchijo", 
																			--[COORDINATES]--
																				-140.5, -138.0,
																			--[SUPPRESS MESSAGE]--
																				true)						
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
							
			elseif conditions.FactionName("oda", context) and conditions.FactionIsHuman("oda", context) then
				out.ting ("Playing as Oda!")
				
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-10.0, -128.0)
					
				else
					if BOOL_dif_easy then
						out.ting("Oda Mission One: Spawn Medium Owari Rebellion")
						scripting.game_interface:force_rebellion_in_region( --[TARGET REGION]--
																				"jap_owari", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_small,
																			--[FORENAME]--	
																				"", 
																			--[FAMILY NAME]--
																				"names_name_names_odaOda", 
																			--[COORDINATES]--
																				-13.4, -132.4,
																			--[SUPPRESS MESSAGE]--
																				true)
						
					elseif BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Oda Mission One: Spawn Medium Owari Rebellion")
						scripting.game_interface:force_rebellion_in_region( --[TARGET REGION]--
																				"jap_owari", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_medium,
																			--[FORENAME]--	
																				"", 
																			--[FAMILY NAME]--
																				"names_name_names_odaOda", 
																			--[COORDINATES]--
																				-13.4, -132.4,
																			--[SUPPRESS MESSAGE]--
																				true)

					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Oda Mission One: Spawn Large Owari Rebellion")
						scripting.game_interface:force_rebellion_in_region( --[TARGET REGION]--
																				"jap_owari", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_large,
																			--[FORENAME]--	
																				"", 
																			--[FAMILY NAME]--
																				"names_name_names_odaOda", 
																			--[COORDINATES]--
																				-13.4, -132.4,
																			--[SUPPRESS MESSAGE]--
																				true)
						
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
							
			elseif conditions.FactionName("tokugawa", context) and conditions.FactionIsHuman("tokugawa", context) then
				out.ting ("Playing as Tokugawa!")
				
				if CampaignUI.IsMultiplayer() then	
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-5.0, -143.0)
					
				else
						
					if BOOL_dif_easy then
						out.ting("Tokugawa Mission One: Spawn Medium Oda Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"oda",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_small,
																--[COORDINATES]--
																	-9.0, -139.0,
																--[ID]--
																	"oda_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					elseif BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Tokugawa Mission One: Spawn Medium Oda Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"oda",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_medium,
																--[COORDINATES]--
																	-9.0, -139.0,
																--[ID]--
																	"oda_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)

					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Tokugawa Mission One: Spawn Large Oda Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"oda",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_large,
																--[COORDINATES]--
																	-9.0, -139.0,
																--[ID]--
																	"oda_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					end
					
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
								
			elseif conditions.FactionName("takeda", context) and conditions.FactionIsHuman("takeda", context) then
				out.ting ("Playing as Takeda!")
				
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(44.0, -135.0)
					
				else
						
					if BOOL_dif_easy then
						out.ting("Takeda Mission One: Spawn Medium Murakami Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"murakami",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_small,
																--[COORDINATES]--
																	43.0, -128.0,
																--[ID]--
																	"murakami_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					elseif BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Takeda Mission One: Spawn Medium Murakami Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"murakami",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_medium,
																--[COORDINATES]--
																	43.0, -128.0,
																--[ID]--
																	"murakami_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)

					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Takeda Mission One: Spawn Large Murakami Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"murakami",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_large,
																--[COORDINATES]--
																	43.0, -128.0,
																--[ID]--
																	"murakami_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
								
			elseif conditions.FactionName("uesugi", context) and conditions.FactionIsHuman("uesugi", context) then
				out.ting ("Playing as Uesugi!")
				
				if CampaignUI.IsMultiplayer() then	
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(83.0, -73.0)
				
				else
					if BOOL_dif_easy then
						out.ting("Uesugi Mission One: Spawn Medium Echigo Rebellion")
						scripting.game_interface:force_rebellion_in_region(	--[TARGET REGION]--
																				"jap_echigo", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_small,
																			--[FORENAME]--
																				"names_name_names_japaneseHarukage", 
																			--[FAMILY NAME]--
																				"names_name_names_uesugiNagao", 
																			--[COORDINATES]--
																				77.0, -79.0,
																			--[SUPPRESS MESSAGE]--
																				true)
						
					elseif BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Uesugi Mission One: Spawn Medium Echigo Rebellion")
						scripting.game_interface:force_rebellion_in_region(	--[TARGET REGION]--
																				"jap_echigo", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_medium,
																			--[FORENAME]--
																				"names_name_names_japaneseHarukage", 
																			--[FAMILY NAME]--
																				"names_name_names_uesugiNagao", 
																			--[COORDINATES]--
																				77.0, -79.0,
																			--[SUPPRESS MESSAGE]--
																				true)

					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Uesugi Mission One: Spawn Large Echigo Rebellion")
						scripting.game_interface:force_rebellion_in_region(	--[TARGET REGION]--
																				"jap_echigo", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_large,
																			--[FORENAME]--
																				"names_name_names_japaneseHarukage", 
																			--[FAMILY NAME]--
																				"names_name_names_uesugiNagao", 
																			--[COORDINATES]--
																				77.0, -79.0,
																			--[SUPPRESS MESSAGE]--
																				true)
						
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
				
			elseif conditions.FactionName("hojo", context) and conditions.FactionIsHuman("hojo", context) then
				out.ting ("Playing as Hojo!")

				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(57.0, -157.0)
					
				else
						
					if BOOL_dif_easy  then
						out.ting("Hojo Mission One: Spawn Medium Ogigayatsu Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"ogigayatsu_uesugi",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_small,
																--[COORDINATES]--
																	65.0, -157.0,
																--[ID]--
																	"ogigayatsu_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					elseif BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Hojo Mission One: Spawn Medium Ogigayatsu Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"ogigayatsu_uesugi",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_medium,
																--[COORDINATES]--
																	65.0, -157.0,
																--[ID]--
																	"ogigayatsu_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Hojo Mission One: Spawn Large Ogigayatsu Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"ogigayatsu_uesugi",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_large,
																--[COORDINATES]--
																	65.0, -157.0,
																--[ID]--
																	"ogigayatsu_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)						
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
				
			elseif conditions.FactionName("date", context) and conditions.FactionIsHuman("date", context) then
				out.ting ("Playing as Date!")
				
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(187.0, -29.0)
				
				else
					if BOOL_dif_easy then
						out.ting("Date Mission One: Spawn Medium Iwate Rebellion")
						scripting.game_interface:force_rebellion_in_region(	--[TARGET REGION]--
																				"jap_iwate", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_medium,
																			--[FORENAME]--	
																				"names_name_names_japaneseTanemune", 
																			--[FAMILY NAME]--
																				"names_name_names_dateDate", 
																			--[COORDINATES]--
																				183.0, -36.0,
																			--[SUPPRESS MESSAGE]--
																				true)
						
					elseif BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Date Mission One: Spawn Medium Iwate Rebellion")
						scripting.game_interface:force_rebellion_in_region(	--[TARGET REGION]--
																				"jap_iwate", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_medium,
																			--[FORENAME]--	
																				"names_name_names_japaneseTanemune", 
																			--[FAMILY NAME]--
																				"names_name_names_dateDate", 
																			--[COORDINATES]--
																				183.0, -36.0,
																			--[SUPPRESS MESSAGE]--
																				true)

					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Date Mission One: Spawn Large Iwate Rebellion")
						scripting.game_interface:force_rebellion_in_region(	--[TARGET REGION]--
																				"jap_iwate", 
																			--[NUMBER OF (RANDOM) REBELLION UNITS]--
																				0, 
																			--[SPECIFIC ARMY LIST]--
																				AI_FORCE_large,
																			--[FORENAME]--	
																				"names_name_names_japaneseTanemune", 
																			--[FAMILY NAME]--
																				"names_name_names_dateDate", 
																			--[COORDINATES]--
																				183.0, -36.0,
																			--[SUPPRESS MESSAGE]--
																				true)
						
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
				
			elseif conditions.FactionName("mori", context) and conditions.FactionIsHuman("mori", context) then
				out.ting ("Playing as Mori!")
				
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-150.0, -92.0)
					
				else

					if BOOL_dif_easy then
						out.ting("Mori Mission One: Spawn Medium Amako Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"amako",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_small,
																--[COORDINATES]--
																	-155.5, -86.0,
																--[ID]--
																	"amako_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					elseif BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Mori Mission One: Spawn Medium Amako Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"amako",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_medium,
																--[COORDINATES]--
																	-155.5, -86.0,
																--[ID]--
																	"amako_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Mori Mission One: Spawn Large Amako Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"amako",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_large,
																--[COORDINATES]--
																	-155.5, -86.0,
																--[ID]--
																	"amako_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
						
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
								
			elseif conditions.FactionName("shimazu", context) and conditions.FactionIsHuman("shimazu", context) then
				out.ting ("Playing as Shimazu!")
				
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-248.0, -161.0)
				else

					if BOOL_dif_normal or BOOL_dif_hard then
						out.ting("Shimazu Mission One: Spawn Small Ito Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"ito",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_small,
																--[COORDINATES]--
																	-234.0, -165.0,
																--[ID]--
																	"ito_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
																	
					elseif BOOL_dif_very_hard or BOOL_dif_legendary then
						out.ting("Shimazu Mission One: Spawn Medium Ito Force")
						scripting.game_interface:create_force(	--[FACTION]--
																	"ito",
																--[SPECIFIC ARMY LIST]--
																	AI_FORCE_medium,
																--[COORDINATES]--
																	-234.0, -165.0,
																--[ID]--
																	"ito_invaders",
																--[USE_COMMAND_QUEUE]--
																	true)
					end
				
				-- Remove the black screen cover
				CampaignUI.ToggleScreenCover(false)
				
				end
			
			elseif conditions.FactionName("iga_ninja", context) and conditions.FactionIsHuman("iga_ninja", context) then
				out.ting ("Playing as Hattori!")
					
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-37.0, -136.0)
				
				else
					-- Remove the black screen cover
					CampaignUI.ToggleScreenCover(false)
					
				end
		
			
			elseif conditions.FactionName("ikko_ikki", context) and conditions.FactionIsHuman("ikko_ikki", context) then
				out.ting ("Playing as Ikki!")
					
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-16.0, -89.0)
				
				else
					-- Remove the black screen cover
					CampaignUI.ToggleScreenCover(false)
						
				end
				
		-- OTOMO GUBBINS --	
			elseif conditions.FactionName("otomo", context) and conditions.FactionIsHuman("otomo", context) then
				out.ting ("Playing as Otomo!")
					
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.95)
					CampaignUI.SetCameraTargetInstant(-192.0, -123.0)
				
				else
					-- Remove the black screen cover
					CampaignUI.ToggleScreenCover(false)
						
				end
				
		-- END OTOMO GUBBINS --		
		
			end
		end
	-- TURN TWO EVENTS
	
	elseif conditions.TurnNumber(context) == 2 then
		out.ting ("Turn 2")
		
		-- OTOMO GUBBINS BEGIN --
		if conditions.FactionName("otomo", context) and conditions.FactionIsHuman("otomo", context) then
			BOOL_turn_two = false
		else
			BOOL_turn_two = true
		end
		-- OTOMO END --
		
		
		if conditions.FactionIsHuman(context) and not CampaignUI.IsMultiplayer() then
			mission_two()			
		end
		
	else
		--out.ting("Not turn 2!")
		BOOL_turn_two = false
	
		-- Trigger the third mission once the first mission has been completed
	
			if conditions.FactionName("shimazu", context) and conditions.FactionIsHuman("shimazu", context) and BOOL_shimazu_osumi_captured and not BOOL_shimazu_trade_port_built and not BOOL_shimazu_mission_three_issued then
				out.ting("Shimazu Mission Three")
				shimazu_intro_mission_three()
				BOOL_shimazu_mission_three_issued = true
							
			elseif conditions.FactionName("chosokabe", context) and conditions.FactionIsHuman("chosokabe", context) and BOOL_chosokabe_tosa_rebellion_crushed and not BOOL_chosokabe_mission_three_issued and BOOL_chosokabe_tosa_free then
				out.ting("Chosokabe Mission Three")
				chosokabe_intro_mission_three()
				BOOL_chosokabe_mission_three_issued = true
				
			elseif conditions.FactionName("oda", context) and conditions.FactionIsHuman("oda", context) and BOOL_oda_owari_rebellion_crushed and not BOOL_oda_mission_three_issued then
				out.ting("Oda Mission Three")
				oda_intro_mission_three()
				BOOL_oda_mission_three_issued = true
				
			elseif conditions.FactionName("tokugawa", context) and conditions.FactionIsHuman("tokugawa", context) and BOOL_tokugawa_oda_defeated and not BOOL_tokugawa_mission_three_issued then
				out.ting("Tokugawa Mission Three")
				tokugawa_intro_mission_three()
				BOOL_tokugawa_mission_three_issued = true
				
			elseif conditions.FactionName("takeda", context) and conditions.FactionIsHuman("takeda", context) and BOOL_takeda_murakami_defeated and not BOOL_takeda_north_shinano_captured and not BOOL_takeda_mission_three_issued then
				out.ting("Takeda Mission Three")
				takeda_intro_mission_three()
				BOOL_takeda_mission_three_issued = true
				
			elseif conditions.FactionName("uesugi", context) and conditions.FactionIsHuman("uesugi", context) and BOOL_uesugi_echigo_rebellion_crushed and not BOOL_uesugi_mission_three_issued then
				out.ting("Uesugi Mission Three")
				uesugi_intro_mission_three()
				BOOL_uesugi_mission_three_issued = true
				
			elseif conditions.FactionName("hojo", context) and conditions.FactionIsHuman("hojo", context) and BOOL_hojo_ogigayatsu_defeated and not BOOL_hojo_musashi_captured and not BOOL_hojo_mission_three_issued then
				out.ting("Hojo Mission Three")
				hojo_intro_mission_three()
				BOOL_hojo_mission_three_issued = true
				
			elseif conditions.FactionName("date", context) and conditions.FactionIsHuman("date", context) and BOOL_date_iwate_rebellion_crushed and not BOOL_date_mission_three_issued then
				out.ting("Date Mission Three")
				date_intro_mission_three()
				BOOL_date_mission_three_issued = true
				
			elseif conditions.FactionName("mori", context) and conditions.FactionIsHuman("mori", context) and BOOL_mori_amako_defeated and not BOOL_mori_iwami_captured and not BOOL_mori_mission_three_issued then
				out.ting("Mori Mission Three")
				mori_intro_mission_three()
				BOOL_mori_mission_three_issued = true
						
			elseif conditions.FactionName("iga_ninja", context) and conditions.FactionIsHuman("iga_ninja", context) and not BOOL_hattori_mission_three_issued then
				out.ting("Hattori Mission Three")
				hattori_intro_mission_three()
				BOOL_hattori_mission_three_issued = true
		
			elseif conditions.FactionName("ikko_ikki", context) and conditions.FactionIsHuman("ikko_ikki", context) and BOOL_ikko_omi_converted and not BOOL_ikko_mission_three_issued and not BOOL_ikko_omi_captured then
				out.ting("Ikko Mission Three")
				ikko_intro_mission_three()
				BOOL_ikko_mission_three_issued = true
		
			end
		
		
	end
	
	if BOOL_ashikaga_hate_player then
		out.ting("Make the Ashikaga hate the player! That is to say: " .. human_shogun)
		scripting.game_interface:force_declare_war("ashikaga", human_shogun)
		BOOL_ashikaga_hate_player = false
	end

end

local function OnFactionTurnEnd(context)
	if conditions.FactionName("chosokabe", context) and not BOOL_chosokabe_tosa_free then
		BOOL_chosokabe_tosa_free = true
	end
end
	


-------------------------------------------------------------------------------------------------------------------------
--
-- SET UP THE ESCAPE KEY TO CIRCUMVENT PLAYER INTERACTION LOCKING
--

function OnKeyPressed(key, is_key_up)
	if is_key_up == true then
		if key == "ESCAPE" or key == "SPACE" then
			if camera_pan ~= 0 then		
				scripting.game_interface:stop_camera()
				scripting.game_interface:dismiss_advice()
				OnCameraMoverFinished(context)	
			end
		end
	end
end

--
-- IF CLICKING ON THE CLOSE ADVISOR BUTTON DURING THE PAN, THEN END WITHOUT LOCKING THE CAMERA
--

local function OnComponentLClickUp(context)
	out.ting("Component clicked!")

	if conditions.IsComponentType("minimise_button", context) and panning then
		out.ting("Cancelling the advice")
		scripting.game_interface:stop_camera()
		scripting.game_interface:dismiss_advice()
		OnCameraMoverFinished(context)
		
-- Stopping flashing the button
	elseif conditions.IsComponentType("button_tech", context) and not BOOL_tech_panel_opened and not CampaignUI.IsMultiplayer() then
		out.ting("Stop flashing the tech button")
		scripting.HighlightComponent("button_tech", false)
		BOOL_tech_panel_opened = true
	
	end
end

-------------------------------------------------------------------------------------------------------------------------
--
-- SAVE AND LOAD BOOLS, PREVENT MISSIONS BEING RE-ISSUED AFTER LOADING A SAVEGAME
--

local function OnSavingGame(context)
	scripting.game_interface:save_named_value("VERSION", 1, context)
	scripting.game_interface:save_named_value("BOOL_chosokabe_tosa_rebellion_crushed", BOOL_chosokabe_tosa_rebellion_crushed, context)
	scripting.game_interface:save_named_value("BOOL_oda_owari_rebellion_crushed", BOOL_oda_owari_rebellion_crushed, context)
	scripting.game_interface:save_named_value("BOOL_takeda_murakami_defeated", BOOL_takeda_murakami_defeated, context)
	scripting.game_interface:save_named_value("BOOL_tokugawa_oda_defeated", BOOL_tokugawa_oda_defeated, context)
	scripting.game_interface:save_named_value("BOOL_uesugi_echigo_rebellion_crushed", BOOL_uesugi_echigo_rebellion_crushed, context)
	scripting.game_interface:save_named_value("BOOL_date_iwate_rebellion_crushed", BOOL_date_iwate_rebellion_crushed, context)
	scripting.game_interface:save_named_value("BOOL_hojo_ogigayatsu_defeated", BOOL_hojo_ogigayatsu_defeated, context)
	scripting.game_interface:save_named_value("BOOL_mori_amako_defeated", BOOL_mori_amako_defeated, context)
	scripting.game_interface:save_named_value("BOOL_shimazu_osumi_captured", BOOL_shimazu_osumi_captured, context)
	scripting.game_interface:save_named_value("BOOL_takeda_north_shinano_captured", BOOL_takeda_north_shinano_captured, context)
	scripting.game_interface:save_named_value("BOOL_hojo_musashi_captured", BOOL_hojo_musashi_captured, context)
	scripting.game_interface:save_named_value("BOOL_mori_iwami_captured", BOOL_mori_iwami_captured, context)
	scripting.game_interface:save_named_value("BOOL_shimazu_trade_port_built", BOOL_shimazu_trade_port_built, context)
	scripting.game_interface:save_named_value("BOOL_tech_panel_opened", BOOL_tech_panel_opened, context)
	scripting.game_interface:save_named_value("BOOL_turn_two", BOOL_turn_two, context)
	scripting.game_interface:save_named_value("BOOL_dif_easy", BOOL_dif_easy, context)
	scripting.game_interface:save_named_value("BOOL_dif_normal", BOOL_dif_normal, context)
	scripting.game_interface:save_named_value("BOOL_dif_hard", BOOL_dif_hard, context)
	scripting.game_interface:save_named_value("BOOL_dif_very_hard", BOOL_dif_very_hard, context)
	scripting.game_interface:save_named_value("BOOL_chosokabe_mission_three_issued", BOOL_chosokabe_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_oda_mission_three_issued", BOOL_oda_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_takeda_mission_three_issued", BOOL_takeda_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_tokugawa_mission_three_issued", BOOL_tokugawa_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_uesugi_mission_three_issued", BOOL_uesugi_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_date_mission_three_issued", BOOL_date_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_hojo_mission_three_issued", BOOL_hojo_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_mori_mission_three_issued", BOOL_mori_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_shimazu_mission_three_issued", BOOL_shimazu_mission_three_issued, context)
	scripting.game_interface:save_named_value("BOOL_hattori_mission_three_issued", BOOL_hattori_mission_three_issued, context)
	scripting.game_interface:save_named_value("previous_shogun", previous_shogun, context)
	scripting.game_interface:save_named_value("VERSION", 2, context)
	scripting.game_interface:save_named_value("human_shogun", human_shogun, context)
	scripting.game_interface:save_named_value("BOOL_ashikaga_hate_player", BOOL_ashikaga_hate_player, context)
	scripting.game_interface:save_named_value("VERSION", 3, context)
	scripting.game_interface:save_named_value("BOOL_chosokabe_tosa_free", BOOL_chosokabe_tosa_free, context)
	scripting.game_interface:save_named_value("VERSION", 4, context)
	scripting.game_interface:save_named_value("BOOL_ikko_omi_converted", BOOL_ikko_omi_converted, context)
	scripting.game_interface:save_named_value("BOOL_ikko_omi_captured", BOOL_ikko_omi_captured, context)
	scripting.game_interface:save_named_value("BOOL_ikko_mission_three_issued", BOOL_ikko_mission_three_issued, context)
end

local function OnLoadingGame(context)
	BOOL_chosokabe_tosa_rebellion_crushed =					scripting.game_interface:load_named_value("BOOL_chosokabe_tosa_rebellion_crushed", false, context)
	BOOL_oda_owari_rebellion_crushed =						scripting.game_interface:load_named_value("BOOL_oda_owari_rebellion_crushed", false, context)
	BOOL_takeda_murakami_defeated =							scripting.game_interface:load_named_value("BOOL_takeda_murakami_defeated", false, context)
	BOOL_tokugawa_oda_defeated =							scripting.game_interface:load_named_value("BOOL_tokugawa_oda_defeated", false, context)
	BOOL_uesugi_echigo_rebellion_crushed =					scripting.game_interface:load_named_value("BOOL_uesugi_echigo_rebellion_crushed", false, context)
	BOOL_date_iwate_rebellion_crushed =						scripting.game_interface:load_named_value("BOOL_date_iwate_rebellion_crushed", false, context)
	BOOL_hojo_ogigayatsu_defeated =							scripting.game_interface:load_named_value("BOOL_hojo_ogigayatsu_defeated", false, context)
	BOOL_mori_amako_defeated =								scripting.game_interface:load_named_value("BOOL_mori_amako_defeated", false, context)
	BOOL_shimazu_osumi_captured =							scripting.game_interface:load_named_value("BOOL_shimazu_osumi_captured", false, context)
	BOOL_takeda_north_shinano_captured =					scripting.game_interface:load_named_value("BOOL_takeda_north_shinano_captured", false, context)
	BOOL_hojo_musashi_captured =							scripting.game_interface:load_named_value("BOOL_hojo_musashi_captured", false, context)
	BOOL_mori_iwami_captured =								scripting.game_interface:load_named_value("BOOL_mori_iwami_captured", false, context)
	BOOL_shimazu_trade_port_built = 						scripting.game_interface:load_named_value("BOOL_shimazu_trade_port_built", false, context)
	BOOL_tech_panel_opened =								scripting.game_interface:load_named_value("BOOL_tech_panel_opened", false, context)
	BOOL_turn_two =											scripting.game_interface:load_named_value("BOOL_turn_two", false, context)
	BOOL_dif_easy =											scripting.game_interface:load_named_value("BOOL_dif_easy", false, context)
	BOOL_dif_normal =										scripting.game_interface:load_named_value("BOOL_dif_normal", false, context)
	BOOL_dif_hard =											scripting.game_interface:load_named_value("BOOL_dif_hard", false, context)
	BOOL_dif_very_hard =									scripting.game_interface:load_named_value("BOOL_dif_very_hard", false, context)
	BOOL_chosokabe_mission_three_issued =					scripting.game_interface:load_named_value("BOOL_chosokabe_mission_three_issued", false, context)
	BOOL_oda_mission_three_issued =							scripting.game_interface:load_named_value("BOOL_oda_mission_three_issued", false, context)
	BOOL_takeda_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_takeda_mission_three_issued", false, context)
	BOOL_tokugawa_mission_three_issued =					scripting.game_interface:load_named_value("BOOL_tokugawa_mission_three_issued", false, context)
	BOOL_uesugi_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_uesugi_mission_three_issued", false, context)
	BOOL_date_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_date_mission_three_issued", false, context)
	BOOL_hojo_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_hojo_mission_three_issued", false, context)
	BOOL_mori_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_mori_mission_three_issued", false, context)
	BOOL_shimazu_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_shimazu_mission_three_issued", false, context)
	BOOL_hattori_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_hattori_mission_three_issued", false, context)
	previous_shogun =										scripting.game_interface:load_named_value("previous_shogun", "ashikaga", context)
	human_shogun =											scripting.game_interface:load_named_value("human_shogun", "", context)
	BOOL_ashikaga_hate_player =								scripting.game_interface:load_named_value("BOOL_ashikaga_hate_player", false, context)
	BOOL_chosokabe_tosa_free =								scripting.game_interface:load_named_value("BOOL_chosokabe_tosa_free", false, context)
	BOOL_ikko_omi_converted =								scripting.game_interface:load_named_value("BOOL_ikko_omi_converted", false, context)
	BOOL_ikko_omi_captured =								scripting.game_interface:load_named_value("BOOL_ikko_omi_captured", false, context)
	BOOL_ikko_mission_three_issued =						scripting.game_interface:load_named_value("BOOL_ikko_mission_three_issued", false, context)
end



--------------------------------------------------------------------------------------------------------------------
-- Add event callbacks
-- For a list of all events supported create a "documentation" directory in your empire directory, run a debug build of the game and see
-- the events.txt file
--------------------------------------------------------------------------------------------------------------------

scripting.AddEventCallBack("UICreated", OnUICreated)
scripting.AddEventCallBack("NewCampaignStarted", OnNewCampaignStarted)
scripting.AddEventCallBack("SavingGame", OnSavingGame)
scripting.AddEventCallBack("LoadingGame", OnLoadingGame)

scripting.AddEventCallBack("MissionSucceeded", OnMissionSucceeded)
scripting.AddEventCallBack("FactionBecomesShogun", OnFactionBecomesShogun)
scripting.AddEventCallBack("FactionTurnStart", OnFactionTurnStart)
scripting.AddEventCallBack("FactionTurnEnd", OnFactionTurnEnd)

scripting.AddEventCallBack("AdviceIssued", OnAdviceIssued)
scripting.AddEventCallBack("AdviceDismissed", OnAdviceDismissed)
scripting.AddEventCallBack("AdviceFinishedTrigger", OnAdviceFinished)
scripting.AddEventCallBack("CameraMoverFinished", OnCameraMoverFinished)

scripting.AddEventCallBack("TimeTrigger", OnTimeTrigger)
scripting.AddEventCallBack("SettlementOccupied", OnSettlementOccupied)
scripting.AddEventCallBack("CampaignSettlementAttacked", OnCampaignSettlementAttacked)
scripting.AddEventCallBack("FactionBecomesLiberationProtectorate", OnFactionBecomesLiberationProtectorate)

scripting.AddEventCallBack("ComponentLClickUp", OnComponentLClickUp)
scripting.AddEventCallBack("PanelClosedCampaign", OnPanelClosedCampaign)

--scripting.AddEventCallBack("CameraMoverCancelled", OnCameraMoverCancelled)
--scripting.AddEventCallBack("ModelCreated", OnModelCreated)
--scripting.AddEventCallBack("BattleCompleted", OnBattleCompleted)
