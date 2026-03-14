require(".\\Subsystems\\HelperFunctions")

 --Trackers
 hmd_component = nil
 right_hand_component= nil
 left_hand_component=nil 
 
  --Collisions:
 BoxCompLH=nil
 BoxCompRH=nil
 BoxCompHmdChestRight	=nil
 BoxCompHmdRightHip     =nil
 BoxCompHmdLeftHip      =nil
 BoxCompHmdRightShoulder=nil
 BoxCompHmdLeftShoulder=nil
 MagBox=nil
 
 --ControlInput
  ThumbLX   = 0
 ThumbLY   = 0
 ThumbRX   = 0
 ThumbRY   = 0
 LTrigger  = 0
 RTrigger  = 0
 rShoulder = false
 lShoulder = false
 lThumb    = false
 rThumb    = false
 Abutton = false
 Bbutton = false
 Xbutton = false
 Ybutton = false
 DPAD_Up   = false
 DPAD_Right= false
 DPAD_Left = false
 DPAD_Down = false
 StickR=UEVR_Vector2f.new()
 SelectButton=false
 AbsThumbFactor = 0
 canPressA=true
 --StaticClasses
 game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
 kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
 kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")
 kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
 Statics = find_static_class("Class /Script/Engine.GameplayStatics")
 --Classes
 VHitBoxClass= find_required_object("Class /Script/Engine.BoxComponent")
 hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult") 
 CameraManager_C = find_required_object("Class /Script/Engine.PlayerCameraManager")
 Key_C= find_required_object("ScriptStruct /Script/InputCore.Key")
 
 
 --TempStructs:
 TempKey = StructObject.new(Key_C)
 Temphitresult = StructObject.new(hitresult_c)
 
 --Globals:
 CurrentEquipmentArray = {}
 canReload=false
 isReloading=false
 isChanging=false
 FoundSocket=nil
 ReloadInProgress=false
 LeftController=uevr.params.vr.get_left_joystick_source()
 StickFactor = 0
 gDelta = 0
 isMenu=false
 isSprinting=false
 AltLoHmdDelRot = 0
 AltLoHmdLastRot = 0
 WpnSwitch=false
 ChangeReq=false
 wasLShoulderPressed=false
 wasRShoulderPressed=false
 CameraManager=UEVR_UObjectHook.get_first_object_by_class(CameraManager_C)
 
 
 isThumbMotion=false
 TriggerCheck=false
 CheckCollision=false
 CheckedMag=false
 neededPitch= 0
 neededYaw = 0
 neededRoll=0
 CheckDelta=0--From FOVFixer
 
 BodyVisibilityChecked=false
 GlockMesh =nil
 BinoMesh=nil
 HandSceneComp=nil
 CurrentWeaponMesh=nil
  
 FireWeapon=true
 world= nil
 isCinematic=false

 unpressShoulder=false
 pressRC=false
 pressRS=false
 pressLC=false
 pressLH=false
 pressLS=false
 HandDistance=0
 canChange=false
 wasMatUpdated=false
 wasRecentered=false
 isSprinting = false

-- global functions:
function GetHandDistance()
	if right_hand_component == nil or left_hand_component==nil then return 0 end
	local rightLoc= right_hand_component:K2_GetComponentLocation()
	local leftLoc = left_hand_component:K2_GetComponentLocation()
	local Dist = kismet_math_library:Vector_Distance(rightLoc,leftLoc)
	return Dist
end

