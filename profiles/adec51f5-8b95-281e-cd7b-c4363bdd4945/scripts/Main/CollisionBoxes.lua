require(".\\Subsystems\\Motion")		
local controllers = require('libs/controllers')

local Debug= true

function CreateLHandBoxCollision()	
		
	if left_hand_component ==nil then
		if not controllers.controllerExists(0) then
			controllers.createController(0)
			left_hand_component= controllers.getController(0)
		else left_hand_component= controllers.getController(0)
		end
		
	elseif BoxCompLH==nil then
		--local Par= left_hand_component:get_outer()
		BoxCompLH= api:add_component_by_class(pawn,VHitBoxClass)
		BoxCompLH:K2_AttachToComponent(left_hand_component," ",0,0,0,true)
		BoxCompLH:SetGenerateOverlapEvents(true)
		BoxCompLH:SetCollisionResponseToAllChannels(1)
		BoxCompLH:SetCollisionObjectType(40)
		BoxCompLH:SetCollisionEnabled(1) 
		BoxCompLH.RelativeScale3D.X=0.1
		BoxCompLH.RelativeScale3D.Y=0.1
		BoxCompLH.RelativeScale3D.Z=0.1
		if Debug then
			BoxCompLH.bHiddenInGame=false
		end
	elseif BoxCompLH:GetAttachParent() ~= left_hand_component then
		BoxCompLH:K2_AttachToComponent(left_hand_component," ",0,0,0,true)
	end
		
	
	
end
	
function UpdateWeaponCollisionZones(pawn, WeaponMeshBP)
	 
	if pawn==nil then return nil end
	local CurrWpnBP = WeaponMeshBP
	--print(CurrWpnBP:get_full_name())
	local WpnZone1 = {}
	WpnZone1 =	CurrWpnBP:K2_GetComponentsByClass(VHitBoxClass)
	if WpnZone1==nil or #WpnZone1 == 0 then
		local Hit ={}
		--local MagOffset = CurrWpnBP.WeaponMesh:GetSocketTransform("magazine",2).Translation
		local MagBox= nil
		MagBox= api:add_component_by_class(CurrWpnBP,VHitBoxClass)
		--MagBox:K2_SetRelativeLocation(MagOffset, false, Hit,false)
		MagBox:K2_AttachToComponent(CurrWpnBP.WeaponMesh,"magazine",0,0,0,true)
		
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
		--local AttachOffset = CurrWpnBP.WeaponMesh:GetSocketTransform("BarrelAttachment_socket",2).Translation
		AttachBox= api:add_component_by_class(CurrWpnBP,VHitBoxClass)
		AttachBox:K2_AttachToComponent(CurrWpnBP.WeaponMesh,"BarrelAttachment_socket",0,0,0,true)
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
			--MagBox.bHiddenInGame=false
			--AttachBox.bHiddenInGame=false
		end
	end
		
		
end

function CollisionFunctions(pawn,CurrWpnBP)
	local _Comps = {}
	if pawn~=nil and BoxCompLH ~=nil then
		BoxCompLH:GetOverlappingComponents(_Comps)
		isMagFound=false
		for i, comp in ipairs(_Comps) do
				--print(comp:get_full_name())
					if	(string.find(comp:get_full_name(), "Box") and comp:GetOwner()== CurrWpnBP and comp:GetAttachSocketName():to_string()== "magazine" ) 
						then
--					
						isMagFound=true
					
					end
		end
		if not GripIsReload then
					if LTrigger<10 and isMagFound and not lShoulder then
						canReload=true
					end
					if (LTrigger<10 and not isMagFound) or lShoulder then
						canReload=false
					end
					if canReload and LTrigger>10 and not lShoulder then
						isReloading=true
						canReload=false
					end
					if isReloading and LTrigger<10 then
						isReloading=false--
						ReloadInProgress=false
						pawn:InpActEvt_Reload_K2Node_InputActionEvent_8(Key)
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
						pawn:InpActEvt_Reload_K2Node_InputActionEvent_8(Key)
					end
		end
		if canReload then
				uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
		end
		if isReloading and not ReloadInProgress then
			ReloadInProgress=true
			pawn:InpActEvt_Reload_K2Node_InputActionEvent_7(Key)
			--pawn:InpActEvt_Reload_K2Node_InputActionEvent_8(Key)
		--	pawn:InpActEvt_Reload_K2Node_InputActionEvent_7(Key)
		end
		
		
		
	end
end