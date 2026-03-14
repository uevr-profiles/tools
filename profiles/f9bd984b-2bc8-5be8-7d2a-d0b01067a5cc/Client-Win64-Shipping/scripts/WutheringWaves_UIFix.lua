--This Mod was originally done by Polar. GitHub repository:https://github.com/mirudo2/WuWa-UI-Fix-for-UEVR
--And modified by Sannpokun.

UEVR_UObjectHook.set_disabled(true)



--user config
local ConfigFileName = "WutheringWaveVRConfig.txt"
local ConfigData = nil

local WorldScale_VR = 0.93000
local WorldScale_2D = 0.01
--offset from the center of the pawn actor.
local FirstPersonModeHeadPos = 65
local FirstPersonModeHeadPos_Crouch = 25
local bAutoDecideDecoupledPitch = true
local bHideUI_FPMode = true
local bUseHMDOrientation_FPMode = true
local RenderingMode = 0


function NearlyEqual(a, b, epsilon)
    epsilon = epsilon or 1e-6
    local diff = math.abs(a - b)

    if a == b then
        return true  -- Exactly equal (including ±inf)
    elseif a == 0 or b == 0 or diff < 1e-12 then
        -- Handle near-zero values: use absolute error
        return diff < (epsilon * 1e-6)
    else
        -- General case: use relative error
        return (diff / math.min((math.abs(a) + math.abs(b)), math.huge)) < epsilon
    end
end

local function WriteConfig()
	ConfigData = "WorldScale_VR=" .. tostring(WorldScale_VR) .. "\n" .. 
	             "WorldScale_2D=" .. tostring(WorldScale_2D) .. "\n" ..
				 "FirstPersonModeHeadPos=" .. tostring(FirstPersonModeHeadPos) .. "\n" ..
				 "FirstPersonModeHeadPos_Crouch=" .. tostring(FirstPersonModeHeadPos_Crouch) .. "\n" ..
				 "bAutoDecideDecoupledPitch=" .. tostring(bAutoDecideDecoupledPitch) .. "\n" ..
				 "bHideUI_FPMode=" .. tostring(bHideUI_FPMode) .. "\n" ..
				 "bUseHMDOrientation_FPMode=" .. tostring(bUseHMDOrientation_FPMode) .. "\n" .. 
				 "RenderingMode=" .. tostring(RenderingMode) .. "\n"
	fs.write(ConfigFileName, ConfigData)
end

local function ReadConfig()
	print("Read user config from file.")
	ConfigData = fs.read(ConfigFileName)
	if ConfigData ~= "" then -- Check if file was read successfully
		print("config read")
        for key, value in ConfigData:gmatch("([^=]+)=([^\n]+)\n?") do
            print("parsing key:", key, "value:", value)
            if key == "WorldScale_VR" then
                WorldScale_VR = tonumber(value) or WorldScale_VR
            elseif key == "WorldScale_2D" then
                WorldScale_2D = tonumber(value) or WorldScale_2D
            elseif key == "FirstPersonModeHeadPos" then
                FirstPersonModeHeadPos = tonumber(value) or FirstPersonModeHeadPos
            elseif key == "FirstPersonModeHeadPos_Crouch" then
                FirstPersonModeHeadPos_Crouch = tonumber(value) or FirstPersonModeHeadPos_Crouch
            elseif key == "bAutoDecideDecoupledPitch" then
                bAutoDecideDecoupledPitch = (value == "true")
			elseif key == "bHideUI_FPMode" then
                bHideUI_FPMode = (value == "true")
			elseif key == "bUseHMDOrientation_FPMode" then
				bUseHMDOrientation_FPMode = (value == "true")
			elseif key == "RenderingMode" then
				RenderingMode = tonumber(value) or RenderingMode
            end

        end
	else
		print("Error: Could not read config file.")
	end
end

ReadConfig()

--const 
local WorldUI_Scale = 0.12
local UEVR_UI_Dist = 2.313000

--variables
local api = uevr.api
local m_VR = uevr.params.vr
local log_functions = uevr.params.functions

--local MathUtility = require("Lib.MathUtility")

local player_controller = nil
local local_pawn = nil
local LastFrame_LocalPawn = nil
local TickDelta = 0

local Transform_C  = api:find_uobject("ScriptStruct /Script/CoreUObject.Transform")
local relative_transform = StructObject.new(Transform_C)
relative_transform.Scale3D.X = 1
relative_transform.Scale3D.Y = 1
relative_transform.Scale3D.Z = 1

local kismet_math_library_c = api:find_uobject("Class /Script/Engine.KismetMathLibrary")
local kismet_math_library = kismet_math_library_c:get_class_default_object()

local fhitresult_c = api:find_uobject("ScriptStruct /Script/Engine.HitResult")
local fhitresult = StructObject.new(fhitresult_c)

local vector_c = api:find_uobject("ScriptStruct /Script/CoreUObject.Vector")
local vector = StructObject.new(vector_c)

local vector2d_c = api:find_uobject("ScriptStruct /Script/CoreUObject.Vector2D")
local vector2d = StructObject.new(vector2d_c)

local rotator_c = api:find_uobject("ScriptStruct /Script/CoreUObject.Rotator")
local rotator = StructObject.new(rotator_c)

local UIItem_c = api:find_uobject("Class /Script/LGUI.UIItem")
local LGUICanvas_c = api:find_uobject("Class /Script/LGUI.LGUICanvas")
local LGUICanvasScaler_c = api:find_uobject("Class /Script/LGUI.LGUICanvasScaler")
local ScreenSpace_c = api:find_uobject("Class /Script/LGUI.LGUIScreenSpaceInteraction")
local LGUIBehaviour_c = api:find_uobject("Class /Script/LGUI.LGUIBehaviour")
local UIDrawcallMesh_c = api:find_uobject("Class /Script/LGUI.UIDrawcallMesh")
local CameraComponent_c = api:find_uobject("Class /Script/Engine.CameraComponent")
local SceneComponent_c = api:find_uobject("Class /Script/Engine.SceneComponent")
local LGUI_Map_UI_Params_C = api:find_uobject("Class /Script/LGUI.KuroWorldMapUIParams")
local KismetSysLib_C = api:find_uobject("Class /Script/Engine.KismetSystemLibrary")
local CameraActor_C = api:find_uobject("Class /Script/Engine.CameraActor")
local MediaPlayer_C = api:find_uobject("Class /Script/MediaAssets.MediaPlayer")
local KismetSysLib = KismetSysLib_C:get_class_default_object()
local CineCameraActor_C = api:find_uobject("Class /Script/CinematicCamera.CineCameraActor")
local GameplayStatics_c = api:find_uobject("Class /Script/Engine.GameplayStatics")
local GameplayStatics = GameplayStatics_c:get_class_default_object()
local KismetStrLib_C = api:find_uobject("Class /Script/Engine.KismetStringLibrary")
local KismetStrLib = KismetStrLib_C:get_class_default_object()
local EffectSystemActor_C = api:find_uobject("Class /Script/KuroGameplay.EffectSystemActor")


local ScreenSpace = nil
local LGUICanvasScaler = nil
local PointerEventData = nil

local ScreenSpaceActor = nil
local IsUIToWorld = false

local dialog_detection
local VideoPlay_detection
local IsUIInteraction = false
local CA_IsUIInteraction = false
local IsDialogue = false
local IsPaused = true
local bForceHideCursor = false

--InputConfig 
local InputInterval = 0.5

local isCameraFixed = false
local ZoomValue = 150
local ZOffset = 30

local start_timer = 0
local first_CameraActor = false
local VRMod_Initialized = false

local hook_started = false
local UIDistanceDialog = 0
local UIHeightDialog = 0
local UIHeight_Default = 1
local CamOffset_Y = 0
local CamAdjustRateByRenderMode = 1
local CineCamLoc_LastFrame = vector
local CineCamRot_LastFrame = rotator
local bCineCameraChangedPos = false
local CameraDistIncrementFactor = 1


local first_recenter = nil
local first_recenter_counter = 0

local is_freecam = false
local UIMode_To = 0
local UIMode_Current = 0
local isUIHidden = false
local ShouldHideUI = false

local InputLastTime = 0.0
local print_LastTime = 0.0


local default_view_target = nil
local last_view_target = nil
local last_view_target_name = "BP_CharacterController_C"
local view_target_name = ""
local df_view_target_name = ""
local camera_actor = nil
local camera_component = nil

local level = nil
local last_level = nil

local hud_actor = nil
local current_hud_actor = nil

-- FPS Mode 
local FPCameraActor = nil
local bIsFPMode = false
local bShouldToFPMode = false
local CheckFPHidden_LastTime = 0.0
--DecoupledPitch
local bIsDecoupedPitch = true
local bShouldDecoupledPitch = true

-- initalize lookup table for counting pressed button.
local bitCountLUT = {}
for i = 0, 255 do
    local v, c = i, 0
    while v ~= 0 do
        v = v & (v - 1)
        c = c + 1
    end
    bitCountLUT[i] = c
end

-- count pressed button
local function countPressedButtons(wButtons)
    return bitCountLUT[wButtons & 0xFF] + bitCountLUT[(wButtons >> 8) & 0xFF]
end


local function SafeIsValid(InObj)
	local ok
	local valid
	ok = pcall(function()
		InObj:get_fname():to_string()
	end) 
	if ok then
		ok, valid = pcall(function()
			return KismetSysLib:IsValid(InObj)
		end)

		if not ok then
			KismetSysLib = KismetSysLib_C:get_class_default_object()
			print("Kismet system library ref is not valid, trying to get it!!")
			return false
		else
			return valid	
		end
	else
		return false
	end
	
end

local function FName(InStr)
    return KismetStrLib:Conv_StringToName(InStr)
end

-- Get UEVR setting 
local function get_mod_value(str)

	str = tostring(m_VR:get_mod_value(str))
	str = str:gsub("[\r\n%z]", "")
	str = str:match("^%s*(%S+)") or ""
	return str
	
end

-- check if playing video
local function GetIsVideoPlaying()
	local MediaPlayer = api:find_uobject("MediaPlayer /Game/Aki/UI/UIResources/UiPlot/VideoPlayer/CommonVideoPlayer.CommonVideoPlayer")
	local IsPlaying = false
	if SafeIsValid(MediaPlayer) then
	
		IsPlaying = MediaPlayer:IsPlaying()
	
	end
	return IsPlaying
end

-- 1st person mode functions
local function SpawnFirstPersonCamera()
	local world = player_controller:get_outer():get_outer()
	FPCameraActor = GameplayStatics:BeginDeferredActorSpawnFromClass(world, CameraActor_C, relative_transform, 1, nil, 0)

end

local function SetFPCameraHeight(InHeight)
	if SafeIsValid(FPCameraActor) then
		local RootCom = FPCameraActor:K2_GetRootComponent()
		local RelativeLoc = StructObject.new(vector_c)
		RelativeLoc.Z = InHeight
		RootCom:K2_SetRelativeLocation(RelativeLoc, false, fhitresult, true)
	end
end

local function AttachFPCameraToPawn(InPawn)
	if SafeIsValid(FPCameraActor) and SafeIsValid(InPawn) then
		FPCameraActor:K2_AttachToActor(InPawn, FName("none"), 1, 1, 1, true)
		FPCameraActor:K2_GetRootComponent():SetAbsolute(false, true, false)
		SetFPCameraHeight(FirstPersonModeHeadPos)
	end
end

local function GetIsCharFullyHidden(InChar)
	if SafeIsValid(InChar) then
		return false
	end
	
	local bIsFullyHidden = true
	bIsFullyHidden = InChar.bHidden

	if not bIsFullyHidden then
		return false
	end

	local EffectActors = {}
	InChar:GetAttachedActors(EffectActors, true, false)

	for i, Actor in ipairs(EffectActors) do
		if Actor:is_a(EffectSystemActor_C) then
			bIsFullyHidden = bIsFullyHidden and Actor.bHidden
		end
	end

	return bIsFullyHidden
end

local function SetHideCharAndEffect(InActor, InHide)
	if not SafeIsValid(InActor) then
		return
	end

	local EffectActors = {}
	InActor:GetAttachedActors(EffectActors, true, false)
	InActor:SetActorHiddenInGame(InHide)

	for i, Actor in ipairs(EffectActors) do
		if Actor:is_a(EffectSystemActor_C) then
			print("Hide effect actor:" .. tostring(Actor:get_fname()))    
			Actor:SetActorHiddenInGame(InHide)
		end
	end

end

local function SetFPMode(InBool)
	if not IsUIToWorld and InBool then
		return 
	end

	if not SafeIsValid(FPCameraActor) then
		SpawnFirstPersonCamera()
	end

	if InBool then
		print("Switch to 1st person mode!!")
		if SafeIsValid(local_pawn) then
			AttachFPCameraToPawn(local_pawn)
			player_controller:SetViewTargetWithBlend(FPCameraActor, 0.1, 0, 1, false,false)

			SetHideCharAndEffect(local_pawn, true)
			if SafeIsValid(ScreenSpaceActor) then
				ScreenSpaceActor:K2_AttachToActor(FPCameraActor, FName("none"), 1, 1, 1, true)
			end
		end
		ShouldHideUI = bHideUI_FPMode
		local OrientationMode = (bUseHMDOrientation_FPMode == true) and 1 or 0
		m_VR.set_mod_value("VR_MovementOrientation", OrientationMode)
	else
		print("Switch to 3rd person mode!!")
		player_controller:SetViewTargetWithBlend(hud_actor, 0.1, 0, 1, false,false)
		if SafeIsValid(local_pawn) then
			SetHideCharAndEffect(local_pawn, false)
			--local_pawn:SetActorHiddenInGame(false)	
			
			if SafeIsValid(ScreenSpaceActor) then
				ScreenSpaceActor:K2_AttachToActor(default_view_target, FName("none"), 1, 1, 1, true)
			end
		end
		ShouldHideUI = false
		m_VR.set_mod_value("VR_MovementOrientation", 0)
	end

	bIsFPMode = InBool
end

-- Set UI to World spcae, and set VR mode to 3D.
local function SetUIToWorld()
	-- set 2d screen mod off
	m_VR.set_mod_value("VR_2DScreenMode", "false")
	-- remeber decoupled pitch setup
	if bShouldDecoupledPitch == true then
		bIsDecoupedPitch = true
		m_VR.set_mod_value("VR_DecoupledPitch", "true")
	end
	
	ScreenSpace = UEVR_UObjectHook.get_first_object_by_class(ScreenSpace_c)
	LGUICanvasScaler = UEVR_UObjectHook.get_first_object_by_class(LGUICanvasScaler_c)
	
	ScreenSpaceActor = ScreenSpace:get_outer()

	if SafeIsValid(default_view_target) then
		if SafeIsValid(hud_actor) then
			hud_actor:K2_AttachToActor(default_view_target, FName("none"), 1, 1, 1, true)
		end

		if SafeIsValid(ScreenSpaceActor) then
			ScreenSpaceActor:K2_AttachToActor(default_view_target, FName("none"), 1, 1, 1, true)
		end
	end


	if LGUICanvasScaler.Canvas:GetRenderMode() == 0 then -- Fix and force UI to be redrawn
		
		local LGUICanvas_arr = LGUICanvas_c:get_objects_matching(false)
		local UIDrawcallMesh_arr = UIDrawcallMesh_c:get_objects_matching(false)
		
		for i, nObj in ipairs(UIDrawcallMesh_arr) do
			nObj:SetVisibility(false, true)
		end

		for i, nObj in ipairs(LGUICanvas_arr) do
			nObj:SetRenderMode(0)
			nObj:SetRenderMode(1)
		end
		
		print("Render Mode Changed!")
		log_functions.log_warn("LuaUIFix: Render Mode Changed!")
	
	end

	ScreenSpaceActor:SetActorScale3D(Vector3d.new(WorldUI_Scale, WorldUI_Scale, WorldUI_Scale))
	m_VR.set_mod_value("VR_WorldScale", WorldScale_VR)
	m_VR.set_mod_value("UI_Distance", UEVR_UI_Dist)

	print("UIItem Size", ScreenSpaceActor.UIItem:GetWidth(), ScreenSpaceActor.UIItem:GetHeight())
	log_functions.log_warn("LuaUIFix: UIItem Size " .. tostring(ScreenSpaceActor.UIItem:GetWidth()) .. "x" .. tostring(ScreenSpaceActor.UIItem:GetHeight()))
	
	IsUIToWorld = true

	--[[ if default_view_target == nil and SafeIsValid(player_controller) then
		default_view_target = player_controller:GetViewTarget()
	end ]]

	if SafeIsValid(player_controller) and SafeIsValid(hud_actor) then
		player_controller:SetViewTargetWithBlend(hud_actor, 0.5, 0, 1, false,false)	
	end
	
	if bShouldToFPMode then
		SetFPMode(true)
	end

	print("SetUIToWorld Called!")
	log_functions.log_warn("LuaUIFix: SetUIToWorld Called!")
	
end

local function MakeNewRot(Pitch, Yaw, Roll)
	local NewRot = StructObject.new(rotator_c)
	NewRot.Pitch = Pitch
	NewRot.Yaw = Yaw
	NewRot.Roll = Roll
	return NewRot
end
	
local function clearConsole()
	-- fake clear console
	for i = 1, 30 do 
		print ""
	end 
end

--set UI back to Screen space, and set VR mode back to 2D.
local function SetUIToScreenSpace()
	-- set 2d screen mod on
	m_VR.set_mod_value("VR_2DScreenMode", "true")
	m_VR.set_mod_value("VR_DecoupledPitch", "false")
	bIsDecoupedPitch = false
	
	ScreenSpace = UEVR_UObjectHook.get_first_object_by_class(ScreenSpace_c)
	LGUICanvasScaler = UEVR_UObjectHook.get_first_object_by_class(LGUICanvasScaler_c)
	
	ScreenSpaceActor = ScreenSpace:get_outer()
	
	-- Fix and force UI to be redrawn
	local LGUICanvas_arr = LGUICanvas_c:get_objects_matching(false)
	local UIDrawcallMesh_arr = UIDrawcallMesh_c:get_objects_matching(false)

	for i, nObj in ipairs(UIDrawcallMesh_arr) do
		nObj:SetVisibility(false, true)
	end

	for i, nObj in ipairs(LGUICanvas_arr) do
		nObj:SetRenderMode(0)
	end	

	for i, nObj in ipairs(LGUICanvas_arr) do
		if nObj ~= LGUICanvasScaler.Canvas then 
			nObj:SetRenderMode(1)
		end
	end	

	--set transform back to what is should be
	ScreenSpaceActor:K2_DetachFromActor(1, 1, 1)
	ScreenSpaceActor:K2_SetActorRelativeLocation(Vector3d.new(0, 0, 100), false, fhitresult, false)
	ScreenSpaceActor:K2_SetActorRelativeRotation(MakeNewRot(0, 0, -90), false, fhitresult, false)
	ScreenSpaceActor:SetActorScale3D(Vector3d.new(1, 1, 1))

	print("Render Mode Changed to screen space!")
	log_functions.log_warn("LuaUIFix: Render Mode Changed! To screen space!")
	
	m_VR.set_mod_value("VR_WorldScale", WorldScale_2D)

	IsUIToWorld = false
	if SafeIsValid(player_controller) and SafeIsValid(default_view_target) then
		player_controller:SetViewTargetWithBlend(default_view_target, 0.5, 0, 1, false,false)	
	end

	m_VR.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
	print("[LHB_UIFix_Debug] Hide Cursor!")
	log_functions.log_warn("LuaUIFix: SetUIToScreenSpace Called!")
	
	if bIsFPMode then
		SetFPMode(false)
	end 
end

--add new camera to support manipulating relative location.
local function setCameraComponent(camera_actor)

	hud_actor = player_controller:GetHUD()
	
	if SafeIsValid(hud_actor) then
		camera_component = hud_actor:GetComponentByClass(CameraComponent_c)
		
		if not SafeIsValid(camera_component) then
			camera_component = hud_actor:AddComponentByClass(CameraComponent_c, false, relative_transform, false, FName("MyCameraComponent"))
			
			print("new CameraComponent added!")
			log_functions.log_warn("LuaUIFix: new CameraComponent added!")
		end
		
		if not camera_component:IsActive() then camera_component:Activate() end
		
		camera_component:SetFieldOfView(76)
	
		default_view_target = camera_actor
		log_functions.log_warn("LuaUIFix: default_view_target " .. default_view_target:get_full_name())
		print("LuaUIFix: default_view_target " .. default_view_target:get_full_name())
		if IsUIToWorld then
			player_controller:SetViewTargetWithBlend(hud_actor, 0.5, 0, 1, false,false)	
		end
			
	end

end

--Fix Mini Map vars
local FixMiniMapScale_LastTime = 0
local CheckMiniMapParent_LastTime = 0
local FixMiniMap_Delay = 15
local MiniMapIconParent = nil
local LevelChanged_LastTime = 0

local ShouldAutoTo2D_OnLevelChange = false
local UI_FixLocalRot = MakeNewRot(0, 90, -90)

--Fix Mini Map functions
local function FixMiniMapIconScale(InNewScale, MiniMapParent)
	if SafeIsValid(MiniMapParent) then
		local Icons = {}
		MiniMapParent:GetChildrenComponents(false, Icons)
		for i, Icon in ipairs(Icons) do
			Icon:SetRelativeScale3D(Vector3d.new(InNewScale, InNewScale, InNewScale))
			--print(string.format("[MiniMapFix] Fixed Scale : %s", Icon:get_full_name()))
		end
	end
end

local function GetMiniMapIconParent()
	local ScreenSpaceInteraction = UEVR_UObjectHook.get_first_object_by_class(ScreenSpace_c)
	local SearchParent = ScreenSpaceInteraction:GetAttachParent()
	local MiniMapStructPos = {1, 0, 0, 4, 0, 2, 1, 0, 2}

	if SafeIsValid(SearchParent) then
		for i, pos in ipairs(MiniMapStructPos) do
			local Children = {}
			SearchParent:GetChildrenComponents(false, Children)
			for i, child in ipairs(Children) do
				if child:is_a(UIItem_c:as_class()) and pos == child:GetHierarchyIndex() then
					SearchParent = child
					--print(string.format("Name: %s\nWorldScale: %s\nRelativeScale: %s\n", SearchParent:get_full_name(), GetFVectorStr(SearchParent:K2_GetComponentScale()), GetFVectorStr(SearchParent.RelativeScale3D)))
					goto NextHierachy
				end
			end

			::NextHierachy::
		end
	end

	return SearchParent
end

local function FixMiniMapTick(InDelta)
	if UIMode_To == 3 then
		if not SafeIsValid(MiniMapIconParent) then
			if CheckMiniMapParent_LastTime <= 1 then
				CheckMiniMapParent_LastTime = CheckMiniMapParent_LastTime + InDelta
			else
				MiniMapIconParent = GetMiniMapIconParent()
				CheckMiniMapParent_LastTime = 0
			end
		else
			if FixMiniMapScale_LastTime <= 0.2 then
				FixMiniMapScale_LastTime = FixMiniMapScale_LastTime + InDelta
			else
				FixMiniMapIconScale(0.5, MiniMapIconParent)
				FixMiniMapScale_LastTime = 0
			end
		end
	end
end

local function ResetCutSceneCamOffset()
	UIDistanceDialog = 0
	UIHeightDialog = UIHeight_Default
	CamOffset_Y = 0
end





local function SetRotBasedDecoupledPitch(InActor, InRot)
	if SafeIsValid(InActor) then
		local LocalPawn = api:get_local_pawn(0)
		local UpVec = LocalPawn.CharacterMovement:Kuro_GetGravityDirect() * -1
		
		local bIsSpecialGravity = kismet_math_library:DegAcos(kismet_math_library:Dot_VectorVector(UpVec, Vector3d.new(0, 0, 1))) > 5

		if bIsSpecialGravity then
			if get_mod_value("VR_DecoupledPitch") == "true" then
				m_VR.set_mod_value("VR_DecoupledPitch", "false")
			end

			if bIsDecoupedPitch then
				
				local MadeRotator_Z = kismet_math_library:MakeRotFromZ(UpVec)

				local TeampRot = kismet_math_library:ComposeRotators(InRot, kismet_math_library:NegateRotator(MadeRotator_Z))

				if InActor ~= ScreenSpaceActor then
					TeampRot = MakeNewRot(0, TeampRot.Yaw, 0)
				end
				TeampRot = kismet_math_library:ComposeRotators(TeampRot, MadeRotator_Z)
				InActor:K2_SetActorRotation(TeampRot, false, fhitresult, false)
			else
				InActor:K2_SetActorRotation(InRot, false, fhitresult, false)
			end

		else
			if bIsDecoupedPitch then
				if get_mod_value("VR_DecoupledPitch") == "false" then
					m_VR.set_mod_value("VR_DecoupledPitch", "true")
				end
				
				if InActor == ScreenSpaceActor then
					InRot = MakeNewRot(0, InRot.Yaw, InRot.Roll)
				end
			else	
				if get_mod_value("VR_DecoupledPitch") == "true" then
					m_VR.set_mod_value("VR_DecoupledPitch", "false")
				end
			end
			
			InActor:K2_SetActorRotation(InRot, false, fhitresult, false)
		end
		
	end
end

local function ChangeRenderingMethod(InRenderingMode)
	RenderingMode = InRenderingMode
	if InRenderingMode < 1 then
		m_VR.set_mod_value("VR_RenderingMethod", InRenderingMode)
	else
		m_VR.set_mod_value("VR_RenderingMethod", 1)
		if InRenderingMode < 2 then
			m_VR.set_mod_value("VR_SyncedSequentialMethod", 1)
		else
			m_VR.set_mod_value("VR_SyncedSequentialMethod", 0)
		end
	end
	WriteConfig()
end

-- user config UI
uevr.sdk.callbacks.on_draw_ui(function()
	imgui.text("Wuthering Waves Mod Settings")
    imgui.text("Mod by Polar and Sannpokun")
    imgui.text("")
	
	if not VRMod_Initialized then
		imgui.text("Please wait for Mod initialization complete!!")
		return
	end

	local bNeedSave = false
	local changed, new_value

	changed, new_value = imgui.slider_int("Rendering Method", RenderingMode, 0, 2)
	if changed then
		ChangeRenderingMethod(new_value)
	end

	changed, new_value = imgui.drag_float("World Scale in VR", WorldScale_VR, 0.01, 0.01, 10)
	if changed then
		WorldScale_VR = new_value
		if get_mod_value("VR_2DScreenMode") == "false" then
			m_VR.set_mod_value("VR_WorldScale", WorldScale_VR)
		end
		bNeedSave = true
	end
	
	changed, new_value = imgui.drag_float("World Scale in 2D Mode", WorldScale_2D, 0.01, 0.01, 10)
	if changed then 
		WorldScale_2D = new_value
		if get_mod_value("VR_2DScreenMode") == "true" then
			m_VR.set_mod_value("VR_WorldScale", WorldScale_2D)
		end
		bNeedSave = true
	end

	changed, new_value = imgui.drag_float("1st Person Height(Standing)", FirstPersonModeHeadPos, 1, -100, 100)
	if changed then 
		FirstPersonModeHeadPos = new_value
		if bIsFPMode and SafeIsValid(FPCameraActor) then
			SetFPCameraHeight(FirstPersonModeHeadPos)
		end
		bNeedSave = true
	end

	changed, new_value = imgui.drag_float("1st Person Height(Crouch)", FirstPersonModeHeadPos_Crouch, 1, -100, 100)
	if changed then 
		FirstPersonModeHeadPos_Crouch = new_value
		if bIsFPMode and SafeIsValid(FPCameraActor) then
			SetFPCameraHeight(FirstPersonModeHeadPos_Crouch)
		end
		bNeedSave = true
	end
	
	changed, new_value = imgui.checkbox("Auto Decide Decoupled Pitch", bAutoDecideDecoupledPitch)
	if changed then
		bAutoDecideDecoupledPitch = new_value
		if bAutoDecideDecoupledPitch then
			if UIMode_To == 3 then
				bIsDecoupedPitch = true
			else
				bIsDecoupedPitch = false
			end
		end
		bNeedSave = true
	end

	changed, new_value = imgui.checkbox("Hide UI(1st Person)", bHideUI_FPMode)
	if changed then
		bHideUI_FPMode = new_value
		if bIsFPMode then
			ShouldHideUI = bHideUI_FPMode
		end
		bNeedSave = true
	end

	changed, new_value = imgui.checkbox("Use HMD Orientation(1st Person)", bUseHMDOrientation_FPMode)
	if changed then
		bUseHMDOrientation_FPMode = new_value
		if bIsFPMode then
			local OrientationMode = (bUseHMDOrientation_FPMode == true) and 1 or 0
			m_VR.set_mod_value("VR_MovementOrientation", OrientationMode)
		end
		bNeedSave = true
	end

	if bNeedSave then
		WriteConfig()
	end

end)

local StartBtnPress_LastTime = 0

--------------------------------------------------------------------------------Engin Post Tick
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)   
    -- handling input interval check
    if InputLastTime <= 1.0 then 
        InputLastTime = InputLastTime + delta 
    end
	--used for debug print frequency control
	print_LastTime = print_LastTime + delta	

	if LevelChanged_LastTime < 50 then
		LevelChanged_LastTime = LevelChanged_LastTime + delta
	end

	if StartBtnPress_LastTime <= 1 then
		StartBtnPress_LastTime = StartBtnPress_LastTime + delta
	end

	if CheckFPHidden_LastTime <= 1 then
		CheckFPHidden_LastTime = CheckFPHidden_LastTime + delta
	end

end)


--------------------------------------------------------------------------------Engin Pre Tick
uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)

	player_controller = api:get_player_controller(0)
	level = player_controller:get_outer()

	camera_actor = player_controller:GetViewTarget()
	
	view_target_name = string.sub(camera_actor:get_full_name(), 0, 11)
	TickDelta = delta

	CamAdjustRateByRenderMode = RenderingMode == 2 and 0.5 or 1

	if string.sub(view_target_name, 0, 5) == "Actor" then
		is_freecam = true
	else
		is_freecam = false
	end
	-- check level change
	if level ~= last_level then
		last_level = level
		MiniMapIconParent = nil
		LevelChanged_LastTime = 0
		default_view_target = nil
		if VRMod_Initialized then
			ShouldAutoTo2D_OnLevelChange = true
		end
		-- Reset 1st person mode vars.
		FPCameraActor = nil
		bIsFPMode = false
		print(string.format("Level Changed! Current Level is : %s", level:get_full_name()))
	end

	if VRMod_Initialized then
		current_hud_actor = player_controller:GetHUD()
		if SafeIsValid(current_hud_actor) then
			if current_hud_actor ~= hud_actor then
				setCameraComponent(camera_actor)
			end
		end
	end
	
	if view_target_name == "DefaultPawn" then
	
		if get_mod_value("VR_2DScreenMode") == "false" then
		
			m_VR.set_mod_value("VR_2DScreenMode", "true")
		
		end
		
		first_recenter = os.time()
		
		m_VR.set_mod_value("VR_SnapturnJoystickDeadzone", 0.200000)
		
	end
	
	
	if camera_actor ~= last_view_target then
	
		if VRMod_Initialized then
		
			if string.sub(view_target_name, 0, 3) ~= "HUD" and not is_freecam and not bIsFPMode then
			
				default_view_target = camera_actor
				log_functions.log_warn("LuaUIFix: default_view_target " .. default_view_target:get_full_name())
				
				if SafeIsValid(default_view_target) and IsUIToWorld then
					if SafeIsValid(hud_actor) then
						hud_actor:K2_AttachToActor(default_view_target, FName("none"), 1, 1, 1, true)
					end

					if SafeIsValid(ScreenSpaceActor) then
						ScreenSpaceActor:K2_AttachToActor(default_view_target, FName("none"), 1, 1, 1, true)
					end
					
				end

			end
			
		end
	
		print("Current ViewTarget", camera_actor:get_full_name())
		log_functions.log_warn("LuaUIFix: Current ViewTarget " .. camera_actor:get_full_name())
		
		last_view_target = camera_actor
		
	end
	
	local_pawn = api:get_local_pawn(0)

	if SafeIsValid(default_view_target) and SafeIsValid(hud_actor) and SafeIsValid(ScreenSpaceActor) and SafeIsValid(local_pawn) then
	
		df_view_target_name = string.sub(default_view_target:get_fname():to_string(), 0, 11)

		if IsUIToWorld then 

			local LocalPawn_Location = local_pawn:K2_GetActorLocation()

			local DefaultViewTarget_Rot = default_view_target:K2_GetActorRotation()
			local DefaultViewTarget_Location = default_view_target:K2_GetActorLocation()
			local forward_vector = kismet_math_library:Conv_RotatorToVector(DefaultViewTarget_Rot)
			local GameCam_Right_Vec = default_view_target:GetActorRightVector()
			local GameCam_Up_Vec = default_view_target:GetActorUpVector()

			local Hud_Location_Target = Vector3d.new(0,0,0)
			local Hud_Rot_Target = StructObject.new(rotator_c)
			local UI_Location_Target = Vector3d.new(0,0,0)
			local UI_Rot_Target = StructObject.new(rotator_c)

			local LGUI_Map_UI_Params_Inst = UEVR_UObjectHook.get_first_object_by_class(LGUI_Map_UI_Params_C)
			
			if isCameraFixed and df_view_target_name == "CameraActor" and not IsUIInteraction then

				Hud_Location_Target = LocalPawn_Location - (forward_vector * ZoomValue)
				Hud_Location_Target.Z = Hud_Location_Target.Z + ZOffset
				
				SetRotBasedDecoupledPitch(hud_actor, DefaultViewTarget_Rot)
				Hud_Location_Target.Z = kismet_math_library:FInterpTo(hud_actor:K2_GetActorLocation().Z, Hud_Location_Target.Z, delta, 10)
				hud_actor:K2_SetActorLocation(Hud_Location_Target, false, fhitresult, false)
				
				UI_Location_Target = Hud_Location_Target + (forward_vector * 200)
			
				UI_Rot_Target = kismet_math_library:ComposeRotators(UI_FixLocalRot, DefaultViewTarget_Rot)
				
				--ScreenSpaceActor:K2_SetActorRotation(UI_Rot_Target, false, fhitresult, false)
				SetRotBasedDecoupledPitch(ScreenSpaceActor, UI_Rot_Target)

				if is_freecam or isUIHidden then UI_Location_Target.Z = -99999 end
				ScreenSpaceActor:K2_SetActorLocation(UI_Location_Target, false, fhitresult, false)
                UIMode_To = 1

			elseif IsUIInteraction then

				Hud_Location_Target = DefaultViewTarget_Location - (forward_vector * UIDistanceDialog) + (GameCam_Right_Vec * CamOffset_Y) + (GameCam_Up_Vec * UIHeightDialog)

				SetRotBasedDecoupledPitch(hud_actor, DefaultViewTarget_Rot)
				hud_actor:K2_SetActorLocation(Hud_Location_Target, false, fhitresult, false)
				
				UI_Location_Target = hud_actor:K2_GetActorLocation() + (forward_vector * 200)
				
				UI_Rot_Target = kismet_math_library:ComposeRotators(UI_FixLocalRot, DefaultViewTarget_Rot)
				--ScreenSpaceActor:K2_SetActorRotation(UI_Rot_Target, false, fhitresult, false)
				SetRotBasedDecoupledPitch(ScreenSpaceActor, UI_Rot_Target)
				if is_freecam or isUIHidden then UI_Location_Target.Z = -99999 end
		
				ScreenSpaceActor:K2_SetActorLocation(UI_Location_Target, false, fhitresult, false)
				UIMode_To = 2
			else 
				
				SetRotBasedDecoupledPitch(hud_actor, DefaultViewTarget_Rot)
				hud_actor:K2_SetActorLocation(DefaultViewTarget_Location, false, fhitresult, false)
				
				if bIsFPMode and SafeIsValid(FPCameraActor) then
					UI_Location_Target = FPCameraActor:K2_GetActorLocation() + (forward_vector * 200)
					SetRotBasedDecoupledPitch(FPCameraActor, DefaultViewTarget_Rot)
				else
					UI_Location_Target = DefaultViewTarget_Location + (forward_vector * 200)
				end
				
				UI_Rot_Target = kismet_math_library:ComposeRotators(UI_FixLocalRot, DefaultViewTarget_Rot)
				--ScreenSpaceActor:K2_SetActorRotation(UI_Rot_Target, false, fhitresult, false)
				SetRotBasedDecoupledPitch(ScreenSpaceActor, UI_Rot_Target)
				if is_freecam or isUIHidden then UI_Location_Target.Z = -99999 end
				ScreenSpaceActor:K2_SetActorLocation(UI_Location_Target, false, fhitresult, false)
				UIMode_To = 3
			end
			
			if UIMode_To ~= 3 then
				-- End 1st person mode if not in free locomotion.
				if bIsFPMode then
					SetFPMode(false)
				end

				if bAutoDecideDecoupledPitch then
					bShouldDecoupledPitch = false
					bIsDecoupedPitch = false
				end
			end
			
			if UIMode_To ~= UIMode_Current then
				-- auto decide decoupled pitch settings based on user config.
				if bAutoDecideDecoupledPitch then
					if UIMode_To == 3 then
						bIsDecoupedPitch = true
					else
						bIsDecoupedPitch = false
					end
				end

				if UIMode_To == 3 and bShouldToFPMode then
					SetFPMode(true)
				end

				ResetCutSceneCamOffset()
				
			end

			-- we are in VR mode, switch to VR camera if are not using it.
			if SafeIsValid(hud_actor) and SafeIsValid(camera_actor) then
				if camera_actor ~= hud_actor and not is_freecam and not bIsFPMode then
					player_controller:SetViewTargetWithBlend(hud_actor, 0.5, 0, 1, false,false)	
				end
			end

			-- handle changing player character in 1st person mode
			if bIsFPMode then
				if CheckFPHidden_LastTime > 0.1 then
					if GetIsCharFullyHidden(local_pawn) == false then
						SetHideCharAndEffect(local_pawn, true)
						--local_pawn:SetActorHiddenInGame(true)
					end
					CheckFPHidden_LastTime = 0
				end
				

				if local_pawn ~= LastFrame_LocalPawn then
					AttachFPCameraToPawn(local_pawn)
				end

				if camera_actor ~= FPCameraActor and not is_freecam then
					player_controller:SetViewTargetWithBlend(FPCameraActor, 0.0, 0, 1, false,false)
				end
			end

			UIMode_Current = UIMode_To

		else
			-- we are in 2D mode, switch back to default camera if we are not using it.
			if SafeIsValid(default_view_target) and SafeIsValid(camera_actor) then
				if camera_actor ~= default_view_target and not is_freecam then
					player_controller:SetViewTargetWithBlend(default_view_target, 0.5, 0, 1, false,false)	
				end
			end
		end

		if isUIHidden ~= ShouldHideUI then 
			if ShouldHideUI then 
				m_VR.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
				ScreenSpaceActor:SetActorScale3D(Vector3d.new(0,0,0))
				isUIHidden = true
			else
				ScreenSpaceActor:SetActorScale3D(Vector3d.new(WorldUI_Scale, WorldUI_Scale, WorldUI_Scale))
				isUIHidden = false
			end
			
		end
        --if cutscene camera changed view, we reset cam offset
		if default_view_target:is_a(CineCameraActor_C) then
			local LocDiff = default_view_target:K2_GetActorLocation() - CineCamLoc_LastFrame
			local Fwd_Vec_Current = kismet_math_library:GetForwardVector(default_view_target:K2_GetActorRotation())
			local Fwd_Vec_Last = kismet_math_library:GetForwardVector(CineCamRot_LastFrame)

			local bPosChanged = kismet_math_library:VSize(LocDiff) > 30
			local bRotChanged = kismet_math_library:DegAcos(kismet_math_library:Dot_VectorVector(Fwd_Vec_Current, Fwd_Vec_Last)) > 10
			if bPosChanged or bRotChanged then
				ResetCutSceneCamOffset()
				bCineCameraChangedPos = true
			end

			CineCamLoc_LastFrame = default_view_target:K2_GetActorLocation()
			CineCamRot_LastFrame = default_view_target:K2_GetActorRotation()
		end
	end
	
    if not first_CameraActor and not VRMod_Initialized and view_target_name == "CameraActor" then
	
		first_CameraActor = true
		start_timer = os.time()
			
    elseif not first_CameraActor and not VRMod_Initialized and get_mod_value("VR_SnapturnJoystickDeadzone") == "0.200001" then
	
		first_CameraActor = true
		start_timer = os.time()
		
	end

	if first_CameraActor and not VRMod_Initialized then
		if os.time() - start_timer >= 3 then
		
			if not hook_started then
			
				dialog_detection()

				VideoPlay_detection()
		
				print("hook_started!")
				log_functions.log_warn("LuaUIFix: hook_started!")
				
				hook_started = true
				
			end
			
			local IsPlayingVideo = GetIsVideoPlaying()
			
			if not IsPlayingVideo then
			
                setCameraComponent(camera_actor)

                SetUIToWorld()

                first_CameraActor = false
                
                m_VR.set_mod_value("VR_SnapturnJoystickDeadzone", 0.200001)

				print("First time UI to world!")

				VRMod_Initialized = true
			
			end
			
			start_timer = os.time()
		
		end
	
	end


	-- try to fix mini map icon scale 
	if IsUIToWorld and LevelChanged_LastTime > FixMiniMap_Delay then
		FixMiniMapTick(delta)	
	end

	-- Delay set to 2d mode on level changed.
	if LevelChanged_LastTime > 2 and ShouldAutoTo2D_OnLevelChange then
		SetUIToScreenSpace()
		ShouldAutoTo2D_OnLevelChange = false
	end

	LastFrame_LocalPawn = local_pawn
	

end)

local rouletteInteraction = false
--Back
local Is_Back_Pressed_LastFrame = false
local isBackCombinationInput = false
local isBackTheFirstInput = false
--Start
local Is_Start_Pressed_LastFrame = false
local isStartCombinationInput = false
local isStartTheFirstInput = false
local StartBtnPressCount = 0
--RB
local Is_RB_Pressed_LastFrame = false
local isRBCombinationInput = false
--LB
local Is_LB_Pressed_LastFrame = false
local isLBCombinationInput = false
local Is_L3_Pressed_LastFrame = false
local isL3CombinationInput = false

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

	player_controller = api:get_player_controller(0)
	camera_actor = player_controller:GetViewTarget()
	
	local bShowMouse = player_controller.bShowMouseCursor
	
	if SafeIsValid(default_view_target) then
	
		df_view_target_name = string.sub(default_view_target:get_fname():to_string(), 0, 11)
		
	end

    local gamepad = state.Gamepad
	
	local DPAD_UP = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP ~= 0
	local DPAD_DOWN = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_DOWN ~= 0
	local DPAD_LEFT = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_LEFT ~= 0
	local DPAD_RIGHT = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT ~= 0
	local START = gamepad.wButtons & XINPUT_GAMEPAD_START ~= 0
	local BACK = gamepad.wButtons & XINPUT_GAMEPAD_BACK ~= 0
	local LEFT_THUMB = gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0
	local RIGHT_THUMB = gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB ~= 0
	local LEFT_SHOULDER = gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0
	local RIGHT_SHOULDER = gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0
	local GAMEPAD_Y = gamepad.wButtons & XINPUT_GAMEPAD_Y ~= 0
	local GAMEPAD_X = gamepad.wButtons & XINPUT_GAMEPAD_X ~= 0
	local GAMEPAD_A = gamepad.wButtons & XINPUT_GAMEPAD_A ~= 0
	local GAMEPAD_B = gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0
    local leftTrigger = gamepad.bLeftTrigger ~= 0
	local rightTrigger = gamepad.bRightTrigger ~= 0

	
	--Reset Start button state on released.
	if not START and Is_Start_Pressed_LastFrame == true then
		if not isStartCombinationInput then
			if UIMode_To == 3 then
				gamepad.wButtons = gamepad.wButtons | XINPUT_GAMEPAD_START
			end
		end
		isStartCombinationInput = false
		isStartTheFirstInput = false
	end
	--Register Start button as the first input in the combination.
	if START and not Is_Start_Pressed_LastFrame and countPressedButtons(gamepad.wButtons) == 1 then
		isStartTheFirstInput = true	
	end
	--Change rendering method by pushing Start first then pushing LB.
	if isStartTheFirstInput then
		if START and LEFT_SHOULDER then
			if not isLBCombinationInput then
				local NewRenderingMode = RenderingMode == 0 and 1 or 0
				ChangeRenderingMethod(NewRenderingMode)
			end
			isStartCombinationInput = true
			isLBCombinationInput = true
		end
	end

	--Make Menu only shows on button released.
	if START then
		gamepad.wButtons = gamepad.wButtons & ~XINPUT_GAMEPAD_START
	end
	
	--Reset back button state on released.
	if not BACK and Is_Back_Pressed_LastFrame == true then    
        if not isBackCombinationInput then
			if UIMode_To == 3 then
            	gamepad.wButtons = gamepad.wButtons | XINPUT_GAMEPAD_BACK
			else
				ShouldHideUI = not isUIHidden
			end
        end
        isBackCombinationInput = false
		isBackTheFirstInput = false
    end
	--Register Back button as the first input in the combination.
	if BACK and not Is_Back_Pressed_LastFrame and countPressedButtons(gamepad.wButtons) == 1 then
        isBackTheFirstInput = true
    end
	--If RB is the first button input, don't trigger switch screen until back is the first button input.
	if isBackTheFirstInput then
		-- Switch between 3d mode and 2d mode
		if BACK and RIGHT_SHOULDER then
			if not isRBCombinationInput then
				--print("Switch screen mode~~")
				if IsUIToWorld then 
					SetUIToScreenSpace()
				else
					SetUIToWorld()
				end
			end
			isBackCombinationInput = true
			isRBCombinationInput = true
		end

		if BACK and LEFT_SHOULDER then 
			if not isLBCombinationInput then 
				SetFPMode(not bIsFPMode)
				bShouldToFPMode = not bShouldToFPMode
			end
			isBackCombinationInput = true
			isLBCombinationInput = true
		end
	end

	--Make show map function only works on button released.
	if BACK then
		gamepad.wButtons = gamepad.wButtons & ~XINPUT_GAMEPAD_BACK
	end

	--Reset right shoulder button state on released.
    if not RIGHT_SHOULDER and Is_RB_Pressed_LastFrame == true then
        isRBCombinationInput = false
    end
	--Reset left shoulder button state on released.
	if not LEFT_SHOULDER and Is_LB_Pressed_LastFrame == true then
        isLBCombinationInput = false
    end

	if LEFT_THUMB and RIGHT_THUMB then
		isL3CombinationInput = true
	end

	-- hide ui
	if LEFT_THUMB and LEFT_SHOULDER then 
		if InputLastTime > InputInterval then 
			ShouldHideUI = not ShouldHideUI
			isLBCombinationInput = true
			InputLastTime = 0.0
			if bIsFPMode then
				bHideUI_FPMode = ShouldHideUI
				WriteConfig()
			end
			print(string.format("Switch UI hidden state: %s!!", tostring(ShouldHideUI)))
		end
		isL3CombinationInput = true
	end 
    

	-- change to decoupled pitch (mostly used when there's a coversation with other characters)
	if LEFT_THUMB and RIGHT_SHOULDER then 
		if InputLastTime > InputInterval then 
			if bIsDecoupedPitch == false then 
				bIsDecoupedPitch = true
				bShouldDecoupledPitch = true
			else
				bIsDecoupedPitch = false
				bShouldDecoupledPitch = false
			end
			InputLastTime = 0.0
		end
		isL3CombinationInput = true
	end
	
	

	--if switch screen mode triggered, disable game RB funtion if not released button.
	if RIGHT_SHOULDER and isRBCombinationInput then
		gamepad.wButtons = gamepad.wButtons & ~XINPUT_GAMEPAD_RIGHT_SHOULDER
	end	

    if IsUIToWorld and df_view_target_name == "CameraActor" then
		if RIGHT_THUMB and LEFT_SHOULDER then
			if InputLastTime > InputInterval then 
				isCameraFixed = not isCameraFixed
				print("isCameraFixed Changed!")
				InputLastTime = 0.0
			end
		end

		if LEFT_THUMB then
			
			if GAMEPAD_X and isCameraFixed then
			
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_X
				ZOffset = ZOffset - 1
			
			end
			
			if GAMEPAD_Y and isCameraFixed then
			
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_Y
				ZOffset = ZOffset + 1
			
			end
			
		end
		
		if LEFT_SHOULDER then
		
			if leftTrigger and isCameraFixed then
			
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_LEFT_SHOULDER
				ZoomValue = ZoomValue + 2
			
			end
			
			if rightTrigger and isCameraFixed then
			
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_LEFT_SHOULDER
				ZoomValue = ZoomValue - 2
			
			end
		
		end
		
	end
	
	if LEFT_THUMB then
		if GAMEPAD_A then
		
			state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_A
			isL3CombinationInput = true
		end	
	end

	if LEFT_THUMB ~= Is_L3_Pressed_LastFrame and not LEFT_THUMB then
		if not isL3CombinationInput then
			--switch between 2 different height (stand or crouch) in 1st person mode.
			if bIsFPMode and SafeIsValid(FPCameraActor) then

				if NearlyEqual(FPCameraActor:K2_GetRootComponent().RelativeLocation.Z, FirstPersonModeHeadPos, 0.1) then
					SetFPCameraHeight(FirstPersonModeHeadPos_Crouch)
				else
					SetFPCameraHeight(FirstPersonModeHeadPos)
				end 
				
			end
		end
		--Reset L3 button state on released.
		isL3CombinationInput = false
	end


	if InputLastTime < InputInterval then 
		state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_LEFT_SHOULDER
		state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_RIGHT_SHOULDER
		state.Gamepad.bLeftTrigger = 0
		state.Gamepad.bRightTrigger = 0
	end

	if RIGHT_THUMB then
		ResetCutSceneCamOffset()
		print("Reset UI distance!")	
	end

	if IsUIToWorld then

		if df_view_target_name ~= "CameraActor" or IsDialogue or bShowMouse or CA_IsUIInteraction or rouletteInteraction then

			IsUIInteraction = true
			
			if get_mod_value("FrameworkConfig_AlwaysShowCursor") == "false" and not is_freecam then
				if get_mod_value("VR_2DScreenMode") ~= "true" and not isUIHidden then
					m_VR.set_mod_value("FrameworkConfig_AlwaysShowCursor", "true")
					--ResetCutSceneCamOffset()
				end

				print('IsUIInteraction', IsUIInteraction)
				
				IsPaused = true
				print('IsPaused', IsPaused)
				log_functions.log_warn("LuaUIFix: IsPaused true")
	
				print('UIDistanceDialog', UIDistanceDialog)
			
			elseif get_mod_value("FrameworkConfig_AlwaysShowCursor") == "true" and is_freecam then
			
				m_VR.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
			
			end
		else
		
			IsUIInteraction = false
			
			if get_mod_value("FrameworkConfig_AlwaysShowCursor") == "true" then
			
				m_VR.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
				print('IsUIInteraction', IsUIInteraction)
			
			end
		
		end
	
	end
	-- only do this in 3d mode
	if get_mod_value("VR_2DScreenMode") == "false" then
		if IsUIInteraction and not rouletteInteraction then

			local bAdjustCamera = leftTrigger or LEFT_SHOULDER or rightTrigger or RIGHT_SHOULDER
			local bAdjustCamDist = leftTrigger or rightTrigger

			if not bAdjustCamera then
				bCineCameraChangedPos = false
			end

			if bAdjustCamDist then
				CameraDistIncrementFactor = CameraDistIncrementFactor * (1 + 0.05 * (72 * TickDelta) * CamAdjustRateByRenderMode) 
			else
				CameraDistIncrementFactor = 1		
			end

			local CamXChanges = 2 * CameraDistIncrementFactor * CamAdjustRateByRenderMode
			local CamYZChanges = 2 * CamAdjustRateByRenderMode

			if not bCineCameraChangedPos then
				if leftTrigger then UIDistanceDialog = UIDistanceDialog - CamXChanges end
				if rightTrigger then UIDistanceDialog = UIDistanceDialog + CamXChanges end
				
				if not LEFT_THUMB then 
					if GAMEPAD_Y then
						if LEFT_SHOULDER and not isLBCombinationInput then CamOffset_Y = CamOffset_Y - CamYZChanges end
						if RIGHT_SHOULDER then CamOffset_Y = CamOffset_Y + CamYZChanges end
					else
						if LEFT_SHOULDER and not isLBCombinationInput then UIHeightDialog = UIHeightDialog - CamYZChanges end
						if RIGHT_SHOULDER then UIHeightDialog = UIHeightDialog + CamYZChanges end
					end
					
				end
			end

			-- Blocking gamepad commands
			state.Gamepad.bLeftTrigger = 0
			state.Gamepad.bRightTrigger = 0
			
			state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_LEFT_SHOULDER
			state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_RIGHT_SHOULDER

			state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_Y
	
		end
	end
	
	if get_mod_value("FrameworkConfig_AlwaysShowCursor") == "true" and (bForceHideCursor or is_freecam) then
	
		m_VR.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
	
	end

	--Record last frame key state
	Is_Back_Pressed_LastFrame = BACK
    Is_RB_Pressed_LastFrame = RIGHT_SHOULDER
	Is_Start_Pressed_LastFrame = START
	Is_LB_Pressed_LastFrame = LEFT_SHOULDER
	Is_L3_Pressed_LastFrame = LEFT_THUMB
	
end)

local IsDialogueHook = nil
local IsNotDialogHook = nil

function dialog_detection()

	IsDialogueHook = LGUIBehaviour_c:find_function("OnEnableBP")

	if SafeIsValid(IsDialogueHook) then

		IsDialogueHook:set_function_flags(IsDialogueHook:get_function_flags() | 0x400)
		IsDialogueHook:hook_ptr(function(fn, obj, locals, result)

			if obj:get_class():get_full_name() == "Class /Script/LGUI.UIExtendToggleSpriteTransition" then
			
				if obj.TransitionState.CheckedHoverState.Sprite:get_fname():to_string() == "SP_PlotSkipBgIcon1" then
					
					IsDialogue = true
					IsUIInteraction = true
					ShouldHideUI = false
					print('IsDialogue', IsDialogue)
					log_functions.log_warn("LuaUIFix: IsDialogue true")
					
				end
				
			end
			
			if not IsDialogue then
			
				if obj:get_class():get_full_name() == "Class /Script/LGUI.UISpriteTransition" then
				
					if obj.TransitionInfo.PressedTransition.Sprite:get_full_name() == 
					   "LGUITexturePackerSpriteData /Game/Aki/UI/UIResources/Common/Atlas/SP_BtnBack.SP_BtnBack" then
						
						CA_IsUIInteraction = true
						
					end
					
				end
			
			end

			return false
		end)
		
	end
	
	IsNotDialogHook = LGUIBehaviour_c:find_function("OnDestroyBP")

	if SafeIsValid(IsNotDialogHook) then

		IsNotDialogHook:set_function_flags(IsNotDialogHook:get_function_flags() | 0x400)
		IsNotDialogHook:hook_ptr(function(fn, obj, locals, result)

			if obj:get_class():get_full_name() == "Class /Script/LGUI.UIExtendToggleSpriteTransition" then
			
				if obj.TransitionState.CheckedHoverState.Sprite:get_fname():to_string() == "SP_PlotSkipBgIcon1" then
					
					IsDialogue = false
					IsUIInteraction = false
					bForceHideCursor = false
					print('IsDialogue', IsDialogue)
					log_functions.log_warn("LuaUIFix: IsDialogue false")
					
				end
				
			end
			
			if not IsDialogue then
			
				if obj:get_class():get_full_name() == "Class /Script/LGUI.UISpriteTransition" then
				
					if obj.TransitionInfo.PressedTransition.Sprite:get_full_name() == 
					   "LGUITexturePackerSpriteData /Game/Aki/UI/UIResources/Common/Atlas/SP_BtnBack.SP_BtnBack" then
						
						CA_IsUIInteraction = false
						
					end
					
				end
			
			end

			return false
		end)
		
	end
	
end

local MediaPlayHook = nil

function VideoPlay_detection()

	if not SafeIsValid(MediaPlayer_C) then
		print("MediaPlayer_C not exist, bind failed!!")
		return
	end
	local InFuncName = "Play"
    MediaPlayHook = MediaPlayer_C:find_function(InFuncName)

    if SafeIsValid(MediaPlayHook) then
        MediaPlayHook:set_function_flags(MediaPlayHook:get_function_flags() | 0x400)
        MediaPlayHook:hook_ptr(function(fn, obj, locals, result)
          
            --print(string.format("New map opened : %s", locals.LevelName:to_string()))
            print(string.format("[LHB_DebugPrint] We are playing a new video, video: %s!", obj:GetMediaName():to_string()))
			SetUIToScreenSpace()
            return true
        end, nil)
        print("Bind successed! " .. InFuncName)
    else
        print(string.format("function : %s is not found", InFuncName))
    end
end


uevr.sdk.callbacks.on_script_reset(function()
	clearConsole()
	if SafeIsValid(IsDialogueHook) then
		IsDialogueHook:set_function_flags(IsDialogueHook:get_function_flags() & ~0x400)
	end
	
	if SafeIsValid(IsNotDialogHook) then
		IsNotDialogHook:set_function_flags(IsNotDialogHook:get_function_flags() & ~0x400)
	end

	if SafeIsValid(MediaPlayHook) then
		MediaPlayHook:set_function_flags(MediaPlayHook:get_function_flags() & ~0x400)
	end
	
	print("Reset script!")

	SetFPMode(false)

	if SafeIsValid(FPCameraActor) then
		FPCameraActor:K2_DestroyActor()
	end
	-- Make sure this is the final clean step, otherwise may mess up the default view target.
	if VRMod_Initialized and default_view_target then
		print("set view target back to game camera!")
		player_controller = api:get_player_controller(0)
		player_controller:SetViewTargetWithBlend(default_view_target, 0.5, 0, 1, false,false)
	
	end
end)

function set_cvar_float(cvar, value)
    local console_manager = api:get_console_manager()
    
    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        print("setting float", value)
        var:set_float(value)
    else   
        print("cvar does not exist: ", cvar)
    end
end

--m_VR.set_mod_value("VR_RenderingMethod", 0)
m_VR.set_mod_value("VR_AimMethod", 0)
bIsDecoupedPitch = true
m_VR.set_mod_value("VR_DecoupledPitch", "false")
m_VR.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
m_VR.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
m_VR.set_mod_value("UI_Distance", UEVR_UI_Dist)
m_VR.set_mod_value("VR_WorldScale", WorldScale_2D)
m_VR.set_mod_value("VR_HorizontalProjectionOverride", 1)
m_VR.set_mod_value("VR_VerticalProjectionOverride", 1)
set_cvar_float("r.StaticMeshLODDistanceScale", 0.5)
--m_VR.set_mod_value("OpenXR_ResolutionScale", 1.5)
