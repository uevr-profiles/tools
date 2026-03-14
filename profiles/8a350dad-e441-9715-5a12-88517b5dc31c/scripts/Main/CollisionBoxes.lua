require(".\\Subsystems\\Motion")		
local controllers = require('libs/controllers')

local Debug= false

function CreateLHandBoxCollision()	
		
	if left_hand_component ==nil or right_hand_component==nil then
		if not controllers.controllerExists(0) then
			controllers.createController(0)
			left_hand_component= controllers.getController(0)
		else left_hand_component= controllers.getController(0)
		end
		if not controllers.controllerExists(1) then
			controllers.createController(1)
			right_hand_component= controllers.getController(1)
		else right_hand_component= controllers.getController(1)
		end
	elseif BoxCompLH==nil  then
		--local Par= left_hand_component:get_outer()
		BoxCompLH= api:add_component_by_class(pawn,VHitBoxClass)
		BoxCompLH:K2_AttachToComponent(left_hand_component," ",0,0,0,true)
		BoxCompLH:SetGenerateOverlapEvents(true)
		BoxCompLH:SetCollisionResponseToAllChannels(1)
		BoxCompLH:SetCollisionObjectType(40)
		BoxCompLH:SetCollisionEnabled(1) 
		BoxCompLH.RelativeScale3D.X=0.3
		BoxCompLH.RelativeScale3D.Y=0.15
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
		
		
		
		
		if hmd_component ==nil then
			if not controllers.controllerExists(2) then
				controllers.createController(2)
				hmd_component= controllers.getController(2)
			else hmd_component= controllers.getController(2)
			end
		end
		
		if BoxCompHmdRightShoulder==nil then
		--local Par= left_hand_component:get_outer()
			BoxCompHmdRightShoulder= api:add_component_by_class(pawn,VHitBoxClass)
			BoxCompHmdRightShoulder:K2_AttachToComponent(hmd_component,"RS",0,0,0,true)
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
			BoxCompHmdRightHip:SetGenerateOverlapEvents(true)
			BoxCompHmdRightHip:SetCollisionResponseToAllChannels(1)
			BoxCompHmdRightHip:SetCollisionObjectType(0)
			BoxCompHmdRightHip:SetCollisionEnabled(1) 
			BoxCompHmdRightHip.RelativeScale3D.X=0.5
			BoxCompHmdRightHip.RelativeScale3D.Y=0.38
			BoxCompHmdRightHip.RelativeScale3D.Z=0.38
			if Debug then
						 BoxCompHmdRightHip.bHiddenInGame=false
			end
		end
		if BoxCompHmdLeftHip==nil then
		--local Par= left_hand_component:get_outer()
			BoxCompHmdLeftHip= api:add_component_by_class(pawn,VHitBoxClass)
			BoxCompHmdLeftHip:K2_AttachToComponent(hmd_component,"LH",0,0,0,true)
			BoxCompHmdLeftHip:SetGenerateOverlapEvents(true)
			BoxCompHmdLeftHip:SetCollisionResponseToAllChannels(1)
			BoxCompHmdLeftHip:SetCollisionObjectType(0)
			BoxCompHmdLeftHip:SetCollisionEnabled(1) 
			BoxCompHmdLeftHip.RelativeScale3D.X=0.5
			BoxCompHmdLeftHip.RelativeScale3D.Y=0.38
			BoxCompHmdLeftHip.RelativeScale3D.Z=0.38
			if Debug then
						 BoxCompHmdLeftHip.bHiddenInGame=false
		    end
		end
		if BoxCompHmdChestRight==nil then
			--local Par= left_hand_component:get_outer()
			BoxCompHmdChestRight= api:add_component_by_class(pawn,VHitBoxClass)
			BoxCompHmdChestRight:K2_AttachToComponent(hmd_component,"RC",0,0,0,true)
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
		
	
	
end
	
function UpdateWeaponCollisionZones(pawn, WeaponMeshBP)
	 
	if pawn==nil then return nil end
	if WeaponMeshBP==nil then return end
	local CurrWpnBP1 = WeaponMeshBP
	--print(CurrWpnBP:get_full_name())
	local WpnZone1 = {}
	WpnZone1 =	CurrWpnBP1:K2_GetComponentsByClass(VHitBoxClass)
	if WpnZone1==nil or #WpnZone1 == 0 then
		local Hit ={}
		--local MagOffset = CurrWpnBP1.WeaponMesh:GetSocketTransform("magazine",2).Translation
		local MagBox= nil
		MagBox= api:add_component_by_class(CurrWpnBP1,VHitBoxClass)
		--MagBox:K2_SetRelativeLocation(MagOffset, false, Hit,false)
		MagBox:K2_AttachToComponent(CurrWpnBP1.WeaponMesh,"magazine",0,0,0,true)
		
		MagBox:SetGenerateOverlapEvents(true)
		MagBox.RelativeLocation.Z=0---MagOffset.Z-17   --up down
		MagBox.RelativeLocation.X=0--MagOffset.X		-- left right
		MagBox.RelativeLocation.Y=0--MagOffset.Y
		MagBox.RelativeScale3D.X=0.05
		MagBox.RelativeScale3D.Y=0.1
		MagBox.RelativeScale3D.Z=0.2
		MagBox:SetCollisionResponseToAllChannels(1)
		MagBox:SetCollisionObjectType(0)
		MagBox:SetCollisionEnabled(1)
		MagBox:SetCollisionResponseToChannel(30, 1)
		local AttachBox = nil
		--local AttachOffset = CurrWpnBP1.WeaponMesh:GetSocketTransform("BarrelAttachment_socket",2).Translation
		AttachBox= api:add_component_by_class(CurrWpnBP1,VHitBoxClass)
		AttachBox:K2_AttachToComponent(CurrWpnBP1.WeaponMesh,"BarrelAttachment_socket",0,0,0,true)
		--AttachBox:K2_SetRelativeLocation(AttachOffset, false, Hit,false)
		AttachBox:SetGenerateOverlapEvents(true)
		--AttachBox.RelativeLocation.Z=-AttachOffset.Z
		--AttachBox.RelativeLocation.X=AttachOffset.X
		--AttachBox.RelativeLocation.Y=AttachOffset.Y
		AttachBox.RelativeScale3D.X=0.1
		AttachBox.RelativeScale3D.Y=0.1
		AttachBox.RelativeScale3D.Z=0.1
		AttachBox:SetCollisionResponseToAllChannels(1)
		AttachBox:SetCollisionObjectType(0)
		AttachBox:SetCollisionEnabled(1)
		AttachBox:SetCollisionResponseToChannel(30, 1)
		if Debug then
			MagBox.bHiddenInGame=false
			AttachBox.bHiddenInGame=false
		end
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
					if	string.find(comp:get_full_name(), "Box")    
						then
						
						--print(comp.AttachSocketName:to_string())
						if comp.AttachSocketName:to_string()== "Magazine" or comp.AttachSocketName:to_string()== "magazine" then
						
							--print(comp:get_full_name())
							isMagFound=true
							--print(comp.AttachSocketName:to_string())
						end
						
					end
		end
		--print(isMagFound)
		
	end
	if pawn~=nil and BoxCompLH ~=nil and lShoulder and not ReloadInProgress and not wasShoulderPressed then
		local _Comps = {}
		BoxCompLH:GetOverlappingComponents(_Comps)
		
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
							isRCFound=true
							print("RC FOUND")
							FoundSocket = "RC"
						elseif comp.AttachSocketName:to_string()== "RH" then
							print("RH FOUND")
							isRHFound=true
							FoundSocket = "RH"
						elseif comp.AttachSocketName:to_string()== "LH" then
							isLHFound=true
							FoundSocket = "LH"
							print("LH FOUND")
						end
					end
		end
	end	
	if pawn~=nil and BoxCompRH ~=nil and rShoulder and not ReloadInProgress and not wasShoulderPressed then
		local _Comps = {}
		BoxCompRH:GetOverlappingComponents(_Comps)
		
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
							isRCFound=true
							print("RC FOUND")
							FoundSocket = "RC"
						elseif comp.AttachSocketName:to_string()== "RH" then
							print("RH FOUND")
							isRHFound=true
							FoundSocket = "RH"
						elseif comp.AttachSocketName:to_string()== "LH" then
							isLHFound=true
							FoundSocket = "LH"
							print("LH FOUND")
						end
					end
		end
	end		
		
		
		if not (lShoulder or rShoulder) then
			wasShoulderPressed=false
		end
		
		
		if  (isLHFound or isRHFound or isRSFound or isRCFound)  and not wasShoulderPressed then
			canChange=true
			
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
			wasShoulderPressed=true
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
				pawn:InpActEvt_EquipRifle_K2Node_InputActionEvent_1(Key)
			elseif FoundSocket == "RH" then
				pawn:InpActEvt_EquipPistol_K2Node_InputActionEvent_0(Key)
			elseif FoundSocket == "RC" then
				pawn:InpActEvt_ToggleGPS_K2Node_InputActionEvent_15(Key)
				pawn:InpActEvt_ToggleGPS_K2Node_InputActionEvent_16(Key)
			elseif FoundSocket == "LH" then
				pawn:SetEquippedSlot(4)
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
	
	if BoxCompHmdRightShoulder ~=nil then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightShoulder):set_location_offset(Vector3f.new(-20,-5,-30)) -- x=LeftRigth, y = Up down, Z= Forward Backwards
	end
	if BoxCompHmdRightHip ~=nil then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdRightHip):set_location_offset(Vector3f.new(-20,50,0)) -- x=forward bward, y = left right, Z=Forward Backwards
	end
	if BoxCompHmdChestRight~=nil then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdChestRight):set_location_offset(Vector3f.new(-20,25,0)) -- x=forward bward, y = left right, Z= Forward Backwards
	end
	if BoxCompHmdLeftHip ~=nil then
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_hand(2)
		
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_permanent(true)
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,-0.5*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		UEVR_UObjectHook.get_or_add_motion_controller_state(BoxCompHmdLeftHip):set_location_offset(Vector3f.new(20,40,-20)) -- x=forward bward, y = left right, Z= Forward Backwards
	end
end	

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	local dpawn=nil
	dpawn=api:get_local_pawn(0)	
	local CurrWpnBP = nil
	if dpawn~=nil and not WasReset then
			--gDelta = delta
		CreateLHandBoxCollision(dpawn)
		--local CurrWpnBP = dpawn:BP_GetWeaponObject()
		
		if CheckCollision then
			CheckCollision=false
			CurrWpnBP = dpawn:BP_GetWeaponObject()
			UpdateWeaponCollisionZones(dpawn,CurrWpnBP)
		end	
		--	
		
		
	end
	UpdatePlayerCollisionZones(dpawn)
	CollisionFunctions(dpawn)
end)