require(".\\Subsystems\\HelperFunctions") 
require(".\\Subsystems\\GlobalData") 
 --CustomClasses
 
 Debug=false
 
MotionComps_C= find_required_object("Class /Script/HeadMountedDisplay.MotionControllerComponent")
TactiNav_C = find_required_object("BlueprintGeneratedClass /Game/Blueprints/InventorySystem/Items/Gadgets/GCPS/TactiNav_Communicator_X-7/BP_TactiNav_Communicator_X-7.BP_TactiNav_Communicator_X-7_C")
--MatHand = find_required_object("Material /Game/Characters/Mannequins/Materials/Gloves/OakleyHN_Coyote_sdr.OakleyHN_Coyote_sdr")
--MatHand1 =find_required_object("MaterialInstanceConstant /Game/Characters/Mannequins/Materials/Gloves/MI_Oakley_FP.MI_Oakley_FP")
Cam=nil
TactiNav= nil--BlueprintGeneratedClass /Game/Blueprints/InventorySystem/Items/Gadgets/GCPS/TactiNav_Communicator_X-7/BP_TactiNav_Communicator_X-7.BP_TactiNav_Communicator_X-7_C
TactiNavVisible=false


function AssignMotionComp(ID)
	local MotionCompsArray = UEVR_UObjectHook.get_objects_by_class(MotionComps_C,true)
	if ID == 0 then
		left_hand_component= SearchSubObjectArrayForObject(MotionCompsArray, "L_MotionController")
		left_hand_component:K2_DestroyComponent(left_hand_component)
		--print(left_hand_component:get_full_name())
	elseif ID == 1 then
		right_hand_component=SearchSubObjectArrayForObject(MotionCompsArray, "R_MotionController")
		right_hand_component:K2_DestroyComponent(right_hand_component)
		--print(right_hand_component:get_full_name())
	elseif ID == 2 then
		hmd_component = SearchSubObjectArrayForObject(MotionCompsArray, "MotionControllerComponent")
	--	print(hmd_component:get_full_name())
	end
end
		

function CustomInput(pawn)
if pawn==nil then return end
--VecY =  pawn.Mesh:GetRightVector() 
--VecY.X = VecY.X * ThumbLY/32767
--VecY.Y = VecY.Y * ThumbLY/32767
--VecY.Z = VecY.Z * ThumbLY/32767 
----VecX = pawn.Mesh:GetForwardVector()
--VecX.X = VecX.X * (-ThumbLX/32767)
--VecX.Y = VecX.Y * (-ThumbLX/32767)
--VecX.Z = VecX.Z * (-ThumbLX/32767)
--UE5.5.4 fix:
local CurrentYaw = pawn.Controller.ControlRotation.Yaw
VecY ={}
VecY.Y = math.sin(CurrentYaw/180*math.pi)  * ThumbLY/32767
VecY.X = math.cos(CurrentYaw/180*math.pi)  * ThumbLY/32767
VecX ={}
VecX.Y = math.cos((CurrentYaw)/180*math.pi) * (ThumbLX/32767)
VecX.X = math.sin((CurrentYaw+180)/180*math.pi) * (ThumbLX/32767)
VecNew ={}
VecNew.X = VecY.X+VecX.X
VecNew.Y = VecY.Y+VecX.Y
local Factor = 1


--pawn:AddMovementInput(VecNew,Factor,true)
pawn.ControlInputVector.X = VecNew.X
pawn.ControlInputVector.Y = VecNew.Y

if not rShoulder then
	pawn.Controller.ControlRotation.Pitch=0
end
end

function CheckBodyVisibility(pawn)
	if pawn~=nil then
		if pawn.BP_MasterCloth then
			local MeshArray2 = pawn.BP_MasterCloth.AttachChildren[1].AttachChildren
			local SceneComp= pawn.Mesh-- MeshArray2[1]
			for i, comp in ipairs(MeshArray2) do
				if i~= 1 then
					comp:SetRenderInMainPass(false,true)
					comp:SetVisibility(false)
					--print("found Mesh")
				end
					comp:SetScalarParameterValueOnMaterials("FOV_Alpha",0)
			end
			BodyVisibilityChecked=true
			if right_hand_component~=nil then 
				--local SceneComp= MeshArray2[1]
				SceneComp:K2_AttachToComponent(right_hand_component,"",0,0,0,false)
				SceneComp.RelativeRotation.Y=-90
				local default_transform = SceneComp:GetSocketTransform("ik_hand_gun",2)
				local DefaultTranslation = default_transform.Translation
				SceneComp.RelativeLocation.Z=-DefaultTranslation.Z---144.940
				SceneComp.RelativeLocation.X=DefaultTranslation.X---22.440---39
				SceneComp.RelativeLocation.Y=DefaultTranslation.Y---7.430---39
			end
			if HandSceneComp==nil then
				HandSceneComp=SceneComp
			end
			
		end
		
	end
end

function UpdateHandsVisByMontage(dpawn)
	if dpawn~=nil then
			ReloadMontage=false
			local AbilityArray= {}
			if dpawn.BP_GameplayAbilityComponent~=nil then
				AbilityArray=dpawn.BP_GameplayAbilityComponent.ActiveAbilities
				if AbilityArray~=nil then
					for i, comp in ipairs(AbilityArray) do
						if string.find(comp:get_full_name(),"Reload") then
							ReloadMontage=true
						end
					end
				end
		--	print(ReloadMontage)
			end
		end
end


local MouseY=-540
local MouseX=-960
local rotLast=nil
local MenuJustOpened=false
  Cursor= nil --find_required_object("W_IRR_ArrowButton_C /Game/Blueprints/UICore/Widgets/Laptop/W_IRR_ListControls.W_IRR_ListControls_C.WidgetTree.LeftButton")
function SetMouseLocation(player)
	--local CursorBP_IRRScaledSizedBox_C /Kronos/Examples/Widgets/Popups/WBP_WaitForPlayers.WBP_WaitForPlayers_C.WidgetTree.BP_IRRScaledSizedBox_C_1
	if TactiNav==nil then
		TactiNav=UEVR_UObjectHook.get_first_object_by_class(TactiNav_C,false)
	else
		TactiNavVisible=not TactiNav.SkeletalMesh.bHiddenInGame
	end
	
	if Cursor==nil then
		Cursor=find_required_object("W_IRR_ArrowButton_C /Game/Blueprints/UICore/Widgets/Laptop/W_IRR_ListControls.W_IRR_ListControls_C.WidgetTree.LeftButton")
	end
	if not isMenu then
		MouseY=-540
		MouseX=-960
		--rotCurr=nil
	end
	if Cursor~=nil and (isMenu or TactiNavVisible) then
		player:SetMouseCursorWidget(1,Cursor)
		
	--and right_hand_component~=nil  then
		--uevr.params.vr.get_pose(WHandIndex, WeaponHand_Pos, WeaponHand_Rot)	
			--print("mouse")
		if rotLast==nil then
			rotLast = right_hand_component:K2_GetComponentToWorld()
		--	player:GetMousePosition(CurrentLocX,CurrentLocY)
		--	print(CurrentLocY)
		--	print(CurrentLocX)
		end	
		local rotTemp = right_hand_component:K2_GetComponentToWorld()
		
		--print(CurrentLocY)
		--print(CurrentLocX)
		local rotDiff = kismet_math_library:MakeRelativeTransform(rotLast,rotTemp)
		
		MouseY = MouseY + (rotDiff.Rotation.Y)/math.pi*180  /45 * 1080
		MouseX = MouseX + (rotDiff.Rotation.Z)/math.pi*180 /45*1920
		player:SetMouseLocation(-MouseX,-MouseY)
		rotLast = rotTemp
		
		
	end
	if  rShoulder then
		--rotCurr=nil
		MouseY=-540
		MouseX=-960
	end
end



-- "Properties",
--        "AttachChildren",
--        "ChildActorComponent BP_MasterCloth",
--        "Properties",
--        "AttachChildren",
--        "SceneComponent DefaultSceneRoot",
--        "Properties",
--        "AttachChildren",
--        "SkeletalMeshComponent NODE_AddSkeletalMeshComponent-5_0"