-------------------------------------------------------------------------------
------------------------------ SCRIPT SETUP -----------------------------------
-------------------------------------------------------------------------------
local core = require "ui/CoreUtils"
local advice = require "export_advice"
local scripting = require "EpisodicScripting"
local camera_pan = 0

local new_game = false
local panning = false
local gempei_victory_advice = false

local fujiwara_hiraizumi = false
local fujiwara_kubota = false
local taira_yashima = false
local taira_fukuhara = false
local minamoto_kamakura = false
local minamoto_kiso = false

EpisodicScripting = scripting

scripting.SetCampaign("jap_gempei")
out.ting("Shogun: Gempei War campaign script!")

local function OnNewCampaignStarted(context)
	new_game = true
	gempei_victory_advice = true

end

local function OnUICreated(context)

	if scripting.IsOnCampaignMap() then
		
		if new_game and not CampaignUI.IsMultiplayer() then
			
			-- Add black screen cover, hide pop-in
			CampaignUI.ToggleScreenCover(true)
			CampaignUI.ToggleCinematicBorders(true)
			
		-- FUJIWARA
			if conditions.FactionKeyIsLocal("gem_fujiwara_hiraizumi", context) then
				scripting.game_interface:register_movies("Genpei/FSM_GEN.bik")
				out.ting("Hiraizumi Fujiwara! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraHeading(0.0)
				CampaignUI.SetCameraTargetInstant(169.0, -58.0)
				new_game = false
				fujiwara_hiraizumi = true
		
			elseif conditions.FactionKeyIsLocal("gem_fujiwara_kubota", context) then
				scripting.game_interface:register_movies("Genpei/FSM_GEN.bik")
				out.ting("Kubota Fujiwara! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraHeading(0.0)
				CampaignUI.SetCameraTargetInstant(160.0, -17.0)
				new_game = false
				fujiwara_kubota = true

		--TAIRA
			elseif conditions.FactionKeyIsLocal("gem_taira_fukuhara", context) then
				scripting.game_interface:register_movies("Genpei/FSM_GEN.bik")
				out.ting("Fukuhara Taira! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraHeading(0.0)
				CampaignUI.SetCameraTargetInstant(-56.0, -124.0)
				new_game = false
				taira_fukuhara = true

			elseif conditions.FactionKeyIsLocal("gem_taira_yashima", context) then
				scripting.game_interface:register_movies("Genpei/FSM_GEN.bik")
				out.ting("Yashima Taira! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraHeading(0.0)
				CampaignUI.SetCameraTargetInstant(-104.0, -118.0)
				new_game = false
				taira_yashima = true
	
		-- MINAMOTO
			elseif conditions.FactionKeyIsLocal("gem_minamoto_kamakura", context) then
				scripting.game_interface:register_movies("Genpei/FSM_GEN.bik")
				out.ting("Kamakura Minamoto! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraHeading(0.0)
				CampaignUI.SetCameraTargetInstant(59.0, -159.0)
				new_game = false
				minamoto_kamakura = true

			elseif conditions.FactionKeyIsLocal("gem_minamoto_kiso", context) then
				scripting.game_interface:register_movies("Genpei/FSM_GEN.bik")
				out.ting("Kiso Minamoto! Moving camera to initial position")
				scripting.game_interface:take_shroud_snapshot()
				scripting.game_interface:make_neighbouring_regions_visible_in_shroud()
				scripting.game_interface:override_ui("disable_settlement_labels", true)
				scripting.game_interface:override_ui("disable_advice_changes", true)
				scripting.game_interface:steal_user_input(true)
				scripting.game_interface:set_zoom_limit(1.19, 0.676)
				CampaignUI.SetCameraZoom(0.7)
				CampaignUI.SetCameraHeading(0.0)
				CampaignUI.SetCameraTargetInstant(23.0, -130.0)
				new_game = false
				minamoto_kiso = true
				
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


local message_handler = MessageManager

-------------------------------------------------------------------------------------------------------------------------
--
-- INTRO MISSION SETUP
--

local final_zoom_limit = 1.1, 0.8

--
-- FUJIWARA --
--
	-- HIRAIZUMI --	
		local function fujiwara_hiraizumi_intro_mission()
			out.ting("Fujiwara Mission: Request Allegiance")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"gem_fujiwara_hiraizumi_intro_mission",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"gem_fujiwara_hiraizumi",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_gem_master_inspector#8")
		end

		
			
	
	-- KUBOTA --
		local function fujiwara_kubota_intro_mission()
			out.ting("Fujiwara Mission: Request Allegiance")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"gem_fujiwara_kubota_intro_mission",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"gem_fujiwara_kubota",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_gem_master_inspector#8")
		end


--
-- TAIRA --
--
	-- FUKUHARA --
		local function taira_fukuhara_intro_mission()
			out.ting("Taira Mission: Request Allegiance")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"gem_taira_fukuhara_intro_mission",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"gem_taira_fukuhara",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_gem_master_inspector#8")
		end
		
	-- YASHIMA --
		local function taira_yashima_intro_mission()
			out.ting("Taira Mission: Request Allegiance")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"gem_taira_yashima_intro_mission",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"gem_taira_yashima",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_gem_master_inspector#8")
		end
		

--
-- MINAMOTO --
--
	-- KAMAKURA --
		local function minamoto_kamakura_intro_mission()
			out.ting("Minamoto Mission: Request Allegiance")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"gem_minamoto_kamakura_intro_mission",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"gem_minamoto_kamakura",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_gem_master_inspector#8")
		end
		
	-- KISO --
		local function minamoto_kiso_intro_mission()
			out.ting("Minamoto Mission: Request Allegiance")
			scripting.game_interface:trigger_custom_mission(--[MISSION KEY]-- 
																"gem_minamoto_kiso_intro_mission",
															--[MISSION ISSUER]--
																"CLAN_ELDERS",													
															--[FACTION KEY]--
																"gem_minamoto_kiso",													
															--[TURN LIMIT]--
																0,
															--[TARGET]--
																"",
															--[REWARD]--
																"effect_bundle:p_gem_master_inspector#8")
		end
		


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
-- POST-INTRO ADVICE
--

local function OnPanelClosedCampaign(context)
	if conditions.IsComponentType("events", context) then
	
		if gempei_victory_advice then
			out.ting("Triggering the Gempei Victory advice in a few seconds!")
			effect.advance_scripted_advice_thread("2235_Campaign_Advice_Gempei_Victory_Thread", 1)
			gempei_victory_advice = false
		end
	end
	

end

		
		
-------------------------------------------------------------------------------------------------------------------------
--
-- MISSION SUCCESSES
--

local function OnMissionSucceeded(context)
	out.ting("Mission Success!")	

end



-------------------------------------------------------------------------------------------------------------------------
--
-- TIME TRIGGERS
--

local function OnTimeTrigger(context)

-- INTRO MISSIONS
	if context.string == "gempei_victory_advice_trigger" then
			effect.advance_scripted_advice_thread("2235_Campaign_Advice_Gempei_Victory_Thread", 1)
			gempei_victory_advice = false
	
	--[[
	elseif context.string == "trigger_fujiwara_hiraizumi_intro_mission" then
		fujiwara_hiraizumi_intro_mission()

	elseif context.string == "trigger_fujiwara_kubota_intro_mission" then
		fujiwara_kubota_intro_mission()
	
	elseif context.string == "trigger_taira_yashima_intro_mission" then
		taira_yashima_intro_mission()

	elseif context.string == "trigger_taira_fukuhara_intro_mission" then
		taira_fukuhara_intro_mission()

	elseif context.string == "trigger_minamoto_kamakura_intro_mission" then
		minamoto_kamakura_intro_mission()

	elseif context.string == "trigger_minamoto_kiso_intro_mission" then
		minamoto_kiso_intro_mission()
		]]
	end
	
	
end



-------------------------------------------------------------------------------------------------------------------------
--
-- CLAN INTROS AND CAMERA PANS
--

-- TRIGGER A PAN BASED UPON A PIECE OF ADVICE TRIGGERING

local function OnAdviceIssued(context)

	-- 3035_STW2_Gempei_Clan_Intro_Fujiwara_1_Thread
	
	if conditions.AdviceJustDisplayed("2139658665", context) and not CampaignUI.IsMultiplayer() then
		
		-- HIRAIZUMI --
		if fujiwara_hiraizumi then
			panning = true
			scripting.game_interface:set_zoom_limit(1.19, 0.676)
			scripting.game_interface:scroll_camera_with_direction(14,	
													{199.8, -65.3, 0.78, -1.17},
													{173.18, -56.0, 0.9, -0.88},
													{165.0, -66.6, 1.0, 0.06},
													{159.7, -75.3, 0.9, 0.23})

			camera_pan = 100
		
		
		-- KUBOTA --
		elseif fujiwara_kubota then
			panning = true
			scripting.game_interface:set_zoom_limit(1.19, 0.676)
			scripting.game_interface:scroll_camera_with_direction(14,	
													{133.5, -3.61, 0.86, 1.8},
													{153.6, -15.97, 1.0, 0.81},
													{144.4, -40.75, 1.0, 0.06},
													{142.6, -62.34, 0.85, 0.13})

			camera_pan = 110
		end
	
	-- 3034_STW2_Gempei_Clan_Intro_Taira_1_Thread
	elseif conditions.AdviceJustDisplayed("2139658661", context) and not CampaignUI.IsMultiplayer() then
		
		-- FUKUHARA --
		if taira_fukuhara then
			panning = true
			scripting.game_interface:set_zoom_limit(1.19, 0.676)
			scripting.game_interface:scroll_camera_with_direction(17,	
													{-69.0, -162.0, 0.7, 0.58},
													{-71.0, -138.0, 0.93, 0.81},
													{-54.0, -139.0, 1.0, -0.57},
													{-46.0, -137.0, 0.8, -1.07})
				
			camera_pan = 120

		-- YASHIMA --
		elseif taira_yashima then
			panning = true
			scripting.game_interface:set_zoom_limit(1.19, 0.676)
			scripting.game_interface:scroll_camera_with_direction(17,	
													{-131.0, -113.0, 0.7, 1.0},
													{-117.0, -114.0, 0.93, 1.58},
													{-103.5, -123.0, 1.05, 1.15},
													{-89.2, -126.3, 0.8, -0.22})
				
			camera_pan = 130
		end
			
	-- 3033_STW2_Gempei_Clan_Intro_Minamoto_1_Thread
	elseif conditions.AdviceJustDisplayed("2139658658", context) and not CampaignUI.IsMultiplayer() then
		
		-- KAMAKURA --
		if minamoto_kamakura then
			panning = true
			scripting.game_interface:set_zoom_limit(1.19, 0.676)
			scripting.game_interface:scroll_camera_with_direction(13,
													{46.0, -178.0, 0.8, 0.33},
													{47.2, -167.3, 1.1, 0.39},
													{61.8, -162.5, 1.0, -1.1})
				
			camera_pan = 140	
			
		-- KISO --
		elseif minamoto_kiso then
			panning = true
			scripting.game_interface:set_zoom_limit(1.19, 0.676)
			scripting.game_interface:scroll_camera_with_direction(13,
													{8.8, -148.7, 0.71, 0.54},
													{23.3, -129.6, 1.0, -0.2},
													{37.4, -115.5, 0.9, -1.9})
				
			camera_pan = 150
		
		end
	end		
end



local function OnAdviceFinished(context)

	if conditions.AdviceJustDisplayed("2139658634", context) then
	end
	
end
	

-- TRIGGER A CAMERA PAN BASED UPON A PREVIOUS CAMERA PAN ENDING

local function OnCameraMoverFinished(context)

	-- 3035_STW2_Gempei_Clan_Intro_Fujiwara_1_Thread
	-- HIRAIZUMI --
	if camera_pan == 100 then
		scripting.game_interface:scroll_camera_with_direction(4,	
													{159.7, -75.3, 0.9, 0.23},	
													{159.7, -75.3, 0.9, 0.231})
				
		camera_pan = 101		

	elseif camera_pan == 101 then
		scripting.game_interface:scroll_camera_with_direction(45,	
													{159.7, -75.3, 0.9, 0.231},	
													{39.0, -118.46, 0.7, -1.42},	
													{-44.7, -132.65, 0.93, -0.31},	
													{35.11, -157.9, 0.71, 0.31},	
													{160.57, -69.7, 0.9, 0.0})
				
		camera_pan = 102	


	elseif camera_pan == 102 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.9)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(160.57, -69.7)
		camera_pan = 0
		
	--	scripting.game_interface:add_time_trigger("trigger_fujiwara_hiraizumi_intro_mission", 0.01)
			
	-- KUBOTA --
	elseif camera_pan == 110 then
		scripting.game_interface:scroll_camera_with_direction(4,	
													{142.6, -62.34, 0.85, 0.13},	
													{142.6, -62.34, 0.85, 0.131})
				
		camera_pan = 111		

	elseif camera_pan == 111 then
		scripting.game_interface:scroll_camera_with_direction(45,	
													{142.6, -62.34, 0.85, 0.131},	
													{39.0, -118.46, 0.7, -1.42},	
													{-44.7, -132.65, 0.93, -0.31},	
													{35.11, -157.9, 0.71, 0.31},	
													{144.7, -66.5, 0.9, 0.0})
				
		camera_pan = 112	

		elseif camera_pan == 112 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.9)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(144.7, -66.5)
		camera_pan = 0
		
	--	scripting.game_interface:add_time_trigger("trigger_fujiwara_kubota_intro_mission", 0.01)
			
			
			
	-- 3034_STW2_Gempei_Clan_Intro_Taira_1_Thread
	-- FUKUHARA --
	elseif camera_pan == 120 then
		scripting.game_interface:scroll_camera_with_direction(3,	
													{-46.0, -137.0, 0.8, -1.07},	
													{-46.0, -137.0, 0.8, -1.069})
				
		camera_pan = 121		

	elseif camera_pan == 121 then
		scripting.game_interface:scroll_camera_with_direction(30,	
													{-46.0, -137.0, 0.8, -1.069},	
													{50.0, -161.0, 0.7, -0.44},	
													{105.0, -92.0, 0.75, 1.069},	
												--	{7.5, -117.0, 0.85, -1.08},	
													{-61.2, -136.7, 0.93, 0.0})
				
		camera_pan = 122	
		
	elseif camera_pan == 122 then	
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.9)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(-61.2, -136.7)
		camera_pan = 0
		
	--	scripting.game_interface:add_time_trigger("trigger_taira_fukuhara_intro_mission", 0.01)

		
	-- YASHIMA --
	elseif camera_pan == 130 then
		scripting.game_interface:scroll_camera_with_direction(3,	
													{-89.2, -126.3, 0.8, -0.22},	
													{-89.2, -126.3, 0.8, -0.219})
				
		camera_pan = 131
		
	elseif camera_pan == 131 then
		scripting.game_interface:scroll_camera_with_direction(30,	
													{-89.2, -126.3, 0.8, -0.219},	
													{50.0, -161.0, 0.7, -0.44},	
													{105.0, -92.0, 0.75, 1.069},	
												--	{7.5, -117.0, 0.85, -1.08},	
													{-89.2, -126.3, 0.828, 0.0})
				
		camera_pan = 132	
		
	elseif camera_pan == 132 then	
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.828)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(-89.2, -126.3)
		camera_pan = 0
		
	--	scripting.game_interface:add_time_trigger("trigger_taira_yashima_intro_mission", 0.01)


		
	-- 3033_STW2_Gempei_Clan_Intro_Minamoto_1_Thread
	-- KAMKURA --
	elseif camera_pan == 140 then
		scripting.game_interface:scroll_camera_with_direction(3,	
													{61.8, -162.5, 1.0, -1.1},	
													{61.8, -162.5, 1.0, -1.101})
				
		camera_pan = 141	

	elseif camera_pan == 141 then
		scripting.game_interface:scroll_camera_with_direction(45,	
													{61.8, -162.5, 1.0, -1.101},	
													{-43.0, -139.4, 0.85, -0.74},	
													{34.5, -101.0, 0.7, -1.71},	
													{117.28, -68.3, 0.71, 0.86},	
													{53.3, -165.0, 0.93, 0.0})
				
		camera_pan = 142	
		
	elseif camera_pan == 142 then
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.93)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(53.3, -165.0)
		camera_pan = 0
		
	--	scripting.game_interface:add_time_trigger("trigger_minamoto_kamakura_intro_mission", 0.01)

		
	-- KISO --
	elseif camera_pan == 150 then
		scripting.game_interface:scroll_camera_with_direction(3,	
													{37.4, -115.5, 0.9, -1.9},	
													{37.4, -115.5, 0.9, -1.901})
				
		camera_pan = 151	

	elseif camera_pan == 151 then
		scripting.game_interface:scroll_camera_with_direction(45,	
													{37.4, -115.5, 0.9, -1.901},	
													{-36.0, -123.7, 0.85, -2.0},	
													{54.5, -161.0, 0.7, -0.84},	
													{145.2, -79.3, 0.75, 0.27},	
													{23.7, -131.0, 0.9, 0.0})
				
		camera_pan = 152	

	elseif camera_pan == 152 then	
		panning = false
		scripting.game_interface:restore_shroud_from_snapshot()
		scripting.game_interface:override_ui("disable_settlement_labels", false)
		scripting.game_interface:override_ui("disable_advice_changes", false)
		scripting.game_interface:steal_user_input(false)
		scripting.game_interface:set_zoom_limit(1.1, 0.8)
		CampaignUI.ToggleCinematicBorders(false)
		CampaignUI.SetCameraZoom(0.9)
		CampaignUI.SetCameraHeading(0.0)
		CampaignUI.SetCameraTargetInstant(23.7, -131.0)
		camera_pan = 0
		
	--	scripting.game_interface:add_time_trigger("trigger_minamoto_kiso_intro_mission", 0.01)
		
	end
	
end


local function OnAdviceDismissed(context)
	
	if gempei_victory_advice then
		scripting.game_interface:add_time_trigger("gempei_victory_advice_trigger", 0.1)
		gempei_victory_advice = false
	end
	
	if camera_pan ~= 0 then
			
		-- 3035_STW2_Gempei_Clan_Intro_Fujiwara_1_Thread
		-- HIRAIZUMI --
		if (camera_pan == 100) or (camera_pan == 101) or (camera_pan == 102) then
			camera_pan = 102
			scripting.game_interface:stop_camera()
			
		-- KUBOTA --
		elseif (camera_pan == 110) or (camera_pan == 111) or (camera_pan == 112) then
			camera_pan = 112
			scripting.game_interface:stop_camera()
			
			
		-- 3034_STW2_Gempei_Clan_Intro_Taira_1_Thread
		-- FUKUHARA --
		elseif (camera_pan == 120) or (camera_pan == 121) or (camera_pan == 122) then
			camera_pan = 122
			scripting.game_interface:stop_camera()
			
		-- YASHIMA --
		elseif (camera_pan == 130) or (camera_pan == 131) or (camera_pan == 132) then
			camera_pan = 132
			scripting.game_interface:stop_camera()
			
			
		-- 3033_STW2_Gempei_Clan_Intro_Minamoto_1_Thread
		-- KAMKURA --
		elseif (camera_pan == 140) or (camera_pan == 141) or (camera_pan == 142) then
			camera_pan = 142
			scripting.game_interface:stop_camera()
			
		-- KISO --
		elseif (camera_pan == 150) or (camera_pan == 151) or (camera_pan == 152) then
			camera_pan = 152
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
		
		
		-- INITIAL MP CAMERA
		
		if conditions.FactionIsLocal(context) then
			
			-- Remove the black screen cover
			CampaignUI.ToggleScreenCover(false)
					
			-- HIRAIZUMI --
			if conditions.FactionName("gem_fujiwara_hiraizumi", context) and conditions.FactionIsHuman("gem_fujiwara_hiraizumi", context) then
				out.ting ("Playing as Hiraizumi Fujiwara!")
								
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.9)
					CampaignUI.SetCameraTargetInstant(169.0, -58.0)
				end
			
			-- KUBOTA --
			elseif conditions.FactionName("gem_fujiwara_kubota", context) and conditions.FactionIsHuman("gem_fujiwara_kubota", context) then
				out.ting ("Playing as Kubota Fujiwara!")
				
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.90)
					CampaignUI.SetCameraTargetInstant(160.0, -17.0)
				end
			

			-- FUKUHARA --
			elseif conditions.FactionName("gem_taira_fukuhara", context) and conditions.FactionIsHuman("gem_taira_fukuhara", context) then
				out.ting ("Playing as Fukuhara Taira!")
				
				if CampaignUI.IsMultiplayer() then	
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.9)
					CampaignUI.SetCameraTargetInstant(-56.0, -124.0)
				end
			
			-- YASHIMA --			
			elseif conditions.FactionName("gem_taira_yashima", context) and conditions.FactionIsHuman("gem_taira_yashima", context) then
				out.ting ("Playing as Yashima Taira!")
				
				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.828)
					CampaignUI.SetCameraTargetInstant(-89.2, -126.3)				
				end
				

			-- KAMAKURA --	
			elseif conditions.FactionName("gem_minamoto_kamakura", context) and conditions.FactionIsHuman("gem_minamoto_kamakura", context) then
				out.ting ("Playing as Kamakura Minamoto!")
				
				if CampaignUI.IsMultiplayer() then	
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.9)
					CampaignUI.SetCameraTargetInstant(59.0, -159.0)
				end
			
			-- KISO --
			elseif conditions.FactionName("gem_minamoto_kiso", context) and conditions.FactionIsHuman("gem_minamoto_kiso", context) then
				out.ting ("Playing as Kiso Minamoto!")

				if CampaignUI.IsMultiplayer() then
					scripting.game_interface:set_zoom_limit(1.1, 0.8)
					CampaignUI.SetCameraZoom(0.90)
					CampaignUI.SetCameraTargetInstant(23.0, -130.0)
				end
				
			end
		end
	
	elseif conditions.TurnNumber(context) == 2 then
		out.ting ("Turn 2. Triggering mission.")
		
		if conditions.FactionIsHuman(context) and not CampaignUI.IsMultiplayer() then
			fujiwara_hiraizumi_intro_mission()
			fujiwara_kubota_intro_mission()
			taira_yashima_intro_mission()
			taira_fukuhara_intro_mission()
			minamoto_kamakura_intro_mission()
			minamoto_kiso_intro_mission()
		end
		
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
	end
end

-------------------------------------------------------------------------------------------------------------------------
--
-- SAVE AND LOAD BOOLS, PREVENT MISSIONS BEING RE-ISSUED AFTER LOADING A SAVEGAME
--

local function OnSavingGame(context)
	scripting.game_interface:save_named_value("VERSION", 1, context)
	scripting.game_interface:save_named_value("BOOL_dif_easy", BOOL_dif_easy, context)
	scripting.game_interface:save_named_value("BOOL_dif_normal", BOOL_dif_normal, context)
	scripting.game_interface:save_named_value("BOOL_dif_hard", BOOL_dif_hard, context)
	scripting.game_interface:save_named_value("BOOL_dif_very_hard", BOOL_dif_very_hard, context)
end

local function OnLoadingGame(context)
	BOOL_dif_easy =											scripting.game_interface:load_named_value("BOOL_dif_easy", false, context)
	BOOL_dif_normal =										scripting.game_interface:load_named_value("BOOL_dif_normal", false, context)
	BOOL_dif_hard =											scripting.game_interface:load_named_value("BOOL_dif_hard", false, context)
	BOOL_dif_very_hard =									scripting.game_interface:load_named_value("BOOL_dif_very_hard", false, context)
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
--scripting.AddEventCallBack("FactionBecomesShogun", OnFactionBecomesShogun)
scripting.AddEventCallBack("FactionTurnStart", OnFactionTurnStart)
--scripting.AddEventCallBack("FactionTurnEnd", OnFactionTurnEnd)

scripting.AddEventCallBack("AdviceIssued", OnAdviceIssued)
scripting.AddEventCallBack("AdviceDismissed", OnAdviceDismissed)
scripting.AddEventCallBack("AdviceFinishedTrigger", OnAdviceFinished)
scripting.AddEventCallBack("CameraMoverFinished", OnCameraMoverFinished)

scripting.AddEventCallBack("TimeTrigger", OnTimeTrigger)
--scripting.AddEventCallBack("SettlementOccupied", OnSettlementOccupied)
--scripting.AddEventCallBack("CampaignSettlementAttacked", OnCampaignSettlementAttacked)
--scripting.AddEventCallBack("FactionBecomesLiberationProtectorate", OnFactionBecomesLiberationProtectorate)

scripting.AddEventCallBack("ComponentLClickUp", OnComponentLClickUp)
scripting.AddEventCallBack("PanelClosedCampaign", OnPanelClosedCampaign)

--scripting.AddEventCallBack("CameraMoverCancelled", OnCameraMoverCancelled)
--scripting.AddEventCallBack("ModelCreated", OnModelCreated)
--scripting.AddEventCallBack("BattleCompleted", OnBattleCompleted)
