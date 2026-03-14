require(".\\Subsystems\\Motion")		
--local controllers = require('libs/controllers')

local Debug= false
local WParam_C = find_required_object("ScriptStruct /Script/GameplayFramework.EquipParams")
local WParam = StructObject.new(WParam_C)
function CreateLHandBoxCollision()	
		
--	if left_hand_component ==nil or right_hand_component==nil then
	--	if not controllers.controllerExists(0) then
	--		controllers.createController(0)
	--		left_hand_component= controllers.getController(0)
	--	else left_hand_component= controllers.getController(0)
	--	end
	--	if not controllers.controllerExists(1) then
	--		controllers.createController(1)
	--		right_hand_component= controllers.getController(1)
	--	else right_hand_component= controllers.getController(1)
	--	end
	--else
	if BoxCompLH==nil  then
		--local Par= left_hand_component:get_outer()
		BoxCompLH= api:add_component_by_class(pawn,VHitBoxClass)
		BoxCompLH:K2_AttachToComponent(left_hand_component," ",0,0,0,true)
		BoxCompLH:SetGenerateOverlapEvents(true)
		BoxCompLH:SetCollisionResponseToAllChannels(1)
		BoxCompLH:SetCollisionObjectType(40)
		BoxCompLH:SetCollisionEnabled(1) 
		BoxCompLH.RelativeScale3D.X=0.3
		BoxCompLH.RelativeScale3D.Y=0.05
		BoxCompLH.RelativeScale3D.Z=0.1
			if BoxCompRH==nil then
				BoxCompRH= api:add_component_by_class(pawn,VHitBoxClass)
				BoxCompRH:K2_AttachToComponent(right_hand_component," ",0,0,0,true)
				BoxCompRH:SetGenerateOverlapEvents(true)
				BoxCompRH:SetCollisionResponseToAllChannels(1)
				BoxCompRH:SetCollisionObjectType(40)
				BoxCompRH:SetCollisionEnabled(1) 
				BoxCompRH.RelativeScale3D.X=0.1
				BoxCompRH.RelativeScale3D.Y=0.15
				BoxCompRH.RelativeScale3D.Z=0.1
			end	
		if Debug then
			BoxCompLH.bHiddenInGame=false
			BoxCompRH.bHiddenInGame=false
		end
		
		
		
		
	--if hmd_component ==nil then
	--	if not controllers.controllerExists(2) then
	--		controllers.createController(2)
	--		hmd_component= controllers.getController(2)
	--	else hmd_component= controllers.getController(2)
	--	end
	--end
		
		if BoxCompHmdRightShoulder==nil then
		--local Par= left_hand_component:get_outer()
			BoxCompHmdRightShoulder= api:add_component_by_class(pawn,VHitBoxClass)
			BoxCompHmdRightShoulder:K2_AttachToComponent(hmd_component,"RS",0,0,0,true)
			BoxCompHmdRightShoulder.AttachSocketName="RS"
			BoxCompHmdRightShoulder:SetGenerateOverlapEvents(true)
			BoxCompHmdRightShoulder:SetCollisionResponseToAllChannels(1)
			BoxCompHmdRightShoulder:SetCollisionObjectType(0)
			BoxCompHmdRightShoulder:SetCollisionEnabled(1) 
			BoxCompHmdRightShoulder.RelativeScale3D.X=0.5
			BoxCompHmdRightShoulder.RelativeScale3D.Y=0.5
			BoxCompHmdRightShoulder.RelativeScale3D.Z=0.4
			if Debug then
				BoxCompHmdRightShoulder.bHiddenInGame=false
			end
		end
		if BoxCompHmdRightHip==nil then
		--local Par= left_hand_component:get_outer()
			BoxCompHmdRightHip= api:add_component_by_class(pawn,VHitBoxClass)
			BoxCompHmdRightHip:K2_AttachToComponent(hmd_component,"RH",0,0,0,true)
			BoxCompHmdRightHip.AttachSocketName="RH"
			BoxCompHmdRightHip:SetGenerateOverlapEvents(true)
			BoxCompHmdRightHip:SetCollisionResponseToAllChannels(1)
			BoxCompHmdRightHip:SetCollisionObjectType(0)
			BoxCompHmdRightHip:SetCollisionEnabled(1) 
			BoxCompHmdRightHip.RelativeScale3D.X=0.35
			BoxCompHmdRightHip.RelativeScale3D.Y=0.35
			BoxCompHmdRightHip.RelativeScale3D.Z=0.35
			if Debug then
						 BoxCompHmdRightHip.bHiddenInGame=false
			end
		end
		if BoxCompHmdLeftHip==nil then
		--local Par= left_hand_component:get_outer()
			BoxCompHmdLeftHip= api:add_component_by_class(pawn,VHitBoxClass)
			BoxCompHmdLeftHip:K2_AttachToComponent(hmd_component,"LH",0,0,0,true)
			BoxCompHmdLeftHip.AttachSocketName="LH"
			BoxCompHmdLeftHip:SetGenerateOverlapEvents(true)
			BoxCompHmdLeftHip:SetCollisionResponseToAllChannels(1)
			BoxCompHmdLeftHip:SetCollisionObjectType(0)
			BoxCompHmdLeftHip:SetCollisionEnabled(1) 
			BoxCompHmdLeftHip.RelativeScale3D.X=0.3
			BoxCompHmdLeftHip.RelativeScale3D.Y=0.3
			BoxCompHmdLeftHip.RelativeScale3D.Z=0.3
			if Debug then
						 BoxCompHmdLeftHip.bHiddenInGame=false
		    end
		end
		if BoxCompHmdChestRight==nil then
			--local Par= left_hand_component:get_outer()
			BoxCompHmdChestRight= api:add_component_by_class(pawn,VHitBoxClass)
			BoxCompHmdChestRight:K2_AttachToComponent(hmd_component,"RC",0,0,0,true)
			BoxCompHmdChestRight.AttachSocketName="RC"
			BoxCompHmdChestRight:SetGenerateOverlapEvents(true)
			BoxCompHmdChestRight:SetCollisionResponseToAllChannels(1)
			BoxCompHmdChestRight:SetCollisionObjectType(0)
			BoxCompHmdChestRight:SetCollisionEnabled(1) 
			BoxCompHmdChestRight.RelativeScale3D.X=0.1
			BoxCompHmdChestRight.RelativeScale3D.Y=0.35
			BoxCompHmdChestRight.RelativeScale3D.Z=0.3
			if Debug then
						 BoxCompHmdChestRight.bHiddenInGame=false
		    end
		end
			
		if Debug then
			BoxCompLH.bHiddenInGame=false
		end
		 
		
		
		
		
		
		
	end
	
	
	--print(controllers.controllerExists(0))	
	
	
end
	
function UpdateWeaponCollisionZones(pawn, WeaponMeshBP)
	 
	if pawn==nil then return nil end
	if WeaponMeshBP==nil then return end
	local CurrWpnBP1 = WeaponMeshBP
	--print(CurrWpnBP:get_full_name())
	local WpnZone1 = {}
	pcall(function()
	WpnZone1 =	CurrWpnBP1:K2_GetComponentsByClass(VHitBoxClass)
	end)
	if WpnZone1==nil or #WpnZone1 == 0 then
		local Hit ={}
		--local MagOffset = CurrWpnBP1.WeaponBase:GetSocketTransform("magazine",2).Translation
		local MagBox= nil
		MagBox= api:add_component_by_class(CurrWpnBP1,VHitBoxClass)
		--MagBox:K2_SetRelativeLocation(MagOffset, false, Hit,false)
		--local Name =kismet_string_library:Conv_StringToName("Magazine_01")
		pcall(function()
		if CurrWpnBP1.WeaponBase:DoesSocketExist("Magazine_01") then
			MagBox:K2_AttachToComponent(CurrWpnBP1.WeaponBase,"Magazine_01",0,0,0,false)
		elseif CurrWpnBP1.WeaponBase:DoesSocketExist("Magazine") then
			MagBox:K2_AttachToComponent(CurrWpnBP1.WeaponBase,"Magazine",0,0,0,false)
		end
		end)
		--MagBox.AttachSocketName="Magazine_01"
		MagBox:SetGenerateOverlapEvents(true)
		--if string.find(CurrWpnBP:get_full_name,"Pump") or string.find(CurrWpnBP:get_full_name,"PAS") then
		--MagBox.RelativeLocation.Z=10---MagOffset.Z-17   --up down
		--MagBox.RelativeLocation.X=0--MagOffset.X		-- left right
		--MagBox.RelativeLocation.Y=20--MagOffset.Y
		--elseif string.find(CurrWpnBP:get_full_name,"Pump") or string.find(CurrWpnBP:get_full_name,"PAS") then
		MagBox.RelativeScale3D.X=0.05
		MagBox.RelativeScale3D.Y=0.1
		MagBox.RelativeScale3D.Z=0.2
		MagBox:SetCollisionResponseToAllChannels(1)
		MagBox:SetCollisionObjectType(0)
		MagBox:SetCollisionEnabled(1)
		MagBox:SetCollisionResponseToChannel(30, 1)
		--local AttachBox = nil
		----local AttachOffset = CurrWpnBP1.WeaponBase:GetSocketTransform("BarrelAttachment_socket",2).Translation
		--AttachBox= api:add_component_by_class(CurrWpnBP1,VHitBoxClass)
		--AttachBox:K2_AttachToComponent(CurrWpnBP1.WeaponBase,"BarrelEnd",0,0,0,true)
		----AttachBox:K2_SetRelativeLocation(AttachOffset, false, Hit,false)
		--AttachBox:SetGenerateOverlapEvents(true)
		----AttachBox.RelativeLocation.Z=-AttachOffset.Z
		----AttachBox.RelativeLocation.X=AttachOffset.X
		----AttachBox.RelativeLocation.Y=AttachOffset.Y
		--AttachBox.RelativeScale3D.X=0.1
		--AttachBox.RelativeScale3D.Y=0.1
		--AttachBox.RelativeScale3D.Z=0.1
		--AttachBox:SetCollisionResponseToAllChannels(1)
		--AttachBox:SetCollisionObjectType(0)
		--AttachBox:SetCollisionEnabled(1)
		--AttachBox:SetCollisionResponseToChannel(30, 1)
		if Debug then
			MagBox.bHiddenInGame=false
			--AttachBox.bHiddenInGame=false
			print(MagBox.AttachSocketName:to_string())
		end
	elseif WpnZone1[1].AttachSocketName~= "Magazine_01" and WpnZone1[1].AttachSocketName~= "Magazine" then
		if CurrWpnBP1.WeaponBase:DoesSocketExist("Magazine_01") then
			WpnZone1[1]:K2_AttachToComponent(CurrWpnBP1.WeaponBase,"Magazine_01",0,0,0,false)
		elseif CurrWpnBP1.WeaponBase:DoesSocketExist("Magazine") then
			WpnZone1[1]:K2_AttachToComponent(CurrWpnBP1.WeaponBase,"Magazine",0,0,0,false)
		end
	
	--WpnZone1[1].AttachSocketName="Magazine_01"
			--print(WpnZone1[1].AttachSocketName:to_string())
	end
		
		
end

function CollisionFunctions(pawn)
	
	isMagFound=false
	isRSFound =false
	isRCFound =false
	isRHFound =false
	isLHFound =false
	if pawn~=nil and BoxCompLH ~=nil and LTrigger > 10 and not CheckedMag and not wasShoulderPressed then
		CheckedMag=true
		local _Comps = {}
		BoxCompLH:GetOverlappingComponents(_Comps)
		--print("mag check")
		for i, comp in ipairs(_Comps) do
					--print(comp:get_full_name())
					--print(comp.AttachSocketName:to_string())
					if	string.find(comp:get_full_name(), "Box")    
						then
						
						--print(comp.AttachSocketName:to_string())
						if comp.AttachSocketName:to_string()== "Magazine" or comp.AttachSocketName:to_string()== "Magazine_01" then
						
							--print(comp:get_full_name())
							isMagFound=true
							
						end
						
					end
		end
		--print(isMagFound)
		
	end
	if pawn~=nil and BoxCompLH ~=nil and lShoulder and not wasLShoulderPressed then
		local _Comps = {}
		BoxCompLH:GetOverlappingComponents(_Comps)
		wasLShoulderPressed=true
		for i, comp in ipairs(_Comps) do
					local CompName = comp:get_full_name()
					if	string.find(CompName, "Box")    
						then
						--print(comp.AttachSocketName:to_string())
						if comp.AttachSocketName:to_string()== "RS" then
							if Debug then
							print("RS FOUND")
							end
							--isRSFound=true
							--FoundSocket = "RS"
							
						elseif comp.AttachSocketName:to_string()== "RC" then
							isRCFound=true
							if Debug then
							print("RC FOUND")
							end
							FoundSocket = "RC"
						elseif comp.AttachSocketName:to_string()== "RH" then
							if Debug then
							
							print("RH FOUND")
							end
							--isRHFound=true
							--FoundSocket = "RH"
						elseif comp.AttachSocketName:to_string()== "LH" then
							isLHFound=true

							FoundSocket = "LH"
							if Debug then
							print("LH FOUND")
							end
						end
					end
		end
	end	
	if pawn~=nil and BoxCompRH ~=nil and rShoulder and not wasRShoulderPressed  then
		local _Comps = {}
		BoxCompRH:GetOverlappingComponents(_Comps)
		wasRShoulderPressed=true
		for i, comp in ipairs(_Comps) do
					local CompName = comp:get_full_name()
					if	string.find(CompName, "Box")    
						then
						--print(comp.AttachSocketName:to_string())
						if comp.AttachSocketName:to_string()== "RS" then
							print("RS FOUND")
							isRSFound=true
							FoundSocket = "RS"
							
						elseif comp.AttachSocketName:to_string()== "RC" then
							--isRCFound=true
							print("RC FOUND")
							--FoundSocket = "RC"
						elseif comp.AttachSocketName:to_string()== "RH" then
							print("RH FOUND")
							isRHFound=true
							FoundSocket = "RH"
						elseif comp.AttachSocketName:to_string()== "LH" then
						--isLHFound=true
						--	FoundSocket = "LH"
							print("LH FOUND")
						end
					end
		end
	end		
		
		
		if not (rShoulder) then
			wasRShoulderPressed=false
		end
		if not (lShoulder) then
			wasLShoulderPressed=false
		end
		
		if  (isLHFound or isRHFound or isRSFound or isRCFound)   then
			canChange=true
			--unpressShoulder=true
		--else unpressShoulder=false	
			print("Can change")
		end
		if not (isLHFound or isRHFound or isRSFound or isRCFound) then
			canChange=false
			
		
		end
		if canChange and (lShoulder or rShoulder)  then
						--if (isLHFound or isRHFound or isRSFound or isRCFound)  then
			isChanging=true
			canChange=false
			print("changing")
			wasRShoulderPressed=true
			wasLShoulderPressed=true
		end
		
		
		
		if not GripIsReload then
					
					if  isMagFound and not lShoulder then
						canReload=true
						--print("canReload  "..canReload)
					end
					
						
					if not (isMagFound) or lShoulder then
						canReload=false
					end
					
					if canReload and LTrigger>10 and not lShoulder then
						if isMagFound then
							isReloading=true
						end
						canReload=false
					end
					
					
					if  LTrigger<10 then
						isReloading=false--
						ReloadInProgress=false
						CheckedMag=false
						--pawn:InpActEvt_Reload_K2Node_InputActionEvent_8(Key)
					end
					
		elseif GripIsReload then
					if not lShoulder and isMagFound then
						canReload=true
					end
					if not lShoulder and not isMagFound then
						canReload=false
					end
					if canReload and  lShoulder then
						isReloading=true
						canReload=false
					end
					if isReloading and not lShoulder then
						isReloading=false
						ReloadInProgress=false
						--pawn:InpActEvt_Reload_K2Node_InputActionEvent_8(Key)
					end
					if CheckedMag  and not lShoulder  then
						CheckedMag=false
					end
		end
		--if canReload then
		--		uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
		--end
		if isReloading and not ReloadInProgress then
			ReloadInProgress=true
			print("okay")
			--pawn:InpActEvt_Reload_K2Node_InputActionEvent_7(Key)
			--pawn:InpActEvt_Reload_K2Node_InputActionEvent_8(Key)
		--	pawn:InpActEvt_Reload_K2Node_InputActionEvent_7(Key)
		end
		
		if isChanging then
			--print("OK")
			--print(FoundSocket)
			isChanging=false
			ChangeReq=true
			if FoundSocket == "RS" then
				
				
				--WParam.Params.Weapon = find_required_object("BP_DoubleGun_C /Game/Maps/MadGame_P.MadGame_P.PersistentLevel.BP_DoubleGun_C_2147480850")
				--WParam.Params.bOverride=false
				--WParam.Params.bSkipAnimation=false
				pressY=true
			--	pawn:InpActEvt_EquipRifle_K2Node_InputActionEvent_1(Key)
			elseif FoundSocket == "RH" then
				pressY=true
				
				--pawn:InpActEvt_EquipPistol_K2Node_InputActionEvent_0(Key)
			elseif FoundSocket == "RC" then
				pressRS=true
			elseif FoundSocket == "LH" then
				pressLS=true
			end	
		end
		
		
	
end


local Offset=0
local HmdRotatorYLast=0


local function GetHmdYawOffset()		
	local deltaOffset= 0
	if math.abs(neededYaw - HmdRotatorYLast) < 90 then
		deltaOffset=neededYaw - HmdRotatorYLast
	else
		deltaOffset= 1
	end	
	if math.abs(Offset) <= 70 then
		Offset= Offset+deltaOffset
	elseif Offset >70 then
		Offset=70
	elseif Offset< -70 then
		Offset=-70
	end	
	if ThumbLY>15000 or neededPitch>-20 then
			Offset=Offset/4
	end
	local YawOffset= Offset/180*math.pi	
	HmdRotatorYLast=neededYaw	
	return YawOffset
end


local function UpdatePlayerCollisionZones(dpawn)
	if dpawn==nil then return end
	
	if BoxCompHmdRightShoulder ~=nil and UEVR_UObjectHook.exists(BoxCompHmdRightShoulder) then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_location_offset(Vector3f.new(-20,-5,-30)) -- x=LeftRigth, y = Up down, Z= Forward Backwards
	else BoxCompHmdRightShoulder=nil
	end
	if BoxCompHmdRightHip ~=nil and UEVR_UObjectHook.exists(BoxCompHmdRightHip) then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_location_offset(Vector3f.new(-20,50,0)) -- x=LeftRigth, y = Up down, Z=Forward Backwards
	else BoxCompHmdRightHip=nil
	end
	if BoxCompHmdChestRight~=nil and UEVR_UObjectHook.exists(BoxCompHmdChestRight) then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_location_offset(Vector3f.new(-20,25,0)) --x=LeftRigth,y = Up down, Z= Forward Backwards
	else BoxCompHmdChestRight=nil
	end
	if BoxCompHmdLeftHip ~=nil and UEVR_UObjectHook.exists(BoxCompHmdLeftHip) then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_location_offset(Vector3f.new(20,75,0)) -- x=LeftRigth, y = Up down, Z= Forward Backwards
	else BoxCompHmdLeftHip=nil
	end
end	

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	local dpawn=nil
	dpawn=api:get_local_pawn(0)	
	local CurrWpnBP = nil
	if dpawn~=nil  then
			
		CreateLHandBoxCollision(dpawn)
		
			if CurrentWeaponMesh~=nil then
				CurrWpnBP = CurrentWeaponMesh:get_outer()
			end
			UpdateWeaponCollisionZones(dpawn,CurrWpnBP)
		
	UpdatePlayerCollisionZones(dpawn)
	CollisionFunctions(dpawn)	
		
	end
	
end)